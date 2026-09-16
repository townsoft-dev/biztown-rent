import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../core/phone_validation.dart';
import '../data/auth_repository.dart';
import '../data/models/manager_account.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/check_row.dart';
import '../shared/confirm_dialog.dart';
import '../shared/field_label.dart';
import '../shared/section_label.dart';
import '../shared/toggle_row.dart';
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
          ? AppStrings.t('managerForm.conflictError')
          : AppStrings.t('managerForm.saveError'));
    } catch (e) {
      setState(() => _errorText = AppStrings.t('managerForm.saveError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.t('managerForm.removeConfirmTitle'),
      description: AppStrings.t('managerForm.removeConfirmDescription'),
      confirmLabel: AppStrings.t('managerForm.remove'),
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
        _errorText = AppStrings.t('managerForm.removeError');
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
    ref.watch(languageProvider);
    final managersAsync = _isEdit
        ? ref.watch(managerAccountsProvider)
        : const AsyncValue<List<ManagerAccount>>.data([]);
    final ownedIdsAsync = ref.watch(ownedHouseIdsProvider);
    final housesAsync = ref.watch(housesProvider);
    final roomStatusesAsync = ref.watch(roomStatusesByHouseProvider);
    final activeManagersAsync = ref.watch(activeManagerByHouseProvider);
    final myPhone = ref.watch(currentUserProfileProvider).valueOrNull?.phone;

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
          TopBar(
              title: AppStrings.t('managerForm.title'),
              onBack: () => context.pop()),
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
                          SectionLabel(
                              AppStrings.t('managerForm.sectionProfile')),
                          AppTextField(
                            label: AppStrings.t('managerForm.fullName'),
                            controller: _fullNameController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppStrings.t('common.required')
                                : null,
                          ),
                          const SizedBox(height: 10),
                          // Figma chỉ có 1 label "Role" DÙNG CHUNG cho cả 2
                          // ô bên dưới (không phải 2 field tự có label
                          // riêng) — trước đó dùng `AppTextField(label:
                          // 'Role', ...)` khiến ô "Manager" tự có thêm label
                          // riêng còn `ToggleRow` thì không, làm 2 ô lệch
                          // chiều cao khi bám đáy (`crossAxisAlignment.end`).
                          // `IntrinsicHeight` + `stretch` ép cả 2 ô LUÔN cùng
                          // 1 chiều cao thật sự, không phụ thuộc tính toán
                          // tay dễ sai giữa `TextFormField` và `ToggleRow`.
                          FieldLabel(AppStrings.t('managerForm.role')),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 11),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgMuted,
                                      borderRadius: BorderRadius.circular(
                                          AppRadii.inputField),
                                    ),
                                    child: Text(AppStrings.t('common.manager'),
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: ToggleRow(
                                    label: AppStrings.t(
                                        'managerForm.accountActive'),
                                    value: _isActive,
                                    onChanged: (v) =>
                                        setState(() => _isActive = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_isEdit) ...[
                            AppTextField(
                              label: AppStrings.t('managerForm.phone'),
                              initialValue: widget.phone,
                              readOnly: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                  AppStrings.t('managerForm.phoneReadonlyNote'),
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 17 / 12,
                                      color: AppColors.textTertiary)),
                            ),
                          ] else
                            AppTextField(
                              label: AppStrings.t('managerForm.phone'),
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              hintText: AppStrings.t('managerForm.phoneHint'),
                              inputFormatters: const [VnPhoneInputFormatter()],
                              validator: (v) {
                                final phoneError = validateVnPhone(v);
                                if (phoneError != null) return phoneError;
                                // Qua được validateVnPhone nghĩa là v chắc
                                // chắn khác null và đúng định dạng.
                                if (myPhone != null &&
                                    AuthRepository.normalizePhoneForDb(v!) ==
                                        myPhone) {
                                  return AppStrings.t(
                                      'managerForm.cannotInviteSelf');
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 10),
                          AppTextField(
                            label: AppStrings.t('managerForm.idNumber'),
                            controller: _idNumberController,
                          ),
                          if (_isEdit && _joinedAt != null) ...[
                            const SizedBox(height: 10),
                            AppTextField(
                              label: AppStrings.t('managerForm.joinFrom'),
                              initialValue:
                                  DateFormat('dd/MM/yyyy').format(_joinedAt!),
                              readOnly: true,
                            ),
                          ],
                          const SizedBox(height: 10),
                          AppTextField(
                            label: AppStrings.t('managerForm.note'),
                            controller: _noteController,
                            maxLines: 3,
                            textarea: true,
                            hintText: AppStrings.t('managerForm.noteHint'),
                          ),
                          const SizedBox(height: 6),
                          SectionLabel(
                              AppStrings.t('managerForm.sectionHouseAccess')),
                          if (houses.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                AppStrings.t('managerForm.noHousesOwned'),
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          for (final house in houses) ...[
                            Builder(builder: (context) {
                              final conflict =
                                  activeManagers[house.id] != null &&
                                          activeManagers[house.id]!.phone !=
                                              (widget.phone ?? '')
                                      ? activeManagers[house.id]!.name
                                      : null;
                              final roomCount =
                                  roomStatuses[house.id]?.length ?? 0;
                              return CheckRow(
                                title: house.name,
                                subtitle: conflict != null
                                    ? AppStrings.t('managerForm.managedByOther',
                                        {'name': conflict})
                                    : AppStrings.t('managerForm.roomCount',
                                        {'count': '$roomCount'}),
                                checked: _selectedHouseIds.contains(house.id),
                                disabled: conflict != null,
                                onTap: () => setState(() {
                                  if (_selectedHouseIds.contains(house.id)) {
                                    _selectedHouseIds.remove(house.id);
                                  } else {
                                    _selectedHouseIds.add(house.id);
                                  }
                                }),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (houses.isNotEmpty && _selectedHouseIds.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 6),
                              child: Text(
                                AppStrings.t('managerForm.noHouseSelectedHint'),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary),
                              ),
                            ),
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
                                  label: AppStrings.t('common.cancel'),
                                  style: AppButtonStyle.ghost,
                                  onPressed:
                                      _isSaving ? null : () => context.pop(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: AppButton(
                                      label: AppStrings.t('common.save'),
                                      onPressed: _isSaving ? null : _save)),
                            ],
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 8),
                            AppButton(
                              label: AppStrings.t(
                                  'managerForm.removeAccountButton'),
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
