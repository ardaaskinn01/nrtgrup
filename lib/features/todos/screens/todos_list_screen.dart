import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/todo_item.dart';
import '../providers/todo_providers.dart';
import '../repositories/todo_repository.dart';
import '../widgets/add_todo_modal.dart';

class TodosListScreen extends ConsumerWidget {
  const TodosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final todosAsync = ref.watch(filteredTodosProvider);
    final filterMode = ref.watch(todoFilterModeProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Yapılacaklar'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'Görev Ekle',
        onPressed: () => AddTodoModal.show(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFieldBar(
              hintText: 'Görev ara (başlık, açıklama)...',
              onChanged: (val) => ref.read(todoSearchQueryProvider.notifier).state = val,
            ),
          ),
          // Durum Filtre Çipleri
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChipItem(
                  label: 'Tümü',
                  selected: filterMode == TodoFilterMode.all,
                  onSelected: () =>
                      ref.read(todoFilterModeProvider.notifier).state = TodoFilterMode.all,
                ),
                _FilterChipItem(
                  label: 'Bekleyenler',
                  selected: filterMode == TodoFilterMode.pending,
                  onSelected: () =>
                      ref.read(todoFilterModeProvider.notifier).state = TodoFilterMode.pending,
                ),
                _FilterChipItem(
                  label: 'Zamanı Geçenler',
                  selected: filterMode == TodoFilterMode.overdue,
                  onSelected: () =>
                      ref.read(todoFilterModeProvider.notifier).state = TodoFilterMode.overdue,
                ),
                _FilterChipItem(
                  label: 'Tamamlananlar',
                  selected: filterMode == TodoFilterMode.completed,
                  onSelected: () =>
                      ref.read(todoFilterModeProvider.notifier).state = TodoFilterMode.completed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: todosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Görevler Yüklenemedi',
                subtitle: '$err',
              ),
              data: (todos) {
                if (todos.isEmpty) {
                  return const EmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'Görev Bulunamadı',
                    subtitle:
                        'Sağ alttaki "Görev Ekle" butonundan tarihli yapılacak iş ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 96),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return _TodoCard(
                      todo: todo,
                      onToggle: (val) => _toggleTodo(context, ref, todo, val),
                      onEdit: () => AddTodoModal.show(context, initialTodo: todo),
                      onDelete: () => _deleteTodo(context, ref, todo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodo(
    BuildContext context,
    WidgetRef ref,
    TodoItem todo,
    bool completed,
  ) async {
    if (todo.id == null) return;
    try {
      await ref.read(todoRepositoryProvider).toggleTodoStatus(todo.id!, completed);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme hatası: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _deleteTodo(BuildContext context, WidgetRef ref, TodoItem todo) async {
    if (todo.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Görevi Sil',
      message: '"${todo.title}" görevini silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(todoRepositoryProvider).deleteTodo(todo.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final TodoItem todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = todo.isOverdue;
    final isCompleted = todo.isCompleted;

    final Color accentColor;
    if (isCompleted) {
      accentColor = AdaptiveColors.success(context);
    } else if (isOverdue) {
      accentColor = AdaptiveColors.error(context);
    } else if (todo.isToday) {
      accentColor = AdaptiveColors.orange(context);
    } else {
      accentColor = theme.brightness == Brightness.dark
          ? const Color(0xFF60A5FA)
          : const Color(0xFF2563EB);
    }

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
      leftAccentColor: accentColor,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isCompleted,
                activeColor: AdaptiveColors.success(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (val) => onToggle(val ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      todo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? AdaptiveColors.subText(context)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Tarih Rozeti
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: accentColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                todo.isToday
                                    ? 'Bugün (${AppFormatters.formatDate(todo.dueDate)})'
                                    : (todo.isTomorrow
                                        ? 'Yarın (${AppFormatters.formatDate(todo.dueDate)})'
                                        : AppFormatters.formatDate(todo.dueDate)),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Zamanı Geçti Damgası
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ZAMANI GEÇTİ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isCompleted)
                          StatusPill(
                            label: 'Tamamlandı',
                            color: AdaptiveColors.success(context),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AdaptiveColors.subText(context)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
            ],
          ),
          if (todo.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  todo.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
