import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Alacaklar'),
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
          // Genel Toplam Alacak Hero Kartı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: HeroGradientCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const IconSquircle(
                    color: AppTheme.primaryOrangeLight,
                    icon: Icons.call_received_rounded,
                    size: 50,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GENEL TOPLAM ALACAK',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        totalAsync.when(
                          loading: () => const Text('...', style: TextStyle(color: Colors.white)),
                          error: (_, __) => const Text('-', style: TextStyle(color: Colors.white)),
                          data: (total) => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppFormatters.formatCurrency(total),
                              style: const TextStyle(
                                color: AppTheme.primaryOrangeLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  listAsync.maybeWhen(
                    data: (people) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${people.length} kişi',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Arama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: SearchFieldBar(
              hintText: 'Alacaklı ara...',
              onChanged: (val) => ref.read(receivableSearchQueryProvider.notifier).state = val,
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
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 96),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    final hasDebt = person.balance > 0;
                    final statusColor = hasDebt
                        ? AdaptiveColors.orange(context)
                        : AdaptiveColors.success(context);

                    return SurfaceCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
                      leftAccentColor: statusColor,
                      onTap: () {
                        if (person.id != null) {
                          context.push('${AppConstants.alacaklarRoute}/${person.id}');
                        }
                      },
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconSquircle(
                                color: statusColor,
                                text: person.name.isNotEmpty ? person.name[0].toUpperCase() : 'A',
                                size: 46,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (person.phone.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 13,
                                            color: AdaptiveColors.subText(context),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            person.phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AdaptiveColors.subText(context),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Detay ve tahsilat geçmişi',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AdaptiveColors.subText(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(person.balance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusPill(
                                    label: hasDebt ? 'Kalan Alacak' : 'Kapandı',
                                    color: statusColor,
                                    showDot: true,
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  size: 20,
                                  color: AdaptiveColors.subText(context),
                                ),
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
                        ],
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
