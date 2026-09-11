import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "toggle row" (Figma, node 331:2916 ở P-06 "Account active") — khung viền
/// hairline bo góc 9px, chứa 1 nhãn + 1 switch. Dùng ở field nào cần bật/tắt
/// 1 trạng thái boolean ngay trong form (khác hẳn `Switch` trần không khung
/// của Material mặc định). KHÔNG tự đặt chiều cao cố định — luôn đặt bên
/// trong `IntrinsicHeight` + `CrossAxisAlignment.stretch` cùng 1 ô khác (VD ô
/// readonly "Manager" ở P-06) để 2 ô LUÔN cùng chiều cao thật sự, tránh lệch
/// cao thấp giữa `ToggleRow` và `TextFormField`/`Container` cạnh nó.
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
          _MiniSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// "switch" (Figma, node 331:2918 — ảnh minh hoạ 44×24) — tự vẽ lại bằng
/// hình khối cơ bản thay vì ép `Switch` gốc của Material (kích thước tự
/// nhiên ~59×39, tỉ lệ khác hẳn) vào đúng khung 44×24 bằng
/// `FittedBox(fit: BoxFit.fill)` — cách đó ép sai tỉ lệ khiến cả track lẫn
/// nút tròn bị kéo méo. Tự vẽ đúng 44×24 ngay từ đầu thì không có gì để méo.
class _MiniSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.success : AppColors.neutral200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 2,
                    offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
