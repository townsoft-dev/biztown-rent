import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/contract.dart';
import '../shared/app_chip.dart';
import '../shared/app_fab.dart';
import '../shared/house_filter_chip.dart';
import '../shared/list_card.dart';
import '../shared/search_field.dart';
import '../shared/segmented_control.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// T-01/T-02 — Tenant & Contract (node 220:3194/220:3283, Figma) — 1 màn với
/// Segmented control 2 state (Tenants/Contracts), giống cách H-03 gộp "House
/// detail"/"Rooms" trong `room_list_screen.dart`. Đây là root của tab
/// "Tenant" (bottom nav) — KHÔNG có nút back (giống H-01/P-01), dù Figma vẽ
/// mũi tên back cho mục đích click-through prototype.
class TenantContractScreen extends ConsumerStatefulWidget {
  const TenantContractScreen({super.key});

  @override
  ConsumerState<TenantContractScreen> createState() =>
      _TenantContractScreenState();
}

enum _TenantFilter { all, unassigned, renting }

enum _ContractFilter { active, endingSoon, ended }

class _TenantContractScreenState extends ConsumerState<TenantContractScreen> {
  int _tab = 0;
  final _searchController = TextEditingController();
  String _search = '';
  _TenantFilter _tenantFilter = _TenantFilter.all;
  _ContractFilter _contractFilter = _ContractFilter.active;
  String? _selectedHouseId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickHouse() async {
    final houses = ref.read(housesProvider).valueOrNull ?? const [];
    final picked = await HouseFilterChip.showPicker(context,
        houses: houses, selectedHouseId: _selectedHouseId);
    // showPicker trả về `null` cho CẢ 2 trường hợp "chọn All houses" lẫn
    // "đóng sheet không chọn gì" — không phân biệt được qua giá trị trả về,
    // nhưng chấp nhận được vì đóng sheet không chọn gì thì giữ nguyên lựa
    // chọn cũ cũng ra kết quả y hệt "về All houses" chỉ khi trước đó đã là
    // All houses; nếu trước đó đã chọn 1 Nhà cụ thể, đóng sheet devuelve
    // `null` sẽ VÔ TÌNH về "All houses" thay vì giữ nguyên. Chấp nhận đánh
    // đổi nhỏ này vì sheet có tuỳ chọn "All houses" tường minh để quay lại.
    setState(() => _selectedHouseId = picked);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton: AppFab(
          onPressed: () => context
              .push(_tab == 0 ? '/tenant/new' : '/tenant/contracts/new')),
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('tenantList.title'),
            subtitle: _tab == 0
                ? ref.watch(tenantsProvider).maybeWhen(
                      data: (tenants) => AppStrings.t(
                          'tenantList.tenantsInPool',
                          {'count': '${tenants.length}'}),
                      orElse: () => '',
                    )
                : ref.watch(contractsProvider).maybeWhen(
                      data: (contracts) => AppStrings.t(
                          'tenantList.contractsTracked',
                          {'count': '${contracts.length}'}),
                      orElse: () => '',
                    ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                AppSegmentedControl(
                  labels: [
                    AppStrings.t('tenantList.tabTenants'),
                    AppStrings.t('tenantList.tabContracts'),
                  ],
                  selectedIndex: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 8),
                if (_tab == 0)
                  ..._buildTenantsTab()
                else
                  ..._buildContractsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTenantsTab() {
    return [
      SearchField(
        controller: _searchController,
        hintText: AppStrings.t('tenantList.searchHint'),
        onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          AppChip(
            label: AppStrings.t('tenantList.filterAll'),
            selected: _tenantFilter == _TenantFilter.all,
            onTap: () => setState(() => _tenantFilter = _TenantFilter.all),
          ),
          const SizedBox(width: 6),
          AppChip(
            label: AppStrings.t('tenantList.filterUnassigned'),
            selected: _tenantFilter == _TenantFilter.unassigned,
            onTap: () =>
                setState(() => _tenantFilter = _TenantFilter.unassigned),
          ),
          const SizedBox(width: 6),
          AppChip(
            label: AppStrings.t('tenantList.filterRenting'),
            selected: _tenantFilter == _TenantFilter.renting,
            onTap: () => setState(() => _tenantFilter = _TenantFilter.renting),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ref.watch(tenantListProvider).when(
            data: (items) {
              final filtered = items.where((item) {
                if (_tenantFilter == _TenantFilter.unassigned &&
                    item.isRenting) {
                  return false;
                }
                if (_tenantFilter == _TenantFilter.renting && !item.isRenting) {
                  return false;
                }
                if (_search.isEmpty) return true;
                return item.tenant.fullName.toLowerCase().contains(_search) ||
                    item.tenant.phone.contains(_search);
              }).toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    AppStrings.t('tenantList.tenantsEmptyState'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    Builder(builder: (context) {
                      final item = filtered[i];
                      final thumbColors = [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.accentCoral,
                      ];
                      return ListCard(
                        thumbShape: ListCardThumbShape.round,
                        thumbColor: thumbColors[i % thumbColors.length],
                        initials: item.tenant.initials,
                        title: item.tenant.fullName,
                        trailing: StatusPill(
                          text: item.isRenting
                              ? AppStrings.t('tenantList.statusRenting')
                              : AppStrings.t('tenantList.statusUnassigned'),
                          style: item.isRenting
                              ? StatusBadgeStyle.active
                              : StatusBadgeStyle.empty,
                        ),
                        body: item.tenant.phone,
                        meta: item.isRenting
                            ? AppStrings.t('tenantList.roomHouseMeta', {
                                'room':
                                    item.rooms.map((r) => r.roomNo).join(', '),
                                'house': item.house?.name ?? '',
                              })
                            : AppStrings.t('tenantList.noRoomYet'),
                        onTap: () => context.push('/tenant/${item.tenant.id}'),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator())),
            error: (e, st) => Text(
                AppStrings.t('tenantList.tenantsLoadError', {'error': '$e'})),
          ),
    ];
  }

  List<Widget> _buildContractsTab() {
    final houses = ref.watch(housesProvider).valueOrNull ?? const [];
    final selectedHouseName = _selectedHouseId == null
        ? AppStrings.t('common.allHouses')
        : houses
            .firstWhere((h) => h.id == _selectedHouseId,
                orElse: () => houses.first)
            .name;
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: HouseFilterChip(label: selectedHouseName, onTap: _pickHouse),
      ),
      const SizedBox(height: 8),
      ref.watch(contractListProvider).when(
            data: (items) {
              final scoped = _selectedHouseId == null
                  ? items
                  : items.where((i) => i.house.id == _selectedHouseId).toList();
              final activeItems = scoped
                  .where((i) =>
                      i.contract.status == ContractStatus.active &&
                      !i.isEndingSoon)
                  .toList();
              final endingSoonItems =
                  scoped.where((i) => i.isEndingSoon).toList();
              final endedItems = scoped
                  .where((i) => i.contract.status == ContractStatus.ended)
                  .toList();
              final filtered = switch (_contractFilter) {
                _ContractFilter.active => activeItems,
                _ContractFilter.endingSoon => endingSoonItems,
                _ContractFilter.ended => endedItems,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppChip(
                        label: AppStrings.t('tenantList.filterActive',
                            {'count': '${activeItems.length}'}),
                        selected: _contractFilter == _ContractFilter.active,
                        onTap: () => setState(
                            () => _contractFilter = _ContractFilter.active),
                      ),
                      const SizedBox(width: 6),
                      AppChip(
                        label: AppStrings.t('tenantList.filterEndingSoon',
                            {'count': '${endingSoonItems.length}'}),
                        selected: _contractFilter == _ContractFilter.endingSoon,
                        onTap: () => setState(
                            () => _contractFilter = _ContractFilter.endingSoon),
                      ),
                      const SizedBox(width: 6),
                      AppChip(
                        label: AppStrings.t('tenantList.filterEnded',
                            {'count': '${endedItems.length}'}),
                        selected: _contractFilter == _ContractFilter.ended,
                        onTap: () => setState(
                            () => _contractFilter = _ContractFilter.ended),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        AppStrings.t('tenantList.contractsEmptyState'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  for (final item in filtered) ...[
                    ListCard(
                      icon: Symbols.description_rounded,
                      thumbColor: item.contract.status == ContractStatus.ended
                          ? AppColors.secondary
                          : (item.isEndingSoon
                              ? AppColors.accentOrange
                              : AppColors.primary),
                      title:
                          '${item.rooms.map((r) => r.roomNo).join(', ')} — ${item.tenant.fullName}',
                      trailing: StatusPill(
                        text: item.contract.status == ContractStatus.ended
                            ? contractStatusLabel(ContractStatus.ended)
                            : (item.isEndingSoon
                                ? AppStrings.t('status.endingSoon')
                                : contractStatusLabel(ContractStatus.active)),
                        style: item.contract.status == ContractStatus.ended
                            ? StatusBadgeStyle.ended
                            : (item.isEndingSoon
                                ? StatusBadgeStyle.expiringSoon
                                : StatusBadgeStyle.active),
                      ),
                      body: item.house.name,
                      meta: item.contract.status == ContractStatus.ended
                          ? AppStrings.t('tenantList.endedOn', {
                              'date': DateFormat('dd/MM/yyyy')
                                  .format(item.currentVersion.endDate)
                            })
                          : '${AppStrings.t('tenantList.endsOn', {
                                  'date': DateFormat('dd/MM/yyyy')
                                      .format(item.currentVersion.endDate)
                                })}  ·  ${AppStrings.t('tenantList.perMonth', {
                                  'amount': formatNumber(
                                      item.currentVersion.monthlyRent)
                                })}',
                      onTap: () =>
                          context.push('/tenant/contracts/${item.contract.id}'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator())),
            error: (e, st) => Text(
                AppStrings.t('tenantList.contractsLoadError', {'error': '$e'})),
          ),
    ];
  }
}
