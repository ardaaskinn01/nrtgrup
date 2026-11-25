import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/mood_burst.dart';
import '../../../models/receivable.dart';
import '../providers/receivable_providers.dart';
import '../repositories/receivable_repository.dart';
import '../widgets/add_receivable_entry_modal.dart';
import '../widgets/edit_receivable_person_dialog.dart';

class ReceivableDetailScreen extends ConsumerWidget {
  final String personId;

  const ReceivableDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(receivableByIdProvider(personId));
    final entriesAsync = ref.watch(receivableEntriesProvider(personId));

    return personAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Alacak Detayı')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Alacak Detayı')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Bilgiler Yüklenemedi',
          subtitle: '$err',
        ),
      ),
      data: (person) {
        if (person == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Alacak Detayı')),
            body: const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Kişi Bulunamadı',
              subtitle: 'Bu kayıt silinmiş olabilir.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(person.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => EditReceivablePersonDialog.show(context, person),
              ),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'İşlem Ekle',
            onPressed: () async {
              final res = await AddReceivableEntryModal.show(
                context,
                fixedPerson: person,
              );
              if (res != null && res.triggerHappyBurst && context.mounted) {
                MoodBurst.show(context, amount: res.amount, isIncome: true);
              }
            },
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 96),
            children: [
              // Kalan Bakiye Hero Kartı
              HeroGradientCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'KALAN NET ALACAK',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        StatusPill(
                          label: person.balance > 0 ? 'Aktif Alacak' : 'Kapandı',
                          color: person.balance > 0
                              ? AppTheme.primaryOrangeLight
                              : const Color(0xFF4ADE80),
                          showDot: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppFormatters.formatCurrency(person.balance),
                        style: const TextStyle(
                          color: AppTheme.primaryOrangeLight,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    if (person.phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: Colors.white60),
                          const SizedBox(width: 6),
                          Text(
                            person.phone,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => AddReceivableEntryModal.show(
                              context,
                              fixedPerson: person,
                              initialType: ReceivableEntryType.alacakEkle,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Alacak Ekle'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4ADE80),
                              backgroundColor: AppTheme.successColor.withValues(alpha: 0.14),
                              side: const BorderSide(color: Color(0xFF22C55E), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              final res = await AddReceivableEntryModal.show(
                                context,
                                fixedPerson: person,
                                initialType: ReceivableEntryType.tahsilat,
                              );
                              if (res != null && res.triggerHappyBurst && context.mounted) {
                                MoodBurst.show(context, amount: res.amount, isIncome: true);
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Tahsilat Düş'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Hareket Geçmişi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Hareketler Yüklenemedi',
                  subtitle: '$err',
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const SurfaceCard(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz Hareket Yok',
                        subtitle: 'Yukarıdaki butonlardan alacak ekleyebilir veya tahsilat düşebilirsiniz.',
                      ),
                    );
                  }

                  return Column(
                    children: entries.map((entry) {
                      final isAdd = entry.isAddition;
                      final color = isAdd
                          ? AdaptiveColors.orange(context)
                          : AdaptiveColors.success(context);
                      return SurfaceCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        leftAccentColor: color,
                        child: Row(
                          children: [
                            IconSquircle(
                              color: color,
                              size: 42,
                              icon: isAdd ? Icons.add_rounded : Icons.check_rounded,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.description.isNotEmpty
                                        ? entry.description
                                        : entry.type.displayName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        AppFormatters.formatDate(entry.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AdaptiveColors.subText(context),
                                        ),
                                      ),
                                      if (entry.addedToIncome)
                                        StatusPill(
                                          label: 'Gelire Eklendi',
                                          color: AdaptiveColors.success(context),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isAdd ? '+' : '-'}${AppFormatters.formatCurrency(entry.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: color,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: AdaptiveColors.error(context),
                                size: 20,
                              ),
                              onPressed: () => _deleteEntry(context, ref, entry),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    ReceivableEntry entry,
  ) async {
    bool deleteLinked = false;

    if (entry.addedToIncome && entry.transactionId != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hareketi Sil'),
          content: const Text(
            'Bu tahsilat Gelir Gider kasasına da eklenmiş. Bağlı gelir kaydı da silinsin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'only_entry'),
              child: const Text('Sadece Buradan Sil'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, 'both'),
              child: const Text('İkisini de Sil'),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') return;
      deleteLinked = choice == 'both';
    } else {
      final confirmed = await ConfirmDeleteDialog.show(
        context,
        title: 'Hareketi Sil',
        message: 'Bu alacak/tahsilat hareketini silmek istediğinize emin misiniz? Bakiye otomatik güncellenecektir.',
      );
      if (!confirmed) return;
    }

    try {
      await ref.read(receivableRepositoryProvider).deleteEntry(
            personId: personId,
            entry: entry,
            deleteLinkedTransaction: deleteLinked,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hareket silindi ve bakiye güncellendi')),
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
