import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String? id;
  final String name;
  final String phone;
  final String workSummary;
  final int photoCount;
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.workSummary = '',
    this.photoCount = 0,
    required this.createdAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Customer(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      workSummary: data['workSummary'] as String? ?? '',
      photoCount: (data['photoCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'name': name,
      'phone': phone,
      'workSummary': workSummary,
      'photoCount': photoCount,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? workSummary,
    int? photoCount,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      workSummary: workSummary ?? this.workSummary,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CustomerWorkPhoto {
  final String? id;
  final String url;
  final String path;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  const CustomerWorkPhoto({
    this.id,
    required this.url,
    required this.path,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  factory CustomerWorkPhoto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CustomerWorkPhoto(
      id: doc.id,
      url: data['url'] as String? ?? '',
      path: data['path'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: parseDate(data['date'] ?? data['createdAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'path': path,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class CustomerNote {
  final String? id;
  final String content;
  final DateTime date;
  final DateTime createdAt;

  const CustomerNote({
    this.id,
    required this.content,
    required this.date,
    required this.createdAt,
  });

  factory CustomerNote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CustomerNote(
      id: doc.id,
      content: data['content'] as String? ?? '',
      date: parseDate(data['date'] ?? data['createdAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'content': content,
      'date': Timestamp.fromDate(date),
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  CustomerNote copyWith({
    String? id,
    String? content,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return CustomerNote(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
