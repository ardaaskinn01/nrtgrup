import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Tarih',
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          AppFormatters.formatDate(selectedDate),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
