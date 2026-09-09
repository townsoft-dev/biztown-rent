import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../shared/login_screen.dart';
import '../shared/signup_screen.dart';
import '../shared/splash_screen.dart';
import '../landlord/home_placeholder_screen.dart';
import 'supabase_client.dart';

/// Chuyển Stream thành Listenable để go_router tự redirect lại mỗi khi auth
/// state đổi (đăng nhập/đăng xuất) mà không cần rebuild toàn bộ widget tree.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final atSplash = state.matchedLocation == '/splash';
    final atAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (atSplash) return null; // S-00 tự quyết định điều hướng, xem splash_screen.dart
    if (!loggedIn && !atAuth) return '/login';
    if (loggedIn && atAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    // TODO: thay bằng H-01 thật (bottom nav 4 tab) khi code tới Home tab.
    GoRoute(path: '/home', builder: (context, state) => const HomePlaceholderScreen()),
  ],
);
