import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/photo_picker_row.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// H-02 — House Registration (Create/Edit) (node 220:2614, lấy qua Figma MCP
/// 10/09/2026). `houseId == null` → chế độ "Add house" (field trống);
/// ngược lại → "Edit house" nạp sẵn dữ liệu mẫu khớp Figma (chưa nối
/// `tb_house` thật).
class HouseFormScreen extends StatelessWidget {
  final String? houseId;

  const HouseFormScreen({super.key, this.houseId});

  bool get _isEdit => houseId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
            title: _isEdit ? 'Edit house' : 'Add house',
            subtitle: _isEdit ? 'Nha tro Binh An' : null,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const SectionLabel('House info'),
                PhotoPickerRow(photoCount: _isEdit ? 2 : 0, onAddPhoto: () {}),
                const SizedBox(height: 10),
                AppTextField(
                    label: 'Name *',
                    initialValue: _isEdit ? 'Nha tro Binh An' : null,
                    hintText: 'e.g. Nha tro Binh An'),
                const SizedBox(height: 10),
                AppTextField(
                    label: 'Address *',
                    initialValue:
                        _isEdit ? '12 Le Van Sy, District 3, HCMC' : null,
                    hintText: 'Street, ward, district, city'),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Description',
                  initialValue: _isEdit
                      ? '24 rooms, 3 floors, gated, 24/7 security.'
                      : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 6),
                const SectionLabel('Owner info · Main Manager only'),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Owner full name',
                            initialValue:
                                _isEdit ? 'Nguyễn Thúy Hường' : null)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppTextField(
                            label: 'Owner phone',
                            initialValue: _isEdit ? '0909 888 777' : null,
                            keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Owner ID number',
                            initialValue: _isEdit ? '079xxxxxxxxx' : null)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppTextField(
                            label: 'Owner tax code',
                            initialValue: _isEdit ? '0312xxxxxx' : null)),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                    label: 'Owner bank account *',
                    initialValue: _isEdit
                        ? 'Vietcombank · NGUYEN THUY HUONG · 0071000xxxxxx'
                        : null),
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
                    initialValue: _isEdit ? 'huong.nguyen@example.com' : null,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 6),
                const SectionLabel('Default unit prices'),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Electricity /kWh',
                            initialValue: _isEdit ? '3,800' : null,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppTextField(
                            label: 'Water /m³',
                            initialValue: _isEdit ? '35,000' : null,
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                    label: 'Default recurring fees',
                    initialValue:
                        _isEdit ? 'Internet 100,000 · Waste 30,000' : null),
                const SizedBox(height: 10),
                const AppBanner(
                  message:
                      "Unit prices auto-fill a new contract (invoices always use the price on the contract version); recurring fees auto-fill a new room's own recurringFees, which can then be edited per room.",
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                        child: AppButton(
                            label: 'Cancel',
                            style: AppButtonStyle.ghost,
                            onPressed: () => context.pop())),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppButton(
                            label: 'Save', onPressed: () => context.pop())),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
