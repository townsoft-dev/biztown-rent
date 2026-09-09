import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "Stepper" (173:139 trên Figma) — 3 bước Sign up: SĐT → OTP → mật khẩu.
/// Xanh = xong, cam = đang làm, xám = chưa tới. Kích thước cố định 104×8 theo
/// đúng asset gốc (dot r=4 tại x=4/52/100, line dài 28 nối giữa).
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
    final linePaint = Paint();
    for (final x in [14.0, 62.0]) {
      final doneIndex = x == 14.0 ? 1 : 2;
      linePaint.color = doneIndex < current ? AppColors.success : AppColors.neutral200;
      canvas.drawRect(Rect.fromLTWH(x, 3, 28, 2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepperPainter oldDelegate) => oldDelegate.current != current;
}
