import 'package:cloud_firestore/cloud_firestore.dart';

class StaffMember {
  final String? id;
  final String fullName;
  final String phone;
  /// Aylık net maaş (TL)
  final double wage;
  /// Maaş ödeme günü (1 - 31 arası, örn: her ayın 15'i)
  final int salaryDay;
  final String note;
  final String idCardUrl;
  final String idCardPath;
  final DateTime createdAt;

  const StaffMember({
    this.id,
    required this.fullName,
    this.phone = '',
    required this.wage,
    this.salaryDay = 1,
    this.note = '',
    this.idCardUrl = '',
    this.idCardPath = '',
    required this.createdAt,
  });

  /// Verilen referans tarihine göre güncel maaş döneminin başlangıç ve bitiş tarihini döndürür.
  /// Örneğin salaryDay = 15 ise:
  /// - Bugün 20 Kasım ise dönem: 15 Kasım -> 15 Aralık
  /// - Bugün 10 Kasım ise dönem: 15 Ekim -> 15 Kasım
  ({DateTime start, DateTime end}) currentSalaryCycle([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);

    DateTime clampDay(int year, int month, int day) {
      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, day > lastDayOfMonth ? lastDayOfMonth : day);
    }

    final thisMonthSalaryDate = clampDay(today.year, today.month, salaryDay);
    if (!today.isBefore(thisMonthSalaryDate)) {
      final nextMonthSalaryDate = clampDay(today.year, today.month + 1, salaryDay);
      return (start: thisMonthSalaryDate, end: nextMonthSalaryDate);
    } else {
      final prevMonthSalaryDate = clampDay(today.year, today.month - 1, salaryDay);
      return (start: prevMonthSalaryDate, end: thisMonthSalaryDate);
    }
  }

  factory StaffMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffMember(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      wage: (data['wage'] as num?)?.toDouble() ?? 0.0,
      salaryDay: ((data['salaryDay'] as num?)?.toInt() ?? 1).clamp(1, 31),
      note: data['note'] as String? ?? '',
      idCardUrl: data['idCardUrl'] as String? ?? '',
      idCardPath: data['idCardPath'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'fullName': fullName,
      'phone': phone,
      'wage': wage,
      'salaryDay': salaryDay,
      'note': note,
      'idCardUrl': idCardUrl,
      'idCardPath': idCardPath,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  StaffMember copyWith({
    String? id,
    String? fullName,
    String? phone,
    double? wage,
    int? salaryDay,
    String? note,
    String? idCardUrl,
    String? idCardPath,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      wage: wage ?? this.wage,
      salaryDay: salaryDay ?? this.salaryDay,
      note: note ?? this.note,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      idCardPath: idCardPath ?? this.idCardPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Personele yapılan tekil avans / ara ödeme kaydı
class StaffPayment {
  final String? id;
  final double amount;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  const StaffPayment({
    this.id,
    required this.amount,
    required this.date,
    this.note = '',
    required this.createdAt,
  });

  factory StaffPayment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffPayment(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: parseDate(data['date'] ?? data['createdAt']),
      note: data['note'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }
}
