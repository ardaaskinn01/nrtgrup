import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarFileName;
  bool _removeExistingAvatar = false;
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

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarFileName = picked.name;
        _removeExistingAvatar = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
        );
      }
    }
  }

  void _showAvatarSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryOrange),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryOrange),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (_selectedAvatarBytes != null ||
                (widget.initialCustomer?.avatarUrl.isNotEmpty ?? false))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: const Text('Avatarı Kaldır', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedAvatarBytes = null;
                    _selectedAvatarFileName = null;
                    _removeExistingAvatar = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      if (_isEditing) {
        var updated = widget.initialCustomer!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          workSummary: _summaryController.text.trim(),
        );

        if (_removeExistingAvatar && updated.avatarPath.isNotEmpty) {
          await repo.removeCustomerAvatar(widget.initialCustomer!.id!, updated.avatarPath);
          updated = updated.copyWith(avatarUrl: '', avatarPath: '');
        }

        await repo.updateCustomer(widget.initialCustomer!.id!, updated);

        if (_selectedAvatarBytes != null && _selectedAvatarFileName != null) {
          await repo.updateCustomerAvatar(
            customerId: widget.initialCustomer!.id!,
            bytes: _selectedAvatarBytes!,
            fileName: _selectedAvatarFileName!,
            oldAvatarPath: updated.avatarPath.isNotEmpty ? updated.avatarPath : null,
          );
        }
      } else {
        final customer = Customer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          workSummary: _summaryController.text.trim(),
          createdAt: DateTime.now(),
        );
        final newId = await repo.addCustomer(customer);

        if (_selectedAvatarBytes != null && _selectedAvatarFileName != null) {
          await repo.updateCustomerAvatar(
            customerId: newId,
            bytes: _selectedAvatarBytes!,
            fileName: _selectedAvatarFileName!,
          );
        }
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

    final initialAvatar = widget.initialCustomer?.avatarUrl;
    final hasExistingAvatar = !_removeExistingAvatar && (initialAvatar != null && initialAvatar.isNotEmpty);

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

              // Avatar Seçim / Görüntüleme Alanı
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showAvatarSourceActionSheet,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                        backgroundImage: _selectedAvatarBytes != null
                            ? MemoryImage(_selectedAvatarBytes!)
                            : (hasExistingAvatar ? NetworkImage(initialAvatar) as ImageProvider : null),
                        child: (_selectedAvatarBytes == null && !hasExistingAvatar)
                            ? const Icon(
                                Icons.person_outline,
                                size: 46,
                                color: AppTheme.primaryOrange,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showAvatarSourceActionSheet,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Profil Fotoğrafı Seç / Değiştir',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
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
