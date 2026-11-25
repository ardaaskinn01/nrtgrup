import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 96),
            children: [
              // Personel Bilgi Kartı
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                leftAccentColor: AdaptiveColors.orange(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconSquircle(
                          color: AdaptiveColors.orange(context),
                          text: staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'P',
                          size: 52,
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
                              const SizedBox(height: 5),
                              StatusPill(
                                label: '${staff.paymentType.displayName} • ${AppFormatters.formatCurrency(staff.wage)}',
                                color: AdaptiveColors.orange(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (staff.phone.isNotEmpty || staff.note.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      if (staff.phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: AdaptiveColors.subText(context)),
                            const SizedBox(width: 6),
                            Text(
                              staff.phone,
                              style: TextStyle(fontSize: 12.5, color: AdaptiveColors.subText(context)),
                            ),
                          ],
                        ),
                      if (staff.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Not: ${staff.note}',
                          style: TextStyle(fontSize: 12.5, color: AdaptiveColors.subText(context)),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Ay / Yıl Seçici
              SurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
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
              const SizedBox(height: 12),

              // Bu Ay Toplam Çalışılan Süre Hero Kartı
              HeroGradientCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const IconSquircle(
                          color: AppTheme.primaryOrangeLight,
                          icon: Icons.access_time_filled_rounded,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BU AY TOPLAM ÇALIŞILAN SÜRE',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              totalMinutesAsync.when(
                                loading: () => const Text('Hesaplanıyor...', style: TextStyle(color: Colors.white)),
                                error: (_, __) => const Text('-', style: TextStyle(color: Colors.white)),
                                data: (mins) => Text(
                                  AppFormatters.formatDurationMinutes(mins),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryOrangeLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.pureWhite,
                        side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.55)),
                        backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final records = filteredRecordsAsync.value ?? [];
                        WorkedDaysDialog.show(
                          context,
                          staffName: staff.fullName,
                          monthYear: selectedMonthYear,
                          records: records,
                        );
                      },
                      icon: const Icon(Icons.event_note_outlined, size: 18, color: AppTheme.primaryOrangeLight),
                      label: const Text('Çalışılan Günleri Listele'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Giriş - Çıkış Kayıtları',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              filteredRecordsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => SurfaceCard(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Kayıtlar Yüklenemedi',
                    subtitle: '$err',
                  ),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return const SurfaceCard(
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
    final orange = AdaptiveColors.orange(context);

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      leftAccentColor: orange,
      onTap: onEdit,
      child: Row(
        children: [
          IconSquircle(
            color: orange,
            text: '${record.date.day}',
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppFormatters.formatDate(record.date)} (${AppFormatters.formatDayName(record.date)})',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${record.startTimeFormatted} - ${record.endTimeFormatted}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AdaptiveColors.subText(context),
                      ),
                    ),
                    StatusPill(
                      label: '$durationText çalıştı',
                      color: orange,
                    ),
                  ],
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    record.note,
                    style: TextStyle(
                      fontSize: 12,
                      color: AdaptiveColors.subText(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AdaptiveColors.subText(context),
            ),
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
        ],
      ),
    );
  }
}
