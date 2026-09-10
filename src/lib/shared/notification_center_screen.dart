import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import 'list_card.dart';
import 'segmented_control.dart';
import 'status_pill.dart';
import 'top_bar.dart';

/// S-03 — Notification Center (node 220:2270, lấy qua Figma MCP 09/09/2026).
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  int _tab = 0; // 0 = All, 1 = Unread

  static const _items = [
    _NotificationData(
      thumbColor: AppColors.accentCoral,
      icon: Icons.receipt_long,
      title: 'New invoice sent',
      badge: StatusBadgeStyle.sent,
      body: 'P.101 · period 09/2026 · 4,180,000 VND',
      meta: '2 hours ago   → B-04',
    ),
    _NotificationData(
      thumbColor: AppColors.accentOrange,
      icon: Icons.speed,
      title: 'Time to record readings',
      badge: StatusBadgeStyle.expiringSoon,
      body: 'Nha tro Binh An  ·  8 rooms',
      meta: 'Today, 08:00   → H-07',
    ),
    _NotificationData(
      thumbColor: AppColors.primary,
      icon: Icons.event_repeat,
      title: 'Time to create invoices',
      badge: StatusBadgeStyle.draft,
      body: 'Period 09/2026 · 18 active contracts',
      meta: 'Today, 08:00   → B-03',
    ),
    _NotificationData(
      thumbColor: AppColors.error,
      icon: Icons.warning,
      title: 'Invoice overdue',
      badge: StatusBadgeStyle.overdue,
      body: 'P.06 · Hoang Gia Huy · 6 days late',
      meta: 'Yesterday   → B-04',
    ),
    _NotificationData(
      thumbColor: AppColors.info,
      icon: Icons.description,
      title: 'Contract ending soon',
      badge: StatusBadgeStyle.expiringSoon,
      body: 'P.204 · Pham Van Duc · 13 days left',
      meta: '2 days ago   → T-05',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: 'Notifications',
            subtitle: '4 unread',
            onBack: () => context.pop(),
            trailing: TopBarMoreButton(onTap: () {}),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                AppSegmentedControl(
                    labels: const ['All', 'Unread'],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() => _tab = i)),
                const SizedBox(height: 8),
                for (final item in _items) ...[
                  ListCard(
                    thumbColor: item.thumbColor,
                    icon: item.icon,
                    title: item.title,
                    trailing: StatusPill(text: 'Unread', style: item.badge),
                    body: item.body,
                    meta: item.meta,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationData {
  final Color thumbColor;
  final IconData icon;
  final String title;
  final StatusBadgeStyle badge;
  final String body;
  final String meta;

  const _NotificationData(
      {required this.thumbColor,
      required this.icon,
      required this.title,
      required this.badge,
      required this.body,
      required this.meta});
}
