import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/mood_burst.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/receivable.dart';
import '../providers/receivable_providers.dart';
import '../repositories/receivable_repository.dart';
import '../widgets/add_receivable_entry_modal.dart';
import '../widgets/edit_receivable_person_dialog.dart';

class ReceivablesListScreen extends ConsumerWidget {
  const ReceivablesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final listAsync = ref.watch(filteredReceivablesProvider);
    final totalAsync = ref.watch(totalReceivablesProvider);

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Alacaklar'),
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
        label: 'Alacak Ekle',
        onPressed: () async {
          final res = await AddReceivableEntryModal.show(context);
          if (res != null && res.triggerHappyBurst && context.mounted) {
            MoodBurst.show(context, amount: res.amount, isIncome: true);
          }
        },
      ),
      body: Column(
        children: [
          // Genel Toplam Alacak Özeti
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
                        color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.call_received_rounded,
                        color: AppTheme.primaryOrange,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Genel Toplam Alacak',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          totalAsync.when(
                            loading: () => const Text('...', style: TextStyle(color: Colors.white)),
                            error: (_, __) => const Text('-', style: TextStyle(color: Colors.white)),
                            data: (total) => Text(
                              AppFormatters.formatCurrency(total),
                              style: const TextStyle(
                                color: AppTheme.primaryOrange,
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

          // Arama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (val) => ref.read(receivableSearchQueryProvider.notifier).state = val,
              decoration: const InputDecoration(
                hintText: 'Alacaklı ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Alacaklar Yüklenemedi',
                subtitle: '$err',
              ),
              data: (people) {
                if (people.isEmpty) {
                  return const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Kayıtlı Alacak Yok',
                    subtitle: 'Sağ alttaki "Alacak Ekle" butonundan yeni kişi ve alacak ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          if (person.id != null) {
                            context.push('${AppConstants.alacaklarRoute}/${person.id}');
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            person.name.isNotEmpty ? person.name[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          person.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: person.phone.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 13,
                                      color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      person.phone,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                    color: person.balance > 0
                                        ? AppTheme.primaryOrange
                                        : AppTheme.successColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (person.balance > 0 ? AppTheme.primaryOrange : AppTheme.successColor)
                                        .withValues(alpha: isDark ? 0.18 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    person.balance > 0 ? 'Kalan Alacak' : 'Kapandı',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: person.balance > 0
                                          ? AppTheme.primaryOrange
                                          : AppTheme.successColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  EditReceivablePersonDialog.show(context, person);
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
    ReceivablePerson person,
  ) async {
    if (person.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Alacaklı Kişiyi Sil',
      message:
          '"${person.name}" kişisini ve tüm alacak/tahsilat geçmişini silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(receivableRepositoryProvider).deletePerson(person.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi ve alacak kayıtları silindi')),
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
