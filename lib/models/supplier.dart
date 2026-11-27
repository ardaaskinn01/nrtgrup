import 'package:cloud_firestore/cloud_firestore.dart';

enum SupplierCategory {
  pvc,
  cam,
  aksesuar,
  diger;

  String get displayName {
    switch (this) {
      case SupplierCategory.pvc:
        return 'PVC';
      case SupplierCategory.cam:
        return 'Cam';
      case SupplierCategory.aksesuar:
        return 'Aksesuar';
      case SupplierCategory.diger:
        return 'Diğer';
    }
  }

  static SupplierCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pvc':
        return SupplierCategory.pvc;
      case 'cam':
        return SupplierCategory.cam;
      case 'aksesuar':
        return SupplierCategory.aksesuar;
      default:
        return SupplierCategory.diger;
    }
  }
}

class Supplier {
  final String? id;
  final String name;
  final SupplierCategory category;
  final String phone;
  final String notes;
  final DateTime createdAt;

  const Supplier({
    this.id,
    required this.name,
    this.category = SupplierCategory.diger,
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  factory Supplier.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Supplier(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: SupplierCategory.fromString(data['category'] as String?),
      phone: data['phone'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'name': name,
      'category': category.name,
      'phone': phone,
      'notes': notes,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    SupplierCategory? category,
    String? phone,
    String? notes,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
