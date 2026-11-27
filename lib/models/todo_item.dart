import 'package:cloud_firestore/cloud_firestore.dart';

class TodoItem {
  final String? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const TodoItem({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Sadece gün bazında karşılaştırma için saat/dakika sıfırlanmış tarih
  DateTime get dueDateOnly => DateTime(dueDate.year, dueDate.month, dueDate.day);

  /// Bugünün tarihine göre zamanı geçti mi? (Tamamlanmamış ve günü geçmişse)
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    return dueDateOnly.isBefore(todayOnly);
  }

  /// Bugün mü?
  bool get isToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// Yarın mı?
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate.year == tomorrow.year &&
        dueDate.month == tomorrow.month &&
        dueDate.day == tomorrow.day;
  }

  factory TodoItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TodoItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dueDate: parseDate(data['dueDate'] ?? data['createdAt']),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDateOnly),
      'isCompleted': isCompleted,
      'createdAt': isNew ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
