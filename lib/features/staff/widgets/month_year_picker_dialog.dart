import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const MonthYearPickerDialog({super.key, required this.initialDate});

  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showDialog<DateTime>(
      context: context,
      builder: (_) => MonthYearPickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  static const List<String> _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ay ve Yıl Seçin'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yıl Seçici
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _year--),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final m = index + 1;
                final isSelected = m == _month;
                return InkWell(
                  onTap: () => setState(() => _month = m),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryOrange
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      _months[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.pureWhite
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                );
              },
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
          onPressed: () => Navigator.pop(context, DateTime(_year, _month)),
          child: const Text('Seç'),
        ),
      ],
    );
  }
}
