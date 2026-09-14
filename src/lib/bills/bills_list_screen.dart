import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/invoice.dart';
import '../shared/app_chip.dart';
import '../shared/app_fab.dart';
import '../shared/group_header.dart';
import '../shared/house_filter_chip.dart';
import '../shared/invoice_schedule_strip.dart';
import '../shared/stat_card.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'pick_contract_sheet.dart';

enum _StatusFilter { draft, sent, collected, overdue }

/// B-01 — Bills List (node 220:4166, Figma) — root của tab "Bills" (bottom
/// nav), KHÔNG có nút back (giống Home/Tenant), dù Figma vẽ mũi tên back cho
/// mục đích click-through prototype.
class BillsListScreen extends ConsumerStatefulWidget {
  const BillsListScreen({super.key});

  @override
  ConsumerState<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends ConsumerState<BillsListScreen> {
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _houseId;
  _StatusFilter? _statusFilter;

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() => _period = DateTime(picked.year, picked.month, 1));
  }

  Future<void> _pickHouse() async {
    final houses = ref.read(housesProvider).valueOrNull ?? const [];
    final picked = await HouseFilterChip.showPicker(context,
        houses: houses, selectedHouseId: _houseId);
    setState(() => _houseId = picked);
  }

  Future<void> _openCreateSheet() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.receipt_long_rounded),
              title: Text(AppStrings.t('bills.createSingle')),
              subtitle: Text(AppStrings.t('bills.createSingleHint')),
              onTap: () => Navigator.of(context).pop('single'),
            ),
            ListTile(
              leading: const Icon(Symbols.receipt_long_rounded),
              title: Text(AppStrings.t('bills.createBatch')),
              subtitle: Text(AppStrings.t('bills.createBatchHint')),
              onTap: () => Navigator.of(context).pop('batch'),
            ),
          ],
        ),
      ),
    );
    if (mode == null || !mounted) return;
    if (mode == 'single') {
      final contractId = await showPickContractSheet(context, ref);
      if (contractId == null || !mounted) return;
      context.push('/bills/invoices/new?contractId=$contractId');
    } else {
      var houseId = _houseId;
      if (houseId == null) {
        final houses = ref.read(housesProvider).valueOrNull ?? const [];
        houseId = await HouseFilterChip.showPicker(context,
            houses: houses, selectedHouseId: null);
      }
      if (houseId == null || !mounted) return;
      context.push('/bills/invoices/new-batch?houseId=$houseId');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final groupsAsync = ref.watch(billsHouseGroupsProvider(_period));
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton: AppFab(onPressed: _openCreateSheet),
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('bills.title'),
            subtitle: groupsAsync.maybeWhen(
              data: (groups) {
                final rows = groups.expand((g) => g.rows).toList();
                final collected = rows
                    .where((r) =>
                        r.selectedPeriodInvoice?.status ==
                        InvoiceStatus.collected)
                    .length;
                return AppStrings.t('bills.subtitle', {
                  'period': DateFormat('MM/yyyy').format(_period),
                  'collected': '$collected',
                  'total': '${rows.length}',
                });
              },
              orElse: () => '',
            ),
          ),
          Expanded(
            child: groupsAsync.when(
              data: (groups) => _buildBody(groups),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<BillsHouseGroup> groups) {
    final houses = ref.watch(housesProvider).valueOrNull ?? const [];
    final allRows = groups.expand((g) => g.rows).toList();
    final counts = {
      for (final f in _StatusFilter.values)
        f: allRows.where((r) => _matchesStatus(r, f)).length,
    };
    final totalThisPeriod = allRows.fold<num>(
        0, (sum, r) => sum + (r.selectedPeriodInvoice?.totalAmount ?? 0));
    final outstanding = allRows.fold<num>(
        0,
        (sum, r) =>
            sum +
            (r.selectedPeriodInvoice != null &&
                    r.selectedPeriodInvoice!.status != InvoiceStatus.collected
                ? r.selectedPeriodInvoice!.totalAmount
                : 0));

    final filteredGroups = groups
        .where((g) => _houseId == null || g.house.id == _houseId)
        .map((g) => BillsHouseGroup(
            house: g.house,
            rows: g.rows
                .where((r) =>
                    _statusFilter == null || _matchesStatus(r, _statusFilter!))
                .toList()))
        .where((g) => g.rows.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
                child: StatCard(
                    value: formatNumber(totalThisPeriod),
                    label: AppStrings.t('bills.statTotalThisPeriod'))),
            const SizedBox(width: 8),
            Expanded(
                child: StatCard(
                    value: formatNumber(outstanding),
                    label: AppStrings.t('bills.statOutstanding'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AppChip(
                label: DateFormat('MMM yyyy').format(_period),
                selected: true,
                onTap: _pickPeriod),
            const SizedBox(width: 6),
            HouseFilterChip(
              label: _houseId == null
                  ? AppStrings.t('common.allHouses')
                  : houses
                      .firstWhere((h) => h.id == _houseId,
                          orElse: () => houses.first)
                      .name,
              onTap: _pickHouse,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _StatusFilter.values) ...[
                AppChip(
                  label: AppStrings.t('bills.filter${_filterKey(f)}',
                      {'count': '${counts[f]}'}),
                  selected: _statusFilter == f,
                  onTap: () => setState(
                      () => _statusFilter = _statusFilter == f ? null : f),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (filteredGroups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(AppStrings.t('bills.emptyState'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          )
        else
          for (final group in filteredGroups) ...[
            GroupHeader(
                label: group.house.name,
                counterLabel: AppStrings.t('bills.groupContractsCount',
                    {'count': '${group.rows.length}'})),
            const SizedBox(height: 8),
            for (final row in group.rows) ...[
              _ContractCard(row: row, period: _period),
              const SizedBox(height: 8),
            ],
          ],
      ],
    );
  }

  bool _matchesStatus(BillsContractRow row, _StatusFilter filter) {
    final invoice = row.selectedPeriodInvoice;
    return switch (filter) {
      _StatusFilter.draft => invoice?.status == InvoiceStatus.draft,
      _StatusFilter.sent =>
        invoice?.status == InvoiceStatus.sent && !(invoice?.isOverdue ?? false),
      _StatusFilter.collected => invoice?.status == InvoiceStatus.collected,
      _StatusFilter.overdue => invoice?.isOverdue ?? false,
    };
  }

  String _filterKey(_StatusFilter f) => switch (f) {
        _StatusFilter.draft => 'Draft',
        _StatusFilter.sent => 'Sent',
        _StatusFilter.collected => 'Collected',
        _StatusFilter.overdue => 'Overdue',
      };
}

class _ContractCard extends StatelessWidget {
  final BillsContractRow row;
  final DateTime period;

  const _ContractCard({required this.row, required this.period});

  @override
  Widget build(BuildContext context) {
    final invoice = row.selectedPeriodInvoice;
    final style = invoice == null
        ? StatusBadgeStyle.draft
        : invoice.isOverdue
            ? StatusBadgeStyle.overdue
            : switch (invoice.status) {
                InvoiceStatus.draft => StatusBadgeStyle.draft,
                InvoiceStatus.sent => StatusBadgeStyle.sent,
                InvoiceStatus.collected => StatusBadgeStyle.collected,
              };
    final label = invoice == null
        ? AppStrings.t('status.draft')
        : invoice.isOverdue
            ? AppStrings.t('status.overdue')
            : invoiceStatusLabel(invoice.status);
    final subtitle = _subtitleFor(invoice);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: invoice == null
          ? null
          : () => context.push('/bills/invoices/${invoice.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${row.roomNosLabel} · ${row.tenant.fullName}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ),
                StatusPill(text: label, style: style),
              ],
            ),
            const SizedBox(height: 4),
            Text('${formatNumber(row.version.monthlyRent)} /month · $subtitle',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 6),
            InvoiceScheduleStrip(
              chips: row.chips,
              visibleCount: 5,
              showLegend: false,
              onTapPeriod: (periodStart) => context.push(
                  '/tenant/contracts/${row.contract.id}/invoice-schedule?period=${DateFormat('yyyy-MM-dd').format(periodStart)}'),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(Invoice? invoice) {
    if (invoice == null) return AppStrings.t('bills.statusNoInvoiceYet');
    return switch (invoice.status) {
      InvoiceStatus.draft => AppStrings.t('bills.statusDraft'),
      InvoiceStatus.collected => AppStrings.t('bills.statusCollected', {
          'date': DateFormat('dd/MM')
              .format(invoice.collectedAt ?? invoice.createdAt)
        }),
      InvoiceStatus.sent => invoice.isOverdue
          ? AppStrings.t('bills.statusOverdue', {
              'month': '${invoice.periodStart.month}',
              'days': '${DateTime.now().difference(invoice.dueDate).inDays}',
            })
          : AppStrings.t('bills.statusSent', {
              'date': DateFormat('dd/MM')
                  .format(invoice.sentAt ?? invoice.createdAt)
            }),
    };
  }
}
