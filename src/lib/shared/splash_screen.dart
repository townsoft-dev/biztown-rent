import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';

/// S-00 — Splash. Xem docs/SCREEN-SPEC.md mục 2.1.
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
    // TODO: timeout 10s cho mạng chậm (edge case trong SCREEN-SPEC.md) — chưa
    // implement, hiện supabase_flutter tự xử lý refresh session khi khởi tạo.
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
            const Icon(Icons.home_work_outlined, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            Text(
              'BizTown Rent-Manager',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Simple rental management', style: TextStyle(color: Color(0xFFC9CEE0), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
