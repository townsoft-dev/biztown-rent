import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/app_notification.dart';
import 'list_card.dart';
import 'segmented_control.dart';
import 'status_pill.dart';
import 'top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// S-03 — Notification Center (node 220:2270, lấy qua Figma MCP 09/09/2026).
/// Đợt 2026-09-15: nối dữ liệu thật (`tb_notification`) — chỉ 3 loại tức thời
/// đã làm (BR-NOTI-01/03/06); 02/04/05 chạy theo lịch, để đợt sau nên KHÔNG
/// xuất hiện ở đây (không giả vờ có, tránh gây hiểu nhầm).
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  int _tab = 0; // 0 = All, 1 = Unread

  Future<void> _onTap(AppNotification n) async {
    if (n.isUnread) {
      // `notificationsProvider` là Realtime — UPDATE này tự phản ánh lại
      // ngay, không cần invalidate tay.
      await ref.read(notificationRepositoryProvider).markAsRead(n.id);
    }
    if (!mounted) return;
    // `context.go()` (không phải `push()`) — màn này (`/notifications`) nằm
    // NGOÀI `StatefulShellRoute`, còn 2 đích đến đều nằm BÊN TRONG 1 nhánh
    // shell (mỗi tab giữ Navigator riêng luôn tồn tại). `push()` từ ngoài
    // shell vào route bên trong shell làm go_router dựng thêm 1 bản shell
    // thứ 2 chồng lên bản đang có sẵn, đụng GlobalKey của chính branch đó và
    // crash "keyReservation.contains(key)" — lỗi đã biết của go_router, phát
    // hiện khi live-test thật (xem docs/DECISIONS.md).
    switch (n.type) {
      case NotificationType.invoiceSent:
      case NotificationType.invoiceCollected:
        if (n.targetInvoiceId != null) {
          context.go('/bills/invoices/${n.targetInvoiceId}');
        }
      case NotificationType.managerInvited:
        context.go('/profile/managers');
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return AppStrings.t('notifications.justNow');
    if (diff.inMinutes < 60) {
      return AppStrings.t(
          'notifications.minutesAgo', {'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return AppStrings.t(
          'notifications.hoursAgo', {'count': '${diff.inHours}'});
    }
    return AppStrings.t('notifications.daysAgo', {'count': '${diff.inDays}'});
  }

  ({Color color, IconData icon, String title, String body}) _present(
      AppNotification n) {
    final roomNos = (n.payload['roomNos'] as List?)?.join(', ') ?? '';
    final tenantName = n.payload['tenantName'] as String? ?? '';
    final amount = n.payload['amount'];
    final houseName = n.payload['houseName'] as String? ?? '';
    return switch (n.type) {
      NotificationType.invoiceSent => (
          color: AppColors.accentCoral,
          icon: Symbols.receipt_long_rounded,
          title: AppStrings.t('notifications.invoiceSentTitle'),
          body: AppStrings.t('notifications.invoiceLineBody', {
            'rooms': roomNos,
            'tenant': tenantName,
            'amount': formatNumber((amount as num?) ?? 0),
          }),
        ),
      NotificationType.invoiceCollected => (
          color: AppColors.success,
          icon: Symbols.task_alt_rounded,
          title: AppStrings.t('notifications.invoiceCollectedTitle'),
          body: AppStrings.t('notifications.invoiceLineBody', {
            'rooms': roomNos,
            'tenant': tenantName,
            'amount': formatNumber((amount as num?) ?? 0),
          }),
        ),
      NotificationType.managerInvited => (
          color: AppColors.primary,
          icon: Symbols.badge_rounded,
          title: AppStrings.t('notifications.managerInvitedTitle'),
          body: AppStrings.t(
              'notifications.managerInvitedBody', {'house': houseName}),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final itemsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('notifications.title'),
            subtitle: itemsAsync.maybeWhen(
              data: (items) => AppStrings.t('notifications.unreadCount',
                  {'count': '${items.where((n) => n.isUnread).length}'}),
              orElse: () => '',
            ),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered =
                    _tab == 1 ? items.where((n) => n.isUnread).toList() : items;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    AppSegmentedControl(
                        labels: [
                          AppStrings.t('notifications.tabAll'),
                          AppStrings.t('notifications.tabUnread')
                        ],
                        selectedIndex: _tab,
                        onChanged: (i) => setState(() => _tab = i)),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          AppStrings.t('notifications.empty'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textTertiary),
                        ),
                      ),
                    for (final n in filtered) ...[
                      Builder(builder: (context) {
                        final p = _present(n);
                        return ListCard(
                          thumbColor: p.color,
                          icon: p.icon,
                          title: p.title,
                          trailing: n.isUnread
                              ? StatusPill(
                                  text: AppStrings.t('notifications.tabUnread'),
                                  style: StatusBadgeStyle.sent)
                              : null,
                          body: p.body,
                          meta: _relativeTime(n.createdAt),
                          onTap: () => _onTap(n),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
