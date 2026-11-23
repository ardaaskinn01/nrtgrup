import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/receivable.dart';
import '../repositories/receivable_repository.dart';

class EditReceivablePersonDialog extends ConsumerStatefulWidget {
  final ReceivablePerson person;

  const EditReceivablePersonDialog({super.key, required this.person});

  static Future<void> show(BuildContext context, ReceivablePerson person) {
    return showDialog<void>(
      context: context,
      builder: (_) => EditReceivablePersonDialog(person: person),
    );
  }

  @override
  ConsumerState<EditReceivablePersonDialog> createState() =>
      _EditReceivablePersonDialogState();
}

class _EditReceivablePersonDialogState
    extends ConsumerState<EditReceivablePersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _phoneController = TextEditingController(text: widget.person.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || widget.person.id == null) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(receivableRepositoryProvider).updatePerson(
            widget.person.id!,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
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
    return AlertDialog(
      title: const Text('Kişiyi Düzenle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad / Ünvan'),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Ad gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon (Opsiyonel)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
