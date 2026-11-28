import 'package:cloud_firestore/cloud_firestore.dart';

enum ChequeStatus {
  inHand('in_hand', 'Kasada'),
  given('given', 'Verildi');

  final String value;
  final String displayName;

  const ChequeStatus(this.value, this.displayName);

  static ChequeStatus fromString(String? val) {
    return ChequeStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChequeStatus.inHand,
    );
  }
}

/// Kasadaki fiziksel çekleri (tutar, kimden alındığı, kime verildiği ve durumu) takip eden model.
class Cheque {
  final String? id;
  final double amount;
  final String sourceName;
  final String? givenToName;
  final String note;
  final ChequeStatus status;
  final String? imageUrl;
  final String? imagePath;
  final DateTime date;
  final DateTime createdAt;

  const Cheque({
    this.id,
    required this.amount,
    this.sourceName = '',
    this.givenToName,
    this.note = '',
    this.status = ChequeStatus.inHand,
    this.imageUrl,
    this.imagePath,
    required this.date,
    required this.createdAt,
  });

  bool get isInHand => status == ChequeStatus.inHand;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory Cheque.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Cheque(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      sourceName: data['sourceName'] as String? ?? '',
      givenToName: data['givenToName'] as String?,
      note: data['note'] as String? ?? '',
      status: ChequeStatus.fromString(data['status'] as String?),
      imageUrl: data['imageUrl'] as String?,
      imagePath: data['imagePath'] as String?,
      date: parseDate(data['date'] ?? data['createdAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'amount': amount,
      'sourceName': sourceName,
      'givenToName': givenToName,
      'note': note,
      'status': status.value,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'date': Timestamp.fromDate(date),
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  Cheque copyWith({
    String? id,
    double? amount,
    String? sourceName,
    String? givenToName,
    bool clearGivenToName = false,
    String? note,
    ChequeStatus? status,
    String? imageUrl,
    String? imagePath,
    bool clearImage = false,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Cheque(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      sourceName: sourceName ?? this.sourceName,
      givenToName: clearGivenToName ? null : (givenToName ?? this.givenToName),
      note: note ?? this.note,
      status: status ?? this.status,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
