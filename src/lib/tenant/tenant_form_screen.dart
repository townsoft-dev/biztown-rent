import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/tenant.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/avatar.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// T-04 — Tenant Create/Edit (node 220:3476, Figma). `tenantId == null` →
/// tạo mới; ngược lại → sửa, nạp dữ liệu thật qua `tenantProvider`.
class TenantFormScreen extends ConsumerStatefulWidget {
  final String? tenantId;
  // Truyền từ shortcut "+ Quick add tenant" ở T-06 — Nhà tự điền sẵn, ẩn hẳn
  // field House (BR-CTR-13/SCREEN-SPEC T-04), và Lưu xong trả về tenantId
  // vừa tạo cho T-06 chọn sẵn thay vì quay lại T-01.
  final String? presetHouseId;

  const TenantFormScreen({super.key, this.tenantId, this.presetHouseId});

  bool get isEdit => tenantId != null;

  @override
  ConsumerState<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends ConsumerState<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _noteController = TextEditingController();
  TenantSex? _sex;
  DateTime? _dateOfBirth;
  String? _houseId;
  String? _existingFrontPath;
  String? _existingBackPath;
  XFile? _newFrontFile;
  XFile? _newBackFile;
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _prefill(Tenant tenant) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = tenant.fullName;
    _phoneController.text = tenant.phone;
    _emailController.text = tenant.mail ?? '';
    _idNumberController.text = tenant.idNumber ?? '';
    _noteController.text = tenant.note ?? '';
    _sex = tenant.sex;
    _dateOfBirth = tenant.dateOfBirth;
    _houseId = tenant.houseId;
    _existingFrontPath = tenant.idPhotoFront;
    _existingBackPath = tenant.idPhotoBack;
  }

  Future<void> _pickSex() async {
    final picked = await showModalBottomSheet<TenantSex>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final sex in TenantSex.values)
              ListTile(
                title: Text(tenantSexLabel(sex)),
                onTap: () => Navigator.of(context).pop(sex),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sex = picked);
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickIdPhoto({required bool front}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.photo_camera_rounded),
              title: Text(AppStrings.t('common.takePhoto')),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Symbols.photo_library_rounded),
              title: Text(AppStrings.t('common.chooseFromGallery')),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (front) {
        _newFrontFile = file;
      } else {
        _newBackFile = file;
      }
    });
  }

  Future<void> _pickHouse(List<dynamic> houses) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final house in houses)
              ListTile(
                title: Text(house.name as String),
                onTap: () => Navigator.of(context).pop(house.id as String),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _houseId = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if ((_newFrontFile == null && _existingFrontPath == null) ||
        (_newBackFile == null && _existingBackPath == null)) {
      setState(() => _errorText = AppStrings.t('tenantForm.idPhotosRequired'));
      return;
    }
    final houseId = _houseId;
    if (houseId == null) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(tenantRepositoryProvider);
      final phone = _phoneController.text.trim();

      // Cảnh báo trùng SĐT trong CÙNG 1 Nhà (BR-CTR-09 edge case) — chỉ kiểm
      // tra lúc tạo mới hoặc đổi số, không tự chặn, chỉ hỏi lại người dùng.
      if (!widget.isEdit ||
          (await repo.getById(widget.tenantId!)).phone != phone) {
        final existing = await repo.findByPhoneInHouse(houseId, phone);
        if (existing != null && existing.id != widget.tenantId && mounted) {
          final openExisting = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppStrings.t('tenantForm.duplicateFoundTitle')),
              content: Text(AppStrings.t('tenantForm.duplicateFoundDescription',
                  {'name': existing.fullName})),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppStrings.t('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(AppStrings.t('tenantForm.openExisting')),
                ),
              ],
            ),
          );
          if (openExisting == true && mounted) {
            setState(() => _isSaving = false);
            context.pushReplacement('/tenant/${existing.id}');
            return;
          }
        }
      }

      var frontPath = _existingFrontPath;
      var backPath = _existingBackPath;

      final tenant = Tenant(
        id: '',
        houseId: houseId,
        fullName: _fullNameController.text.trim(),
        phone: phone,
        sex: _sex,
        dateOfBirth: _dateOfBirth,
        mail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        idNumber: _idNumberController.text.trim().isEmpty
            ? null
            : _idNumberController.text.trim(),
        idPhotoFront: frontPath,
        idPhotoBack: backPath,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      late final String tenantId;
      if (widget.isEdit) {
        tenantId = widget.tenantId!;
        await repo.update(tenantId, tenant);
      } else {
        final created = await repo.create(tenant);
        tenantId = created.id;
      }

      if (_newFrontFile != null) {
        frontPath = await repo.uploadIdPhoto(
            houseId, tenantId, File(_newFrontFile!.path));
      }
      if (_newBackFile != null) {
        backPath = await repo.uploadIdPhoto(
            houseId, tenantId, File(_newBackFile!.path));
      }
      if (_newFrontFile != null || _newBackFile != null) {
        await repo.update(
          tenantId,
          Tenant(
            id: tenantId,
            houseId: tenant.houseId,
            fullName: tenant.fullName,
            phone: tenant.phone,
            sex: tenant.sex,
            dateOfBirth: tenant.dateOfBirth,
            mail: tenant.mail,
            idNumber: tenant.idNumber,
            idPhotoFront: frontPath,
            idPhotoBack: backPath,
            note: tenant.note,
            createdAt: tenant.createdAt,
          ),
        );
        if (_newFrontFile != null && _existingFrontPath != null) {
          await repo.deletePhoto(_existingFrontPath!);
        }
        if (_newBackFile != null && _existingBackPath != null) {
          await repo.deletePhoto(_existingBackPath!);
        }
      }

      ref.invalidate(tenantsProvider);
      ref.invalidate(tenantListProvider);
      if (widget.isEdit) ref.invalidate(tenantProvider(tenantId));
      if (mounted) context.pop(tenantId);
    } catch (e) {
      setState(() => _errorText = AppStrings.t('tenantForm.saveError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    if (!widget.isEdit) {
      return _buildScaffold(context, null);
    }
    final tenantAsync = ref.watch(tenantProvider(widget.tenantId!));
    return tenantAsync.when(
      data: (tenant) {
        _prefill(tenant);
        return _buildScaffold(context, tenant);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
          body: Center(
              child:
                  Text(AppStrings.t('tenantForm.loadError', {'error': '$e'})))),
    );
  }

  Widget _buildScaffold(BuildContext context, Tenant? tenant) {
    final housesAsync = ref.watch(housesProvider);
    final houses = housesAsync.valueOrNull ?? const [];
    if (!widget.isEdit && _houseId == null) {
      _houseId =
          widget.presetHouseId ?? (houses.isNotEmpty ? houses.first.id : null);
    }
    final showHouseField = houses.length > 1 && widget.presetHouseId == null;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
            title: widget.isEdit
                ? AppStrings.t('tenantForm.titleEdit')
                : AppStrings.t('tenantForm.titleAdd'),
            subtitle: AppStrings.t('tenantForm.subtitlePool'),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // "Upload photo" — decorative only ở đây: `tb_tenant` không
                  // có cột ảnh đại diện riêng (chỉ có `idPhotoFront/Back`),
                  // nên không bịa thêm chỗ lưu; chỉ hiện Avatar chữ cái đầu
                  // theo tên đang gõ, không cho tương tác.
                  Row(
                    children: [
                      Avatar(
                          initials: _fullNameController.text.trim().isEmpty
                              ? '?'
                              : initialsFromName(
                                  _fullNameController.text.trim())),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (showHouseField) ...[
                    AppTextField(
                      label: AppStrings.t('tenantForm.house'),
                      initialValue: houses
                          .firstWhere((h) => h.id == _houseId,
                              orElse: () => houses.first)
                          .name,
                      key: ValueKey('house-$_houseId'),
                      trailing: AppTextFieldTrailingIcon.select,
                      onTap: () => _pickHouse(houses),
                    ),
                    const SizedBox(height: 10),
                  ],
                  AppTextField(
                    label: AppStrings.t('tenantForm.fullName'),
                    controller: _fullNameController,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.t('common.required')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('tenantForm.phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.t('common.required')
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(AppStrings.t('tenantForm.duplicateHint'),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('tenantForm.sex'),
                          initialValue:
                              _sex == null ? '' : tenantSexLabel(_sex!),
                          key: ValueKey('sex-$_sex'),
                          trailing: AppTextFieldTrailingIcon.select,
                          onTap: _pickSex,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('tenantForm.dateOfBirth'),
                          initialValue: _dateOfBirth == null
                              ? ''
                              : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
                          key: ValueKey('dob-$_dateOfBirth'),
                          trailing: AppTextFieldTrailingIcon.date,
                          onTap: _pickDateOfBirth,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('tenantForm.email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('tenantForm.idNumber'),
                    controller: _idNumberController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.t('common.required')
                        : null,
                  ),
                  SectionLabel(AppStrings.t('tenantForm.sectionIdPhotos')),
                  Row(
                    children: [
                      Expanded(
                        child: _IdPhotoPickerTile(
                          label: AppStrings.t('common.front'),
                          existingPath: _existingFrontPath,
                          newFile: _newFrontFile,
                          onTap: () => _pickIdPhoto(front: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _IdPhotoPickerTile(
                          label: AppStrings.t('common.back'),
                          existingPath: _existingBackPath,
                          newFile: _newBackFile,
                          onTap: () => _pickIdPhoto(front: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('tenantForm.note'),
                    controller: _noteController,
                    maxLines: 3,
                    textarea: true,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _IdPhotoPickerTile extends ConsumerWidget {
  final String label;
  final String? existingPath;
  final XFile? newFile;
  final VoidCallback onTap;

  const _IdPhotoPickerTile({
    required this.label,
    required this.existingPath,
    required this.newFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget child;
    if (newFile != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
        child: Image.file(File(newFile!.path),
            fit: BoxFit.cover, width: double.infinity, height: 90),
      );
    } else if (existingPath != null) {
      child = FutureBuilder<String>(
        future:
            ref.read(tenantRepositoryProvider).signedPhotoUrl(existingPath!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)));
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
            child: Image.network(snapshot.data!,
                fit: BoxFit.cover, width: double.infinity, height: 90),
          );
        },
      );
    } else {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.badge_rounded,
              color: AppColors.textTertiary, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
      child: Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
        ),
        child: child,
      ),
    );
  }
}
