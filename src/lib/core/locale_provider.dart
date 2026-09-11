import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

const _prefsKey = 'app_language';

/// Xác định ngôn ngữ khởi động: đã từng chọn (lưu SharedPreferences) thì
/// dùng lại; chưa từng chọn thì lấy theo ngôn ngữ máy (giới hạn đúng 3 ngôn
/// ngữ hỗ trợ), máy dùng ngôn ngữ khác thì mặc định "en". Gọi 1 lần trong
/// `main()` TRƯỚC `runApp` — khung hình đầu tiên phải đã đúng ngôn ngữ, tránh
/// nhấp nháy đổi ngôn ngữ ngay sau khi mở app.
Future<AppLanguage> resolveInitialLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefsKey);
  if (saved != null) {
    for (final lang in AppLanguage.values) {
      if (lang.name == saved) return lang;
    }
  }
  final deviceCode =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return switch (deviceCode) {
    'vi' => AppLanguage.vi,
    'ko' => AppLanguage.ko,
    _ => AppLanguage.en,
  };
}

/// Ngôn ngữ hiện tại — mọi màn có gọi `AppStrings.t(...)` PHẢI
/// `ref.watch(languageProvider)` (dù không dùng giá trị) để tự vẽ lại đúng
/// chữ mới khi người dùng đổi ngôn ngữ ở P-01, vì `AppStrings.t()` tự nó
/// không phải là 1 nguồn dữ liệu Riverpod theo dõi được.
class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppStrings.current;

  Future<void> setLanguage(AppLanguage lang) async {
    AppStrings.current = lang;
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, lang.name);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);
