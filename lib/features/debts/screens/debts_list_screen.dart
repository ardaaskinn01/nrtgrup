import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/debt.dart';
import '../providers/debt_providers.dart';
import '../repositories/debt_repository.dart';
import '../widgets/add_debt_person_modal.dart';

class DebtsListScreen extends ConsumerWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final listAsync = ref.watch(filteredDebtsProvider);
    final totalAsync = ref.watch(totalDebtsProvider);

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Borçlar'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'Kişi Ekle',
        onPressed: () => AddDebtPersonModal.show(context),
      ),
      body: Column(
        children: [
          // Genel Toplam Borç Özeti
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Card(
              color: AppTheme.pureBlack,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.call_made_rounded,
                        color: AppTheme.errorColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Genel Toplam Borç',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          totalAsync.when(
                            loading: () => const Text('...', style: TextStyle(color: Colors.white)),
                            error: (_, __) => const Text('-', style: TextStyle(color: Colors.white)),
                            data: (total) => Text(
                              AppFormatters.formatCurrency(total),
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (val) => ref.read(debtSearchQueryProvider.notifier).state = val,
              decoration: const InputDecoration(
                hintText: 'Borçlu olunan kişi ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Borçlar Yüklenemedi',
                subtitle: '$err',
              ),
              data: (people) {
                if (people.isEmpty) {
                  return const EmptyState(
                    icon: Icons.credit_card_off_outlined,
                    title: 'Kayıtlı Borç Yok',
                    subtitle: 'Sağ alttaki "Kişi Ekle" butonundan borçlu olduğunuz kişiyi ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () {
                          if (person.id != null) {
                            context.push('${AppConstants.borclarRoute}/${person.id}');
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.16),
                          child: Text(
                            person.name.isNotEmpty ? person.name[0].toUpperCase() : 'B',
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          person.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: person.phone.isNotEmpty
                            ? Text(person.phone, style: Theme.of(context).textTheme.bodySmall)
                            : (person.note.isNotEmpty
                                ? Text(
                                    person.note,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppFormatters.formatCurrency(person.balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: person.balance > 0
                                        ? AppTheme.errorColor
                                        : AppTheme.successColor,
                                  ),
                                ),
                                Text(
                                  person.balance > 0 ? 'Kalan Borç' : 'Kapandı',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  AddDebtPersonModal.show(context, initialPerson: person);
                                } else if (val == 'delete') {
                                  _deletePerson(context, ref, person);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _deletePerson(
    BuildContext context,
    WidgetRef ref,
    DebtPerson person,
  ) async {
    if (person.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Borç Kaydını Sil',
      message:
          '"${person.name}" kişisini ve tüm borç/ödeme geçmişini silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(debtRepositoryProvider).deletePerson(person.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi ve borç kayıtları silindi')),
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
