import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/user_profile.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/avatar.dart';
import '../shared/top_bar.dart';

/// P-02 — Personal Profile (View/Edit) (node 220:4805, Figma) — 1 màn luôn ở
/// trạng thái sửa được (không có state View riêng), Full name/ID number sửa
/// tại chỗ, Phone/Role/Created at readonly.
class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() =>
      _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends ConsumerState<PersonalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorText;

  void _prefill(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = profile.fullName;
    _idNumberController.text = profile.idNumber ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await ref.read(userRepositoryProvider).updateProfile(
            fullName: _fullNameController.text.trim(),
            idNumber: _idNumberController.text.trim().isEmpty
                ? null
                : _idNumberController.text.trim(),
          );
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(currentUserNameProvider);
      // Tên vừa đổi cũng là tên hiện ở field "Manager" của H-03 (khi chính
      // mình là Owner và chưa gán Manager nào) — phải làm mới cả family này,
      // nếu không H-03 vẫn hiện tên cũ cho tới khi mở lại app.
      ref.invalidate(houseOwnerNameProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(
          () => _errorText = 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isMainManagerAsync = ref.watch(isMainManagerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(title: 'Personal profile', onBack: () => context.pop()),
          Expanded(
            child: profileAsync.when(
              data: (profile) {
                _prefill(profile);
                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    children: [
                      Row(
                        children: [
                          Avatar(initials: initialsFromName(profile.fullName)),
                          const SizedBox(width: 12),
                          // tb_user chưa có cột ảnh đại diện — chưa có backend
                          // để "Change photo" thật sự đổi ảnh, hiện đúng chữ
                          // Figma nhưng chỉ báo "sắp có" khi bấm, không bịa
                          // tính năng upload chưa được quyết định.
                          GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content:
                                        Text('Coming in a future update.'))),
                            child: Text('Change photo',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 18 / 13,
                                    color: AppColors.info)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Full name *',
                        controller: _fullNameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Phone (login credential) *',
                        initialValue: profile.phone,
                        readOnly: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Phone number can not be changed.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 17 / 12,
                                color: AppColors.textTertiary)),
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: 'ID number (CCCD/CMND)',
                        controller: _idNumberController,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Role',
                        initialValue: isMainManagerAsync.valueOrNull == true
                            ? 'Main Manager'
                            : 'Manager',
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Created at',
                        initialValue:
                            DateFormat('dd/MM/yyyy').format(profile.createdAt),
                        readOnly: true,
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
                              onPressed: _isSaving ? null : () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: AppButton(
                                  label: 'Save',
                                  onPressed: _isSaving ? null : _save)),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Could not load your profile.\n$e')),
            ),
          ),
        ],
      ),
    );
  }
}
