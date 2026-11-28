import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/debt.dart';
import '../../../models/supplier.dart';
import '../../debts/providers/debt_providers.dart';
import '../../debts/widgets/add_debt_person_modal.dart';
import '../providers/supplier_providers.dart';
import '../repositories/supplier_repository.dart';
import '../widgets/add_supplier_modal.dart';

class SuppliersListScreen extends ConsumerWidget {
  const SuppliersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final suppliersAsync = ref.watch(filteredSuppliersProvider);
    final selectedCategory = ref.watch(supplierCategoryFilterProvider);
    final allDebts = ref.watch(debtsStreamProvider).value ?? [];
    final totalSupplierDebt = allDebts
        .where((d) => d.isSupplier)
        .fold<double>(0.0, (sum, d) => sum + d.balance);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Tedarikçiler'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'Tedarikçi Ekle',
        onPressed: () => AddSupplierModal.show(context),
      ),
      body: Column(
        children: [
          // Toplam Tedarikçi Borcu Özeti
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: HeroGradientCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOPLAM TEDARİKÇİ BORCU',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Borçlar defteriyle senkronize',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  Text(
                    AppFormatters.formatCurrency(totalSupplierDebt),
                    style: TextStyle(
                      color: totalSupplierDebt > 0
                          ? const Color(0xFFF87171)
                          : const Color(0xFF4ADE80),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchFieldBar(
              hintText: 'Tedarikçi ara (firma adı, tür, telefon)...',
              onChanged: (val) => ref.read(supplierSearchQueryProvider.notifier).state = val,
            ),
          ),
          // Kategori Filtre Çipleri
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tümü'),
                    selected: selectedCategory == null,
                    onSelected: (_) =>
                        ref.read(supplierCategoryFilterProvider.notifier).state = null,
                  ),
                ),
                ...SupplierCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.displayName),
                      selected: selectedCategory == cat,
                      onSelected: (_) {
                        ref.read(supplierCategoryFilterProvider.notifier).state =
                            selectedCategory == cat ? null : cat;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Tedarikçiler Yüklenemedi',
                subtitle: '$err',
              ),
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Kayıtlı Tedarikçi Yok',
                    subtitle: 'Sağ alttaki "Tedarikçi Ekle" butonundan mal alınan firmaları ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 96),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    final linkedDebts = allDebts
                        .where((d) => d.supplierId == supplier.id)
                        .toList();
                    final supplierDebt = linkedDebts.fold<double>(
                      0.0,
                      (sum, d) => sum + d.balance,
                    );
                    final primaryDebt = linkedDebts.isNotEmpty ? linkedDebts.first : null;
                    return _SupplierCard(
                      supplier: supplier,
                      debtAmount: supplierDebt,
                      linkedDebt: primaryDebt,
                      onEdit: () => AddSupplierModal.show(context, initialSupplier: supplier),
                      onDelete: () => _deleteSupplier(context, ref, supplier),
                      onDebtTap: () {
                        if (primaryDebt?.id != null) {
                          context.push('${AppConstants.borclarRoute}/${primaryDebt!.id}');
                        } else {
                          AddDebtPersonModal.show(context, initialSupplier: supplier);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(
      BuildContext context, WidgetRef ref, Supplier supplier) async {
    if (supplier.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Tedarikçiyi Sil',
      message: '"${supplier.name}" tedarikçisini silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tedarikçi silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final double debtAmount;
  final DebtPerson? linkedDebt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDebtTap;

  const _SupplierCard({
    required this.supplier,
    required this.debtAmount,
    required this.linkedDebt,
    required this.onEdit,
    required this.onDelete,
    required this.onDebtTap,
  });

  Color _categoryColor(BuildContext context, SupplierCategory cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (cat) {
      case SupplierCategory.pvc:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case SupplierCategory.cam:
        return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
      case SupplierCategory.aksesuar:
        return AdaptiveColors.orange(context);
      case SupplierCategory.diger:
        return AdaptiveColors.subText(context);
    }
  }

  IconData _categoryIcon(SupplierCategory cat) {
    switch (cat) {
      case SupplierCategory.pvc:
        return Icons.window_outlined;
      case SupplierCategory.cam:
        return Icons.crop_portrait_rounded;
      case SupplierCategory.aksesuar:
        return Icons.hardware_outlined;
      case SupplierCategory.diger:
        return Icons.storefront_outlined;
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(context, supplier.category);

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      leftAccentColor: catColor,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                color: catColor,
                icon: _categoryIcon(supplier.category),
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusPill(
                          label: supplier.category.displayName,
                          color: catColor,
                        ),
                        if (supplier.phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              onTap: () => _callPhone(supplier.phone),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 13,
                                    color: AdaptiveColors.subText(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      supplier.phone,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AdaptiveColors.subText(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AdaptiveColors.subText(context)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
            ],
          ),
          if (supplier.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                supplier.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 10),
          InkWell(
            onTap: onDebtTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (debtAmount > 0
                        ? AdaptiveColors.error(context)
                        : AdaptiveColors.success(context))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (debtAmount > 0
                          ? AdaptiveColors.error(context)
                          : AdaptiveColors.success(context))
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    size: 15,
                    color: debtAmount > 0
                        ? AdaptiveColors.error(context)
                        : AdaptiveColors.success(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      linkedDebt != null
                          ? 'Güncel Borç: ${AppFormatters.formatCurrency(debtAmount)}'
                          : 'Borç kaydı yok (Eklemek için dokunun)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: debtAmount > 0
                            ? AdaptiveColors.error(context)
                            : AdaptiveColors.success(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AdaptiveColors.subText(context),
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
