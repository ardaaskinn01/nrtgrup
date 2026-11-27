import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/todo_item.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;

  TodoRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('todos');

  Stream<List<TodoItem>> watchTodos() {
    return _collection
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(TodoItem.fromFirestore).toList();
      list.sort((a, b) {
        // Tamamlanmamışlar üstte, tamamlananlar altta
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        final dateCmp = a.dueDateOnly.compareTo(b.dueDateOnly);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<String> addTodo(TodoItem todo) async {
    final docRef = await _collection.add(todo.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateTodo(String id, TodoItem todo) async {
    await _collection.doc(id).update(todo.toFirestore(isNew: false));
  }

  Future<void> toggleTodoStatus(String id, bool isCompleted) async {
    await _collection.doc(id).update({'isCompleted': isCompleted});
  }

  Future<void> deleteTodo(String id) async {
    await _collection.doc(id).delete();
  }
}

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TodoRepository(firestore);
});
