import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceRecord {
  final String? id;
  final DateTime date;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int durationMinutes;
  final String note;
  final DateTime createdAt;

  const AttendanceRecord({
    this.id,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.durationMinutes,
    this.note = '',
    required this.createdAt,
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  int get workedHours => durationMinutes ~/ 60;
  int get workedRemainingMinutes => durationMinutes % 60;

  String get startTimeFormatted =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endTimeFormatted =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  /// Çıkış girişten sonra olmalıdır; aksi halde <= 0 döner.
  static int calculateDurationMinutes(TimeOfDay start, TimeOfDay end) {
    final startTotal = start.hour * 60 + start.minute;
    final endTotal = end.hour * 60 + end.minute;
    return endTotal - startTotal;
  }

  factory AttendanceRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    int parseHour(dynamic timeStr, int fallback) {
      if (timeStr is String && timeStr.contains(':')) {
        return int.tryParse(timeStr.split(':')[0]) ?? fallback;
      }
      return fallback;
    }

    int parseMinute(dynamic timeStr, int fallback) {
      if (timeStr is String && timeStr.contains(':')) {
        return int.tryParse(timeStr.split(':')[1]) ?? fallback;
      }
      return fallback;
    }

    final startH = (data['startHour'] as num?)?.toInt() ?? parseHour(data['startTime'], 8);
    final startM = (data['startMinute'] as num?)?.toInt() ?? parseMinute(data['startTime'], 0);
    final endH = (data['endHour'] as num?)?.toInt() ?? parseHour(data['endTime'], 17);
    final endM = (data['endMinute'] as num?)?.toInt() ?? parseMinute(data['endTime'], 0);
    final duration = (data['durationMinutes'] as num?)?.toInt() ??
        ((endH * 60 + endM) - (startH * 60 + startM)).clamp(0, 1440);

    return AttendanceRecord(
      id: doc.id,
      date: parseDate(data['date']),
      startHour: startH,
      startMinute: startM,
      endHour: endH,
      endMinute: endM,
      durationMinutes: duration,
      note: data['note'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return {
      'date': Timestamp.fromDate(normalizedDate),
      'startTime': startTimeFormatted,
      'endTime': endTimeFormatted,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'durationMinutes': durationMinutes,
      'workedHours': workedHours,
      'workedMinutes': workedRemainingMinutes,
      'note': note,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? durationMinutes,
    String? note,
    DateTime? createdAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
