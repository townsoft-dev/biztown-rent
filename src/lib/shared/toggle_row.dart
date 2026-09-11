import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "toggle row" (Figma, node 331:2916 ở P-06 "Account active") — khung viền
/// hairline bo góc 9px cao 42px, chứa 1 nhãn + 1 `Switch`. Dùng ở field nào
/// cần bật/tắt 1 trạng thái boolean ngay trong form (khác hẳn `Switch` trần
/// không khung của Material mặc định).
class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        children: [
          // Khung chỉ vừa đủ 44×24 cho Switch (Figma: box+padding+switch
          // gần như khít hoàn toàn 169.5px của nửa Row), khiến "Account
          // active" ở đúng cỡ chữ 13.5px bị cắt còn "Account acti…" — dùng
          // `FittedBox(scaleDown)` để chữ tự co vừa đủ không gian còn lại,
          // KHÔNG BAO GIỜ mất chữ, thay vì `TextOverflow.ellipsis` cắt bớt
          // thông tin thật (chỉ co nhẹ khi thật sự thiếu chỗ, gần như không
          // nhận ra bằng mắt thường).
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 17 / 13.5,
                      color: AppColors.textPrimary)),
            ),
          ),
          // Figma dùng `justify-content: space-between` — KHÔNG có khoảng
          // cách cố định riêng giữa label và switch (đã bỏ SizedBox 8px tự
          // thêm trước đó, chiếm mất khoảng trống hiếm hoi label cần).
          // Kích thước cố định 44×24 đúng Figma (node 331:2918) — trước đó
          // dùng `Transform.scale` chỉ co lại phần VẼ, không co lại phần
          // KHÔNG GIAN mà `Row` dành cho `Switch` (Transform không ảnh hưởng
          // layout), khiến label bị bóp hẹp, tự xuống dòng và bị cắt mất chữ
          // "active" (chỉ còn thấy "Account"). `FittedBox` co cả layout lẫn
          // hình vẽ vào đúng khung 44×24 nên label có đủ chỗ hiện trọn vẹn.
          SizedBox(
            width: 44,
            height: 24,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
