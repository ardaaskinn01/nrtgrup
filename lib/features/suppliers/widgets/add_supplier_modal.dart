import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modal_header.dart';
import '../../../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class AddSupplierModal extends ConsumerStatefulWidget {
  final Supplier? initialSupplier;

  const AddSupplierModal({super.key, this.initialSupplier});

  static Future<bool?> show(
    BuildContext context, {
    Supplier? initialSupplier,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddSupplierModal(initialSupplier: initialSupplier),
    );
  }

  @override
  ConsumerState<AddSupplierModal> createState() => _AddSupplierModalState();
}

class _AddSupplierModalState extends ConsumerState<AddSupplierModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  SupplierCategory _selectedCategory = SupplierCategory.pvc;
  bool _isLoading = false;

  bool get _isEditing => widget.initialSupplier != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSupplier;
    if (initial != null) {
      _nameController.text = initial.name;
      _phoneController.text = initial.phone;
      _notesController.text = initial.notes;
      _selectedCategory = initial.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(supplierRepositoryProvider);
      if (_isEditing) {
        final updated = widget.initialSupplier!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
        );
        await repo.updateSupplier(widget.initialSupplier!.id!, updated);
      } else {
        final supplier = Supplier(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await repo.addSupplier(supplier);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Tedarikçi güncellendi' : 'Tedarikçi eklendi'),
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
                  title: _isEditing ? 'Tedarikçi Düzenle' : 'Yeni Tedarikçi Ekle',
                ),
                const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Firma Adı / Ünvanı',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen firma adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<SupplierCategory>(
                value: _selectedCategory,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: const InputDecoration(
                  labelText: 'Firma Türü',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: SupplierCategory.values.map((cat) {
                  return DropdownMenuItem<SupplierCategory>(
                    value: cat,
                    child: Text(
                      cat.displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
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
                controller: _notesController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Alınan Malzemeler / Not (Opsiyonel)',
                  hintText: 'Örn: Profil, ısıcam, menteşe, silikon...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 22),

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
