import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 3 ngôn ngữ hỗ trợ Phase 1 (FR-MGR-05, docs/REQUIREMENTS.md).
enum AppLanguage { en, vi, ko }

/// Đọc text UI từ `assets/lang/*.json` (dungtv tự sửa được, xem
/// changelog/2026-09-10.md mục 11:55). Mặc định tiếng Anh.
///
/// TODO: khi làm màn chọn ngôn ngữ ở P-01, đổi `current` theo cài đặt ngôn
/// ngữ máy lúc khởi động (`WidgetsBinding.instance.platformDispatcher.locale`),
/// giới hạn về đúng 1 trong 3 ngôn ngữ hỗ trợ — máy dùng ngôn ngữ khác thì
/// vẫn mặc định "en".
class AppStrings {
  AppStrings._();

  static AppLanguage current = AppLanguage.en;
  static final Map<AppLanguage, Map<String, dynamic>> _data = {};

  static Future<void> init() async {
    for (final lang in AppLanguage.values) {
      final raw = await rootBundle.loadString('assets/lang/${lang.name}.json');
      _data[lang] = jsonDecode(raw) as Map<String, dynamic>;
    }
  }

  /// `key` dạng "section.key", ví dụ "login.title". `params` thay các
  /// `{name}` giữ chỗ trong text (ví dụ `{"minutes": "5"}` cho "...{minutes} phút.").
  static String t(String key, [Map<String, String>? params]) {
    dynamic node = _data[current];
    for (final part in key.split('.')) {
      if (node is Map<String, dynamic> && node.containsKey(part)) {
        node = node[part];
      } else {
        return key; // thiếu key -> hiện nguyên key để dễ phát hiện, không throw
      }
    }
    var text = node.toString();
    params?.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }
}
