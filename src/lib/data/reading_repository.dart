import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import 'models/reading.dart';

const _photosBucket = 'property-photos';

/// Ném ra khi chỉ số mới nhập nhỏ hơn chỉ số cũ (BR-READ-03/BR-BILL-06) — bắt
/// riêng ở UI để chỉ chặn đúng dòng phòng đó, không chặn lưu các phòng khác
/// (đúng edge case ghi trong SCREEN-SPEC.md mục H-06).
class ReadingOrderException implements Exception {
  final String message;
  const ReadingOrderException(this.message);
}

/// CRUD cho `tb_electricity_reading`/`tb_water_reading` (BR-READ-01..07,
/// BR-METER-13/14, docs/BUSINESS-RULES.md mục 6) — 2 bảng cấu trúc giống hệt
/// nhau nên dùng chung 1 repository, chọn bảng qua tham số `UtilityType`.
class ReadingRepository {
  final SupabaseClient _client;
  const ReadingRepository(this._client);

  Future<Reading?> byId(String id, UtilityType type) async {
    final row =
        await _client.from(type.table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Reading.fromMap(row, type);
  }

  /// Chỉ số gần nhất của 1 phòng (bất kỳ loại nào — PERIODIC/MOVE_IN/MOVE_OUT),
  /// dùng làm "chỉ số cũ" khi ghi 1 bản ghi mới (nguồn sự thật của chuỗi luôn
  /// là `previousReadingId`, không phải trường snapshot `previousReading`).
  Future<Reading?> latestForRoom(String roomId, UtilityType type) async {
    final rows = await _client
        .from(type.table)
        .select()
        .eq('room_id', roomId)
        .order('reading_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return Reading.fromMap(rows.first, type);
  }

  /// Bản ghi PERIODIC của đúng 1 kỳ (tháng) — dùng để biết phòng đã ghi kỳ
  /// này chưa (unique index `one_periodic_reading_per_room_period`).
  Future<Reading?> periodicForPeriod(
      String roomId, UtilityType type, DateTime periodYm) async {
    final row = await _client
        .from(type.table)
        .select()
        .eq('room_id', roomId)
        .eq('reading_type', ReadingType.periodic.dbValue)
        .eq('period_ym', _dateOnly(periodYm))
        .maybeSingle();
    if (row == null) return null;
    return Reading.fromMap(row, type);
  }

  /// Toàn bộ lịch sử chỉ số của 1 phòng (mới nhất trước) — hiển thị ở view
  /// chi tiết H-06.
  Future<List<Reading>> historyForRoom(String roomId, UtilityType type) async {
    final rows = await _client
        .from(type.table)
        .select()
        .eq('room_id', roomId)
        .order('reading_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => Reading.fromMap(row, type)).toList();
  }

  /// Ghi 1 bản ghi PERIODIC mới cho 1 phòng — tự tìm chỉ số gần nhất làm
  /// "cũ", validate current ≥ previous trước khi gọi DB (constraint DB chỉ là
  /// lưới chặn cuối, không phải chỗ báo lỗi chính cho người dùng).
  Future<Reading> createPeriodic({
    required String roomId,
    required String houseId,
    required UtilityType type,
    required DateTime periodYm,
    required DateTime readingDate,
    required num currentReading,
    String? photoUrl,
    String? note,
  }) async {
    final previous = await latestForRoom(roomId, type);
    if (previous != null && currentReading < previous.currentReading) {
      throw ReadingOrderException(
          'Current reading must be ≥ previous reading (${formatReadingValue(previous.currentReading)} ${type.unit}).');
    }
    final recordedByPhone = _client.auth.currentUser?.phone ?? '';
    final id = const Uuid().v4();
    final row = await _client
        .from(type.table)
        .insert({
          'id': id,
          'room_id': roomId,
          'house_id': houseId,
          'reading_type': ReadingType.periodic.dbValue,
          'period_ym': _dateOnly(periodYm),
          'reading_date': _dateOnly(readingDate),
          'previous_reading_id': previous?.id,
          'previous_reading': previous?.currentReading,
          'current_reading': currentReading,
          'recorded_by_phone': recordedByPhone,
          'photo_url': photoUrl,
          'note': note,
        })
        .select()
        .single();
    return Reading.fromMap(row, type);
  }

  /// Sửa tại chỗ 1 bản ghi (chỉ gọi khi đã xác nhận `!isLocked` — xem
  /// BR-METER-13, repository không tự chặn vì đó là quyết định UI cần hiện
  /// thông báo phù hợp trước khi gọi).
  Future<Reading> updateCurrentReading({
    required String id,
    required UtilityType type,
    required num currentReading,
    String? photoUrl,
    String? note,
  }) async {
    final row = await _client
        .from(type.table)
        .update({
          'current_reading': currentReading,
          if (photoUrl != null) 'photo_url': photoUrl,
          'note': note,
        })
        .eq('id', id)
        .select()
        .single();
    return Reading.fromMap(row, type);
  }

  /// isLocked là derived, không lưu cột riêng (BR-READ-04): true nếu chính
  /// bản ghi này đã gắn vào 1 hoá đơn (`invoice_id`), HOẶC nó bị 1 hoá đơn
  /// khác tham chiếu làm chỉ số "from" trong `utility_lines`. Hiện Bills chưa
  /// có tính năng tạo hoá đơn (`tb_invoice` luôn rỗng) nên trong thực tế hàm
  /// này luôn trả `false` — vẫn cài đúng logic để tự đúng ngay khi Bills xây xong.
  Future<bool> isLocked(Reading reading) async {
    if (reading.invoiceId != null) return true;
    final invoices = await _client
        .from('tb_invoice')
        .select('utility_lines')
        .eq('house_id', reading.houseId)
        .neq('status', 'Draft');
    for (final invoice in invoices) {
      final lines = (invoice['utility_lines'] as List?) ?? const [];
      for (final line in lines) {
        if (line is Map && line['readingId'] == reading.id) return true;
      }
    }
    return false;
  }

  Future<String> uploadPhoto(
      String houseId, String roomId, UtilityType type, File file) async {
    final ext = file.path.split('.').last;
    final path =
        '$houseId/readings/$roomId/${type.pathSegment}/${const Uuid().v4()}.$ext';
    await _client.storage.from(_photosBucket).upload(path, file);
    return path;
  }

  Future<String> signedPhotoUrl(String path) async {
    return _client.storage.from(_photosBucket).createSignedUrl(path, 3600);
  }

  String _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day)
      .toIso8601String()
      .split('T')
      .first;
}

final readingRepository = ReadingRepository(supabase);
