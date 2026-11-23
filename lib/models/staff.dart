import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentPeriod {
  daily('daily', 'Günlük'),
  weekly('weekly', 'Haftalık'),
  monthly('monthly', 'Aylık');

  final String value;
  final String displayName;

  const PaymentPeriod(this.value, this.displayName);

  static PaymentPeriod fromString(String? value) {
    return PaymentPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentPeriod.monthly,
    );
  }
}

class StaffMember {
  final String? id;
  final String fullName;
  final String phone;
  final PaymentPeriod paymentType;
  final double wage;
  final String note;
  final DateTime createdAt;

  const StaffMember({
    this.id,
    required this.fullName,
    this.phone = '',
    required this.paymentType,
    required this.wage,
    this.note = '',
    required this.createdAt,
  });

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
      paymentType: PaymentPeriod.fromString(data['paymentType'] as String?),
      wage: (data['wage'] as num?)?.toDouble() ?? 0.0,
      note: data['note'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'fullName': fullName,
      'phone': phone,
      'paymentType': paymentType.value,
      'wage': wage,
      'note': note,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  StaffMember copyWith({
    String? id,
    String? fullName,
    String? phone,
    PaymentPeriod? paymentType,
    double? wage,
    String? note,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      paymentType: paymentType ?? this.paymentType,
      wage: wage ?? this.wage,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
