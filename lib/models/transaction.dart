import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  income('income', 'Gelir'),
  expense('expense', 'Gider');

  final String value;
  final String displayName;

  const TransactionType(this.value, this.displayName);

  static TransactionType fromString(String? value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.income,
    );
  }
}

enum PaymentMethod {
  cash('cash', 'Nakit'),
  checkNote('check_note', 'Çek');

  final String value;
  final String displayName;

  const PaymentMethod(this.value, this.displayName);

  static PaymentMethod fromString(String? value) {
    if (value == 'check_note' || value == 'check') {
      return PaymentMethod.checkNote;
    }
    return PaymentMethod.cash;
  }
}

class TransactionCategories {
  static const List<String> incomeCategories = [
    'İş / Satış',
    'Tahsilat',
    'Hizmet Bedeli',
    'Alacak Tahsilatı',
    'Diğer Gelir',
  ];

  static const List<String> expenseCategories = [
    'Malzeme / Hammadde',
    'Personel / İşçilik',
    'Kira / Aidat',
    'Fatura / Gider',
    'Yakıt / Ulaşım',
    'Borç Ödemesi',
    'Diğer Gider',
  ];

  static List<String> forType(TransactionType type) {
    return type == TransactionType.income ? incomeCategories : expenseCategories;
  }
}

class AppTransaction {
  final String? id;
  final double amount;
  final TransactionType type;
  final String category;
  final PaymentMethod paymentMethod;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final String? sourceType;
  final String? sourceId;
  final String? sourceParentId;

  const AppTransaction({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.paymentMethod = PaymentMethod.cash,
    required this.description,
    required this.date,
    required this.createdAt,
    this.sourceType,
    this.sourceId,
    this.sourceParentId,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  factory AppTransaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppTransaction.fromMap(data, id: doc.id);
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final type = TransactionType.fromString(map['type'] as String?);
    final defaultCat = TransactionCategories.forType(type).first;

    return AppTransaction(
      id: id ?? map['id'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: type,
      category: (map['category'] as String?)?.isNotEmpty == true
          ? map['category'] as String
          : defaultCat,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
      description: map['description'] as String? ?? '',
      date: parseDate(map['date'] ?? map['createdAt']),
      createdAt: parseDate(map['createdAt']),
      sourceType: map['sourceType'] as String?,
      sourceId: map['sourceId'] as String?,
      sourceParentId: map['sourceParentId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'amount': amount,
      'type': type.value,
      'category': category,
      'paymentMethod': paymentMethod.value,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      if (sourceType != null) 'sourceType': sourceType,
      if (sourceId != null) 'sourceId': sourceId,
      if (sourceParentId != null) 'sourceParentId': sourceParentId,
    };
  }

  AppTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    PaymentMethod? paymentMethod,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    String? sourceType,
    String? sourceId,
    String? sourceParentId,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceParentId: sourceParentId ?? this.sourceParentId,
    );
  }
}
