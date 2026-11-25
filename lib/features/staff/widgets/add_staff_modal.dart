import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../models/staff.dart';
import '../repositories/staff_repository.dart';

class AddStaffModal extends ConsumerStatefulWidget {
  final StaffMember? initialStaff;

  const AddStaffModal({super.key, this.initialStaff});

  static Future<bool?> show(
    BuildContext context, {
    StaffMember? initialStaff,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddStaffModal(initialStaff: initialStaff),
    );
  }

  @override
  ConsumerState<AddStaffModal> createState() => _AddStaffModalState();
}

class _AddStaffModalState extends ConsumerState<AddStaffModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wageController = TextEditingController();
  final _noteController = TextEditingController();

  late PaymentPeriod _paymentType;
  bool _isLoading = false;

  bool get _isEditing => widget.initialStaff != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStaff;
    if (initial != null) {
      _nameController.text = initial.fullName;
      _phoneController.text = initial.phone;
      _wageController.text = initial.wage.toStringAsFixed(2).replaceAll('.', ',');
      _noteController.text = initial.note;
      _paymentType = initial.paymentType;
    } else {
      _paymentType = PaymentPeriod.daily;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _wageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final wage = AppFormatters.parseAmount(_wageController.text);
    if (wage == null || wage <= 0) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(staffRepositoryProvider);
      if (_isEditing) {
        final updated = widget.initialStaff!.copyWith(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          paymentType: _paymentType,
          wage: wage,
          note: _noteController.text.trim(),
        );
        await repo.updateStaff(widget.initialStaff!.id!, updated);
      } else {
        final staff = StaffMember(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          paymentType: _paymentType,
          wage: wage,
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
        );
        await repo.addStaff(staff);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Personel güncellendi' : 'Personel eklendi'),
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
                _isEditing ? 'Personel Düzenle' : 'Yeni Personel Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen ad soyad girin';
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

              DropdownButtonFormField<PaymentPeriod>(
                value: _paymentType,
                dropdownColor: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.pureWhite,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Ödeme Tipi',
                  prefixIcon: Icon(Icons.calendar_view_week_outlined),
                ),
                items: PaymentPeriod.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.displayName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentType = val);
                },
              ),
              const SizedBox(height: 14),

              AmountField(
                controller: _wageController,
                label: 'Ücret Bilgisi (TL)',
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  hintText: 'Görev, açıklama vb.',
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
