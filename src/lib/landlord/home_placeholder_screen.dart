import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase_client.dart';
import '../data/auth_repository.dart';

/// Placeholder — thay bằng H-01 thật (bottom nav 4 tab: Home/Tenant & Contract/
/// Bills/Profile) khi code tới Home tab. Hiện chỉ để verify luồng Auth end-to-end.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = supabase.auth.currentUser?.phone ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Home (placeholder)')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đăng nhập thành công: $phone'),
            const SizedBox(height: 16),
            // TODO: tạm để verify S-03 tới khi H-01 thật có bell icon trên Topbar.
            ElevatedButton(
              onPressed: () => context.push('/notifications'),
              child: const Text('Xem Notifications (S-03)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => authRepository.signOut(),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
