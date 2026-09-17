import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Detail row" (168:58 trên Figma) — dòng key–value trong 1 `DetailBlock`.
/// `showDivider = false` cho dòng cuối cùng (bỏ viền gạch dưới).
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const DetailRow(
      {super.key,
      required this.label,
      required this.value,
      this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      // Figma vẽ đường ngăn cách giữa 2 dòng là **nét chấm**, không phải nét
      // liền (dungtv gửi ảnh 2 màn B-02 và T-05, 18/09/2026). `Border` của
      // Flutter không có kiểu nét chấm nên phải tự vẽ — dùng lại đúng cách đã
      // làm cho viền đứt nét của chip "kỳ tương lai" ở `invoice_schedule_strip`.
      decoration: showDivider ? const _DottedBottomBorder() : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung thẻ trắng bo góc chứa nhiều `DetailRow` liên tiếp (168:58's parent
/// "detail block" trên Figma) — dùng ở H-03/H-04/H-06 thay vì tự bọc
/// Container lặp lại mỗi màn.
class DetailBlock extends StatelessWidget {
  final List<Widget> children;

  const DetailBlock({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

/// Đường ngăn cách nét chấm ở đáy 1 `DetailRow`.
///
/// Thông số đo pixel trực tiếp trên component Figma `168:58` (18/09/2026):
/// chấm **2px, cách 2px**, dày 1px, đầu vuông, màu `borderSubtle` `#EEF0F5`,
/// chạy suốt bề ngang dòng. Bản sửa đầu tiên hôm nay đoán 1.5/3.0 màu
/// `neutral200` vì lúc đó Figma MCP mất đăng nhập — sai cả 3 thông số.
class _DottedBottomBorder extends Decoration {
  const _DottedBottomBorder();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DottedBottomBorderPainter();
}

class _DottedBottomBorderPainter extends BoxPainter {
  static const _strokeWidth = 1.0;
  static const _dotWidth = 2.0;
  static const _gapWidth = 2.0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final y = offset.dy + size.height - _strokeWidth / 2;
    final paint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;
    var x = offset.dx;
    final endX = offset.dx + size.width;
    while (x < endX) {
      final next = (x + _dotWidth).clamp(offset.dx, endX);
      canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      x = next + _gapWidth;
    }
  }
}
