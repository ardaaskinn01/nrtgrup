import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/modal_header.dart';
import '../../../models/debt.dart';
import '../../../models/supplier.dart';
import '../../suppliers/providers/supplier_providers.dart';
import '../repositories/debt_repository.dart';

class AddDebtPersonModal extends ConsumerStatefulWidget {
  final DebtPerson? initialPerson;
  final Supplier? initialSupplier;

  const AddDebtPersonModal({
    super.key,
    this.initialPerson,
    this.initialSupplier,
  });

  static Future<bool?> show(
    BuildContext context, {
    DebtPerson? initialPerson,
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
      builder: (_) => AddDebtPersonModal(
        initialPerson: initialPerson,
        initialSupplier: initialSupplier,
      ),
    );
  }

  @override
  ConsumerState<AddDebtPersonModal> createState() => _AddDebtPersonModalState();
}

class _AddDebtPersonModalState extends ConsumerState<AddDebtPersonModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _initialDebtController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  bool _isSupplier = false;
  String? _selectedSupplierId;
  String? _selectedSupplierName;

  bool get _isEditing => widget.initialPerson != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPerson;
    final sup = widget.initialSupplier;
    if (initial != null) {
      _nameController.text = initial.name;
      _phoneController.text = initial.phone;
      _noteController.text = initial.note;
      _isSupplier = initial.isSupplier;
      _selectedSupplierId = initial.supplierId;
      _selectedSupplierName = initial.supplierName;
    } else if (sup != null) {
      _isSupplier = true;
      _selectedSupplierId = sup.id;
      _selectedSupplierName = sup.name;
      _nameController.text = sup.name;
      _phoneController.text = sup.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _initialDebtController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    double? initialDebt;
    if (!_isEditing && _initialDebtController.text.trim().isNotEmpty) {
      initialDebt = AppFormatters.parseAmount(_initialDebtController.text);
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(debtRepositoryProvider);
      if (_isEditing) {
        await repo.updatePerson(
          widget.initialPerson!.id!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          note: _noteController.text.trim(),
          supplierId: _isSupplier ? _selectedSupplierId : null,
          supplierName: _isSupplier ? _selectedSupplierName : null,
        );
      } else {
        await repo.addPerson(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          initialDebt: initialDebt,
          note: _noteController.text.trim(),
          supplierId: _isSupplier ? _selectedSupplierId : null,
          supplierName: _isSupplier ? _selectedSupplierName : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Kişi güncellendi' : 'Borçlu olunan kişi eklendi'),
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
                  title: _isEditing ? 'Kişiyi Düzenle' : 'Borçlu Olunan Kişi Ekle',
                ),
                const SizedBox(height: 6),

                // Tedarikçi Bağlantısı Tiki
                CheckboxListTile(
                  value: _isSupplier,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.primaryOrange,
                  title: const Text(
                    'Bu borç bir Tedarikçiye ait',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Tedarikçiler ekranında borç takibi için bağlanır',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _isSupplier = val ?? false;
                      if (!_isSupplier) {
                        _selectedSupplierId = null;
                        _selectedSupplierName = null;
                      }
                    });
                  },
                ),

                if (_isSupplier) ...[
                  Consumer(
                    builder: (context, ref, _) {
                      final suppliers = ref.watch(suppliersStreamProvider).value ?? [];
                      if (suppliers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Kayıtlı tedarikçi bulunamadı. Önce Tedarikçiler sekmesinden ekleyebilirsiniz.',
                            style: TextStyle(fontSize: 12, color: AppTheme.warningColor),
                          ),
                        );
                      }
                      final validId = suppliers.any((s) => s.id == _selectedSupplierId)
                          ? _selectedSupplierId
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: validId,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          decoration: const InputDecoration(
                            labelText: 'Tedarikçi Seçin',
                            prefixIcon: Icon(Icons.local_shipping_outlined),
                          ),
                          items: suppliers.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.category.displayName})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          validator: (val) {
                            if (_isSupplier && (val == null || val.isEmpty)) {
                              return 'Lütfen bir tedarikçi seçin';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            if (val == null) return;
                            final chosen = suppliers.firstWhere((s) => s.id == val);
                            setState(() {
                              _selectedSupplierId = chosen.id;
                              _selectedSupplierName = chosen.name;
                              _nameController.text = chosen.name;
                              if (chosen.phone.isNotEmpty) {
                                _phoneController.text = chosen.phone;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ] else
                  const SizedBox(height: 4),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kime Borç? (Ad / Ünvan)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Lütfen ad/ünvan girin' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telefon (Opsiyonel)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              if (!_isEditing) ...[
                const SizedBox(height: 14),
                AmountField(
                  controller: _initialDebtController,
                  label: 'Toplam Borç Miktarı (Opsiyonel)',
                  allowZero: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final parsed = AppFormatters.parseAmount(val);
                    if (parsed == null || parsed < 0) {
                      return 'Geçerli bir tutar girin';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 14),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
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
