import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../models/receivable.dart';
import '../providers/receivable_providers.dart';
import '../repositories/receivable_repository.dart';

class AddReceivableEntryModal extends ConsumerStatefulWidget {
  final ReceivablePerson? fixedPerson;
  final ReceivableEntryType initialType;

  const AddReceivableEntryModal({
    super.key,
    this.fixedPerson,
    this.initialType = ReceivableEntryType.alacakEkle,
  });

  static Future<({bool triggerHappyBurst, double amount})?> show(
    BuildContext context, {
    ReceivablePerson? fixedPerson,
    ReceivableEntryType initialType = ReceivableEntryType.alacakEkle,
  }) {
    return showModalBottomSheet<({bool triggerHappyBurst, double amount})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddReceivableEntryModal(
        fixedPerson: fixedPerson,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<AddReceivableEntryModal> createState() =>
      _AddReceivableEntryModalState();
}

class _AddReceivableEntryModalState
    extends ConsumerState<AddReceivableEntryModal> {
  final _formKey = GlobalKey<FormState>();
  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  late ReceivableEntryType _entryType;
  DateTime _selectedDate = DateTime.now();
  bool _addToIncome = true;
  bool _isNewPerson = false;
  String? _selectedPersonId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entryType = widget.initialType;
    if (widget.fixedPerson != null) {
      _selectedPersonId = widget.fixedPerson!.id;
    }
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newPhoneController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<ReceivablePerson> existingPeople) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = AppFormatters.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(receivableRepositoryProvider);
      String personId;
      String personName;

      if (widget.fixedPerson != null) {
        personId = widget.fixedPerson!.id!;
        personName = widget.fixedPerson!.name;
      } else if (_isNewPerson || existingPeople.isEmpty) {
        personName = _newNameController.text.trim();
        personId = await repo.addPerson(
          name: personName,
          phone: _newPhoneController.text.trim(),
        );
      } else {
        final chosen = existingPeople.firstWhere((p) => p.id == _selectedPersonId);
        personId = chosen.id!;
        personName = chosen.name;
      }

      final res = await repo.addEntry(
        personId: personId,
        personName: personName,
        type: _entryType,
        amount: amount,
        date: _selectedDate,
        description: _descController.text.trim(),
        addToIncome: _entryType == ReceivableEntryType.tahsilat && _addToIncome,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _entryType == ReceivableEntryType.alacakEkle
                  ? 'Alacak eklendi'
                  : 'Tahsilat kaydedildi',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(
          context,
          (triggerHappyBurst: res.addedToIncome, amount: res.amount),
        );
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
    final people = ref.watch(receivablesStreamProvider).value ?? [];
    final mustCreateNew = widget.fixedPerson == null && (people.isEmpty || _isNewPerson);

    if (widget.fixedPerson == null &&
        !mustCreateNew &&
        _selectedPersonId == null &&
        people.isNotEmpty) {
      _selectedPersonId = people.first.id;
    }

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
                widget.fixedPerson != null
                    ? '${widget.fixedPerson!.name} • İşlem'
                    : 'Alacak İşlemi Ekle',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Kişi Seçimi (İlk sayfadan açıldığında)
              if (widget.fixedPerson == null) ...[
                if (people.isNotEmpty)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Mevcut Kişi')),
                      ButtonSegment(value: true, label: Text('Yeni Kişi')),
                    ],
                    selected: {_isNewPerson},
                    onSelectionChanged: (sel) => setState(() => _isNewPerson = sel.first),
                    showSelectedIcon: false,
                  ),
                const SizedBox(height: 14),
                if (mustCreateNew) ...[
                  TextFormField(
                    controller: _newNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Kimden Alacak? (Ad / Ünvan)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Lütfen kişi adı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon (Opsiyonel)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ] else
                  DropdownButtonFormField<String>(
                    value: _selectedPersonId,
                    decoration: const InputDecoration(
                      labelText: 'Kimden Alacak?',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: people
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${AppFormatters.formatCurrency(p.balance)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPersonId = val),
                    validator: (val) =>
                        val == null ? 'Lütfen bir kişi seçin' : null,
                  ),
                const SizedBox(height: 14),
              ],

              // Alacak Ekle / Alacaktan Düş (Tahsilat)
              SegmentedButton<ReceivableEntryType>(
                segments: const [
                  ButtonSegment(
                    value: ReceivableEntryType.alacakEkle,
                    label: Text('Alacak Ekle'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: ReceivableEntryType.tahsilat,
                    label: Text('Tahsilat (Düş)'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_entryType},
                onSelectionChanged: (sel) => setState(() => _entryType = sel.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 14),

              AmountField(controller: _amountController),
              const SizedBox(height: 14),

              DatePickerField(
                selectedDate: _selectedDate,
                onDateSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Örn: Kapora, kalan bakiye, kısmi ödeme...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),

              if (_entryType == ReceivableEntryType.tahsilat) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _addToIncome,
                  onChanged: (val) => setState(() => _addToIncome = val ?? true),
                  activeColor: AppTheme.primaryOrange,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Gelir gidere de eklensin mi?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'İşaretliyse bu tahsilat Gelir Gider kasasına gelir olarak işlenir.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _isLoading ? null : () => _submit(people),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
