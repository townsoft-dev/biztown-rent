import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "FAB" (168:61 trên Figma) — nút tròn nổi màu cam, dùng cho hành động thêm
/// mới (Nhà ở H-01, Phòng ở H-03, Tenant ở T-01...). Dùng qua
/// `Scaffold.floatingActionButton`, không tự đặt `Positioned` thủ công.
class AppFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const AppFab({super.key, required this.onPressed, this.icon = Icons.add});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentOrange,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.fab)),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.fab),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.fab),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accentOrange.withValues(alpha: 0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 16)
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
