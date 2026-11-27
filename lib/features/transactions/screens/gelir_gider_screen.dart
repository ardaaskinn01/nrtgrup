import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/transaction.dart';
import '../providers/transaction_providers.dart';
import '../repositories/transaction_repository.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/cash_offset_modal.dart';

class GelirGiderScreen extends ConsumerWidget {
  const GelirGiderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final filteredAsync = ref.watch(filteredTransactionsProvider);
    final period = ref.watch(transactionPeriodProvider);
    final selectedDate = ref.watch(transactionSelectedDateProvider);
    final typeFilter = ref.watch(transactionTypeFilterProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Gelir Gider'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.balance_rounded),
            tooltip: 'Kasa Eşitle (Offset)',
            onPressed: () => CashOffsetModal.show(context),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Üst Filtre Çubuğu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: AdaptiveColors.cardBorder(context)),
              ),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<TransactionFilterPeriod>(
                    segments: const [
                      ButtonSegment(value: TransactionFilterPeriod.all, label: Text('Tümü')),
                      ButtonSegment(value: TransactionFilterPeriod.daily, label: Text('Günlük')),
                      ButtonSegment(value: TransactionFilterPeriod.monthly, label: Text('Aylık')),
                      ButtonSegment(value: TransactionFilterPeriod.yearly, label: Text('Yıllık')),
                    ],
                    selected: {period},
                    onSelectionChanged: (sel) {
                      ref.read(transactionPeriodProvider.notifier).state = sel.first;
                    },
                    showSelectedIcon: false,
                  ),
                ),

                if (period != TransactionFilterPeriod.all) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => _shiftDate(ref, period, selectedDate, -1),
                      ),
                      InkWell(
                        onTap: () => _pickDate(context, ref, selectedDate),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AdaptiveColors.cardBg(context),
                            border: Border.all(color: AdaptiveColors.cardBorder(context)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.primaryOrange),
                              const SizedBox(width: 8),
                              Text(
                                _formatPeriodLabel(period, selectedDate),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => _shiftDate(ref, period, selectedDate, 1),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Tür Filtresi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FilterTabPill(
                      label: 'Tümü',
                      isSelected: typeFilter == null,
                      color: AdaptiveColors.orange(context),
                      onTap: () => ref.read(transactionTypeFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    _FilterTabPill(
                      label: 'Gelir',
                      isSelected: typeFilter == TransactionType.income,
                      color: AdaptiveColors.success(context),
                      onTap: () => ref.read(transactionTypeFilterProvider.notifier).state =
                          typeFilter == TransactionType.income ? null : TransactionType.income,
                    ),
                    const SizedBox(width: 8),
                    _FilterTabPill(
                      label: 'Gider',
                      isSelected: typeFilter == TransactionType.expense,
                      color: AdaptiveColors.error(context),
                      onTap: () => ref.read(transactionTypeFilterProvider.notifier).state =
                          typeFilter == TransactionType.expense ? null : TransactionType.expense,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Özet & Liste
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Veriler Yüklenemedi',
                subtitle: '$err',
              ),
              data: (transactions) {
                double income = 0;
                double expense = 0;
                for (final tx in transactions) {
                  if (tx.isIncome) {
                    income += tx.amount;
                  } else {
                    expense += tx.amount;
                  }
                }
                final net = income - expense;

                return ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 96),
                  children: [
                    // Dönem Özet Hero Kartı
                    HeroGradientCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'DÖNEM NET BAKİYESİ',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${transactions.length} işlem',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppFormatters.formatCurrency(net),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: net >= 0 ? AppTheme.pureWhite : const Color(0xFFF87171),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Toplam Gelir',
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '+${AppFormatters.formatCurrency(income)}',
                                          style: const TextStyle(
                                            color: Color(0xFF4ADE80),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Toplam Gider',
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '-${AppFormatters.formatCurrency(expense)}',
                                          style: const TextStyle(
                                            color: Color(0xFFF87171),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (transactions.isEmpty)
                      const SurfaceCard(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Bu Dönemde İşlem Yok',
                          subtitle: 'Sağ alttaki "İşlem Ekle" butonundan yeni gelir veya gider ekleyebilirsiniz.',
                        ),
                      )
                    else
                      ...transactions.map(
                        (tx) => _TransactionCard(
                          transaction: tx,
                          onEdit: () => AddTransactionModal.show(
                            context,
                            initialTransaction: tx,
                          ),
                          onDelete: () => _deleteTransaction(context, ref, tx),
                        ),
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

  String _formatPeriodLabel(TransactionFilterPeriod period, DateTime date) {
    switch (period) {
      case TransactionFilterPeriod.daily:
        return AppFormatters.formatLongDate(date);
      case TransactionFilterPeriod.monthly:
        return AppFormatters.formatMonthYear(date);
      case TransactionFilterPeriod.yearly:
        return '${date.year}';
      case TransactionFilterPeriod.all:
        return 'Tüm Zamanlar';
    }
  }

  void _shiftDate(WidgetRef ref, TransactionFilterPeriod period, DateTime current, int delta) {
    DateTime next;
    switch (period) {
      case TransactionFilterPeriod.daily:
        next = current.add(Duration(days: delta));
        break;
      case TransactionFilterPeriod.monthly:
        next = DateTime(current.year, current.month + delta, current.day);
        break;
      case TransactionFilterPeriod.yearly:
        next = DateTime(current.year + delta, current.month, current.day);
        break;
      case TransactionFilterPeriod.all:
        next = current;
        break;
    }
    ref.read(transactionSelectedDateProvider.notifier).state = next;
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      ref.read(transactionSelectedDateProvider.notifier).state = picked;
    }
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref, AppTransaction tx) async {
    if (tx.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'İşlemi Sil',
      message:
          '"${tx.description}" (${AppFormatters.formatCurrency(tx.amount)}) kaydını silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class _FilterTabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterTabPill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? color.withValues(alpha: isDark ? 0.22 : 0.14)
          : AdaptiveColors.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : AdaptiveColors.cardBorder(context),
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? color
                  : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final AppTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome
        ? AdaptiveColors.success(context)
        : AdaptiveColors.error(context);
    final theme = Theme.of(context);

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      leftAccentColor: color,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                color: color,
                size: 42,
                icon: isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isNotEmpty
                          ? transaction.description
                          : transaction.category,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(
                          label: transaction.category,
                          color: color,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 12,
                              color: AdaptiveColors.subText(context),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              transaction.paymentMethod.displayName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AdaptiveColors.subText(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.3,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatDate(transaction.date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AdaptiveColors.subText(context),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AdaptiveColors.subText(context),
                ),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
