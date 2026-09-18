import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
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
            Image.asset('assets/logo/biztown-rent-icon-wordmark-alt.png',
                width: 116),
            const SizedBox(height: 18),
            // Tên sản phẩm "RENT MANAGER" tách riêng khỏi logo thương hiệu ở
            // trên (trước đây gộp chung 1 lockup) — theo yêu cầu Dream
            // 18/09/2026: Splash chỉ đẩy logo thương hiệu lên trên, tên sản
            // phẩm ở dưới. Dùng bản **chữ đậm** (`-bold-white`) — Dream gửi
            // thêm 2 file wordmark chữ đậm cùng ngày và chọn dùng bản này
            // thay cho bản chữ thường trước đó, xem docs/DESIGN-SYSTEMS.md
            // mục 1.1.
            Image.asset('assets/logo/rentmanager-wordmark-bold-white.png',
                width: 188),
            const SizedBox(height: 14),
            Text(
              AppStrings.t('splash.tagline'),
              style: const TextStyle(
                  color: Color(0xFFC9CEE0), fontSize: 13, height: 18 / 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
