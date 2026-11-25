import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  final AppTransaction? initialTransaction;
  final TransactionType? initialType;

  const AddTransactionModal({
    super.key,
    this.initialTransaction,
    this.initialType,
  });

  static Future<({bool isNew, bool isIncome, double amount})?> show(
    BuildContext context, {
    AppTransaction? initialTransaction,
    TransactionType? initialType,
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
  late String _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;
    if (initial != null) {
      _selectedType = initial.type;
      _selectedCategory = initial.category;
      _selectedPaymentMethod = initial.paymentMethod;
      _selectedDate = initial.date;
      _amountController.text = initial.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descController.text = initial.description;
    } else {
      _selectedType = widget.initialType ?? TransactionType.income;
      _selectedCategory = TransactionCategories.forType(_selectedType).first;
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
      final validCats = TransactionCategories.forType(newType);
      if (!validCats.contains(_selectedCategory)) {
        _selectedCategory = validCats.first;
      }
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

      if (_isEditing) {
        final updated = widget.initialTransaction!.copyWith(
          amount: parsedAmount,
          type: _selectedType,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          description: desc.isEmpty ? _selectedCategory : desc,
          date: _selectedDate,
        );
        await repo.updateTransaction(widget.initialTransaction!.id!, updated);
      } else {
        final newTx = AppTransaction(
          amount: parsedAmount,
          type: _selectedType,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          description: desc.isEmpty ? _selectedCategory : desc,
          date: _selectedDate,
          createdAt: DateTime.now(),
        );
        await repo.addTransaction(newTx);
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
    final categories = TransactionCategories.forType(_selectedType);
    if (!categories.contains(_selectedCategory)) {
      categories.add(_selectedCategory);
    }

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
              // Tutamak
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
                _isEditing ? 'İşlemi Düzenle' : 'Yeni İşlem Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

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

              // Kategori Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),

              // Ödeme Yöntemi
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Ödeme Yöntemi',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
              ),
              const SizedBox(height: 14),

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

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Güncelle' : 'Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
