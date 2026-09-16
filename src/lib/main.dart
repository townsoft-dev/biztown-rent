import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_strings.dart';
import 'core/locale_provider.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'data/push_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppStrings.init();
    AppStrings.current = await resolveInitialLanguage();
  } catch (e) {
    debugPrint('AppStrings.init() lỗi, dùng key thô tạm thời: $e');
  }
  // S-00 edge case (SCREEN-SPEC.md): "Mạng chậm → timeout hợp lý (10s), không treo
  // màn hình." initSupabase() có thể phải làm mới session qua mạng — nếu quá 10s coi
  // như chưa xác định được session, cứ vào Splash bình thường (Splash tự check lại
  // supabase.auth.currentSession, mạng vẫn chậm thì rơi về /login, không treo app).
  try {
    await initSupabase().timeout(const Duration(seconds: 10));
  } on Exception catch (e) {
    debugPrint(
        'initSupabase() timeout/lỗi, vào Splash với session chưa xác định: $e');
  }
  // Push (FCM) — chuẩn bị hạ tầng xong (docs/DECISIONS.md Đợt 41/46). PHẢI chạy
  // SAU initSupabase() ở trên: `pushRepository` (biến top-level) đọc `supabase`
  // ngay lúc khởi tạo, gọi sớm hơn sẽ crash "You must initialize the supabase
  // instance". Lỗi ở đây không được phép chặn app khởi động, chỉ mất tính năng push.
  try {
    await Firebase.initializeApp();
    pushRepository.listenTokenRefresh();
  } catch (e) {
    debugPrint('Firebase.initializeApp() lỗi, app chạy tiếp không có push: $e');
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
      // Chạm ra ngoài ô nhập thì ẩn bàn phím — áp cho TOÀN APP tại đúng một
      // chỗ, thay vì phải nhớ bọc GestureDetector ở từng màn (dungtv báo
      // 16/09/2026: bàn phím che mất nút Lưu ở màn Thêm phòng, chạm ra ngoài
      // vẫn không ẩn).
      //
      // `HitTestBehavior.translucent` để cú chạm vẫn đi tiếp xuống widget bên
      // dưới — nếu dùng `opaque` thì lớp này nuốt mất mọi cú chạm, bấm nút nào
      // cũng không ăn.
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: child,
      ),
    );
  }
}
