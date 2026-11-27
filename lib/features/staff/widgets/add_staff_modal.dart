import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  Uint8List? _selectedIdCardBytes;
  String? _selectedIdCardFileName;
  bool _removeExistingIdCard = false;

  int _salaryDay = 1;
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
      _salaryDay = initial.salaryDay;
    } else {
      _salaryDay = 1;
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

  Future<void> _pickIdCard(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedIdCardBytes = bytes;
        _selectedIdCardFileName = picked.name;
        _removeExistingIdCard = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kimlik fotoğrafı seçilemedi: $e')),
        );
      }
    }
  }

  void _showIdCardSourceActionSheet() {
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
                _pickIdCard(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryOrange),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickIdCard(ImageSource.gallery);
              },
            ),
            if (_selectedIdCardBytes != null ||
                (widget.initialStaff?.idCardUrl.isNotEmpty ?? false))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: const Text('Kimlik Fotoğrafını Kaldır', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedIdCardBytes = null;
                    _selectedIdCardFileName = null;
                    _removeExistingIdCard = true;
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

    final wage = AppFormatters.parseAmount(_wageController.text);
    if (wage == null || wage <= 0) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(staffRepositoryProvider);
      if (_isEditing) {
        var updated = widget.initialStaff!.copyWith(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          wage: wage,
          salaryDay: _salaryDay,
          note: _noteController.text.trim(),
        );

        if (_removeExistingIdCard && updated.idCardPath.isNotEmpty) {
          await repo.removeStaffIdCard(widget.initialStaff!.id!, updated.idCardPath);
          updated = updated.copyWith(idCardUrl: '', idCardPath: '');
        }

        await repo.updateStaff(widget.initialStaff!.id!, updated);

        if (_selectedIdCardBytes != null && _selectedIdCardFileName != null) {
          await repo.updateStaffIdCard(
            staffId: widget.initialStaff!.id!,
            bytes: _selectedIdCardBytes!,
            fileName: _selectedIdCardFileName!,
            oldIdCardPath: updated.idCardPath.isNotEmpty ? updated.idCardPath : null,
          );
        }
      } else {
        final staff = StaffMember(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          wage: wage,
          salaryDay: _salaryDay,
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
        );
        final newId = await repo.addStaff(staff);

        if (_selectedIdCardBytes != null && _selectedIdCardFileName != null) {
          await repo.updateStaffIdCard(
            staffId: newId,
            bytes: _selectedIdCardBytes!,
            fileName: _selectedIdCardFileName!,
          );
        }
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

    final initialIdCard = widget.initialStaff?.idCardUrl;
    final hasExistingIdCard = !_removeExistingIdCard && (initialIdCard != null && initialIdCard.isNotEmpty);

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
                _isEditing ? 'Personeli Düzenle' : 'Yeni Personel Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Kimlik Fotoğrafı Seçme / Önizleme Alanı
              InkWell(
                onTap: _showIdCardSourceActionSheet,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _selectedIdCardBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_selectedIdCardBytes!, fit: BoxFit.cover),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Değiştir', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : (hasExistingIdCard
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(initialIdCard, fit: BoxFit.cover),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text('Değiştir', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 34,
                                    color: AppTheme.primaryOrange.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Personel Kimlik Fotoğrafı Yükle',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ön/arka kimlik veya vesikalık (İsteğe bağlı)',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )),
                  ),
                ),
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

              AmountField(
                controller: _wageController,
                label: 'Aylık Maaş (TL)',
              ),
              const SizedBox(height: 14),

              // Maaş Günü Seçimi (Ayın kaçı)
              DropdownButtonFormField<int>(
                value: _salaryDay,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: const InputDecoration(
                  labelText: 'Maaş Günü (Her Ayın Kaçında)',
                  prefixIcon: Icon(Icons.event_repeat_outlined),
                ),
                items: List.generate(31, (index) => index + 1).map((day) {
                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text(
                      'Her ayın $day. günü',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _salaryDay = val);
                },
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
