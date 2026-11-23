import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/attendance_record.dart';

class WorkedDaysDialog extends StatelessWidget {
  final String staffName;
  final DateTime monthYear;
  final List<AttendanceRecord> records;

  const WorkedDaysDialog({
    super.key,
    required this.staffName,
    required this.monthYear,
    required this.records,
  });

  static Future<void> show(
    BuildContext context, {
    required String staffName,
    required DateTime monthYear,
    required List<AttendanceRecord> records,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => WorkedDaysDialog(
        staffName: staffName,
        monthYear: monthYear,
        records: records,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kayıtları gün bazında grupla (aynı güne birden fazla giriş-çıkış varsa topla)
    final Map<DateTime, int> minutesByDay = {};
    for (final r in records) {
      final dayKey = DateTime(r.date.year, r.date.month, r.date.day);
      minutesByDay[dayKey] = (minutesByDay[dayKey] ?? 0) + r.durationMinutes;
    }

    final sortedDays = minutesByDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final totalMinutes = records.fold<int>(0, (sum, r) => sum + r.durationMinutes);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Çalışılan Günler'),
          const SizedBox(height: 4),
          Text(
            '$staffName • ${AppFormatters.formatMonthYear(monthYear)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: sortedDays.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Seçili ayda çalışılan gün kaydı bulunmuyor.',
                  textAlign: TextAlign.center,
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sortedDays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final day = sortedDays[index];
                    final mins = minutesByDay[day] ?? 0;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                      title: Text(
                        AppFormatters.formatDate(day),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(AppFormatters.formatDayName(day)),
                      trailing: Text(
                        AppFormatters.formatDurationMinutes(mins),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        if (sortedDays.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${sortedDays.length} Gün • ${AppFormatters.formatDurationMinutes(totalMinutes)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
