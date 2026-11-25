import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../models/customer.dart';
import '../repositories/customer_repository.dart';

class AddNoteModal extends ConsumerStatefulWidget {
  final String customerId;
  final CustomerNote? initialNote;

  const AddNoteModal({
    super.key,
    required this.customerId,
    this.initialNote,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String customerId,
    CustomerNote? initialNote,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddNoteModal(
        customerId: customerId,
        initialNote: initialNote,
      ),
    );
  }

  @override
  ConsumerState<AddNoteModal> createState() => _AddNoteModalState();
}

class _AddNoteModalState extends ConsumerState<AddNoteModal> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.initialNote != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialNote;
    if (initial != null) {
      _contentController.text = initial.content;
      _selectedDate = initial.date;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      if (_isEditing) {
        final updated = widget.initialNote!.copyWith(
          content: _contentController.text.trim(),
          date: _selectedDate,
        );
        await repo.updateNote(widget.customerId, widget.initialNote!.id!, updated);
      } else {
        final note = CustomerNote(
          content: _contentController.text.trim(),
          date: _selectedDate,
          createdAt: DateTime.now(),
        );
        await repo.addNote(widget.customerId, note);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Not güncellendi' : 'İş notu eklendi'),
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
                _isEditing ? 'İş Notunu Düzenle' : 'Yeni İş Notu Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              DatePickerField(
                label: 'Tarih',
                selectedDate: _selectedDate,
                onDateSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _contentController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'İş Notu',
                  hintText: 'Ölçüler, özel istekler, malzeme renk kodları...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen not içeriğini girin';
                  }
                  return null;
                },
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
