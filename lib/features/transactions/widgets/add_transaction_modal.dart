import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../core/widgets/modal_header.dart';
import '../../../models/cheque.dart';
import '../../../models/transaction.dart';
import '../repositories/cheque_repository.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  final AppTransaction? initialTransaction;
  final TransactionType? initialType;
  final bool isPersonalEntry;

  const AddTransactionModal({
    super.key,
    this.initialTransaction,
    this.initialType,
    this.isPersonalEntry = false,
  });

  static Future<({bool isNew, bool isIncome, double amount})?> show(
    BuildContext context, {
    AppTransaction? initialTransaction,
    TransactionType? initialType,
    bool isPersonalEntry = false,
  }) {
    return showModalBottomSheet<({bool isNew, bool isIncome, double amount})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionModal(
        initialTransaction: initialTransaction,
        initialType: initialType,
        isPersonalEntry: isPersonalEntry,
      ),
    );
  }

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  late TransactionType _selectedType;
  late PaymentMethod _selectedPaymentMethod;
  late DateTime _selectedDate;
  Cheque? _selectedCheque;
  bool _isLoading = false;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;
    if (initial != null) {
      _selectedType = initial.type;
      _selectedPaymentMethod = initial.paymentMethod;
      _selectedDate = initial.date;
      _amountController.text = initial.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descController.text = initial.description;
    } else {
      _selectedType = widget.initialType ?? TransactionType.income;
      _selectedPaymentMethod = PaymentMethod.cash;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
      _selectedCheque = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = AppFormatters.parseAmount(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final desc = _descController.text.trim();
      final defaultLabel = _selectedType == TransactionType.income ? 'Genel Gelir' : 'Genel Gider';

      if (_isEditing) {
        final updated = widget.initialTransaction!.copyWith(
          amount: parsedAmount,
          type: _selectedType,
          category: widget.initialTransaction!.category.isNotEmpty
              ? widget.initialTransaction!.category
              : defaultLabel,
          paymentMethod: _selectedPaymentMethod,
          description: desc.isEmpty ? defaultLabel : desc,
          date: _selectedDate,
        );
        await repo.updateTransaction(widget.initialTransaction!.id!, updated);
      } else {
        final finalCategory = widget.isPersonalEntry ? 'Personel Girişi' : defaultLabel;
        final finalDesc = widget.isPersonalEntry
            ? (desc.isEmpty ? '[Personel] $defaultLabel' : '[Personel] $desc')
            : (desc.isEmpty ? defaultLabel : desc);

        final newTx = AppTransaction(
          amount: parsedAmount,
          type: _selectedType,
          category: finalCategory,
          paymentMethod: _selectedPaymentMethod,
          description: finalDesc,
          date: _selectedDate,
          createdAt: DateTime.now(),
          sourceType: widget.isPersonalEntry ? 'personal_entry' : null,
        );
        await repo.addTransaction(newTx);

        if (_selectedPaymentMethod == PaymentMethod.checkNote) {
          final chequeRepo = ref.read(chequeRepositoryProvider);
          if (_selectedType == TransactionType.income) {
            await chequeRepo.addCheque(
              Cheque(
                amount: parsedAmount,
                sourceName: finalDesc,
                note: 'Gelir işlemi ile eklendi',
                status: ChequeStatus.inHand,
                date: _selectedDate,
                createdAt: DateTime.now(),
              ),
            );
          } else if (_selectedCheque?.id != null) {
            await chequeRepo.markChequeGiven(_selectedCheque!.id!, finalDesc);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'İşlem güncellendi'
                  : '${_selectedType.displayName} kaydedildi',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(
          context,
          (
            isNew: !_isEditing,
            isIncome: _selectedType == TransactionType.income,
            amount: parsedAmount,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
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
                ModalHeader(
                  title: _isEditing ? 'İşlemi Düzenle' : 'Yeni İşlem Ekle',
                ),
                const SizedBox(height: 10),

              // Gelir / Gider Seçimi
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Gelir'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Gider'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (sel) => _onTypeChanged(sel.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    if (states.contains(WidgetState.selected)) {
                      return _selectedType == TransactionType.income
                          ? (isDark ? const Color(0xFF1B3D2F) : const Color(0xFFDCFCE7))
                          : (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2));
                    }
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    if (states.contains(WidgetState.selected)) {
                      return _selectedType == TransactionType.income
                          ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                          : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C));
                    }
                    return null;
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    if (states.contains(WidgetState.selected)) {
                      return BorderSide(
                        color: _selectedType == TransactionType.income
                            ? (isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A))
                            : (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)),
                        width: 1.5,
                      );
                    }
                    return null;
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Tutar
              AmountField(controller: _amountController),
              const SizedBox(height: 14),

              // Ödeme Yöntemi (Nakit / Çek) - Sadece Yönetici Yeni İşlemde
              if (!widget.isPersonalEntry && !_isEditing) ...[
                SegmentedButton<PaymentMethod>(
                  segments: const [
                    ButtonSegment(
                      value: PaymentMethod.cash,
                      label: Text('Nakit'),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment(
                      value: PaymentMethod.checkNote,
                      label: Text('Çek'),
                      icon: Icon(Icons.receipt_long_outlined),
                    ),
                  ],
                  selected: {_selectedPaymentMethod},
                  onSelectionChanged: (sel) {
                    setState(() {
                      _selectedPaymentMethod = sel.first;
                      _selectedCheque = null;
                    });
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 14),
                if (_selectedPaymentMethod == PaymentMethod.checkNote &&
                    _selectedType == TransactionType.expense) ...[
                  Consumer(
                    builder: (context, ref, _) {
                      final chequesAsync = ref.watch(inHandChequesProvider);
                      final inHand = chequesAsync.value ?? [];
                      if (inHand.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Kasada verilecek çek bulunmuyor. Gider nakit veya manuel işlenecek.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.errorColor.withValues(alpha: 0.9),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<Cheque>(
                          value: _selectedCheque,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          decoration: const InputDecoration(
                            labelText: 'Verilecek Çeki Seçin (Opsiyonel)',
                            prefixIcon: Icon(Icons.receipt_long_outlined),
                          ),
                          items: inHand.map((c) {
                            final label =
                                '${AppFormatters.formatCurrency(c.amount)} (${c.sourceName.isNotEmpty ? c.sourceName : 'Kasa'})';
                            return DropdownMenuItem(
                              value: c,
                              child: Text(label, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (c) {
                            setState(() {
                              _selectedCheque = c;
                              if (c != null) {
                                _amountController.text =
                                    c.amount.toStringAsFixed(2).replaceAll('.', ',');
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],

              // Tarih
              DatePickerField(
                selectedDate: _selectedDate,
                onDateSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 14),

              // Açıklama
              TextFormField(
                controller: _descController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Örn: Müşteri ödemesi, malzeme alımı...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 22),

              // Butonlar (Vazgeç & Kaydet)
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
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Güncelle' : 'Kaydet'),
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
