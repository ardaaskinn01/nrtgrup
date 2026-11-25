import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/customer.dart';
import '../repositories/customer_repository.dart';

class AddCustomerModal extends ConsumerStatefulWidget {
  final Customer? initialCustomer;

  const AddCustomerModal({super.key, this.initialCustomer});

  static Future<bool?> show(
    BuildContext context, {
    Customer? initialCustomer,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddCustomerModal(initialCustomer: initialCustomer),
    );
  }

  @override
  ConsumerState<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends ConsumerState<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _summaryController = TextEditingController();

  bool _isLoading = false;

  bool get _isEditing => widget.initialCustomer != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCustomer;
    if (initial != null) {
      _nameController.text = initial.name;
      _phoneController.text = initial.phone;
      _summaryController.text = initial.workSummary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      if (_isEditing) {
        final updated = widget.initialCustomer!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          workSummary: _summaryController.text.trim(),
        );
        await repo.updateCustomer(widget.initialCustomer!.id!, updated);
      } else {
        final customer = Customer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          workSummary: _summaryController.text.trim(),
          createdAt: DateTime.now(),
        );
        await repo.addCustomer(customer);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Müşteri güncellendi' : 'Müşteri eklendi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
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
                _isEditing ? 'Müşteri Düzenle' : 'Yeni Müşteri Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Müşteri Adı / Ünvanı',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen müşteri adı veya ünvanı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telefon (Opsiyonel)',
                  hintText: '05XX XXX XX XX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _summaryController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Yapılan İş Özeti (Opsiyonel)',
                  hintText: 'Örn: Mutfak dolabı, cam balkon, doğrama...',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
              ),
              const SizedBox(height: 22),

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
