import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

const _endReasonKeys = [
  'endReasonTenantMovedOut',
  'endReasonNonRenewal',
  'endReasonOwnerReclaims',
  'endReasonBreach',
  'endReasonOther',
];

/// T-09 — End Contract (Settlement) (node 220:3991, Figma). "End reason"
/// (Select) không có cột riêng trong `tb_contract` — gộp vào `settlementNote`
/// cùng "Deduction reason" (2 field tự do trên Figma, DB chỉ có 1 cột text
/// chung), xem docs/DECISIONS.md Đợt 28.
class ContractEndScreen extends ConsumerStatefulWidget {
  final String contractId;

  const ContractEndScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractEndScreen> createState() => _ContractEndScreenState();
}

class _ContractEndScreenState extends ConsumerState<ContractEndScreen> {
  DateTime _moveOutDate = DateTime.now();
  String _endReasonKey = _endReasonKeys.first;
  final _damageDeductionController = TextEditingController();
  final _deductionReasonController = TextEditingController();
  final Map<String, TextEditingController> _electricityControllers = {};
  final Map<String, TextEditingController> _waterControllers = {};
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _damageDeductionController.dispose();
    _deductionReasonController.dispose();
    for (final c in _electricityControllers.values) {
      c.dispose();
    }
    for (final c in _waterControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _elecController(String roomId) =>
      _electricityControllers.putIfAbsent(
          roomId, () => TextEditingController());
  TextEditingController _waterController(String roomId) =>
      _waterControllers.putIfAbsent(roomId, () => TextEditingController());

  Future<void> _pickMoveOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveOutDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _moveOutDate = picked);
  }

  Future<void> _pickEndReason() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final key in _endReasonKeys)
              ListTile(
                title: Text(AppStrings.t('contractEnd.$key')),
                onTap: () => Navigator.of(context).pop(key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _endReasonKey = picked);
  }

  Future<void> _confirmAndSave({
    required List<Room> rooms,
    required String houseId,
    required num deposit,
    required num unpaidTotal,
    required num damageDeduction,
    required num refundAmount,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.t('contractEnd.confirmTitle'),
      description: AppStrings.t('contractEnd.confirmDescription',
          {'amount': formatNumber(refundAmount.abs())}),
      confirmLabel: AppStrings.t('common.delete'),
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final readingRepo = ref.read(readingRepositoryProvider);
      for (final room in rooms) {
        await readingRepo.createMoveOut(
          roomId: room.id,
          houseId: houseId,
          contractId: widget.contractId,
          type: UtilityType.electricity,
          readingDate: _moveOutDate,
          currentReading: parseFormattedNumber(_elecController(room.id).text)!,
        );
        await readingRepo.createMoveOut(
          roomId: room.id,
          houseId: houseId,
          contractId: widget.contractId,
          type: UtilityType.water,
          readingDate: _moveOutDate,
          currentReading: parseFormattedNumber(_waterController(room.id).text)!,
        );
      }

      final noteParts = [
        AppStrings.t('contractEnd.$_endReasonKey'),
        if (_deductionReasonController.text.trim().isNotEmpty)
          _deductionReasonController.text.trim(),
      ];

      await ref.read(contractRepositoryProvider).endContract(
            contractId: widget.contractId,
            unpaidInvoicesTotal: unpaidTotal,
            damageDeduction: damageDeduction,
            refundAmount: refundAmount,
            settlementNote: noteParts.join('. '),
          );

      final roomRepo = ref.read(roomRepositoryProvider);
      for (final room in rooms) {
        await roomRepo.updateStatus(room.id, RoomStatus.empty);
      }

      ref.invalidate(contractProvider(widget.contractId));
      ref.invalidate(contractsProvider);
      ref.invalidate(contractListProvider);
      ref.invalidate(tenantListProvider);
      ref.invalidate(roomsProvider(houseId));
      ref.invalidate(roomStatusesByHouseProvider);
      for (final room in rooms) {
        ref.invalidate(readingHistoryProvider(
            (roomId: room.id, utilityType: UtilityType.electricity)));
        ref.invalidate(readingHistoryProvider(
            (roomId: room.id, utilityType: UtilityType.water)));
        ref.invalidate(roomActiveContractProvider(room.id));
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorText = AppStrings.t('contractEnd.saveError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final contractAsync = ref.watch(contractProvider(widget.contractId));

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
            child:
                Text(AppStrings.t('contractEnd.loadError', {'error': '$e'}))),
        data: (contract) {
          final versionAsync = contract.currentVersionId == null
              ? null
              : ref.watch(contractVersionProvider(contract.currentVersionId!));
          final version = versionAsync?.valueOrNull;
          final tenant =
              ref.watch(tenantProvider(contract.tenantId)).valueOrNull;
          final rooms =
              ref.watch(contractRoomsProvider(widget.contractId)).valueOrNull;
          final unpaidAsync =
              ref.watch(unpaidInvoicesProvider(widget.contractId));

          if (version == null || tenant == null || rooms == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final unpaidInvoices = unpaidAsync.valueOrNull ?? const [];
          final unpaidTotal =
              unpaidInvoices.fold<num>(0, (sum, i) => sum + i.totalAmount);
          final damageDeduction =
              parseFormattedNumber(_damageDeductionController.text) ?? 0;
          final refundAmount =
              version.depositAmount - unpaidTotal - damageDeduction;

          return Column(
            children: [
              TopBar(
                title: AppStrings.t('contractEnd.title'),
                subtitle: AppStrings.t('contractEnd.subtitle', {
                  'room': rooms.map((r) => r.roomNo).join(', '),
                  'tenant': tenant.fullName,
                }),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    AppBanner(
                        message: AppStrings.t('contractEnd.banner'),
                        tone: AppBannerTone.warning),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractEnd.moveOutDate'),
                            initialValue:
                                DateFormat('dd/MM/yyyy').format(_moveOutDate),
                            key: ValueKey('moveOutDate-$_moveOutDate'),
                            trailing: AppTextFieldTrailingIcon.date,
                            onTap: _pickMoveOutDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractEnd.endReason'),
                            initialValue:
                                AppStrings.t('contractEnd.$_endReasonKey'),
                            key: ValueKey('endReason-$_endReasonKey'),
                            trailing: AppTextFieldTrailingIcon.select,
                            onTap: _pickEndReason,
                          ),
                        ),
                      ],
                    ),
                    SectionLabel(
                        AppStrings.t('contractEnd.sectionMoveOutReadings')),
                    for (final room in rooms) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(room.roomNo,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: AppStrings.t(
                                  'contractEnd.moveOutElectricity'),
                              controller: _elecController(room.id),
                              keyboardType: TextInputType.number,
                              inputFormatters: const [
                                ThousandsInputFormatter()
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppTextField(
                              label: AppStrings.t('contractEnd.moveOutWater'),
                              controller: _waterController(room.id),
                              keyboardType: TextInputType.number,
                              inputFormatters: const [
                                ThousandsInputFormatter()
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(AppStrings.t('contractEnd.moveOutHint'),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ),
                    SectionLabel(
                        AppStrings.t('contractEnd.sectionOutstandingInvoices')),
                    DetailBlock(children: [
                      if (unpaidInvoices.isEmpty)
                        DetailRow(
                          label:
                              AppStrings.t('contractEnd.noOutstandingInvoices'),
                          value: '—',
                          showDivider: false,
                        )
                      else ...[
                        for (final invoice in unpaidInvoices)
                          DetailRow(
                            label: DateFormat('MM/yyyy')
                                .format(invoice.periodStart),
                            value: formatNumber(invoice.totalAmount),
                          ),
                        DetailRow(
                          label: AppStrings.t('contractEnd.unpaidTotal'),
                          value: formatNumber(unpaidTotal),
                          showDivider: false,
                        ),
                      ],
                    ]),
                    SectionLabel(AppStrings.t(
                        'contractEnd.sectionDepositReconciliation')),
                    AppTextField(
                      label: AppStrings.t('contractEnd.depositReceived'),
                      initialValue: formatNumber(version.depositAmount),
                      readOnly: true,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: AppStrings.t('contractEnd.damageDeduction'),
                      controller: _damageDeductionController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [ThousandsInputFormatter()],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: AppStrings.t('contractEnd.deductionReason'),
                      controller: _deductionReasonController,
                      maxLines: 3,
                      textarea: true,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: refundAmount < 0
                            ? AppColors.errorBg
                            : AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              AppStrings.t(refundAmount < 0
                                  ? 'contractEnd.tenantOwes'
                                  : 'contractEnd.refundToTenant'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: refundAmount < 0
                                      ? AppColors.error
                                      : AppColors.success)),
                          Text('${formatNumber(refundAmount.abs())} VND',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: refundAmount < 0
                                      ? AppColors.error
                                      : AppColors.success)),
                          Text(
                              AppStrings.t('contractEnd.summaryFormula', {
                                'deposit': formatNumber(version.depositAmount),
                                'unpaid': formatNumber(unpaidTotal),
                                'damage': formatNumber(damageDeduction),
                              }),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: refundAmount < 0
                                      ? AppColors.error
                                      : AppColors.success)),
                        ],
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorText!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: AppStrings.t('common.cancel'),
                            style: AppButtonStyle.ghost,
                            onPressed: _isSaving ? null : () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: AppStrings.t('contractEnd.confirmMoveOut'),
                            style: AppButtonStyle.danger,
                            onPressed: _isSaving
                                ? null
                                : () {
                                    for (final room in rooms) {
                                      final elec = parseFormattedNumber(
                                          _elecController(room.id).text);
                                      final water = parseFormattedNumber(
                                          _waterController(room.id).text);
                                      if (elec == null || water == null) {
                                        setState(() => _errorText =
                                            AppStrings.t(
                                                'contractEnd.missingReadings',
                                                {'room': room.roomNo}));
                                        return;
                                      }
                                    }
                                    _confirmAndSave(
                                      rooms: rooms,
                                      houseId: rooms.first.houseId,
                                      deposit: version.depositAmount,
                                      unpaidTotal: unpaidTotal,
                                      damageDeduction: damageDeduction,
                                      refundAmount: refundAmount,
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
