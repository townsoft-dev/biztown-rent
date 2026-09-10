import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';

/// Khung 4-tab dùng chung cho `StatefulShellRoute.indexedStack` (core/router.dart)
/// — mỗi tab giữ nguyên navigation stack riêng khi chuyển qua lại.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index,
            initialLocation: index == navigationShell.currentIndex),
      ),
    );
  }
}
