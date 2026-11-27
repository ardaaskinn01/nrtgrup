import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/todo_item.dart';
import '../repositories/todo_repository.dart';

final todosStreamProvider = StreamProvider<List<TodoItem>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(todoRepositoryProvider).watchTodos().map((list) {
    // Her güncellemede lokal bildirimleri sabah 09:00 için otomatik senkronize et
    NotificationService.instance.syncTodoNotifications(list);
    return list;
  }).handleError((_) => <TodoItem>[]);
});

enum TodoFilterMode { all, pending, overdue, completed }

final todoFilterModeProvider = StateProvider<TodoFilterMode>((ref) => TodoFilterMode.all);
final todoSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredTodosProvider = Provider<AsyncValue<List<TodoItem>>>((ref) {
  final todosAsync = ref.watch(todosStreamProvider);
  final mode = ref.watch(todoFilterModeProvider);
  final query = ref.watch(todoSearchQueryProvider).trim().toLowerCase();

  return todosAsync.whenData((list) {
    return list.where((t) {
      switch (mode) {
        case TodoFilterMode.all:
          break;
        case TodoFilterMode.pending:
          if (t.isCompleted) return false;
          break;
        case TodoFilterMode.overdue:
          if (!t.isOverdue) return false;
          break;
        case TodoFilterMode.completed:
          if (!t.isCompleted) return false;
          break;
      }
      if (query.isEmpty) return true;
      return t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
    }).toList();
  });
});

/// Ana sayfada gösterilecek bugün ve yarınki tamamlanmamış (veya gecikmiş) görevler
final upcomingDashboardTodosProvider = Provider<AsyncValue<List<TodoItem>>>((ref) {
  final todosAsync = ref.watch(todosStreamProvider);
  return todosAsync.whenData((list) {
    return list
        .where((t) => !t.isCompleted && (t.isToday || t.isTomorrow))
        .toList();
  });
});
