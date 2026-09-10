import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../data/photo_picker_controller.dart';

/// Hàng chọn ảnh (H-02 House info / H-05 Photos trên Figma) — ảnh đã có sẵn
/// (tải qua `resolveExistingUrl`) + ảnh mới vừa chọn (preview từ máy) + 1 ô
/// "+" để thêm. Chưa upload ngay lúc chọn — màn cha (House/Room form) chỉ
/// thật sự upload lên Storage lúc bấm Save, xem `PhotoPickerController`.
class PhotoPickerRow extends StatelessWidget {
  final PhotoPickerController controller;
  final Future<String> Function(String path) resolveExistingUrl;

  const PhotoPickerRow(
      {super.key, required this.controller, required this.resolveExistingUrl});

  Future<void> _pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file != null) controller.addFile(file);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final path in controller.keptExistingPaths) ...[
                _PhotoTile(
                  child: FutureBuilder<String>(
                    future: resolveExistingUrl(path),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
                        child: Image.network(snapshot.data!,
                            width: 72, height: 72, fit: BoxFit.cover),
                      );
                    },
                  ),
                  onRemove: () => controller.removeExisting(path),
                ),
                const SizedBox(width: 8),
              ],
              for (final file in controller.newFiles) ...[
                _PhotoTile(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
                    child: Image.file(File(file.path),
                        width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  onRemove: () => controller.removeNew(file),
                ),
                const SizedBox(width: 8),
              ],
              _PhotoTile(
                dashed: true,
                onTap: () => _pickPhoto(context),
                child: const Icon(Icons.add_a_photo_rounded,
                    color: AppColors.textTertiary, size: 22),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Widget child;
  final bool dashed;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _PhotoTile(
      {required this.child, this.dashed = false, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgMuted,
              borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
              // Figma dùng viền nét đứt cho ô "+"; Flutter không có BorderStyle nét
              // đứt sẵn, dùng viền liền thay thế thay vì thêm package chỉ cho 1 chi
              // tiết nhỏ này.
              border: dashed ? Border.all(color: AppColors.neutral200) : null,
            ),
            child: child,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.error,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}
