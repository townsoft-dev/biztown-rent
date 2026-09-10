import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/house.dart';
import '../data/photo_picker_controller.dart';
import '../data/recurring_fees_controller.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/photo_picker_row.dart';
import '../shared/recurring_fees_editor.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// H-02 — House Registration (Create/Edit) (node 220:2614, lấy qua Figma MCP
/// 10/09/2026), nối CRUD thật vào `tb_house` (10/09/2026, xem
/// changelog/2026-09-10.md). `houseId == null` → tạo mới; ngược lại → sửa,
/// nạp dữ liệu thật qua `houseProvider`.
class HouseFormScreen extends ConsumerStatefulWidget {
  final String? houseId;

  const HouseFormScreen({super.key, this.houseId});

  @override
  ConsumerState<HouseFormScreen> createState() => _HouseFormScreenState();
}

class _HouseFormScreenState extends ConsumerState<HouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerFullNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerIdNumberController = TextEditingController();
  final _ownerTaxCodeController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _electricityPriceController = TextEditingController();
  final _waterPriceController = TextEditingController();
  late final PhotoPickerController _photos;
  late final RecurringFeesController _fees;

  bool _initialized = false;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEdit => widget.houseId != null;

  @override
  void initState() {
    super.initState();
    _photos = PhotoPickerController();
    _fees = RecurringFeesController();
  }

  void _prefill(House house) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = house.name;
    _addressController.text = house.address;
    _descriptionController.text = house.description ?? '';
    _ownerFullNameController.text = house.ownerFullName;
    _ownerPhoneController.text = house.ownerPhone ?? '';
    _ownerIdNumberController.text = house.ownerIdNumber ?? '';
    _ownerTaxCodeController.text = house.ownerTaxCode ?? '';
    _ownerEmailController.text = house.ownerEmail ?? '';
    _bankAccountController.text = [
      house.bankAccountName,
      house.bankAccountNumber
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
    _electricityPriceController.text =
        house.defaultElectricityPrice?.toString() ?? '';
    _waterPriceController.text = house.defaultWaterPrice?.toString() ?? '';
    _photos.existingPaths.addAll(house.photos);
    if (house.recurringFees.isNotEmpty) {
      _fees.rows
        ..clear()
        ..addAll(house.recurringFees.map(
            (f) => RecurringFeeRow(name: f.name, amount: f.amount.toString())));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _ownerFullNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerIdNumberController.dispose();
    _ownerTaxCodeController.dispose();
    _bankAccountController.dispose();
    _ownerEmailController.dispose();
    _electricityPriceController.dispose();
    _waterPriceController.dispose();
    _photos.dispose();
    _fees.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(houseRepositoryProvider);
      final bankParts =
          _bankAccountController.text.split('·').map((e) => e.trim()).toList();
      final house = House(
        id: '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        photos: _photos.keptExistingPaths,
        houseType: 'Dãy trọ',
        ownerFullName: _ownerFullNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim().isEmpty
            ? null
            : _ownerPhoneController.text.trim(),
        ownerIdNumber: _ownerIdNumberController.text.trim().isEmpty
            ? null
            : _ownerIdNumberController.text.trim(),
        ownerTaxCode: _ownerTaxCodeController.text.trim().isEmpty
            ? null
            : _ownerTaxCodeController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim().isEmpty
            ? null
            : _ownerEmailController.text.trim(),
        bankAccountName: bankParts.isNotEmpty && bankParts.first.isNotEmpty
            ? bankParts.first
            : null,
        bankAccountNumber: bankParts.length > 1 && bankParts[1].isNotEmpty
            ? bankParts[1]
            : null,
        defaultElectricityPrice: num.tryParse(
            _electricityPriceController.text.trim().replaceAll(',', '')),
        defaultWaterPrice:
            num.tryParse(_waterPriceController.text.trim().replaceAll(',', '')),
        recurringFees: _fees.fees,
        createdAt: DateTime.now(),
      );

      late final String houseId;
      if (_isEdit) {
        houseId = widget.houseId!;
        await repo.update(houseId, house);
      } else {
        final created = await repo.create(house);
        houseId = created.id;
      }

      // Ảnh mới chỉ có path sau khi tạo/sửa xong (path Storage cần houseId) —
      // upload rồi ghi đè lại đúng 1 lần list `photos` cuối cùng của hàng.
      if (_photos.newFiles.isNotEmpty) {
        final uploadedPaths = <String>[];
        for (final file in _photos.newFiles) {
          uploadedPaths.add(await repo.uploadPhoto(houseId, File(file.path)));
        }
        await repo.update(
            houseId,
            House(
              id: houseId,
              name: house.name,
              address: house.address,
              description: house.description,
              photos: [..._photos.keptExistingPaths, ...uploadedPaths],
              houseType: house.houseType,
              ownerFullName: house.ownerFullName,
              ownerPhone: house.ownerPhone,
              ownerIdNumber: house.ownerIdNumber,
              ownerTaxCode: house.ownerTaxCode,
              ownerEmail: house.ownerEmail,
              bankAccountName: house.bankAccountName,
              bankAccountNumber: house.bankAccountNumber,
              bankBin: house.bankBin,
              serviceFeeRatePerSqm: house.serviceFeeRatePerSqm,
              defaultElectricityPrice: house.defaultElectricityPrice,
              defaultWaterPrice: house.defaultWaterPrice,
              recurringFees: house.recurringFees,
              createdAt: house.createdAt,
            ));
      }
      for (final removed in _photos.removedExisting) {
        await repo.deletePhoto(removed);
      }

      ref.invalidate(housesProvider);
      if (_isEdit) ref.invalidate(houseProvider(houseId));
      if (mounted) context.pop();
    } catch (e) {
      setState(() =>
          _errorText = 'Could not save this house. Please try again.\n$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) {
      return _buildScaffold(context, null);
    }
    final houseAsync = ref.watch(houseProvider(widget.houseId!));
    return houseAsync.when(
      data: (house) {
        _prefill(house);
        return _buildScaffold(context, house);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          Scaffold(body: Center(child: Text('Could not load this house.\n$e'))),
    );
  }

  Widget _buildScaffold(BuildContext context, House? house) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
            title: _isEdit ? 'Edit house' : 'Add house',
            subtitle: house?.name,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  const SectionLabel('House info'),
                  PhotoPickerRow(
                    controller: _photos,
                    resolveExistingUrl: (path) =>
                        ref.read(houseRepositoryProvider).signedPhotoUrl(path),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Name *',
                    controller: _nameController,
                    hintText: 'e.g. Nha tro Binh An',
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Address *',
                    controller: _addressController,
                    hintText: 'Street, ward, district, city',
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 3),
                  const SizedBox(height: 6),
                  const SectionLabel('Owner info · Main Manager only'),
                  Row(
                    children: [
                      Expanded(
                          child: AppTextField(
                              label: 'Owner full name',
                              controller: _ownerFullNameController)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: 'Owner phone',
                          controller: _ownerPhoneController,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: AppTextField(
                              label: 'Owner ID number',
                              controller: _ownerIdNumberController)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: AppTextField(
                              label: 'Owner tax code',
                              controller: _ownerTaxCodeController)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                      label: 'Owner bank account *',
                      controller: _bankAccountController),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Printed on every invoice for this house.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 17 / 12,
                            color: AppColors.textTertiary)),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                      label: 'Owner email',
                      controller: _ownerEmailController,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 6),
                  const SectionLabel('Default unit prices'),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Electricity /kWh',
                          controller: _electricityPriceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: 'Water /m³',
                          controller: _waterPriceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SectionLabel('Default recurring fees'),
                  RecurringFeesEditor(controller: _fees),
                  const SizedBox(height: 10),
                  const AppBanner(
                    message:
                        "Unit prices auto-fill a new contract (invoices always use the price on the contract version); recurring fees auto-fill a new room's own recurring fees, which can then be edited per room.",
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
            ),
          ),
        ],
      ),
    );
  }
}
