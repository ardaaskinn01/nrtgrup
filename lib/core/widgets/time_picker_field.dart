import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class TimePickerField extends StatelessWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final String label;

  const TimePickerField({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
    this.label = 'Saat',
  });

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          AppFormatters.formatTimeOfDay(selectedTime),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
