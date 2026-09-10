import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';

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
            SvgPicture.asset('assets/logo/biztown-rent-manager-lockup-on-navy.svg', width: 280),
            const SizedBox(height: 12),
            const Text(
              'Houses and Rooms Renting Management Tool',
              style: TextStyle(color: Color(0xFFC9CEE0), fontSize: 13, height: 18 / 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
