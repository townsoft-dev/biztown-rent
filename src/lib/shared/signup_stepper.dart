import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "Stepper" (173:139 trên Figma) — 3 bước Sign up: SĐT → OTP → mật khẩu.
/// Xanh = xong, cam = đang làm, xám = chưa tới. Kích thước cố định 104×8 theo
/// đúng asset gốc (dot r=4 tại x=4/52/100, line dài 28 nối giữa).
///
/// Lưu ý: component `173:139` trên Figma là bản CŨ (bước 1 vẽ vạch xám). Màu
/// vạch lấy theo frame màn hình thật, xem chú thích trong `lineColor` bên dưới.
class SignupStepper extends StatelessWidget {
  final int current; // 1, 2, hoặc 3

  const SignupStepper({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 8,
      child: CustomPaint(painter: _StepperPainter(current)),
    );
  }
}

class _StepperPainter extends CustomPainter {
  final int current;
  _StepperPainter(this.current);

  @override
  void paint(Canvas canvas, Size size) {
    Color dotColor(int index) {
      if (index < current) return AppColors.success;
      if (index == current) return AppColors.accentOrange;
      return AppColors.neutral200;
    }

    final dotPaint = Paint();
    for (final cx in [4.0, 52.0, 100.0]) {
      final index = cx == 4.0 ? 1 : (cx == 52.0 ? 2 : 3);
      dotPaint.color = dotColor(index);
      canvas.drawCircle(const Offset(0, 4) + Offset(cx, 0), 4, dotPaint);
    }
    // Vạch nối nằm giữa chấm `index` và chấm `index + 1`.
    //
    // Cam ở vạch NGAY SAU chấm đang làm của bước 1: dungtv báo 16/09/2026 màn
    // Đăng ký vạch này đang xám, "đổi màu chỗ này (thiết kế đã sửa)". Đối chiếu
    // Figma thấy 2 frame nội dung y hệt nhau nhưng vạch khác màu — frame cũ
    // `220:2214` (Create account) để xám, frame mới `386:2282` (Forgot
    // password?) để cam `#EF9F27`. Lấy theo frame mới.
    //
    // Bước 2 vẫn để xám vì CẢ HAI frame bước 2 (`347:2941` và `388:2375`) đều
    // vẽ xám — không tự suy ra quy tắc "luôn cam sau chấm hiện tại" rồi sửa
    // luôn bước 2, vì như thế là đoán ngược lại thiết kế đã duyệt.
    Color lineColor(int index) {
      if (index < current) return AppColors.success;
      if (index == current && current == 1) return AppColors.accentOrange;
      return AppColors.neutral200;
    }

    final linePaint = Paint();
    for (final x in [14.0, 62.0]) {
      linePaint.color = lineColor(x == 14.0 ? 1 : 2);
      canvas.drawRect(Rect.fromLTWH(x, 3, 28, 2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepperPainter oldDelegate) =>
      oldDelegate.current != current;
}
