import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtEntryType {
  borcEkle('borc_ekle', 'Borç Ekle'),
  odeme('odeme', 'Borçtan Düş (Ödeme)');

  final String value;
  final String displayName;

  const DebtEntryType(this.value, this.displayName);

  static DebtEntryType fromString(String? value) {
    return DebtEntryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DebtEntryType.borcEkle,
    );
  }
}

class DebtPerson {
  final String? id;
  final String name;
  final String phone;
  final double balance;
  final String note;
  final DateTime createdAt;

  const DebtPerson({
    this.id,
    required this.name,
    this.phone = '',
    this.balance = 0,
    this.note = '',
    required this.createdAt,
  });

  factory DebtPerson.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return DebtPerson(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      note: data['note'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'name': name,
      'phone': phone,
      'balance': balance,
      'note': note,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  DebtPerson copyWith({
    String? id,
    String? name,
    String? phone,
    double? balance,
    String? note,
    DateTime? createdAt,
  }) {
    return DebtPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DebtEntry {
  final String? id;
  final DebtEntryType type;
  final double amount;
  final DateTime date;
  final String description;
  final bool addedToLedger;
  final String? transactionId;
  final DateTime createdAt;

  const DebtEntry({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description = '',
    this.addedToLedger = false,
    this.transactionId,
    required this.createdAt,
  });

  bool get isAddition => type == DebtEntryType.borcEkle;
  bool get isPayment => type == DebtEntryType.odeme;

  static double calculateBalance(List<DebtEntry> entries) {
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

  factory DebtEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return DebtEntry(
      id: doc.id,
      type: DebtEntryType.fromString(data['type'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: parseDate(data['date'] ?? data['createdAt']),
      description: data['description'] as String? ?? '',
      addedToLedger: data['gidere_eklendi'] as bool? ?? false,
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
      'gidere_eklendi': addedToLedger,
      if (transactionId != null) 'transactionId': transactionId,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }
}
