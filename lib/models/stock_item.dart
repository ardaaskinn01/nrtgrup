import 'package:cloud_firestore/cloud_firestore.dart';
import 'supplier.dart';

class StockItem {
  final String? id;
  final String name;
  final SupplierCategory category;
  final String supplierId;
  final String supplierName;
  final String quantityText;
  final String notes;
  final DateTime date;
  final DateTime createdAt;

  const StockItem({
    this.id,
    required this.name,
    this.category = SupplierCategory.pvc,
    this.supplierId = '',
    this.supplierName = '',
    required this.quantityText,
    this.notes = '',
    required this.date,
    required this.createdAt,
  });

  factory StockItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return StockItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: SupplierCategory.fromString(data['category'] as String?),
      supplierId: data['supplierId'] as String? ?? '',
      supplierName: data['supplierName'] as String? ?? '',
      quantityText: data['quantityText'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      date: parseDate(data['date'] ?? data['createdAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'name': name,
      'category': category.name,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'quantityText': quantityText,
      'notes': notes,
      'date': Timestamp.fromDate(date),
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  StockItem copyWith({
    String? id,
    String? name,
    SupplierCategory? category,
    String? supplierId,
    String? supplierName,
    String? quantityText,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      quantityText: quantityText ?? this.quantityText,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
