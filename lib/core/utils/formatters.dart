import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺ ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat _longDateFormatter = DateFormat('d MMMM yyyy', 'tr_TR');
  static final DateFormat _dayNameFormatter = DateFormat('EEEE', 'tr_TR');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy', 'tr_TR');
  static final DateFormat _timeFormatter = DateFormat('HH:mm', 'tr_TR');
  static final DateFormat _dateTimeFormatter = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  /// Örn: 1234.56 -> "₺ 1.234,56"
  static String formatCurrency(num amount) {
    return _currencyFormatter.format(amount);
  }

  /// Örn: "24.11.2026"
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Örn: "24 Kasım 2026"
  static String formatLongDate(DateTime date) {
    return _longDateFormatter.format(date);
  }

  /// Örn: "Salı"
  static String formatDayName(DateTime date) {
    return _dayNameFormatter.format(date);
  }

  /// Örn: "Kasım 2026"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  /// Örn: "14:30"
  static String formatTime(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }

  /// TimeOfDay -> "14:30"
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Örn: "24.11.2026 14:30"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Dakikayı "X saat Y dk" formatına çevirir
  static String formatDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0 dk';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '$hours saat $minutes dk';
    if (hours > 0) return '$hours saat';
    return '$minutes dk';
  }

  /// Kullanıcının girdiği tutar metnini double'a çevirir ("1.250,50" veya "1250.50")
  static double? parseAmount(String raw) {
    var cleaned = raw.trim().replaceAll('₺', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }
}
