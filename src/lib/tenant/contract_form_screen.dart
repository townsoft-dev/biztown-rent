import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/contract_recurring_fees_controller.dart';
import '../data/models/contract.dart';
import '../data/models/house.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../data/models/tenant.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/contract_recurring_fees_editor.dart';
import '../shared/room_multi_select.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

const _termPresetsMonths = [3, 6, 12, 24, 36];

/// T-06 — Create Contract (node 220:3669, Figma). Có thể mở với 1 phòng đã
/// chọn sẵn (shortcut từ H-05 "Create contract") qua [initialRoomId] — Nhà
/// tự suy ra từ phòng đó.
class ContractFormScreen extends ConsumerStatefulWidget {
  final String? initialRoomId;

  const ContractFormScreen({super.key, this.initialRoomId});

  @override
  ConsumerState<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends ConsumerState<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  // Hiển thị cho 3 field "bấm mở picker" (House/Room/Tenant) — dùng
  // controller thật thay vì `initialValue`+`key` (từng dùng ở đây, phát hiện
  // 11/09/2026 lúc test T-06 trên máy thật: đổi giá trị qua picker tương tác
  // không tự cập nhật lại chữ hiển thị dù state `_houseId`/`_roomIds`/
  // `_tenantId` đã đổi đúng — Save vẫn dùng đúng giá trị mới, chỉ riêng hiển
  // thị bị kẹt). Cập nhật `.text` thủ công mỗi khi 3 field này đổi.
  final _houseDisplayController = TextEditingController();
  final _roomsDisplayController = TextEditingController();
  final _tenantDisplayController = TextEditingController();
  final _depositController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _electricityPriceController = TextEditingController();
  final _waterPriceController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _paymentDueDayController = TextEditingController();
  final _lateFeeTermsController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _brokerFeeController = TextEditingController();
  final _specialNoteController = TextEditingController();
  late final ContractRecurringFeesController _feesController =
      ContractRecurringFeesController();

  String? _houseId;
  List<String> _roomIds = [];
  String? _tenantId;
  DateTime _startDate = DateTime.now();
  int _termMonths = 12;
  UtilityBillingMethod _electricityMethod = UtilityBillingMethod.byReading;
  UtilityBillingMethod _waterMethod = UtilityBillingMethod.flat;
  ServiceBillingMethod _serviceMethod = ServiceBillingMethod.byArea;

  final Map<String, TextEditingController> _electricityReadingControllers = {};
  final Map<String, TextEditingController> _waterReadingControllers = {};
  DateTime _readingDate = DateTime.now();

  bool _initializedFromRoom = false;
  bool _isSaving = false;
  String? _errorText;

  DateTime get _endDate =>
      DateTime(_startDate.year, _startDate.month + _termMonths, _startDate.day)
          .subtract(const Duration(days: 1));

  @override
  void dispose() {
    _houseDisplayController.dispose();
    _roomsDisplayController.dispose();
    _tenantDisplayController.dispose();
    _depositController.dispose();
    _monthlyRentController.dispose();
    _electricityPriceController.dispose();
    _waterPriceController.dispose();
    _servicePriceController.dispose();
    _paymentDueDayController.dispose();
    _lateFeeTermsController.dispose();
    _brokerNameController.dispose();
    _brokerFeeController.dispose();
    _specialNoteController.dispose();
    _feesController.dispose();
    for (final c in _electricityReadingControllers.values) {
      c.dispose();
    }
    for (final c in _waterReadingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncReadingControllers() {
    final keep = _roomIds.toSet();
    _electricityReadingControllers.removeWhere((roomId, c) {
      final drop = !keep.contains(roomId);
      if (drop) c.dispose();
      return drop;
    });
    _waterReadingControllers.removeWhere((roomId, c) {
      final drop = !keep.contains(roomId);
      if (drop) c.dispose();
      return drop;
    });
    for (final roomId in _roomIds) {
      _electricityReadingControllers.putIfAbsent(
          roomId, () => TextEditingController());
      _waterReadingControllers.putIfAbsent(
          roomId, () => TextEditingController());
    }
  }

  void _applyRoomDefaults(List<Room> selectedRooms, House? house) {
    if (selectedRooms.isEmpty) return;
    final totalArea = selectedRooms.fold<num>(0, (sum, r) => sum + r.areaSqm);
    final totalRent =
        selectedRooms.fold<num>(0, (sum, r) => sum + (r.baseRent ?? 0));
    if (_monthlyRentController.text.isEmpty && totalRent > 0) {
      _monthlyRentController.text = formatNumber(totalRent);
      _depositController.text = formatNumber(totalRent);
    }
    if (house != null) {
      if (_electricityPriceController.text.isEmpty &&
          house.defaultElectricityPrice != null) {
        _electricityPriceController.text =
            formatNumber(house.defaultElectricityPrice!);
      }
      if (_waterPriceController.text.isEmpty &&
          house.defaultWaterPrice != null) {
        _waterPriceController.text = formatNumber(house.defaultWaterPrice!);
      }
      if (_servicePriceController.text.isEmpty &&
          house.serviceFeeRatePerSqm != null) {
        _servicePriceController.text =
            formatNumber(house.serviceFeeRatePerSqm! * totalArea);
      }
    }
    if (_feesController.rows.length == 1 &&
        _feesController.rows.first.nameController.text.isEmpty) {
      for (final fee in selectedRooms.first.recurringFees) {
        _feesController.rows.last.nameController.text = fee.name;
        _feesController.rows.last.amountController.text =
            formatNumber(fee.amount);
        _feesController.addRow();
      }
    }
  }

  Future<void> _pickHouse(List<House> houses) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final house in houses)
              ListTile(
                title: Text(house.name),
                onTap: () => Navigator.of(context).pop(house.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == _houseId) return;
    final house = houses.firstWhere((h) => h.id == picked);
    setState(() {
      _houseId = picked;
      _houseDisplayController.text = house.name;
      _roomIds = [];
      _roomsDisplayController.text = '';
      _syncReadingControllers();
    });
  }

  Future<void> _pickRooms() async {
    final houseId = _houseId;
    if (houseId == null) {
      setState(() => _errorText = AppStrings.t('contractForm.pickHouseFirst'));
      return;
    }
    final rooms = await ref.read(roomsProvider(houseId).future);
    final emptyRooms =
        rooms.where((r) => r.status == RoomStatus.empty).toList();
    if (!mounted) return;
    final picked = await RoomMultiSelect.show(context,
        emptyRooms: emptyRooms, selectedRoomIds: _roomIds);
    if (picked == null) return;
    final selectedRooms = rooms.where((r) => picked.contains(r.id)).toList();
    setState(() {
      _roomIds = picked;
      _roomsDisplayController.text =
          selectedRooms.map((r) => r.roomNo).join(', ');
      _syncReadingControllers();
    });
    final house = await ref.read(houseProvider(houseId).future);
    if (!mounted) return;
    setState(() => _applyRoomDefaults(selectedRooms, house));
  }

  Future<void> _pickTenant(List<Tenant> pool) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final tenant in pool)
                ListTile(
                  title: Text(tenant.fullName),
                  subtitle: Text(tenant.phone),
                  onTap: () => Navigator.of(context).pop(tenant.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    final tenant = pool.firstWhere((t) => t.id == picked);
    setState(() {
      _tenantId = picked;
      _tenantDisplayController.text = '${tenant.fullName} — ${tenant.phone}';
      _houseId ??= tenant.houseId;
    });
  }

  Future<void> _quickAddTenant() async {
    final newTenantId = await context.push<String>(
        '/tenant/new${_houseId != null ? '?houseId=$_houseId' : ''}');
    if (newTenantId == null) return;
    final tenant = await ref.read(tenantProvider(newTenantId).future);
    if (!mounted) return;
    setState(() {
      _tenantId = newTenantId;
      _tenantDisplayController.text = '${tenant.fullName} — ${tenant.phone}';
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickReadingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _readingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _readingDate = picked);
  }

  Future<void> _pickTerm() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final months in _termPresetsMonths)
              ListTile(
                title: Text(
                    AppStrings.t('contractForm.months', {'count': '$months'})),
                onTap: () => Navigator.of(context).pop(months),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _termMonths = picked);
  }

  Future<void> _pickUtilityMethod(
      List<UtilityBillingMethod> options,
      UtilityBillingMethod current,
      ValueChanged<UtilityBillingMethod> onPicked) async {
    final picked = await showModalBottomSheet<UtilityBillingMethod>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final method in options)
              ListTile(
                title: Text(utilityBillingMethodLabel(method)),
                onTap: () => Navigator.of(context).pop(method),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickServiceMethod() async {
    final picked = await showModalBottomSheet<ServiceBillingMethod>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final method in ServiceBillingMethod.values)
              ListTile(
                title: Text(serviceBillingMethodLabel(method)),
                onTap: () => Navigator.of(context).pop(method),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _serviceMethod = picked);
  }

  Future<void> _save() async {
    setState(() => _errorText = null);
    if (_houseId == null) {
      setState(() => _errorText = AppStrings.t('contractForm.missingHouse'));
      return;
    }
    if (_roomIds.isEmpty) {
      setState(() => _errorText = AppStrings.t('contractForm.missingRooms'));
      return;
    }
    if (_tenantId == null) {
      setState(() => _errorText = AppStrings.t('contractForm.missingTenant'));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rooms = await ref.read(roomsProvider(_houseId!).future);
    for (final roomId in _roomIds) {
      final elec = parseFormattedNumber(
          _electricityReadingControllers[roomId]?.text ?? '');
      final water =
          parseFormattedNumber(_waterReadingControllers[roomId]?.text ?? '');
      if (elec == null || water == null) {
        final room = rooms.firstWhere((r) => r.id == roomId);
        setState(() => _errorText = AppStrings.t(
            'contractForm.missingReadings', {'room': room.roomNo}));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final selectedRooms =
          rooms.where((r) => _roomIds.contains(r.id)).toList();
      final totalArea = selectedRooms.fold<num>(0, (sum, r) => sum + r.areaSqm);

      final version = ContractVersion(
        id: '',
        contractId: '',
        versionNo: 1,
        changeReason: ChangeReason.newContract,
        startDate: _startDate,
        endDate: _endDate,
        monthlyRent: parseFormattedNumber(_monthlyRentController.text) ?? 0,
        depositAmount: parseFormattedNumber(_depositController.text) ?? 0,
        electricityUnitPrice:
            parseFormattedNumber(_electricityPriceController.text),
        waterUnitPrice: parseFormattedNumber(_waterPriceController.text),
        electricityBillingMethod: _electricityMethod,
        waterBillingMethod: _waterMethod,
        electricityFlatAmount: _electricityMethod == UtilityBillingMethod.flat
            ? parseFormattedNumber(_electricityPriceController.text)
            : null,
        waterFlatAmount: _waterMethod == UtilityBillingMethod.flat
            ? parseFormattedNumber(_waterPriceController.text)
            : null,
        recurringFees: _feesController.fees,
        rentCycleMonths: 1,
        rentCycleAnchorYm: DateTime(_startDate.year, _startDate.month, 1),
        paymentDueDayOfMonth:
            int.tryParse(_paymentDueDayController.text.trim()) ?? 5,
        serviceFeeRatePerSqm: ref
            .read(houseProvider(_houseId!))
            .valueOrNull
            ?.serviceFeeRatePerSqm,
        contractAreaSqm: totalArea,
        serviceFeeAmount: parseFormattedNumber(_servicePriceController.text),
        serviceBillingMethod: _serviceMethod,
        lateFeeTerms: _lateFeeTermsController.text.trim().isEmpty
            ? null
            : _lateFeeTermsController.text.trim(),
        specialNote: _specialNoteController.text.trim().isEmpty
            ? null
            : _specialNoteController.text.trim(),
        realEstate: (_brokerNameController.text.trim().isEmpty &&
                _brokerFeeController.text.trim().isEmpty)
            ? null
            : RealEstateInfo(
                name: _brokerNameController.text.trim().isEmpty
                    ? null
                    : _brokerNameController.text.trim(),
                fee: parseFormattedNumber(_brokerFeeController.text)),
        createdAt: DateTime.now(),
      );

      final contractRepo = ref.read(contractRepositoryProvider);
      final contract = await contractRepo.create(
          tenantId: _tenantId!, roomIds: _roomIds, version: version);

      final roomRepo = ref.read(roomRepositoryProvider);
      for (final roomId in _roomIds) {
        await roomRepo.updateStatus(roomId, RoomStatus.occupied);
      }

      final readingRepo = ref.read(readingRepositoryProvider);
      for (final roomId in _roomIds) {
        await readingRepo.createMoveIn(
          roomId: roomId,
          houseId: _houseId!,
          contractId: contract.id,
          type: UtilityType.electricity,
          readingDate: _readingDate,
          currentReading: parseFormattedNumber(
              _electricityReadingControllers[roomId]!.text)!,
        );
        await readingRepo.createMoveIn(
          roomId: roomId,
          houseId: _houseId!,
          contractId: contract.id,
          type: UtilityType.water,
          readingDate: _readingDate,
          currentReading:
              parseFormattedNumber(_waterReadingControllers[roomId]!.text)!,
        );
      }

      ref.invalidate(contractsProvider);
      ref.invalidate(contractListProvider);
      ref.invalidate(tenantListProvider);
      ref.invalidate(roomsProvider(_houseId!));
      ref.invalidate(roomStatusesByHouseProvider);
      for (final roomId in _roomIds) {
        ref.invalidate(readingHistoryProvider(
            (roomId: roomId, utilityType: UtilityType.electricity)));
        ref.invalidate(readingHistoryProvider(
            (roomId: roomId, utilityType: UtilityType.water)));
        ref.invalidate(roomActiveContractProvider(roomId));
      }
      if (mounted) context.pushReplacement('/tenant/contracts/${contract.id}');
    } on PostgrestException catch (e) {
      setState(() => _errorText = e.code == '23505'
          ? AppStrings.t('contractForm.roomTakenError')
          : AppStrings.t('contractForm.saveError'));
    } catch (e) {
      setState(() => _errorText = AppStrings.t('contractForm.saveError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final housesAsync = ref.watch(housesProvider);
    final houses = housesAsync.valueOrNull ?? const [];
    final tenantsAsync = ref.watch(tenantsProvider);
    final tenants = tenantsAsync.valueOrNull ?? const [];

    if (!_initializedFromRoom && widget.initialRoomId != null) {
      _initializedFromRoom = true;
      ref.read(roomProvider(widget.initialRoomId!).future).then((room) async {
        final house = await ref.read(houseProvider(room.houseId).future);
        if (!mounted) return;
        setState(() {
          _houseId = room.houseId;
          _houseDisplayController.text = house.name;
          _roomIds = [room.id];
          _roomsDisplayController.text = room.roomNo;
          _syncReadingControllers();
          _applyRoomDefaults([room], house);
        });
      });
    }
    if (!_initializedFromRoom) _initializedFromRoom = true;

    final housesById = {for (final h in houses) h.id: h};
    final selectedHouse = _houseId == null ? null : housesById[_houseId];
    final poolForTenant = _houseId == null
        ? tenants
        : tenants.where((t) => t.houseId == _houseId).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('contractForm.title'),
            subtitle: selectedHouse == null
                ? AppStrings.t('contractForm.subtitle')
                : selectedHouse.name,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  SectionLabel(AppStrings.t('contractForm.sectionRoom')),
                  AppTextField(
                    label: AppStrings.t('contractForm.house'),
                    controller: _houseDisplayController,
                    trailing: AppTextFieldTrailingIcon.select,
                    onTap: () => _pickHouse(houses),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('contractForm.room'),
                    controller: _roomsDisplayController,
                    trailing: AppTextFieldTrailingIcon.select,
                    onTap: _pickRooms,
                  ),
                  SectionLabel(AppStrings.t('contractForm.sectionTenant')),
                  AppTextField(
                    label: AppStrings.t('contractForm.selectTenant'),
                    controller: _tenantDisplayController,
                    trailing: AppTextFieldTrailingIcon.select,
                    onTap: () => _pickTenant(poolForTenant),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: AppStrings.t('contractForm.quickAddTenant'),
                    style: AppButtonStyle.ghost,
                    size: AppButtonSize.sm,
                    onPressed: _quickAddTenant,
                  ),
                  SectionLabel(AppStrings.t('contractForm.sectionTerms')),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.startDate'),
                          initialValue:
                              DateFormat('dd/MM/yyyy').format(_startDate),
                          key: ValueKey('start-$_startDate'),
                          trailing: AppTextFieldTrailingIcon.date,
                          onTap: _pickStartDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.term'),
                          initialValue: AppStrings.t(
                              'contractForm.months', {'count': '$_termMonths'}),
                          key: ValueKey('term-$_termMonths'),
                          trailing: AppTextFieldTrailingIcon.select,
                          onTap: _pickTerm,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('contractForm.endDateCalculated'),
                    initialValue: DateFormat('dd/MM/yyyy').format(_endDate),
                    key: ValueKey('end-$_endDate'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.deposit'),
                          controller: _depositController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppStrings.t('common.required')
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.monthlyRent'),
                          controller: _monthlyRentController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppStrings.t('common.required')
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                        AppStrings.t('contractForm.monthlyRentHint', {
                          'amount': _monthlyRentController.text.isEmpty
                              ? '—'
                              : _monthlyRentController.text
                        }),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t(
                              'contractForm.electricityBillingMethod'),
                          initialValue:
                              utilityBillingMethodLabel(_electricityMethod),
                          key: ValueKey('elecMethod-$_electricityMethod'),
                          trailing: AppTextFieldTrailingIcon.select,
                          onTap: () => _pickUtilityMethod(
                              UtilityBillingMethod.values,
                              _electricityMethod,
                              (m) => setState(() => _electricityMethod = m)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.price'),
                          controller: _electricityPriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppStrings.t('common.required')
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label:
                              AppStrings.t('contractForm.waterBillingMethod'),
                          initialValue: utilityBillingMethodLabel(_waterMethod),
                          key: ValueKey('waterMethod-$_waterMethod'),
                          trailing: AppTextFieldTrailingIcon.select,
                          onTap: () => _pickUtilityMethod(
                              UtilityBillingMethod.values,
                              _waterMethod,
                              (m) => setState(() => _waterMethod = m)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.price'),
                          controller: _waterPriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppStrings.t('common.required')
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label:
                              AppStrings.t('contractForm.serviceBillingMethod'),
                          initialValue:
                              serviceBillingMethodLabel(_serviceMethod),
                          key: ValueKey('serviceMethod-$_serviceMethod'),
                          trailing: AppTextFieldTrailingIcon.select,
                          onTap: _pickServiceMethod,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.price'),
                          controller: _servicePriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppStrings.t('common.required')
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(AppStrings.t('contractForm.utilityPriceHint'),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  AppTextField(
                    label: AppStrings.t('contractForm.paymentDueDay'),
                    controller: _paymentDueDayController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final day = int.tryParse((v ?? '').trim());
                      if (day == null || day < 1 || day > 31) {
                        return AppStrings.t('common.required');
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(AppStrings.t('contractForm.paymentDueDayHint'),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  SectionLabel(
                      AppStrings.t('contractForm.sectionRecurringFees')),
                  ContractRecurringFeesEditor(controller: _feesController),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('contractForm.lateFeeTerms'),
                    controller: _lateFeeTermsController,
                    maxLines: 3,
                    textarea: true,
                  ),
                  SectionLabel(AppStrings.t('contractForm.sectionBroker')),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.brokerNameAgency'),
                          controller: _brokerNameController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.t('contractForm.brokerFee'),
                          controller: _brokerFeeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: AppStrings.t('contractForm.specialNote'),
                    controller: _specialNoteController,
                    maxLines: 3,
                    textarea: true,
                  ),
                  SectionLabel(
                      AppStrings.t('contractForm.sectionMoveInReadings')),
                  for (final roomId in _roomIds) ...[
                    _RoomReadingRow(
                      roomId: roomId,
                      electricityController:
                          _electricityReadingControllers[roomId]!,
                      waterController: _waterReadingControllers[roomId]!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_roomIds.isNotEmpty)
                    AppTextField(
                      label: AppStrings.t('contractForm.readingDate'),
                      initialValue:
                          DateFormat('dd/MM/yyyy').format(_readingDate),
                      key: ValueKey('readingDate-$_readingDate'),
                      trailing: AppTextFieldTrailingIcon.date,
                      onTap: _pickReadingDate,
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
                              label: AppStrings.t('contractForm.saveContract'),
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

class _RoomReadingRow extends ConsumerWidget {
  final String roomId;
  final TextEditingController electricityController;
  final TextEditingController waterController;

  const _RoomReadingRow({
    required this.roomId,
    required this.electricityController,
    required this.waterController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider(roomId)).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
              AppStrings.t(
                  'contractForm.roomLabel', {'room': room?.roomNo ?? '…'}),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.t('contractForm.electricityReading'),
                controller: electricityController,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsInputFormatter()],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextField(
                label: AppStrings.t('contractForm.waterReading'),
                controller: waterController,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsInputFormatter()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
