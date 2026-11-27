import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../models/cheque.dart';
import '../../../models/debt.dart';
import '../../../models/transaction.dart';
import '../../transactions/repositories/cheque_repository.dart';
import '../repositories/debt_repository.dart';

class AddDebtEntryModal extends ConsumerStatefulWidget {
  final DebtPerson person;
  final DebtEntryType initialType;

  const AddDebtEntryModal({
    super.key,
    required this.person,
    this.initialType = DebtEntryType.borcEkle,
  });

  static Future<({bool triggerBurst, bool isIncome, double amount})?> show(
    BuildContext context, {
    required DebtPerson person,
    DebtEntryType initialType = DebtEntryType.borcEkle,
  }) {
    return showModalBottomSheet<({bool triggerBurst, bool isIncome, double amount})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddDebtEntryModal(
        person: person,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<AddDebtEntryModal> createState() => _AddDebtEntryModalState();
}

class _AddDebtEntryModalState extends ConsumerState<AddDebtEntryModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  late DebtEntryType _entryType;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  Cheque? _selectedCheque;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entryType = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = AppFormatters.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final res = await ref.read(debtRepositoryProvider).addEntry(
            personId: widget.person.id!,
            personName: widget.person.name,
            type: _entryType,
            amount: amount,
            date: _selectedDate,
            description: _descController.text.trim(),
            addToLedger: true,
            paymentMethod: _entryType == DebtEntryType.odeme
                ? _paymentMethod
                : PaymentMethod.cash,
            selectedChequeId: _selectedCheque?.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _entryType == DebtEntryType.borcEkle
                  ? 'Borç eklendi'
                  : 'Borç ödemesi kaydedildi',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(
          context,
          (triggerBurst: res.addedToLedger, isIncome: res.isIncome, amount: res.amount),
        );
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

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '${widget.person.name} • Borç İşlemi',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              SegmentedButton<DebtEntryType>(
                segments: const [
                  ButtonSegment(
                    value: DebtEntryType.borcEkle,
                    label: Text('Borç Ekle'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: DebtEntryType.odeme,
                    label: Text('Borçtan Düş (Öde)'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_entryType},
                onSelectionChanged: (sel) => setState(() {
                  _entryType = sel.first;
                  _paymentMethod = PaymentMethod.cash;
                  _selectedCheque = null;
                }),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 14),

              if (_entryType == DebtEntryType.odeme) ...[
                DropdownButtonFormField<PaymentMethod>(
                  value: _paymentMethod,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme Şekli',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: PaymentMethod.values.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(
                        m.displayName,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMethod = val;
                        _selectedCheque = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                if (_paymentMethod == PaymentMethod.checkNote)
                  Consumer(
                    builder: (context, ref, _) {
                      final chequesAsync = ref.watch(inHandChequesProvider);
                      final cheques = chequesAsync.value ?? [];

                      if (cheques.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Kasada verilebilecek aktif çek bulunmuyor.',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<Cheque>(
                          value: _selectedCheque,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          decoration: const InputDecoration(
                            labelText: 'Kasadan Verilecek Çeki Seçin',
                            prefixIcon: Icon(Icons.receipt_long_outlined),
                          ),
                          items: cheques.map((c) {
                            final src = c.sourceName.isNotEmpty ? ' • ${c.sourceName}' : '';
                            return DropdownMenuItem<Cheque>(
                              value: c,
                              child: Text(
                                '${AppFormatters.formatCurrency(c.amount)}$src',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          validator: (val) {
                            if (_paymentMethod == PaymentMethod.checkNote && val == null) {
                              return 'Lütfen kasadan bir çek seçin';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setState(() {
                              _selectedCheque = val;
                              if (val != null) {
                                _amountController.text =
                                    val.amount.toStringAsFixed(2).replaceAll('.', ',');
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
              ],

              AmountField(controller: _amountController),
              const SizedBox(height: 14),

              DatePickerField(
                selectedDate: _selectedDate,
                onDateSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Örn: Malzeme borcu, kısmi ödeme...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
