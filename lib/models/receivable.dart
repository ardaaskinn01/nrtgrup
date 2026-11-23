import 'package:cloud_firestore/cloud_firestore.dart';

enum ReceivableEntryType {
  alacakEkle('alacak_ekle', 'Alacak Ekle'),
  tahsilat('tahsilat', 'Alacaktan Düş (Tahsilat)');

  final String value;
  final String displayName;

  const ReceivableEntryType(this.value, this.displayName);

  static ReceivableEntryType fromString(String? value) {
    return ReceivableEntryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReceivableEntryType.alacakEkle,
    );
  }
}

class ReceivablePerson {
  final String? id;
  final String name;
  final String phone;
  final double balance;
  final DateTime createdAt;

  const ReceivablePerson({
    this.id,
    required this.name,
    this.phone = '',
    this.balance = 0,
    required this.createdAt,
  });

  factory ReceivablePerson.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReceivablePerson(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'name': name,
      'phone': phone,
      'balance': balance,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  ReceivablePerson copyWith({
    String? id,
    String? name,
    String? phone,
    double? balance,
    DateTime? createdAt,
  }) {
    return ReceivablePerson(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReceivableEntry {
  final String? id;
  final ReceivableEntryType type;
  final double amount;
  final DateTime date;
  final String description;
  final bool addedToIncome;
  final String? transactionId;
  final DateTime createdAt;

  const ReceivableEntry({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description = '',
    this.addedToIncome = false,
    this.transactionId,
    required this.createdAt,
  });

  bool get isAddition => type == ReceivableEntryType.alacakEkle;
  bool get isCollection => type == ReceivableEntryType.tahsilat;

  static double calculateBalance(List<ReceivableEntry> entries) {
    double total = 0;
    for (final e in entries) {
      if (e.isAddition) {
        total += e.amount;
      } else {
        total -= e.amount;
      }
    }
    return total;
  }

  factory ReceivableEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReceivableEntry(
      id: doc.id,
      type: ReceivableEntryType.fromString(data['type'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: parseDate(data['date'] ?? data['createdAt']),
      description: data['description'] as String? ?? '',
      addedToIncome: data['gelire_eklendi'] as bool? ?? false,
      transactionId: data['transactionId'] as String?,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'type': type.value,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'gelire_eklendi': addedToIncome,
      if (transactionId != null) 'transactionId': transactionId,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }
}
