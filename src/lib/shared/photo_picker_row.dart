import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Hàng chọn ảnh (H-02 House info / H-05 Photos trên Figma) — `photoCount` ô
/// ảnh đã có (placeholder xám, chưa nối Supabase Storage) + 1 ô "+" nét đứt
/// để thêm ảnh mới. Chưa xử lý upload thật — xem docs/CURRENT_STATUS.md mục
/// Supabase Storage.
class PhotoPickerRow extends StatelessWidget {
  final int photoCount;
  final VoidCallback? onAddPhoto;

  const PhotoPickerRow({super.key, this.photoCount = 0, this.onAddPhoto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < photoCount; i++) ...[
          const _PhotoTile(
              child: Icon(Icons.image_rounded,
                  color: AppColors.textTertiary, size: 22)),
          const SizedBox(width: 8),
        ],
        _PhotoTile(
          dashed: true,
          onTap: onAddPhoto,
          child: const Icon(Icons.add_a_photo_rounded,
              color: AppColors.textTertiary, size: 22),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Widget child;
  final bool dashed;
  final VoidCallback? onTap;

  const _PhotoTile({required this.child, this.dashed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}
