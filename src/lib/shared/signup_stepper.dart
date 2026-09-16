import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "Stepper" (173:139 trên Figma) — 3 bước Sign up: SĐT → OTP → mật khẩu.
/// Kích thước cố định 104×8 theo đúng asset gốc (dot r=4 tại x=4/52/100,
/// line dài 28 nối giữa).
///
/// **Quy tắc màu** (dungtv chốt 16/09/2026): chấm CAM = bước người dùng đang
/// đứng. Làm xong bước nào thì chấm bước đó VÀ vạch ngay sau nó chuyển XANH.
/// Bước chưa tới để XÁM. Nói cách khác vạch chỉ có hai màu **xám → xanh**,
/// không bao giờ cam — cam là màu dành riêng cho chấm đang làm.
///
/// Frame `386:2282` (S-04 Forgot password) trên Figma vẽ vạch bước 1 màu cam
/// là SAI so với quy tắc trên, không phải bản thiết kế mới. Đừng sửa code theo
/// nó; xem `docs/DECISIONS.md` Đợt 53.
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
    // Vạch nối nằm giữa chấm `index` và chấm `index + 1`, nên nó xanh đúng khi
    // bước `index` đã xong — cùng điều kiện với chấm `index`.
    final linePaint = Paint();
    for (final x in [14.0, 62.0]) {
      final index = x == 14.0 ? 1 : 2;
      linePaint.color =
          index < current ? AppColors.success : AppColors.neutral200;
      canvas.drawRect(Rect.fromLTWH(x, 3, 28, 2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepperPainter oldDelegate) =>
      oldDelegate.current != current;
}
