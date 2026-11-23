import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../repositories/customer_repository.dart';

class AddWorkPhotoDialog extends ConsumerStatefulWidget {
  final String customerId;
  final XFile imageFile;
  final Uint8List imageBytes;

  const AddWorkPhotoDialog({
    super.key,
    required this.customerId,
    required this.imageFile,
    required this.imageBytes,
  });

  static Future<void> pickAndUpload(
    BuildContext context, {
    required String customerId,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
    );
    if (picked == null || !context.mounted) return;

    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddWorkPhotoDialog(
        customerId: customerId,
        imageFile: picked,
        imageBytes: bytes,
      ),
    );
  }

  @override
  ConsumerState<AddWorkPhotoDialog> createState() => _AddWorkPhotoDialogState();
}

class _AddWorkPhotoDialogState extends ConsumerState<AddWorkPhotoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isUploading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      await ref.read(customerRepositoryProvider).addWorkPhoto(
            customerId: widget.customerId,
            bytes: widget.imageBytes,
            fileName: widget.imageFile.name,
            description: _descController.text.trim(),
            date: _selectedDate,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İş fotoğrafı yüklendi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yükleme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                'Yapılan İş / Ürün Fotoğrafı Ekle',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  widget.imageBytes,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'İş / Ürün Açıklaması',
                  hintText: 'Örn: Mutfak dolabı, alüminyum doğrama, cam balkon...',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen yapılan iş/ürün açıklamasını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              DatePickerField(
                label: 'İş / Montaj Tarihi',
                selectedDate: _selectedDate,
                onDateSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 18),

              if (_isUploading) ...[
                const LinearProgressIndicator(color: AppTheme.primaryOrange),
                const SizedBox(height: 8),
                const Text(
                  'Fotoğraf Supabase Storage\'a yükleniyor...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],

              ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploading ? 'Yükleniyor...' : 'Kaydet ve Yükle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
