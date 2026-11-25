import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/mood_burst.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/transaction.dart';
import '../providers/transaction_providers.dart';
import '../repositories/transaction_repository.dart';
import '../widgets/add_transaction_modal.dart';

class GelirGiderScreen extends ConsumerWidget {
  const GelirGiderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final filteredAsync = ref.watch(filteredTransactionsProvider);
    final period = ref.watch(transactionPeriodProvider);
    final selectedDate = ref.watch(transactionSelectedDateProvider);
    final typeFilter = ref.watch(transactionTypeFilterProvider);

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Gelir Gider'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'İşlem Ekle',
        onPressed: () async {
          final result = await AddTransactionModal.show(context);
          if (result != null && result.isNew && context.mounted) {
            MoodBurst.show(
              context,
              amount: result.amount,
              isIncome: result.isIncome,
            );
          }
        },
      ),
      body: Column(
        children: [
          // Üst Filtre Çubuğu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                // Dönem Seçimi
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
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _shiftDate(ref, period, selectedDate, -1),
                      ),
                      InkWell(
                        onTap: () => _pickDate(context, ref, selectedDate),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primaryOrange),
                              const SizedBox(width: 8),
                              Text(
                                _formatPeriodLabel(period, selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _shiftDate(ref, period, selectedDate, 1),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Tür Filtresi
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: typeFilter == null,
                      onSelected: (_) => ref.read(transactionTypeFilterProvider.notifier).state = null,
                    ),
                    ChoiceChip(
                      label: const Text('Gelir'),
                      selected: typeFilter == TransactionType.income,
                      onSelected: (_) => ref.read(transactionTypeFilterProvider.notifier).state =
                          typeFilter == TransactionType.income ? null : TransactionType.income,
                    ),
                    ChoiceChip(
                      label: const Text('Gider'),
                      selected: typeFilter == TransactionType.expense,
                      onSelected: (_) => ref.read(transactionTypeFilterProvider.notifier).state =
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  children: [
                    // Dönem Özeti
                    _PeriodSummaryRow(
                      income: income,
                      expense: expense,
                      net: net,
                    ),
                    const SizedBox(height: 16),

                    if (transactions.isEmpty)
                      const Card(
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

class _PeriodSummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _PeriodSummaryRow({
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniSummaryCard(
            label: 'Gelir',
            value: AppFormatters.formatCurrency(income),
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniSummaryCard(
            label: 'Gider',
            value: AppFormatters.formatCurrency(expense),
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniSummaryCard(
            label: 'Net',
            value: AppFormatters.formatCurrency(net),
            color: net >= 0 ? AppTheme.primaryOrange : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
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
    final color = isIncome ? AppTheme.successColor : AppTheme.errorColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          transaction.description.isNotEmpty ? transaction.description : transaction.category,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${AppFormatters.formatDate(transaction.date)} • ${transaction.category} • ${transaction.paymentMethod.displayName}',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            PopupMenuButton<String>(
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
      ),
    );
  }
}
