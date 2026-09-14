import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/contract.dart';
import '../data/models/recurring_fee.dart';
import '../data/recurring_fees_controller.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/detail_row.dart';
import '../shared/recurring_fees_editor.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// T-07 — Contract Renew / Amend (node 220:3807, Figma) — 1 màn dùng chung
/// cho cả Renew và Amend, chỉ khác `changeReason` truyền vào lúc mở (BR-CTR-07
/// — không có UI đổi danh sách phòng ở màn này, xem docs/SCREEN-SPEC.md).
/// Figma hiện tại (chưa cập nhật theo pattern billing-method của T-06) không
/// có UI sửa billing method hay phí dịch vụ — 2 field này giữ nguyên không
/// đổi từ phiên bản hiện hành, chỉ 1 mình `RealEstateInfo` (môi giới) cũng
/// giữ nguyên tương tự (xem docs/DECISIONS.md Đợt 28).
class ContractRenewScreen extends ConsumerStatefulWidget {
  final String contractId;
  final ChangeReason reason;

  const ContractRenewScreen(
      {super.key, required this.contractId, required this.reason});

  @override
  ConsumerState<ContractRenewScreen> createState() =>
      _ContractRenewScreenState();
}

class _ContractRenewScreenState extends ConsumerState<ContractRenewScreen> {
  final _depositController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _electricityPriceController = TextEditingController();
  final _waterPriceController = TextEditingController();
  final _paymentDueDayController = TextEditingController();
  final _lateFeeTermsController = TextEditingController();
  final _specialNoteController = TextEditingController();
  late final RecurringFeesController _feesController =
      RecurringFeesController();

  ContractVersion? _current;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorText;

  late final Listenable _formListenable = Listenable.merge([
    _depositController,
    _monthlyRentController,
    _electricityPriceController,
    _waterPriceController,
    _paymentDueDayController,
    _lateFeeTermsController,
    _specialNoteController,
    _feesController,
  ]);

  @override
  void dispose() {
    _depositController.dispose();
    _monthlyRentController.dispose();
    _electricityPriceController.dispose();
    _waterPriceController.dispose();
    _paymentDueDayController.dispose();
    _lateFeeTermsController.dispose();
    _specialNoteController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  void _prefill(ContractVersion current) {
    if (_initialized) return;
    _initialized = true;
    _current = current;
    if (widget.reason == ChangeReason.renewal) {
      _startDate = current.endDate.add(const Duration(days: 1));
      _endDate =
          DateTime(_startDate!.year + 1, _startDate!.month, _startDate!.day)
              .subtract(const Duration(days: 1));
    } else {
      _startDate = DateTime.now();
      _endDate = current.endDate;
    }
    _depositController.text = formatNumber(current.depositAmount);
    _monthlyRentController.text = formatNumber(current.monthlyRent);
    _electricityPriceController.text = formatNumber(
        current.electricityBillingMethod == UtilityBillingMethod.flat
            ? (current.electricityFlatAmount ?? 0)
            : (current.electricityUnitPrice ?? 0));
    _waterPriceController.text = formatNumber(
        current.waterBillingMethod == UtilityBillingMethod.flat
            ? (current.waterFlatAmount ?? 0)
            : (current.waterUnitPrice ?? 0));
    _paymentDueDayController.text = '${current.paymentDueDayOfMonth}';
    _lateFeeTermsController.text = current.lateFeeTerms ?? '';
    _specialNoteController.text = current.specialNote ?? '';
    for (final fee in current.recurringFees) {
      if (_feesController.rows.length == 1 &&
          _feesController.rows.first.nameController.text.isEmpty) {
        _feesController.rows.last.nameController.text = fee.name;
        _feesController.rows.last.amountController.text =
            formatNumber(fee.amount);
      } else {
        _feesController.addRow();
        _feesController.rows.last.nameController.text = fee.name;
        _feesController.rows.last.amountController.text =
            formatNumber(fee.amount);
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final current = _current;
    if (current == null || _startDate == null || _endDate == null) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final newElectricityPrice =
          parseFormattedNumber(_electricityPriceController.text) ?? 0;
      final newWaterPrice =
          parseFormattedNumber(_waterPriceController.text) ?? 0;
      final version = ContractVersion(
        id: '',
        contractId: widget.contractId,
        versionNo: current.versionNo + 1,
        changeReason: widget.reason,
        startDate: _startDate!,
        endDate: _endDate!,
        monthlyRent: parseFormattedNumber(_monthlyRentController.text) ?? 0,
        depositAmount: parseFormattedNumber(_depositController.text) ?? 0,
        electricityUnitPrice:
            current.electricityBillingMethod == UtilityBillingMethod.flat
                ? current.electricityUnitPrice
                : newElectricityPrice,
        waterUnitPrice: current.waterBillingMethod == UtilityBillingMethod.flat
            ? current.waterUnitPrice
            : newWaterPrice,
        electricityBillingMethod: current.electricityBillingMethod,
        waterBillingMethod: current.waterBillingMethod,
        electricityFlatAmount:
            current.electricityBillingMethod == UtilityBillingMethod.flat
                ? newElectricityPrice
                : current.electricityFlatAmount,
        waterFlatAmount: current.waterBillingMethod == UtilityBillingMethod.flat
            ? newWaterPrice
            : current.waterFlatAmount,
        recurringFees: _feesController.fees,
        rentCycleMonths: current.rentCycleMonths,
        rentCycleAnchorYm: current.rentCycleAnchorYm,
        paymentDueDayOfMonth:
            int.tryParse(_paymentDueDayController.text.trim()) ??
                current.paymentDueDayOfMonth,
        serviceFeeRatePerSqm: current.serviceFeeRatePerSqm,
        contractAreaSqm: current.contractAreaSqm,
        serviceFeeAmount: current.serviceFeeAmount,
        serviceBillingMethod: current.serviceBillingMethod,
        lateFeeTerms: _lateFeeTermsController.text.trim().isEmpty
            ? null
            : _lateFeeTermsController.text.trim(),
        specialNote: _specialNoteController.text.trim().isEmpty
            ? null
            : _specialNoteController.text.trim(),
        realEstate: current.realEstate,
        createdAt: DateTime.now(),
      );

      await ref
          .read(contractRepositoryProvider)
          .addVersion(widget.contractId, version);

      ref.invalidate(contractProvider(widget.contractId));
      ref.invalidate(contractVersionsProvider(widget.contractId));
      ref.invalidate(contractListProvider);
      final roomIds =
          await ref.read(contractRoomIdsProvider(widget.contractId).future);
      for (final roomId in roomIds) {
        ref.invalidate(roomActiveContractProvider(roomId));
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorText = AppStrings.t('contractRenew.saveError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final contractAsync = ref.watch(contractProvider(widget.contractId));
    final isRenewal = widget.reason == ChangeReason.renewal;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
            child:
                Text(AppStrings.t('contractRenew.loadError', {'error': '$e'}))),
        data: (contract) {
          final versionAsync = contract.currentVersionId == null
              ? null
              : ref.watch(contractVersionProvider(contract.currentVersionId!));
          final current = versionAsync?.valueOrNull;
          final rooms =
              ref.watch(contractRoomsProvider(widget.contractId)).valueOrNull;

          if (current == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _prefill(current);
          final newVersionNo = current.versionNo + 1;

          return Column(
            children: [
              TopBar(
                title: AppStrings.t(isRenewal
                    ? 'contractRenew.titleRenew'
                    : 'contractRenew.titleAmend'),
                subtitle: AppStrings.t('contractRenew.subtitle', {
                  'room': rooms == null || rooms.isEmpty
                      ? '…'
                      : rooms.map((r) => r.roomNo).join(', '),
                  'version': '$newVersionNo',
                }),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    AppBanner(
                      message: AppStrings.t(
                          isRenewal
                              ? 'contractRenew.bannerRenewal'
                              : 'contractRenew.bannerAmendment',
                          {'version': '$newVersionNo'}),
                    ),
                    SectionLabel(AppStrings.t('contractRenew.sectionNewTerms')),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractRenew.startDate'),
                            initialValue: _startDate == null
                                ? ''
                                : DateFormat('dd/MM/yyyy').format(_startDate!),
                            key: ValueKey('start-$_startDate'),
                            trailing: AppTextFieldTrailingIcon.date,
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractRenew.endDate'),
                            initialValue: _endDate == null
                                ? ''
                                : DateFormat('dd/MM/yyyy').format(_endDate!),
                            key: ValueKey('end-$_endDate'),
                            trailing: AppTextFieldTrailingIcon.date,
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    if (isRenewal)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                            AppStrings.t('contractRenew.prefilledHint', {
                              'date': DateFormat('dd/MM/yyyy')
                                  .format(current.endDate)
                            }),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textTertiary)),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractRenew.deposit'),
                            controller: _depositController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [ThousandsInputFormatter()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractRenew.monthlyRent'),
                            controller: _monthlyRentController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [ThousandsInputFormatter()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label:
                                AppStrings.t('contractRenew.electricityPrice'),
                            controller: _electricityPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [ThousandsInputFormatter()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            label: AppStrings.t('contractRenew.waterPrice'),
                            controller: _waterPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [ThousandsInputFormatter()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: AppStrings.t('contractRenew.paymentDueDay'),
                      controller: _paymentDueDayController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    RecurringFeesEditor(controller: _feesController),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: AppStrings.t('contractRenew.lateFeeTerms'),
                      controller: _lateFeeTermsController,
                      maxLines: 3,
                      textarea: true,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: AppStrings.t('contractRenew.specialNote'),
                      controller: _specialNoteController,
                      maxLines: 3,
                      textarea: true,
                    ),
                    SectionLabel(AppStrings.t('contractRenew.sectionChangedVs',
                        {'version': '${current.versionNo}'})),
                    AnimatedBuilder(
                      animation: _formListenable,
                      builder: (context, _) => _ChangedVsBlock(
                        current: current,
                        newStartDate: _startDate!,
                        newEndDate: _endDate!,
                        newDeposit:
                            parseFormattedNumber(_depositController.text) ?? 0,
                        newMonthlyRent:
                            parseFormattedNumber(_monthlyRentController.text) ??
                                0,
                        newElectricityPrice: parseFormattedNumber(
                                _electricityPriceController.text) ??
                            0,
                        newWaterPrice:
                            parseFormattedNumber(_waterPriceController.text) ??
                                0,
                        newPaymentDueDay: int.tryParse(
                                _paymentDueDayController.text.trim()) ??
                            current.paymentDueDayOfMonth,
                        newFees: _feesController.fees,
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
                            label: AppStrings.t('contractRenew.createVersion',
                                {'version': '$newVersionNo'}),
                            onPressed: _isSaving ? null : _save,
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

class _ChangedVsBlock extends StatelessWidget {
  final ContractVersion current;
  final DateTime newStartDate;
  final DateTime newEndDate;
  final num newDeposit;
  final num newMonthlyRent;
  final num newElectricityPrice;
  final num newWaterPrice;
  final int newPaymentDueDay;
  final List<RecurringFee> newFees;

  const _ChangedVsBlock({
    required this.current,
    required this.newStartDate,
    required this.newEndDate,
    required this.newDeposit,
    required this.newMonthlyRent,
    required this.newElectricityPrice,
    required this.newWaterPrice,
    required this.newPaymentDueDay,
    required this.newFees,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final oldElectricityPrice =
        current.electricityBillingMethod == UtilityBillingMethod.flat
            ? (current.electricityFlatAmount ?? 0)
            : (current.electricityUnitPrice ?? 0);
    final oldWaterPrice =
        current.waterBillingMethod == UtilityBillingMethod.flat
            ? (current.waterFlatAmount ?? 0)
            : (current.waterUnitPrice ?? 0);
    final oldFeesText = current.recurringFees
        .map((f) => '${f.name} ${formatNumber(f.amount)}')
        .join(', ');
    final newFeesText =
        newFees.map((f) => '${f.name} ${formatNumber(f.amount)}').join(', ');

    final rows = <Widget>[];
    void addIfChanged(String label, String oldValue, String newValue) {
      if (oldValue == newValue) return;
      rows.add(DetailRow(label: label, value: '$oldValue → $newValue'));
    }

    addIfChanged(AppStrings.t('contractDetail.startDate'),
        df.format(current.startDate), df.format(newStartDate));
    addIfChanged(AppStrings.t('contractDetail.endDate'),
        df.format(current.endDate), df.format(newEndDate));
    addIfChanged(AppStrings.t('contractDetail.deposit'),
        formatNumber(current.depositAmount), formatNumber(newDeposit));
    addIfChanged(AppStrings.t('contractDetail.monthlyRent'),
        formatNumber(current.monthlyRent), formatNumber(newMonthlyRent));
    addIfChanged(AppStrings.t('contractDetail.electricity'),
        formatNumber(oldElectricityPrice), formatNumber(newElectricityPrice));
    addIfChanged(AppStrings.t('contractDetail.water'),
        formatNumber(oldWaterPrice), formatNumber(newWaterPrice));
    addIfChanged(AppStrings.t('contractRenew.paymentDueDay'),
        '${current.paymentDueDayOfMonth}', '$newPaymentDueDay');
    addIfChanged(
        AppStrings.t('contractDetail.recurringFees'), oldFeesText, newFeesText);

    if (rows.isEmpty) {
      return Text(AppStrings.t('contractRenew.noChanges'),
          style: const TextStyle(color: AppColors.textSecondary));
    }
    for (var i = 0; i < rows.length; i++) {
      if (i == rows.length - 1) {
        final row = rows[i] as DetailRow;
        rows[i] =
            DetailRow(label: row.label, value: row.value, showDivider: false);
      }
    }
    return DetailBlock(children: rows);
  }
}
