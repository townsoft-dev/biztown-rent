import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/auth_repository.dart';
import '../data/models/manager_account.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/confirm_dialog.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// P-06 — Manager Detail (Create/Edit/Delete) (node 220:5099 + 410:2863,
/// Figma) — `phone == null` → mời Manager mới; ngược lại → sửa/thu quyền
/// người đã có. "House access" chỉ liệt kê Nhà tôi SỞ HỮU (P-06 không phải
/// nơi 1 Manager tự mời Manager khác).
class ManagerFormScreen extends ConsumerStatefulWidget {
  final String? phone;

  const ManagerFormScreen({super.key, this.phone});

  @override
  ConsumerState<ManagerFormScreen> createState() => _ManagerFormScreenState();
}

class _ManagerFormScreenState extends ConsumerState<ManagerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isActive = true;
  Set<String> _selectedHouseIds = {};
  Set<String> _previousHouseIds = {};
  DateTime? _joinedAt;
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEdit => widget.phone != null;

  void _prefill(ManagerAccount? manager) {
    if (_initialized) return;
    _initialized = true;
    if (manager != null) {
      _fullNameController.text = manager.fullName;
      _idNumberController.text = manager.idNumber ?? '';
      _noteController.text = manager.note ?? '';
      _isActive = manager.isActive;
      _selectedHouseIds = {...manager.houseIds};
      _previousHouseIds = {...manager.houseIds};
      _joinedAt = manager.joinedAt;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _isEdit
        ? widget.phone!
        : AuthRepository.normalizePhoneForDb(_phoneController.text);
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await ref.read(userRepositoryProvider).saveManager(
            phone: phone,
            fullName: _fullNameController.text.trim(),
            idNumber: _idNumberController.text.trim().isEmpty
                ? null
                : _idNumberController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            isActive: _isActive,
            houseIds: _selectedHouseIds,
            previousHouseIds: _previousHouseIds,
          );
      _invalidateManagerProviders();
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      setState(() => _errorText = e.code == '23505'
          ? 'One of the selected houses already has an active manager. Please go back and try again.'
          : 'Could not save this manager. Please try again.');
    } catch (e) {
      setState(
          () => _errorText = 'Could not save this manager. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove manager account?',
      description:
          'Are you sure you want to remove this manager account from your houses? This action cannot be undone.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).removeManager(widget.phone!);
      _invalidateManagerProviders();
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorText = 'Could not remove this manager. Please try again.';
      });
    }
  }

  void _invalidateManagerProviders() {
    ref.invalidate(managerAccountsProvider);
    ref.invalidate(activeManagerByHouseProvider);
    // Field "Manager" ở H-03 đọc từ đây — phải làm mới cho MỌI nhà, không
    // chỉ những nhà vừa đổi, vì gỡ 1 Manager có thể làm 1 nhà rơi về trạng
    // thái "chưa có Manager" (hiện Owner thay).
    ref.invalidate(houseManagersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final managersAsync = _isEdit
        ? ref.watch(managerAccountsProvider)
        : const AsyncValue<List<ManagerAccount>>.data([]);
    final ownedIdsAsync = ref.watch(ownedHouseIdsProvider);
    final housesAsync = ref.watch(housesProvider);
    final roomStatusesAsync = ref.watch(roomStatusesByHouseProvider);
    final activeManagersAsync = ref.watch(activeManagerByHouseProvider);

    ManagerAccount? manager;
    if (_isEdit) {
      for (final m in managersAsync.valueOrNull ?? const <ManagerAccount>[]) {
        if (m.phone == widget.phone) {
          manager = m;
          break;
        }
      }
    }

    final isLoading = (_isEdit && !managersAsync.hasValue) ||
        !ownedIdsAsync.hasValue ||
        !housesAsync.hasValue;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(title: 'Manager account', onBack: () => context.pop()),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(builder: (context) {
                    _prefill(manager);
                    final ownedIds = ownedIdsAsync.value!;
                    final houses = housesAsync.value!
                        .where((h) => ownedIds.contains(h.id))
                        .toList();
                    final roomStatuses = roomStatusesAsync.valueOrNull ?? {};
                    final activeManagers =
                        activeManagersAsync.valueOrNull ?? {};

                    return Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        children: [
                          const SectionLabel('Manager profile'),
                          AppTextField(
                            label: 'Full name *',
                            controller: _fullNameController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: AppTextField(
                                  label: 'Role',
                                  initialValue: 'Manager',
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _AccountActiveToggle(
                                  value: _isActive,
                                  onChanged: (v) =>
                                      setState(() => _isActive = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_isEdit) ...[
                            AppTextField(
                              label: 'Phone (login credential) *',
                              initialValue: widget.phone,
                              readOnly: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('The phone cannot be changed.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 17 / 12,
                                      color: AppColors.textTertiary)),
                            ),
                          ] else
                            AppTextField(
                              label: 'Phone (login credential) *',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              hintText: 'e.g. 0988 111 222',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          const SizedBox(height: 10),
                          AppTextField(
                            label: 'ID number',
                            controller: _idNumberController,
                          ),
                          if (_isEdit && _joinedAt != null) ...[
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Join from',
                              initialValue:
                                  DateFormat('dd/MM/yyyy').format(_joinedAt!),
                              readOnly: true,
                            ),
                          ],
                          const SizedBox(height: 10),
                          AppTextField(
                            label: 'Note',
                            controller: _noteController,
                            maxLines: 3,
                            hintText:
                                'e.g. Manages the Binh An row on weekdays',
                          ),
                          const SizedBox(height: 6),
                          const SectionLabel('House access'),
                          if (houses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "You don't own any house yet — create a house first.",
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          for (final house in houses) ...[
                            _HouseCheckRow(
                              title: house.name,
                              roomCount: roomStatuses[house.id]?.length ?? 0,
                              checked: _selectedHouseIds.contains(house.id),
                              conflictManagerName:
                                  activeManagers[house.id] != null &&
                                          activeManagers[house.id]!.phone !=
                                              (widget.phone ?? '')
                                      ? activeManagers[house.id]!.name
                                      : null,
                              onTap: () => setState(() {
                                if (_selectedHouseIds.contains(house.id)) {
                                  _selectedHouseIds.remove(house.id);
                                } else {
                                  _selectedHouseIds.add(house.id);
                                }
                              }),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 6),
                          if (_errorText != null) ...[
                            Text(_errorText!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12)),
                            const SizedBox(height: 8),
                          ],
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
                                      onPressed: _isSaving ? null : _save)),
                            ],
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Remove manager account',
                              style: AppButtonStyle.danger,
                              onPressed: _isSaving ? null : _remove,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

class _AccountActiveToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccountActiveToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Account active',
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 17 / 13.5,
                    color: AppColors.textPrimary)),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseCheckRow extends StatelessWidget {
  final String title;
  final int roomCount;
  final bool checked;
  final String? conflictManagerName;
  final VoidCallback onTap;

  const _HouseCheckRow({
    required this.title,
    required this.roomCount,
    required this.checked,
    this.conflictManagerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = conflictManagerName != null;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: disabled ? AppColors.bgMuted : AppColors.bgDefault,
          border: Border.all(
            color: disabled
                ? AppColors.borderSubtle
                : (checked ? AppColors.primary : AppColors.borderSubtle),
            width: !disabled && checked ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            Icon(
              checked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: disabled
                  ? AppColors.neutral200
                  : (checked ? AppColors.primary : AppColors.neutral200),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 18 / 13,
                          color: AppColors.textPrimary)),
                  Text(
                      disabled
                          ? 'Managed by $conflictManagerName'
                          : '$roomCount rooms',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 17 / 12,
                          color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
