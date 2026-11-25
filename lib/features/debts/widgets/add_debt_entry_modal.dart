import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../models/debt.dart';
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
  DateTime _selectedDate = DateTime.now();
  bool _addToLedger = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entryType = widget.initialType;
    _addToLedger = _entryType == DebtEntryType.odeme;
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
            addToLedger: _addToLedger,
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
    final isPayment = _entryType == DebtEntryType.odeme;

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
                onSelectionChanged: (sel) => setState(() => _entryType = sel.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 14),

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
              const SizedBox(height: 10),

              CheckboxListTile(
                value: _addToLedger,
                onChanged: (val) => setState(() => _addToLedger = val ?? false),
                activeColor: AppTheme.primaryOrange,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Gelir gidere de eklensin mi?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  isPayment
                      ? 'İşaretliyse Gelir Gider kasasına GİDER olarak işlenir.'
                      : 'İşaretliyse kasaya giren para olarak GELİR işlenir.',
                  style: const TextStyle(fontSize: 12),
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
