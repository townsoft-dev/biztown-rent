import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Top bar" — component dùng chung (166:34 trên Figma), 3 variant: Title,
/// Title+Action, Home (greeting + tên + dòng tổng quan + chuông — dùng
/// `TopBar.home(...)`). 375-wide navy header: back (tròn 26px, nền trắng 14%)
/// + tiêu đề 20 bold trắng, kèm subtitle tuỳ chọn (12px, #C9CEE0) và 1 action
/// tròn bên phải (30px, nền trắng 12%).
class TopBar extends StatelessWidget {
  final String? greeting;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double opacity;

  const TopBar(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.trailing,
      this.opacity = 1})
      : greeting = null;

  /// Variant "Home": dòng chào (nhỏ, mờ) phía trên tên (thay cho back button),
  /// dòng tổng quan (subtitle) phía dưới. VD: H-01 "Hello, / Tên / 3 houses...".
  const TopBar.home(
      {super.key,
      required this.greeting,
      required String name,
      required String overview,
      this.trailing,
      this.opacity = 1})
      : title = name,
        subtitle = overview,
        onBack = null;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      // SafeArea(bottom: false) — dành chỗ cho status bar hệ thống phía trên
      // (giống lý do AppBottomNav dùng SafeArea(top: false) cho thanh điều
      // hướng dưới) — thiếu cái này khiến nút back/action bị status bar đè
      // lên, có lúc chặn luôn tap (phát hiện qua phản hồi thật trên máy).
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (greeting != null)
                Text(greeting!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 17 / 12,
                        color: const Color(0xFFC9CEE0))),
              Row(
                children: [
                  if (onBack != null) ...[
                    _TopBarCircleButton(
                        icon: Symbols.arrow_back_rounded,
                        size: 26,
                        iconSize: 16,
                        bgOpacity: 0.14,
                        onTap: onBack!),
                    const SizedBox(width: 8)
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 26 / 20,
                          color: Colors.white),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 17 / 12,
                        color: const Color(0xFFC9CEE0))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TopBarMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const TopBarMoreButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TopBarCircleButton(
        icon: Symbols.more_vert_rounded,
        size: 30,
        iconSize: 18,
        bgOpacity: 0.12,
        onTap: onTap);
  }
}

class TopBarBellButton extends StatelessWidget {
  final VoidCallback onTap;
  // Số thông báo chưa đọc — hiện chấm đỏ nếu > 0. Mặc định 0 (không chấm)
  // để không ảnh hưởng chỗ dùng cũ.
  final int unreadCount;
  const TopBarBellButton(
      {super.key, required this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _TopBarCircleButton(
            icon: Symbols.notifications_rounded,
            size: 30,
            iconSize: 18,
            bgOpacity: 0.12,
            onTap: onTap),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                    BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Nút tròn "⋮" mở menu Edit/(Record monthly readings)/Delete — đúng
/// component "action pop-up" trên Figma. Bản 2 mục (node `400:2669`/`400:2759`,
/// dùng ở H-04 Room Detail) và bản 3 mục (node `400:2576`, dùng ở H-03 House
/// Detail — có thêm "Record monthly readings" ở giữa, đúng chỗ trả lời câu
/// hỏi "H-06 chưa có điểm vào thật" ghi ở đợt trước) đều chung 1 style: khung
/// trắng bo góc 9px viền hairline, mọi dòng **cùng màu navy đậm** (không tô
/// đỏ cho Delete), gạch chia mảnh dưới mỗi dòng trừ dòng cuối. Dùng
/// `PopupMenuButton` bọc quanh đúng visual tròn có sẵn (không tự vẽ menu
/// riêng) — "Delete" luôn phải qua `ConfirmDialog.show(...)` trước khi thực
/// hiện, không xoá thẳng khi bấm.
class TopBarActionMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback? onRecordReadings;
  final VoidCallback onDelete;

  const TopBarActionMenuButton(
      {super.key,
      required this.onEdit,
      this.onRecordReadings,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TopBarMenuAction>(
      tooltip: '',
      offset: const Offset(0, 36),
      color: Colors.white,
      elevation: 2,
      menuPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      onSelected: (action) => switch (action) {
        _TopBarMenuAction.edit => onEdit(),
        _TopBarMenuAction.recordReadings => onRecordReadings?.call(),
        _TopBarMenuAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _TopBarMenuAction.edit,
          padding: EdgeInsets.zero,
          height: 0,
          child: _ActionPopupRow(
              label: AppStrings.t('common.edit'), showDivider: true),
        ),
        if (onRecordReadings != null)
          PopupMenuItem(
            value: _TopBarMenuAction.recordReadings,
            padding: EdgeInsets.zero,
            height: 0,
            child: _ActionPopupRow(
                label: AppStrings.t('common.recordMonthlyReadings'),
                showDivider: true),
          ),
        PopupMenuItem(
          value: _TopBarMenuAction.delete,
          padding: EdgeInsets.zero,
          height: 0,
          child: _ActionPopupRow(label: AppStrings.t('common.delete')),
        ),
      ],
      child: const _TopBarCircleIcon(
          icon: Symbols.more_vert_rounded,
          size: 30,
          iconSize: 18,
          bgOpacity: 0.12),
    );
  }
}

enum _TopBarMenuAction { edit, recordReadings, delete }

class _ActionPopupRow extends StatelessWidget {
  final String label;
  final bool showDivider;

  const _ActionPopupRow({required this.label, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    // `width: double.infinity` là bắt buộc: `PopupMenuButton` bọc nội dung
    // trong `IntrinsicWidth`, nên nếu để Container tự co thì mỗi dòng rộng
    // đúng bằng chữ của nó — gạch dưới "Sửa" ngắn cũn, gạch dưới "Ghi chỉ số
    // hàng tháng" dài hơn hẳn, trông như lỗi vỡ layout chứ không phải đường
    // kẻ ngăn cách (dungtv báo 18/09/2026). Cho rộng vô hạn thì cả 3 dòng
    // cùng bằng bề ngang menu, gạch chạy suốt như Figma.
    //
    // Padding ngang/dọc 5px — Dream yêu cầu tăng kích thước từng dòng trong
    // menu này (18/09/2026) vì bản cũ chỉ có padding dọc 2px, vùng bấm quá
    // sát chữ. `PopupMenuItem` cha vẫn giữ `padding: EdgeInsets.zero` +
    // `height: 0` để không cộng dồn 2 lớp padding.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: showDivider
          // Màu `#7F7F7F` đo pixel trực tiếp trên node Figma `400:2652`
          // (18/09/2026). KHÔNG phải `borderSubtle` (#EEF0F5, gần như vô hình
          // trên nền trắng) và cũng không phải `neutral200` như bản sửa đầu
          // tiên hôm nay — lúc đó Figma MCP đang mất đăng nhập nên mới phải
          // ước lượng bằng mắt từ ảnh chụp.
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.menuDivider)))
          : null,
      child: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );
  }
}

class _TopBarCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double bgOpacity;
  final VoidCallback onTap;

  const _TopBarCircleButton(
      {required this.icon,
      required this.size,
      required this.iconSize,
      required this.bgOpacity,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: _TopBarCircleIcon(
          icon: icon, size: size, iconSize: iconSize, bgOpacity: bgOpacity),
    );
  }
}

class _TopBarCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double bgOpacity;

  const _TopBarCircleIcon(
      {required this.icon,
      required this.size,
      required this.iconSize,
      required this.bgOpacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: bgOpacity),
          shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
