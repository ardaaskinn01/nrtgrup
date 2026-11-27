import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/modal_header.dart';
import '../../../models/transaction.dart';
import '../providers/transaction_providers.dart';
import '../repositories/cheque_repository.dart';
import '../repositories/transaction_repository.dart';

/// Kasadaki gerçek Nakit ve Çek (adet + tekil tutarlar) bilgisini girerek
/// sistem bakiyesini ve çek portföyünü gerçek duruma eşitleyen (offset) modal.
class CashOffsetModal extends ConsumerStatefulWidget {
  const CashOffsetModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CashOffsetModal(),
    );
  }

  @override
  ConsumerState<CashOffsetModal> createState() => _CashOffsetModalState();
}

class _CashOffsetModalState extends ConsumerState<CashOffsetModal> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _noteController = TextEditingController();
  final List<TextEditingController> _chequeControllers = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _cashController.dispose();
    _noteController.dispose();
    for (final c in _chequeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setChequeCount(int count) {
    setState(() {
      while (_chequeControllers.length < count) {
        _chequeControllers.add(TextEditingController());
      }
      while (_chequeControllers.length > count) {
        _chequeControllers.removeLast().dispose();
      }
    });
  }

  Future<void> _submit(double currentBalance) async {
    if (!_formKey.currentState!.validate()) return;

    final targetCash = AppFormatters.parseAmount(_cashController.text) ?? 0.0;
    final chequeAmounts = <double>[];
    double targetChequesTotal = 0.0;

    for (final ctrl in _chequeControllers) {
      final val = AppFormatters.parseAmount(ctrl.text) ?? 0.0;
      if (val > 0) {
        chequeAmounts.add(val);
        targetChequesTotal += val;
      }
    }

    final targetTotal = targetCash + targetChequesTotal;
    final diff = targetTotal - currentBalance;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // 1. Önce kasadaki çek portföyünü girilen gerçek çek listesi ile değiştir
      await ref.read(chequeRepositoryProvider).replaceInHandCheques(chequeAmounts, now);

      // 2. Toplam bakiyede fark varsa Gelir/Gider defterine offset kaydı at
      if (diff.abs() >= 0.01) {
        final isIncome = diff > 0;
        final note = _noteController.text.trim();
        final desc = note.isNotEmpty
            ? 'Kasa Eşitleme: $note (Nakit: ${AppFormatters.formatCurrency(targetCash)}, ${chequeAmounts.length} Çek: ${AppFormatters.formatCurrency(targetChequesTotal)})'
            : 'Kasa Eşitleme (Nakit: ${AppFormatters.formatCurrency(targetCash)}, ${chequeAmounts.length} Çek: ${AppFormatters.formatCurrency(targetChequesTotal)})';

        final tx = AppTransaction(
          amount: diff.abs(),
          type: isIncome ? TransactionType.income : TransactionType.expense,
          category: 'Kasa Eşitleme',
          paymentMethod: PaymentMethod.cash,
          description: desc,
          date: now,
          createdAt: now,
          sourceType: 'offset',
        );

        await ref.read(transactionRepositoryProvider).addTransaction(tx);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kasa eşitlendi: ${AppFormatters.formatCurrency(targetTotal)} '
              '(Nakit + ${chequeAmounts.length} Çek)',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom + 20
        : MediaQuery.of(context).viewPadding.bottom + 24;
    final balanceAsync = ref.watch(overallBalanceProvider);
    final summary = balanceAsync.value;
    final currentBalance = summary?.netBalance ?? 0.0;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomPadding,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ModalHeader(
                  title: 'Kasa Eşitleme (Nakit & Çek)',
                ),
                const SizedBox(height: 6),
                Text(
                'Elinizdeki gerçek nakit tutarını ve kasadaki çeklerin adet/tutarlarını girin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mevcut Sistem Bakiyesi:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      AppFormatters.formatCurrency(currentBalance),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kasadaki Nakit
              AmountField(
                controller: _cashController,
                label: 'Kasadaki Gerçek Nakit (TL)',
                allowZero: true,
              ),
              const SizedBox(height: 14),

              // Kasadaki Çek Adedi Seçici
              DropdownButtonFormField<int>(
                value: _chequeControllers.length,
                dropdownColor: theme.colorScheme.surface,
                decoration: const InputDecoration(
                  labelText: 'Kasadaki Çek Sayısı',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                items: List.generate(11, (i) => i).map((count) {
                  return DropdownMenuItem<int>(
                    value: count,
                    child: Text(
                      count == 0 ? 'Çek Yok (0 adet)' : '$count Adet Çek',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _setChequeCount(val);
                },
              ),

              if (_chequeControllers.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_chequeControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AmountField(
                      controller: _chequeControllers[index],
                      label: '${index + 1}. Çek Tutarı (TL)',
                    ),
                  );
                }),
              ],

              const SizedBox(height: 6),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Örn: Başlangıç kasası, sayım farkı...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _submit(currentBalance),
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.balance_rounded),
                      label: const Text('Kasayı Eşitle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
