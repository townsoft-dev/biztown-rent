import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// State cho 1 ô chọn ảnh (H-02/H-05 Photos) — tách khỏi widget hiển thị
/// (`PhotoPickerRow`) để màn cha (House/Room form) đọc được kết quả lúc bấm
/// Save mà không phải tự quản lý list ảnh rải rác trong `setState`.
class PhotoPickerController extends ChangeNotifier {
  /// Path ảnh đã có sẵn trong Storage (đang sửa 1 Nhà/Phòng có ảnh cũ).
  final List<String> existingPaths;
  final List<XFile> _newFiles = [];
  final List<String> _removedExisting = [];

  PhotoPickerController({List<String>? initialPaths})
      : existingPaths = List.of(initialPaths ?? const []);

  List<XFile> get newFiles => List.unmodifiable(_newFiles);

  /// Path ảnh cũ vẫn còn giữ lại (đã trừ những cái người dùng bấm xoá).
  List<String> get keptExistingPaths =>
      existingPaths.where((p) => !_removedExisting.contains(p)).toList();

  /// Path ảnh cũ bị xoá — màn cha gọi `HouseRepository.deletePhoto`/
  /// `RoomRepository.deletePhoto` cho từng path này SAU KHI lưu thành công.
  List<String> get removedExisting => List.unmodifiable(_removedExisting);

  void addFile(XFile file) {
    _newFiles.add(file);
    notifyListeners();
  }

  void removeExisting(String path) {
    _removedExisting.add(path);
    notifyListeners();
  }

  void removeNew(XFile file) {
    _newFiles.remove(file);
    notifyListeners();
  }
}
