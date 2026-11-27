import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/stock_item.dart';
import '../../../models/supplier.dart';
import '../../suppliers/providers/supplier_providers.dart';
import '../repositories/stock_repository.dart';

class AddStockModal extends ConsumerStatefulWidget {
  final StockItem? initialStock;

  const AddStockModal({super.key, this.initialStock});

  static Future<bool?> show(
    BuildContext context, {
    StockItem? initialStock,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddStockModal(initialStock: initialStock),
    );
  }

  @override
  ConsumerState<AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends ConsumerState<AddStockModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  SupplierCategory _selectedCategory = SupplierCategory.pvc;
  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.initialStock != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStock;
    if (initial != null) {
      _nameController.text = initial.name;
      _quantityController.text = initial.quantityText;
      _notesController.text = initial.notes;
      _selectedCategory = initial.category;
      _selectedSupplierId = initial.supplierId.isNotEmpty ? initial.supplierId : null;
      _selectedSupplierName = initial.supplierName;
      _selectedDate = initial.date;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(stockRepositoryProvider);
      if (_isEditing) {
        final updated = widget.initialStock!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          supplierId: _selectedSupplierId ?? '',
          supplierName: _selectedSupplierName,
          quantityText: _quantityController.text.trim(),
          notes: _notesController.text.trim(),
          date: _selectedDate,
        );
        await repo.updateStock(widget.initialStock!.id!, updated);
      } else {
        final item = StockItem(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          supplierId: _selectedSupplierId ?? '',
          supplierName: _selectedSupplierName,
          quantityText: _quantityController.text.trim(),
          notes: _notesController.text.trim(),
          date: _selectedDate,
          createdAt: DateTime.now(),
        );
        await repo.addStock(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Stok kaydı güncellendi' : 'Stok kaydı eklendi'),
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

    final suppliersAsync = ref.watch(suppliersStreamProvider);
    final allSuppliers = suppliersAsync.value ?? [];
    final categorySuppliers =
        allSuppliers.where((s) => s.category == _selectedCategory).toList();

    // Eğer seçili tedarikçi güncel kategori listesinde yoksa seçimi temizle
    final validSelectedSupplierId = categorySuppliers.any((s) => s.id == _selectedSupplierId)
        ? _selectedSupplierId
        : null;

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
                _isEditing ? 'Stok Kaydını Düzenle' : 'Yeni Stok Alımı Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Kategori Seçimi
              DropdownButtonFormField<SupplierCategory>(
                value: _selectedCategory,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: const InputDecoration(
                  labelText: 'Malzeme Kategorisi',
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
                    setState(() {
                      _selectedCategory = val;
                      _selectedSupplierId = null;
                      _selectedSupplierName = '';
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Kategoriye Göre Tedarikçi Seçimi
              DropdownButtonFormField<String?>(
                value: validSelectedSupplierId,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  labelText: '${_selectedCategory.displayName} Tedarikçisi (Opsiyonel)',
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                  helperText: categorySuppliers.isEmpty
                      ? 'Bu kategoride kayıtlı tedarikçi bulunmuyor.'
                      : null,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Tedarikçi Seçilmedi',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  ...categorySuppliers.map((sup) {
                    return DropdownMenuItem<String?>(
                      value: sup.id,
                      child: Text(
                        sup.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSupplierId = val;
                    if (val == null) {
                      _selectedSupplierName = '';
                    } else {
                      final match = categorySuppliers.firstWhere((s) => s.id == val);
                      _selectedSupplierName = match.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // Malzeme / Ürün Adı
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Alınan Malzeme / Ürün Adı',
                  hintText: 'Örn: 70lik Beyaz Profil, 4+12+4 Isıcam...',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen alınan malzeme adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Miktar (Metin olarak)
              TextFormField(
                controller: _quantityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Miktar / Ölçü (Metin)',
                  hintText: 'Örn: 50 boy, 120 m2, 40 adet, 3 koli...',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen miktar veya ölçü bilgisini girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Alım Tarihi Seçimi
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Alım Tarihi',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.edit_calendar_outlined, size: 18),
                  ),
                  child: Text(
                    AppFormatters.formatDate(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Açıklama / Not
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Açıklama / Not (Opsiyonel)',
                  hintText: 'Örn: İrsaliye no, renk kodu, şantiye bilgisi...',
                  prefixIcon: Icon(Icons.notes_outlined),
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
