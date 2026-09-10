import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // S-00 edge case (SCREEN-SPEC.md): "Mạng chậm → timeout hợp lý (10s), không treo
  // màn hình." initSupabase() có thể phải làm mới session qua mạng — nếu quá 10s coi
  // như chưa xác định được session, cứ vào Splash bình thường (Splash tự check lại
  // supabase.auth.currentSession, mạng vẫn chậm thì rơi về /login, không treo app).
  try {
    await initSupabase().timeout(const Duration(seconds: 10));
  } on Exception catch (e) {
    debugPrint('initSupabase() timeout/lỗi, vào Splash với session chưa xác định: $e');
  }
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BizTown Rent-Manager',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
