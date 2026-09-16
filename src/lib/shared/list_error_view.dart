import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';

/// Hiển thị khi một màn danh sách tải dữ liệu thất bại.
///
/// Lý do tồn tại (16/09/2026): bản TestFlight trên iPhone của dungtv hiện thẳng
/// dòng lỗi kỹ thuật ra cho người dùng cuối —
/// `PostgrestException(message: JWT issued at future, code: PGRST303, ...)`.
/// Chủ trọ thật đọc dòng đó không hiểu gì và tưởng app hỏng. dungtv yêu cầu
/// không được để hiện tượng đó xảy ra nữa.
///
/// Nguyên tắc: người dùng chỉ thấy câu dễ hiểu + cách khắc phục (bấm Thử lại
/// hoặc kéo xuống); chi tiết kỹ thuật vẫn giữ nguyên trong log của lập trình
/// viên qua `debugPrint`, không mất thông tin để truy vết.
class ListErrorView extends StatelessWidget {
  const ListErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    debugPrint('Tải danh sách thất bại: $error');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.cloud_off,
              size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            AppStrings.t('common.loadFailed'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t('common.loadFailedHint'),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Symbols.refresh, size: 18),
            label: Text(AppStrings.t('common.retry')),
          ),
        ],
      ),
    );
  }
}
