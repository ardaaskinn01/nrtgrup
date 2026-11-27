import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/stock_item.dart';
import '../../../models/supplier.dart';
import '../providers/stock_providers.dart';
import '../repositories/stock_repository.dart';
import '../widgets/add_stock_modal.dart';

class StockListScreen extends ConsumerWidget {
  const StockListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final stocksAsync = ref.watch(filteredStocksProvider);
    final selectedCategory = ref.watch(stockCategoryFilterProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Stok'),
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
        label: 'Stok Ekle',
        onPressed: () => AddStockModal.show(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFieldBar(
              hintText: 'Stok ara (malzeme, miktar, tedarikçi)...',
              onChanged: (val) => ref.read(stockSearchQueryProvider.notifier).state = val,
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
                        ref.read(stockCategoryFilterProvider.notifier).state = null,
                  ),
                ),
                ...SupplierCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.displayName),
                      selected: selectedCategory == cat,
                      onSelected: (_) {
                        ref.read(stockCategoryFilterProvider.notifier).state =
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
            child: stocksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Stok Kayıtları Yüklenemedi',
                subtitle: '$err',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Kayıtlı Stok Yok',
                    subtitle: 'Sağ alttaki "Stok Ekle" butonundan mal alım kaydı ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _StockCard(
                      item: item,
                      onEdit: () => AddStockModal.show(context, initialStock: item),
                      onDelete: () => _deleteStock(context, ref, item),
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

  Future<void> _deleteStock(BuildContext context, WidgetRef ref, StockItem item) async {
    if (item.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Stok Kaydını Sil',
      message: '"${item.name}" stok kaydını silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(stockRepositoryProvider).deleteStock(item.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok kaydı silindi')),
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

class _StockCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StockCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
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
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(context, item.category);

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
                icon: _categoryIcon(item.category),
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
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
                          label: item.category.displayName,
                          color: catColor,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AdaptiveColors.subText(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.formatDate(item.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AdaptiveColors.subText(context),
                          ),
                        ),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.scale_outlined, size: 13, color: catColor),
                    const SizedBox(width: 5),
                    Text(
                      item.quantityText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.supplierName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 13,
                        color: AdaptiveColors.subText(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.supplierName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
