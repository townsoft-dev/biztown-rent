import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'segmented_control.dart';
import 'top_bar.dart';

/// S-03 — Notification Center (node 220:2270, lấy qua Figma MCP 09/09/2026).
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  int _tab = 0; // 0 = All, 1 = Unread

  static const _items = [
    _NotificationItem(
      thumbColor: AppColors.accentCoral,
      icon: Icons.receipt_long,
      title: 'New invoice sent',
      badge: StatusBadgeStyle.sent,
      body: 'P.101 · period 09/2026 · 4,180,000 VND',
      meta: '2 hours ago   → B-04',
    ),
    _NotificationItem(
      thumbColor: AppColors.accentOrange,
      icon: Icons.speed,
      title: 'Time to record readings',
      badge: StatusBadgeStyle.expiringSoon,
      body: 'Nha tro Binh An  ·  8 rooms',
      meta: 'Today, 08:00   → H-07',
    ),
    _NotificationItem(
      thumbColor: AppColors.primary,
      icon: Icons.event_repeat,
      title: 'Time to create invoices',
      badge: StatusBadgeStyle.draft,
      body: 'Period 09/2026 · 18 active contracts',
      meta: 'Today, 08:00   → B-03',
    ),
    _NotificationItem(
      thumbColor: AppColors.error,
      icon: Icons.warning,
      title: 'Invoice overdue',
      badge: StatusBadgeStyle.overdue,
      body: 'P.06 · Hoang Gia Huy · 6 days late',
      meta: 'Yesterday   → B-04',
    ),
    _NotificationItem(
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
                AppSegmentedControl(labels: const ['All', 'Unread'], selectedIndex: _tab, onChanged: (i) => setState(() => _tab = i)),
                const SizedBox(height: 8),
                for (final item in _items) ...[item, const SizedBox(height: 8)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Color thumbColor;
  final IconData icon;
  final String title;
  final StatusBadgeStyle badge;
  final String body;
  final String meta;

  const _NotificationItem({required this.thumbColor, required this.icon, required this.title, required this.badge, required this.body, required this.meta, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [BoxShadow(color: const Color(0xFF14192E).withValues(alpha: 0.06), offset: const Offset(0, 1), blurRadius: 1)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: thumbColor, borderRadius: BorderRadius.circular(AppRadii.thumbIcon)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, height: 20 / 14, color: AppColors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: badge.background, borderRadius: BorderRadius.circular(AppRadii.pill)),
                      child: Text('Unread', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, height: 14 / 11, color: badge.foreground)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(body, style: GoogleFonts.inter(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(meta, style: GoogleFonts.inter(fontSize: 12, height: 17 / 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
