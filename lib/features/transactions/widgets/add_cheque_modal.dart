import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../core/widgets/modal_header.dart';
import '../../../models/cheque.dart';
import '../repositories/cheque_repository.dart';

class AddChequeModal extends ConsumerStatefulWidget {
  final Cheque? initialCheque;

  const AddChequeModal({super.key, this.initialCheque});

  static Future<bool?> show(
    BuildContext context, {
    Cheque? initialCheque,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddChequeModal(initialCheque: initialCheque),
    );
  }

  @override
  ConsumerState<AddChequeModal> createState() => _AddChequeModalState();
}

class _AddChequeModalState extends ConsumerState<AddChequeModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _givenToController = TextEditingController();
  final _noteController = TextEditingController();

  late ChequeStatus _status;
  late DateTime _selectedDate;
  Uint8List? _selectedImageBytes;
  String? _selectedImageFileName;
  bool _removeExistingImage = false;
  bool _isLoading = false;

  bool get _isEditing => widget.initialCheque != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCheque;
    if (initial != null) {
      _amountController.text = initial.amount.toStringAsFixed(2).replaceAll('.', ',');
      _sourceController.text = initial.sourceName;
      _givenToController.text = initial.givenToName ?? '';
      _noteController.text = initial.note;
      _status = initial.status;
      _selectedDate = initial.date;
    } else {
      _status = ChequeStatus.inHand;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _givenToController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageFileName = picked.name;
        _removeExistingImage = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    final hasExisting = !_removeExistingImage && (widget.initialCheque?.hasImage ?? false);
    final hasAny = _selectedImageBytes != null || hasExisting;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kameradan Çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (hasAny)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: const Text('Görseli Kaldır', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImageBytes = null;
                    _selectedImageFileName = null;
                    _removeExistingImage = true;
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
    final parsedAmount = AppFormatters.parseAmount(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(chequeRepositoryProvider);
      final storage = ref.read(supabaseStorageServiceProvider);

      String? imageUrl = widget.initialCheque?.imageUrl;
      String? imagePath = widget.initialCheque?.imagePath;

      if (_removeExistingImage && imagePath != null && imagePath.isNotEmpty) {
        try {
          await storage.deleteWorkPhoto(imagePath);
        } catch (_) {}
        imageUrl = null;
        imagePath = null;
      }

      if (_isEditing) {
        final existingId = widget.initialCheque!.id!;
        if (_selectedImageBytes != null) {
          if (imagePath != null && imagePath.isNotEmpty) {
            try {
              await storage.deleteWorkPhoto(imagePath);
            } catch (_) {}
          }
          final uploaded = await storage.uploadChequeImage(
            chequeId: existingId,
            bytes: _selectedImageBytes!,
            fileName: _selectedImageFileName ?? 'cheque.jpg',
          );
          imageUrl = uploaded.publicUrl;
          imagePath = uploaded.path;
        }

        final updated = widget.initialCheque!.copyWith(
          amount: parsedAmount,
          sourceName: _sourceController.text.trim(),
          givenToName: _status == ChequeStatus.given ? _givenToController.text.trim() : null,
          clearGivenToName: _status == ChequeStatus.inHand,
          note: _noteController.text.trim(),
          status: _status,
          imageUrl: imageUrl,
          imagePath: imagePath,
          clearImage: imageUrl == null,
          date: _selectedDate,
        );
        await repo.updateCheque(existingId, updated);
      } else {
        final newCheque = Cheque(
          amount: parsedAmount,
          sourceName: _sourceController.text.trim(),
          givenToName: _status == ChequeStatus.given ? _givenToController.text.trim() : null,
          note: _noteController.text.trim(),
          status: _status,
          date: _selectedDate,
          createdAt: DateTime.now(),
        );
        final docId = await repo.addCheque(newCheque);

        if (_selectedImageBytes != null) {
          final uploaded = await storage.uploadChequeImage(
            chequeId: docId,
            bytes: _selectedImageBytes!,
            fileName: _selectedImageFileName ?? 'cheque.jpg',
          );
          await repo.updateCheque(
            docId,
            newCheque.copyWith(
              id: docId,
              imageUrl: uploaded.publicUrl,
              imagePath: uploaded.path,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Çek güncellendi' : 'Çek kaydedildi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
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

    final existingUrl = widget.initialCheque?.imageUrl;
    final hasExisting = !_removeExistingImage && existingUrl != null && existingUrl.isNotEmpty;

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
                  title: _isEditing ? 'Çeki Düzenle' : 'Yeni Çek Ekle',
                ),
                const SizedBox(height: 10),

                // Çek Görseli Seçme Alanı
                InkWell(
                  onTap: _showImagePickerSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 130,
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
                      child: _selectedImageBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Değiştir',
                                      style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : hasExisting
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      existingUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image_outlined, size: 36),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Değiştir',
                                          style: TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 32,
                                      color: AppTheme.primaryOrange.withValues(alpha: 0.85),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Çek Görseli / Fotoğrafı Ekle (Opsiyonel)',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Durum Seçimi
                SegmentedButton<ChequeStatus>(
                  segments: const [
                    ButtonSegment(
                      value: ChequeStatus.inHand,
                      label: Text('Kasada'),
                      icon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    ButtonSegment(
                      value: ChequeStatus.given,
                      label: Text('Verildi'),
                      icon: Icon(Icons.outbox_outlined),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (sel) => setState(() => _status = sel.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 14),

                AmountField(controller: _amountController),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _sourceController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Kimden Alındı (Opsiyonel)',
                    hintText: 'Örn: Ahmet Yılmaz, ABC İnşaat...',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                if (_status == ChequeStatus.given) ...[
                  TextFormField(
                    controller: _givenToController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Kime Verildi (Opsiyonel)',
                      hintText: 'Örn: Tedarikçi veya alacaklı adı...',
                      prefixIcon: Icon(Icons.forward_to_inbox_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                DatePickerField(
                  label: 'Çek / Vade Tarihi',
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Banka / Çek No (Opsiyonel)',
                    hintText: 'Örn: Garanti Bankası, Vade 15.12...',
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
