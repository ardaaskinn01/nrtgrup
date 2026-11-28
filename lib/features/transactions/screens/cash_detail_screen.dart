import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/cheque.dart';
import '../../debts/providers/debt_providers.dart';
import '../../receivables/providers/receivable_providers.dart';
import '../providers/transaction_providers.dart';
import '../repositories/cheque_repository.dart';
import '../widgets/add_cheque_modal.dart';
import '../widgets/cash_offset_modal.dart';

class CashDetailScreen extends ConsumerWidget {
  const CashDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(overallBalanceProvider);
    final chequesAsync = ref.watch(chequesStreamProvider);
    final totalReceivablesAsync = ref.watch(totalReceivablesProvider);
    final totalDebtsAsync = ref.watch(totalDebtsProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa & Mali Durum'),
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsStreamProvider);
          ref.invalidate(chequesStreamProvider);
          ref.invalidate(receivablesStreamProvider);
          ref.invalidate(debtsStreamProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 32),
          children: [
            // Ana Kasa Hero Kartı
            balanceAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => SurfaceCard(child: Text('Kasa bilgisi yüklenemedi: $err')),
              data: (summary) {
                final receivables = totalReceivablesAsync.value ?? 0.0;
                final debts = totalDebtsAsync.value ?? 0.0;
                final netWorth = summary.netBalance + receivables - debts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroGradientCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOPLAM KASA VARLIĞI (NAKİT + ÇEK)',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppFormatters.formatCurrency(summary.netBalance),
                              style: TextStyle(
                                color: summary.netBalance >= 0
                                    ? AppTheme.pureWhite
                                    : const Color(0xFFF87171),
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _DarkSubBox(
                                  icon: Icons.payments_outlined,
                                  iconColor: const Color(0xFF4ADE80),
                                  label: 'Kasadaki Nakit',
                                  value: AppFormatters.formatCurrency(summary.cashBalance),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DarkSubBox(
                                  icon: Icons.receipt_long_outlined,
                                  iconColor: AppTheme.primaryOrangeLight,
                                  label: 'Kasadaki Çek (${summary.chequeCount} Adet)',
                                  value: AppFormatters.formatCurrency(summary.chequeBalance),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Genel Mali Pozisyon Kartı (Kasa + Alacak - Borç)
                    SurfaceCard(
                      padding: const EdgeInsets.all(16),
                      leftAccentColor: AdaptiveColors.orange(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Genel Mali Pozisyon',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MaliRow(
                            label: 'Toplam Kasa (Nakit + Çek)',
                            value: AppFormatters.formatCurrency(summary.netBalance),
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(height: 6),
                          _MaliRow(
                            label: '+ Toplam Alacaklar',
                            value: AppFormatters.formatCurrency(receivables),
                            color: AdaptiveColors.success(context),
                          ),
                          const SizedBox(height: 6),
                          _MaliRow(
                            label: '- Toplam Borçlar',
                            value: AppFormatters.formatCurrency(debts),
                            color: AdaptiveColors.error(context),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          _MaliRow(
                            label: 'Net Şirket Öz Varlığı',
                            value: AppFormatters.formatCurrency(netWorth),
                            color: netWorth >= 0
                                ? AdaptiveColors.success(context)
                                : AdaptiveColors.error(context),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dönemsel Gelir / Gider Özeti
                    Row(
                      children: [
                        Expanded(
                          child: SurfaceCard(
                            padding: const EdgeInsets.all(14),
                            leftAccentColor: AdaptiveColors.success(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Gelir',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AdaptiveColors.subText(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(summary.totalIncome),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AdaptiveColors.success(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bu ay: ${AppFormatters.formatCurrency(summary.monthIncome)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AdaptiveColors.subText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SurfaceCard(
                            padding: const EdgeInsets.all(14),
                            leftAccentColor: AdaptiveColors.error(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Gider',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AdaptiveColors.subText(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(summary.totalExpense),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AdaptiveColors.error(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bu ay: ${AppFormatters.formatCurrency(summary.monthExpense)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AdaptiveColors.subText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Çek Portföyü Başlığı
            Text(
              'Çek Portföyü',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            chequesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => SurfaceCard(child: Text('Çekler yüklenemedi: $err')),
              data: (cheques) {
                if (cheques.isEmpty) {
                  return const SurfaceCard(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Kayıtlı Çek Yok',
                      subtitle:
                          'Alacak tahsilatında "Çek" seçtiğinizde veya Kasa Eşitleme ile çek eklediğinizde tüm çekler burada listelenir.',
                    ),
                  );
                }

                final inHand = cheques.where((c) => c.isInHand).toList();
                final given = cheques.where((c) => !c.isInHand).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inHand.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Kasada Bulunan Çekler (${inHand.length} Adet)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AdaptiveColors.orange(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...inHand.map((c) => _ChequeCard(
                            cheque: c,
                            onEdit: () => AddChequeModal.show(context, initialCheque: c),
                            onDelete: () => _deleteCheque(context, ref, c),
                          )),
                      const SizedBox(height: 14),
                    ],
                    if (given.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Borca Verilen / Çıkan Çekler (${given.length} Adet)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AdaptiveColors.subText(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...given.map((c) => _ChequeCard(
                            cheque: c,
                            onEdit: () => AddChequeModal.show(context, initialCheque: c),
                            onDelete: () => _deleteCheque(context, ref, c),
                          )),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCheque(BuildContext context, WidgetRef ref, Cheque cheque) async {
    if (cheque.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Çeki Sil',
      message:
          '${AppFormatters.formatCurrency(cheque.amount)} tutarındaki çeki silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(chequeRepositoryProvider).deleteCheque(cheque.id!);
      if (cheque.imagePath != null && cheque.imagePath!.isNotEmpty) {
        try {
          await ref.read(supabaseStorageServiceProvider).deleteWorkPhoto(cheque.imagePath!);
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çek silindi')),
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

class _DarkSubBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DarkSubBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaliRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _MaliRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? theme.colorScheme.onSurface : AdaptiveColors.subText(context),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _ChequeCard extends StatelessWidget {
  final Cheque cheque;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChequeCard({
    required this.cheque,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInHand = cheque.isInHand;
    final color = isInHand ? AdaptiveColors.orange(context) : AdaptiveColors.subText(context);

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      leftAccentColor: color,
      onTap: onEdit,
      child: Row(
        children: [
          if (cheque.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                cheque.imageUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => IconSquircle(
                  color: color,
                  icon: Icons.receipt_long_outlined,
                  size: 42,
                ),
              ),
            )
          else
            IconSquircle(
              color: color,
              icon: Icons.receipt_long_outlined,
              size: 42,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.formatCurrency(cheque.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    decoration: isInHand ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isInHand
                      ? 'Kimden: ${cheque.sourceName.isNotEmpty ? cheque.sourceName : 'Kasa'} • ${AppFormatters.formatDate(cheque.date)}'
                      : 'Verilen: ${cheque.givenToName ?? '-'} (Alınan: ${cheque.sourceName})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AdaptiveColors.subText(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cheque.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cheque.note,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AdaptiveColors.subText(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          StatusPill(
            label: cheque.status.displayName,
            color: isInHand ? AdaptiveColors.success(context) : AdaptiveColors.subText(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Düzenle',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AdaptiveColors.error(context)),
            tooltip: 'Sil',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
