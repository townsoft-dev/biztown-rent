import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Đọc từ --dart-define, không hardcode secret.
/// Ví dụ chạy: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
}

/// Mã lỗi PostgREST khi token có `iat` (thời điểm cấp) nằm ở TƯƠNG LAI so với
/// đồng hồ máy chủ đang kiểm tra.
const _jwtIssuedAtFutureCode = 'PGRST303';

/// Bọc lớp HTTP của Supabase để tự thử lại khi gặp lỗi lệch đồng hồ máy chủ.
///
/// Lỗi thật gặp trên iPhone của dungtv (bản TestFlight, 16/09/2026): mở app lên
/// là màn Người thuê hiện thẳng dòng lỗi kỹ thuật
/// `PostgrestException(message: JWT issued at future, code: PGRST303)`, tắt app
/// bật lại thì hết.
///
/// Vì sao KHÔNG sửa bằng cách làm mới phiên rồi thử lại: `iat` do chính máy chủ
/// Supabase sinh ra, nên lỗi này là lệch đồng hồ giữa nơi CẤP token và nơi KIỂM
/// TRA token. Làm mới phiên chỉ tạo ra token có `iat` còn mới hơn, càng chắc bị
/// coi là "tương lai". Cách đúng là CHỜ một chút rồi gửi lại ĐÚNG token cũ — lúc
/// đó đồng hồ bên kiểm tra đã đuổi kịp. Đây cũng chính là lý do tắt/mở lại app
/// thì hết: đủ thời gian trôi qua.
///
/// Đặt ở tầng HTTP thay vì ở từng provider/repository để phủ MỌI truy vấn của
/// toàn app bằng một chỗ duy nhất (36 provider + mọi repository), tránh sót chỗ.
class _RetryOnClockSkewClient extends http.BaseClient {
  _RetryOnClockSkewClient(this._inner);

  final http.Client _inner;

  static const _retryDelay = Duration(seconds: 2);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode != 401) return response;

    // Phải đọc hết body mới biết có đúng mã PGRST303 không, nhưng body là
    // stream chỉ đọc được 1 lần — nên luôn dựng lại response để nơi gọi vẫn
    // đọc được bình thường trong trường hợp không thử lại.
    final body = await response.stream.bytesToString();
    final isClockSkew = body.contains(_jwtIssuedAtFutureCode);

    // Chỉ thử lại được với request thường (có sẵn bodyBytes để gửi lại). Loại
    // streamed/multipart (VD upload ảnh lên Storage) không dựng lại được nên bỏ
    // qua — chấp nhận được vì lỗi này chỉ xảy ra ngay sau khi cấp token, còn
    // upload ảnh luôn là thao tác người dùng chủ động bấm sau đó.
    if (!isClockSkew || request is! http.Request) {
      return _rebuild(response, body);
    }

    debugPrint(
        'Supabase trả $_jwtIssuedAtFutureCode (lệch đồng hồ máy chủ) — chờ '
        '${_retryDelay.inSeconds}s rồi gửi lại: ${request.method} ${request.url.path}');
    await Future<void>.delayed(_retryDelay);

    final retry = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
    return _inner.send(retry);
  }

  http.StreamedResponse _rebuild(http.StreamedResponse original, String body) {
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream.value(bytes),
      original.statusCode,
      contentLength: bytes.length,
      request: original.request,
      headers: original.headers,
      isRedirect: original.isRedirect,
      persistentConnection: original.persistentConnection,
      reasonPhrase: original.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    httpClient: _RetryOnClockSkewClient(http.Client()),
  );
}

SupabaseClient get supabase => Supabase.instance.client;
