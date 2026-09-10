import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/house.dart';
import '../data/models/vn_bank.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// P-03 — Payout Bank Account (node 220:4878, Figma) — sửa tài khoản nhận
/// tiền (in trên hoá đơn/sinh mã QR VietQR) cho từng Nhà tôi SỞ HỮU, gộp
/// nhiều nhà vào 1 màn thay vì phải mở từng H-02. Vẫn là các field free-text
/// sẵn có trên `tb_house` (không phải bảng riêng) — xem DECISIONS.md Đợt 21
/// (Owner info vẫn nhập tay tự do theo từng Nhà, "Apply to all houses" chỉ
/// là hành động copy TƯỜNG MINH do người dùng tự bấm, không tự động đồng bộ).
class PayoutBankAccountScreen extends ConsumerStatefulWidget {
  const PayoutBankAccountScreen({super.key});

  @override
  ConsumerState<PayoutBankAccountScreen> createState() =>
      _PayoutBankAccountScreenState();
}

class _PayoutBankAccountScreenState
    extends ConsumerState<PayoutBankAccountScreen> {
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ownerFullNameController = TextEditingController();
  final _ownerTaxCodeController = TextEditingController();
  VnBank? _selectedBank;
  String? _editingHouseId;
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ownerFullNameController.dispose();
    _ownerTaxCodeController.dispose();
    super.dispose();
  }

  bool _hasAccount(House house) =>
      house.bankAccountNumber != null && house.bankAccountNumber!.isNotEmpty;

  void _selectHouse(House house) {
    setState(() {
      _editingHouseId = house.id;
      _selectedBank = VnBank.byBin(house.bankBin);
      _accountNameController.text = house.bankAccountName ?? '';
      _accountNumberController.text = house.bankAccountNumber ?? '';
      _ownerFullNameController.text = house.ownerFullName;
      _ownerTaxCodeController.text = house.ownerTaxCode ?? '';
    });
  }

  Future<void> _pickBank() async {
    final picked = await showModalBottomSheet<VnBank>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final bank in VnBank.all)
              ListTile(
                title: Text(bank.name),
                onTap: () => Navigator.of(context).pop(bank),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _selectedBank = picked);
  }

  Future<void> _save(House house) async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(houseRepositoryProvider);
      await repo.update(
          house.id,
          house.copyWith(
            ownerFullName: _ownerFullNameController.text.trim(),
            ownerTaxCode: _ownerTaxCodeController.text.trim().isEmpty
                ? null
                : _ownerTaxCodeController.text.trim(),
            bankAccountName: _accountNameController.text.trim().isEmpty
                ? null
                : _accountNameController.text.trim(),
            bankAccountNumber: _accountNumberController.text.trim().isEmpty
                ? null
                : _accountNumberController.text.trim(),
            bankBin: _selectedBank?.bin,
          ));
      ref.invalidate(housesProvider);
      ref.invalidate(houseProvider(house.id));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorText = 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _applyToAll(List<House> houses) async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(houseRepositoryProvider);
      for (final house in houses) {
        await repo.update(
            house.id,
            house.copyWith(
              ownerFullName: _ownerFullNameController.text.trim(),
              ownerTaxCode: _ownerTaxCodeController.text.trim().isEmpty
                  ? null
                  : _ownerTaxCodeController.text.trim(),
              bankAccountName: _accountNameController.text.trim().isEmpty
                  ? null
                  : _accountNameController.text.trim(),
              bankAccountNumber: _accountNumberController.text.trim().isEmpty
                  ? null
                  : _accountNumberController.text.trim(),
              bankBin: _selectedBank?.bin,
            ));
      }
      ref.invalidate(housesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Applied to ${houses.length} houses.')));
      }
    } catch (e) {
      setState(() =>
          _errorText = 'Could not apply to all houses. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownedIdsAsync = ref.watch(ownedHouseIdsProvider);
    final housesAsync = ref.watch(housesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(title: 'Payout bank account', onBack: () => context.pop()),
          Expanded(
            child: (ownedIdsAsync.valueOrNull == null ||
                    housesAsync.valueOrNull == null)
                ? const Center(child: CircularProgressIndicator())
                : Builder(builder: (context) {
                    final ownedIds = ownedIdsAsync.value!;
                    final houses = housesAsync.value!
                        .where((h) => ownedIds.contains(h.id))
                        .toList();
                    if (houses.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            "You don't own any house yet.",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }
                    final missingCount =
                        houses.where((h) => !_hasAccount(h)).length;
                    final editingHouse = houses.firstWhere(
                        (h) => h.id == (_editingHouseId ?? houses.first.id),
                        orElse: () => houses.first);
                    if (_editingHouseId == null) {
                      _selectHouse(editingHouse);
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        if (missingCount > 0) ...[
                          AppBanner(
                            message:
                                '$missingCount ${missingCount == 1 ? 'house has' : 'houses have'} no payout account yet — invoices for that house will be sent without payment details.',
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SectionLabel('Houses'),
                        for (final house in houses) ...[
                          ListCard(
                            thumbColor: AppColors.primary,
                            icon: Icons.account_balance_rounded,
                            title: house.name,
                            trailing: StatusPill(
                              text: _hasAccount(house) ? 'Set' : 'Missing',
                              style: _hasAccount(house)
                                  ? StatusBadgeStyle.active
                                  : StatusBadgeStyle.disabled,
                            ),
                            body: _hasAccount(house)
                                ? [
                                    VnBank.byBin(house.bankBin)?.name,
                                    house.bankAccountName,
                                    house.bankAccountNumber
                                  ].whereType<String>().join(' · ')
                                : 'No account yet',
                            onTap: () => _selectHouse(house),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 6),
                        SectionLabel('Edit — ${editingHouse.name}'),
                        AppTextField(
                          label: 'Bank name *',
                          initialValue: _selectedBank?.name ?? '',
                          key: ValueKey(
                              'bank-${editingHouse.id}-${_selectedBank?.bin}'),
                          readOnly: true,
                          trailing: AppTextFieldTrailingIcon.select,
                          onTap: _pickBank,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Account name *',
                          controller: _accountNameController,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Account number *',
                          controller: _accountNumberController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Owner full name',
                                controller: _ownerFullNameController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppTextField(
                                label: 'Owner tax code',
                                controller: _ownerTaxCodeController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Apply to all houses',
                          style: AppButtonStyle.ghost,
                          size: AppButtonSize.sm,
                          onPressed:
                              _isSaving ? null : () => _applyToAll(houses),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 8),
                          Text(_errorText!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Cancel',
                                style: AppButtonStyle.ghost,
                                onPressed:
                                    _isSaving ? null : () => context.pop(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: AppButton(
                                    label: 'Save',
                                    onPressed: _isSaving
                                        ? null
                                        : () => _save(editingHouse))),
                          ],
                        ),
                      ],
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
