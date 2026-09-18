import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../data/push_repository.dart';

/// S-00 — Splash. Xem docs/SCREEN-SPEC.md mục 2.1 + ảnh Figma thật (09/09/2026).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Timeout 10s cho mạng chậm (SCREEN-SPEC.md edge case) đã xử lý ở main.dart
    // (bọc initSupabase()). Giữ màn này hiện đủ lâu (2s) để thấy rõ logo/tagline —
    // dungtv phản hồi 400ms trước đó chớp quá nhanh trên máy thật.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final hasSession = supabase.auth.currentSession != null;
    // Không await — không được phép làm chậm điều hướng vì lý do push.
    if (hasSession) unawaited(pushRepository.registerDeviceToken());
    context.go(hasSession ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo thương hiệu BizTown (icon + wordmark "BizTown", luôn đi
            // cùng nhau — không dùng icon trần) — bộ asset mới Dream gửi
            // 18/09/2026, xem docs/DESIGN-SYSTEMS.md mục 1.1. Bản "Rent" (cột
            // cam) vì app này là Rent Manager trong bộ ứng dụng BizTown.
            // Icon 100×100 có ĐỔ BÓNG để nổi khỏi nền navy — nền splash và
            // nền ô vuông icon cùng là `#23305E` nên không có bóng thì icon
            // chìm hẳn vào nền (dungtv báo 18/09/2026).
            //
            // Thông số bóng đo pixel trên bản render Figma S-00 (node
            // `220:2153`): chỉ đổ XUỐNG DƯỚI, lan ~9px, chỗ đậm nhất `#1B2548`
            // trên nền `#23305E` — quy ra đen ~23%.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.23),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Image.asset(
                  'assets/logo/biztown-rent-icon-wordmark-alt.png',
                  width: 100),
            ),
            // 12px: khoảng hở đo trên Figma (đáy icon y=402.5 → đỉnh wordmark
            // y=414.5).
            const SizedBox(height: 12),
            Image.asset('assets/logo/rentmanager-wordmark-bold-white.png',
                width: 248),
            // Figma ẩn hẳn dòng mô tả (`hidden="true"`) — dungtv: trang tải rất
            // nhanh, không cần dòng giới thiệu. Chuỗi `splash.tagline` vẫn giữ
            // trong 3 file ngôn ngữ phòng khi dùng lại chỗ khác.
          ],
        ),
      ),
    );
  }
}
