import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
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
  bool _isUploadingAvatar = false;
  String? _errorText;

  void _prefill(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = profile.fullName;
    _idNumberController.text = profile.idNumber ?? '';
  }

  /// Đổi ảnh đại diện — thay vì gộp vào nút "Save" chung của form (chỉ dành
  /// cho Full name/ID number), upload NGAY khi chọn xong ảnh, đúng hành vi
  /// "Change photo" quen thuộc của hầu hết app (bấm là đổi luôn, không cần
  /// bấm Save riêng). Xoá ảnh cũ SAU KHI DB đã trỏ sang ảnh mới thành công,
  /// tránh cửa sổ hở nơi DB trỏ vào 1 path vừa bị xoá nếu có lỗi giữa chừng.
  Future<void> _changePhoto(String? previousPath) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(AppStrings.t('common.takePhoto')),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(AppStrings.t('common.chooseFromGallery')),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (file == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(userRepositoryProvider).uploadAvatar(File(file.path));
      if (previousPath != null) {
        await ref.read(userRepositoryProvider).deleteAvatar(previousPath);
      }
      ref.invalidate(currentUserProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppStrings.t('personalProfile.avatarUploadError'))));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
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
      setState(() => _errorText = AppStrings.t('personalProfile.saveError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isMainManagerAsync = ref.watch(isMainManagerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
              title: AppStrings.t('personalProfile.title'),
              onBack: () => context.pop()),
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
                          Builder(builder: (context) {
                            final avatarUrlAsync = profile.avatarPath == null
                                ? null
                                : ref.watch(
                                    avatarUrlProvider(profile.avatarPath!));
                            return Avatar(
                              initials: initialsFromName(profile.fullName),
                              imageUrl: avatarUrlAsync?.valueOrNull,
                            );
                          }),
                          const SizedBox(width: 12),
                          if (_isUploadingAvatar)
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                          else
                            GestureDetector(
                              onTap: () => _changePhoto(profile.avatarPath),
                              child: Text(
                                  AppStrings.t('personalProfile.changePhoto'),
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      height: 18 / 13,
                                      color: AppColors.info)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: AppStrings.t('personalProfile.fullName'),
                        controller: _fullNameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppStrings.t('common.required')
                            : null,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: AppStrings.t('personalProfile.phone'),
                        initialValue: profile.phone,
                        readOnly: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(AppStrings.t('personalProfile.phoneHint'),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 17 / 12,
                                color: AppColors.textTertiary)),
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: AppStrings.t('personalProfile.idNumber'),
                        controller: _idNumberController,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: AppStrings.t('personalProfile.role'),
                        initialValue: isMainManagerAsync.valueOrNull == true
                            ? AppStrings.t('common.mainManager')
                            : AppStrings.t('common.manager'),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: AppStrings.t('personalProfile.createdAt'),
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
                              label: AppStrings.t('common.cancel'),
                              style: AppButtonStyle.ghost,
                              onPressed: _isSaving ? null : () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: AppButton(
                                  label: AppStrings.t('common.save'),
                                  onPressed: _isSaving ? null : _save)),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(AppStrings.t(
                      'personalProfile.loadError', {'error': '$e'}))),
            ),
          ),
        ],
      ),
    );
  }
}
