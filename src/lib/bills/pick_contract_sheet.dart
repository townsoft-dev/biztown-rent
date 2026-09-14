import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../core/providers.dart';
import '../data/models/contract.dart';

/// Bottom sheet chọn 1 hợp đồng Active — dùng khi tạo hoá đơn đơn lẻ (B-02),
/// không có frame Figma riêng cho bước này (đối chiếu `get_metadata` chỉ
/// thấy đúng 5 frame B-01→B-05) — theo đúng pattern picker sẵn có trong app
/// (`HouseFilterChip.showPicker`, tenant picker ở T-06).
Future<String?> showPickContractSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Consumer(builder: (context, ref, _) {
        final itemsAsync = ref.watch(contractListProvider);
        return itemsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$e'),
          ),
          data: (items) {
            final active = items
                .where((i) => i.contract.status == ContractStatus.active)
                .toList();
            if (active.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppStrings.t('bills.pickContractEmpty'),
                    textAlign: TextAlign.center),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(AppStrings.t('bills.pickContractTitle'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                for (final item in active)
                  ListTile(
                    title: Text(
                        '${item.rooms.map((r) => r.roomNo).join(', ')} — ${item.tenant.fullName}'),
                    subtitle: Text(item.house.name),
                    onTap: () => Navigator.of(context).pop(item.contract.id),
                  ),
              ],
            );
          },
        );
      }),
    ),
  );
}
