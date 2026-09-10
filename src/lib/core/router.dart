import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import '../data/models/reading.dart';
import '../landlord/home_screen.dart';
import '../landlord/house_form_screen.dart';
import '../landlord/reading_detail_screen.dart';
import '../landlord/reading_entry_screen.dart';
import '../landlord/room_detail_screen.dart';
import '../landlord/room_form_screen.dart';
import '../landlord/room_list_screen.dart';
import '../shared/app_shell.dart';
import '../shared/coming_soon_screen.dart';
import '../shared/login_screen.dart';
import '../shared/notification_center_screen.dart';
import '../shared/signup_screen.dart';
import '../shared/splash_screen.dart';
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
    final atLogin = state.matchedLocation == '/login';
    final atSignup = state.matchedLocation == '/signup';

    if (atSplash) {
      return null; // S-00 tự quyết định điều hướng, xem splash_screen.dart
    }
    if (!loggedIn && !atLogin && !atSignup) return '/login';
    // KHÔNG tự redirect sang /home khi loggedIn (kể cả lúc đang ở /login) — chỉ dùng
    // redirect này để CHẶN truy cập khi chưa đăng nhập. Lý do: SignupScreen dùng
    // context.push('/signup') (để nút Back hoạt động đúng — xem Đợt 09/09 16:00), mà
    // push() không đổi state.matchedLocation ở đây (vẫn báo "/login" dù đang hiện
    // SignupScreen) — nếu còn rule "loggedIn && atLogin → /home", Supabase tạo
    // session ngay sau verifyOTP (trước khi đặt mật khẩu) sẽ bị hiểu nhầm là "đang ở
    // /login đã đăng nhập" và bắn thẳng sang /home, bỏ qua hẳn bước Set password.
    // Điều hướng sau khi đăng nhập/đăng ký giờ làm tường minh: LoginScreen tự
    // context.go('/home') sau signInWithPassword; SignupScreen tự context.go('/home')
    // sau khi bấm "Get started" ở bottom sheet thành công.
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                  path: 'houses/new',
                  builder: (context, state) => const HouseFormScreen()),
              GoRoute(
                path: 'houses/:houseId',
                builder: (context, state) =>
                    RoomListScreen(houseId: state.pathParameters['houseId']!),
                routes: [
                  GoRoute(
                      path: 'edit',
                      builder: (context, state) => HouseFormScreen(
                          houseId: state.pathParameters['houseId'])),
                  GoRoute(
                    path: 'rooms/new',
                    builder: (context, state) => RoomFormScreen(
                        houseId: state.pathParameters['houseId']!),
                  ),
                  GoRoute(
                    path: 'rooms/:roomId',
                    builder: (context, state) => RoomDetailScreen(
                      houseId: state.pathParameters['houseId']!,
                      roomId: state.pathParameters['roomId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => RoomFormScreen(
                          houseId: state.pathParameters['houseId']!,
                          roomId: state.pathParameters['roomId'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'readings',
                    builder: (context, state) => ReadingEntryScreen(
                        houseId: state.pathParameters['houseId']!),
                    routes: [
                      // roomId + utility (electricity/water) — 1 phòng có 2
                      // chuỗi chỉ số độc lập (tb_electricity_reading và
                      // tb_water_reading), không phải 1 "readingId" đơn lẻ.
                      GoRoute(
                        path: ':roomId/:utility',
                        builder: (context, state) => ReadingDetailScreen(
                          houseId: state.pathParameters['houseId']!,
                          roomId: state.pathParameters['roomId']!,
                          utilityType: UtilityTypeX.fromPathSegment(
                              state.pathParameters['utility']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )
        ]),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tenant',
              builder: (context, state) => const ComingSoonScreen(
                  title: 'Tenant & Contract', icon: Icons.group_rounded),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/bills',
                builder: (context, state) => const ComingSoonScreen(
                    title: 'Bills', icon: Icons.receipt_long_rounded))
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => ComingSoonScreen(
                title: 'Profile',
                icon: Icons.person_rounded,
                footer: OutlinedButton(
                    onPressed: () => authRepository.signOut(),
                    child: const Text('Đăng xuất')),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
