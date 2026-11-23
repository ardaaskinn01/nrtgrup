import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/attendance_record.dart';
import '../providers/attendance_providers.dart';
import '../providers/staff_providers.dart';
import '../repositories/attendance_repository.dart';
import '../widgets/add_attendance_modal.dart';
import '../widgets/month_year_picker_dialog.dart';
import '../widgets/worked_days_dialog.dart';

class StaffDetailScreen extends ConsumerWidget {
  final String staffId;

  const StaffDetailScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final selectedMonthYear = ref.watch(attendanceMonthYearProvider);
    final filteredRecordsAsync = ref.watch(filteredAttendanceProvider(staffId));
    final totalMinutesAsync = ref.watch(monthlyTotalMinutesProvider(staffId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Detayı'),
      ),
      floatingActionButton: AppFab(
        label: 'Giriş-Çıkış Ekle',
        onPressed: () => AddAttendanceModal.show(
          context,
          staffId: staffId,
        ),
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Bilgiler Yüklenemedi',
          subtitle: '$err',
        ),
        data: (staff) {
          if (staff == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Personel Bulunamadı',
              subtitle: 'Bu personel kaydı silinmiş olabilir.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
            children: [
              // Personel Bilgi Kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.16),
                            child: Text(
                              staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff.fullName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${staff.paymentType.displayName} • ${AppFormatters.formatCurrency(staff.wage)}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (staff.phone.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Telefon: ${staff.phone}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                      if (staff.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Not: ${staff.note}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Ay / Yıl Seçici
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          ref.read(attendanceMonthYearProvider.notifier).state = DateTime(
                            selectedMonthYear.year,
                            selectedMonthYear.month - 1,
                          );
                        },
                      ),
                      InkWell(
                        onTap: () async {
                          final picked = await MonthYearPickerDialog.show(
                            context,
                            selectedMonthYear,
                          );
                          if (picked != null) {
                            ref.read(attendanceMonthYearProvider.notifier).state = picked;
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                                color: AppTheme.primaryOrange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppFormatters.formatMonthYear(selectedMonthYear),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          ref.read(attendanceMonthYearProvider.notifier).state = DateTime(
                            selectedMonthYear.year,
                            selectedMonthYear.month + 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bu Ay Toplam Çalışılan Süre Kartı + Çalışılan Günler Butonu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.access_time_filled_rounded,
                              color: AppTheme.primaryOrange,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bu Ay Toplam Çalışılan Süre',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                totalMinutesAsync.when(
                                  loading: () => const Text('Hesaplanıyor...'),
                                  error: (_, __) => const Text('-'),
                                  data: (mins) => Text(
                                    AppFormatters.formatDurationMinutes(mins),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          final records = filteredRecordsAsync.value ?? [];
                          WorkedDaysDialog.show(
                            context,
                            staffName: staff.fullName,
                            monthYear: selectedMonthYear,
                            records: records,
                          );
                        },
                        icon: const Icon(Icons.event_note_outlined, size: 18),
                        label: const Text('Çalışılan Günleri Listele'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Giriş - Çıkış Kayıtları',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),

              filteredRecordsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Card(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Kayıtlar Yüklenemedi',
                    subtitle: '$err',
                  ),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return const Card(
                      child: EmptyState(
                        icon: Icons.history_toggle_off,
                        title: 'Bu Ayda Kayıt Yok',
                        subtitle: 'Sağ alttaki "Giriş-Çıkış Ekle" butonundan kayıt oluşturabilirsiniz.',
                      ),
                    );
                  }

                  return Column(
                    children: records
                        .map(
                          (rec) => _AttendanceCard(
                            record: rec,
                            onEdit: () => AddAttendanceModal.show(
                              context,
                              staffId: staffId,
                              initialRecord: rec,
                            ),
                            onDelete: () => _deleteRecord(context, ref, rec),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    AttendanceRecord record,
  ) async {
    if (record.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Kaydı Sil',
      message:
          '${AppFormatters.formatDate(record.date)} (${record.startTimeFormatted} - ${record.endTimeFormatted}) çalışma kaydını silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(attendanceRepositoryProvider).deleteAttendance(staffId, record.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalışma kaydı silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AttendanceCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final durationText = AppFormatters.formatDurationMinutes(record.durationMinutes);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${record.date.day}',
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${AppFormatters.formatDate(record.date)} (${AppFormatters.formatDayName(record.date)})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${record.startTimeFormatted} - ${record.endTimeFormatted}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$durationText çalıştı',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              if (record.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.note,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') onEdit();
            if (val == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
