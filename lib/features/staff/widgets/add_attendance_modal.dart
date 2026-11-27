import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../core/widgets/modal_header.dart';
import '../../../core/widgets/time_picker_field.dart';
import '../../../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class AddAttendanceModal extends ConsumerStatefulWidget {
  final String staffId;
  final AttendanceRecord? initialRecord;
  final DateTime? defaultDate;

  const AddAttendanceModal({
    super.key,
    required this.staffId,
    this.initialRecord,
    this.defaultDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String staffId,
    AttendanceRecord? initialRecord,
    DateTime? defaultDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddAttendanceModal(
        staffId: staffId,
        initialRecord: initialRecord,
        defaultDate: defaultDate,
      ),
    );
  }

  @override
  ConsumerState<AddAttendanceModal> createState() => _AddAttendanceModalState();
}

class _AddAttendanceModalState extends ConsumerState<AddAttendanceModal> {
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isLoading = false;

  bool get _isEditing => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    if (initial != null) {
      _selectedDate = initial.date;
      _startTime = initial.startTime;
      _endTime = initial.endTime;
      _noteController.text = initial.note;
    } else {
      _selectedDate = widget.defaultDate ?? DateTime.now();
      _startTime = const TimeOfDay(hour: 8, minute: 30);
      _endTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _durationMinutes =>
      AttendanceRecord.calculateDurationMinutes(_startTime, _endTime);

  bool get _isTimeValid => _durationMinutes > 0;

  Future<void> _submit() async {
    if (!_isTimeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış saati giriş saatinden önce veya eşit olamaz.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final duration = _durationMinutes;

      if (_isEditing) {
        final updated = widget.initialRecord!.copyWith(
          date: _selectedDate,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          endHour: _endTime.hour,
          endMinute: _endTime.minute,
          durationMinutes: duration,
          note: _noteController.text.trim(),
        );
        await repo.updateAttendance(
          widget.staffId,
          widget.initialRecord!.id!,
          updated,
        );
      } else {
        final record = AttendanceRecord(
          date: _selectedDate,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          endHour: _endTime.hour,
          endMinute: _endTime.minute,
          durationMinutes: duration,
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
        );
        await repo.addAttendance(widget.staffId, record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Çalışma kaydı güncellendi' : 'Giriş-çıkış kaydı eklendi',
            ),
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
    final duration = _durationMinutes;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModalHeader(
                title: _isEditing ? 'Giriş-Çıkış Düzenle' : 'Giriş-Çıkış Ekle',
              ),
              const SizedBox(height: 10),

            // Geçmiş ve gelecek tarih seçilebilir
            DatePickerField(
              label: 'Çalışma Tarihi',
              selectedDate: _selectedDate,
              onDateSelected: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TimePickerField(
                    label: 'Giriş Saati',
                    selectedTime: _startTime,
                    onTimeSelected: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TimePickerField(
                    label: 'Çıkış Saati',
                    selectedTime: _endTime,
                    onTimeSelected: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Süre Önizleme veya Hata Uyarısı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isTimeValid
                    ? AppTheme.primaryOrange.withValues(alpha: 0.12)
                    : AppTheme.errorColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isTimeValid
                      ? AppTheme.primaryOrange.withValues(alpha: 0.45)
                      : AppTheme.errorColor.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isTimeValid ? Icons.timer_outlined : Icons.error_outline,
                    color: _isTimeValid ? AppTheme.primaryOrange : AppTheme.errorColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isTimeValid
                          ? 'Toplam Çalışma: ${AppFormatters.formatDurationMinutes(duration)}'
                          : 'Çıkış saati giriş saatinden önce veya eşit olamaz.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isTimeValid ? AppTheme.primaryOrange : AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _noteController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Not / Açıklama (Opsiyonel)',
                hintText: 'Örn: Şantiye montajı, yarım gün vb.',
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
                    onPressed: (_isLoading || !_isTimeValid) ? null : _submit,
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
  );
  }
}
