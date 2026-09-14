import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/contract.dart';
import '../shared/app_button.dart';
import '../shared/avatar.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// T-03 — Tenant Detail (View) (node 220:3381, Figma).
class TenantDetailScreen extends ConsumerWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _zalo(String phone) async {
    await launchUrl(Uri.parse('https://zalo.me/$phone'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.t('tenantDetail.deleteConfirmTitle'),
      description: AppStrings.t('tenantDetail.deleteConfirmDescription'),
      confirmLabel: AppStrings.t('common.delete'),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(tenantRepositoryProvider).delete(tenantId);
      ref.invalidate(tenantsProvider);
      ref.invalidate(tenantListProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('tenantDetail.deleteError'))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final tenantAsync = ref.watch(tenantProvider(tenantId));
    final contractsAsync = ref.watch(contractsByTenantProvider(tenantId));

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          Builder(builder: (context) {
            final tenant = tenantAsync.valueOrNull;
            final activeContract = contractsAsync.valueOrNull
                ?.where((c) => c.status == ContractStatus.active)
                .firstOrNull;
            final activeRooms = activeContract == null
                ? null
                : ref
                    .watch(contractRoomsProvider(activeContract.id))
                    .valueOrNull;
            return TopBar(
              title: tenant?.fullName ?? '',
              subtitle: activeContract == null
                  ? AppStrings.t('tenantDetail.notRentingMeta')
                  : AppStrings.t('tenantDetail.rentingMeta', {
                      'room': activeRooms == null || activeRooms.isEmpty
                          ? '…'
                          : activeRooms.map((r) => r.roomNo).join(', '),
                    }),
              onBack: () => context.pop(),
              trailing: tenant == null
                  ? null
                  : TopBarActionMenuButton(
                      onEdit: () => context.push('/tenant/$tenantId/edit'),
                      onDelete: () => _delete(context, ref),
                    ),
            );
          }),
          Expanded(
            child: tenantAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(
                      AppStrings.t('tenantDetail.loadError', {'error': '$e'}))),
              data: (tenant) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    Row(
                      children: [
                        Avatar(initials: tenant.initials),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tenant.fullName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              Text(tenant.phone,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: AppStrings.t('tenantDetail.call'),
                            style: AppButtonStyle.ghost,
                            onPressed: () => _call(tenant.phone),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: AppStrings.t('tenantDetail.zalo'),
                            style: AppButtonStyle.ghost,
                            onPressed: () => _zalo(tenant.phone),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DetailBlock(children: [
                      DetailRow(
                          label: AppStrings.t('tenantDetail.sex'),
                          value: tenant.sex == null
                              ? '—'
                              : tenantSexLabel(tenant.sex!)),
                      DetailRow(
                          label: AppStrings.t('tenantDetail.dateOfBirth'),
                          value: tenant.dateOfBirth == null
                              ? '—'
                              : DateFormat('dd/MM/yyyy')
                                  .format(tenant.dateOfBirth!)),
                      DetailRow(
                          label: AppStrings.t('tenantDetail.email'),
                          value: tenant.mail ?? '—'),
                      DetailRow(
                          label: AppStrings.t('tenantDetail.idNumber'),
                          value: tenant.idNumber ?? '—'),
                      DetailRow(
                          label: AppStrings.t('tenantDetail.note'),
                          value: tenant.note ?? '—',
                          showDivider: false),
                    ]),
                    const SizedBox(height: 6),
                    SectionLabel(AppStrings.t('tenantDetail.sectionIdPhotos')),
                    Row(
                      children: [
                        Expanded(
                            child: _IdPhotoTile(
                                path: tenant.idPhotoFront,
                                label: AppStrings.t('common.front'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _IdPhotoTile(
                                path: tenant.idPhotoBack,
                                label: AppStrings.t('common.back'))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SectionLabel(AppStrings.t('tenantDetail.sectionContracts')),
                    contractsAsync.when(
                      loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator())),
                      error: (e, st) => Text('$e'),
                      data: (contracts) {
                        if (contracts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              AppStrings.t('tenantDetail.noContractsYet'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final contract in contracts) ...[
                              _ContractRow(contract: contract),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IdPhotoTile extends StatelessWidget {
  final String? path;
  final String label;

  const _IdPhotoTile({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
          border: Border.all(color: AppColors.neutral200),
        ),
        alignment: Alignment.center,
        child: path == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.badge_rounded,
                      color: AppColors.textTertiary, size: 22),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
              )
            : FutureBuilder<String>(
                future:
                    ref.read(tenantRepositoryProvider).signedPhotoUrl(path!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator(strokeWidth: 2);
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.thumbIcon),
                    child: Image.network(snapshot.data!,
                        fit: BoxFit.cover, width: double.infinity, height: 90),
                  );
                },
              ),
      );
    });
  }
}

class _ContractRow extends ConsumerWidget {
  final Contract contract;

  const _ContractRow({required this.contract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = contract.currentVersionId == null
        ? null
        : ref
            .watch(contractVersionProvider(contract.currentVersionId!))
            .valueOrNull;
    final rooms = ref.watch(contractRoomsProvider(contract.id)).valueOrNull;
    final houses = ref.watch(housesProvider).valueOrNull ?? const [];
    final house = (rooms == null || rooms.isEmpty)
        ? null
        : houses.where((h) => h.id == rooms.first.houseId).firstOrNull;

    return ListCard(
      icon: Symbols.description_rounded,
      thumbColor: contract.status == ContractStatus.ended
          ? AppColors.secondary
          : AppColors.primary,
      title: house?.name ?? '…',
      trailing: StatusPill(
        text: contractStatusLabel(contract.status),
        style: contract.status == ContractStatus.ended
            ? StatusBadgeStyle.ended
            : StatusBadgeStyle.active,
      ),
      body: version == null
          ? '…'
          : '${DateFormat('dd/MM/yyyy').format(version.startDate)} → ${DateFormat('dd/MM/yyyy').format(version.endDate)}',
      meta: contract.status == ContractStatus.ended
          ? (contract.refundAmount != null
              ? formatNumber(contract.refundAmount!)
              : null)
          : (version == null ? null : formatNumber(version.monthlyRent)),
      onTap: () => context.push('/tenant/contracts/${contract.id}'),
    );
  }
}
