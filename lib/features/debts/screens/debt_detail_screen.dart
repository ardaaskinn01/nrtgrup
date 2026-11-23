import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/mood_burst.dart';
import '../../../models/debt.dart';
import '../providers/debt_providers.dart';
import '../repositories/debt_repository.dart';
import '../widgets/add_debt_entry_modal.dart';
import '../widgets/add_debt_person_modal.dart';

class DebtDetailScreen extends ConsumerWidget {
  final String personId;

  const DebtDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(debtByIdProvider(personId));
    final entriesAsync = ref.watch(debtEntriesProvider(personId));

    return personAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Borç Detayı')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Borç Detayı')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Bilgiler Yüklenemedi',
          subtitle: '$err',
        ),
      ),
      data: (person) {
        if (person == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Borç Detayı')),
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
                onPressed: () => AddDebtPersonModal.show(context, initialPerson: person),
              ),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'İşlem Ekle',
            onPressed: () async {
              final res = await AddDebtEntryModal.show(context, person: person);
              if (res != null && res.triggerBurst && context.mounted) {
                MoodBurst.show(context, amount: res.amount, isIncome: res.isIncome);
              }
            },
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
            children: [
              // Kalan Borç Kartı
              Card(
                color: AppTheme.pureBlack,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kalan Net Borç',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.formatCurrency(person.balance),
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (person.phone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Telefon: ${person.phone}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                      if (person.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          person.note,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final res = await AddDebtEntryModal.show(
                                  context,
                                  person: person,
                                  initialType: DebtEntryType.borcEkle,
                                );
                                if (res != null && res.triggerBurst && context.mounted) {
                                  MoodBurst.show(context, amount: res.amount, isIncome: res.isIncome);
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Borç Ekle'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.pureWhite,
                                side: const BorderSide(color: AppTheme.successColor),
                              ),
                              onPressed: () async {
                                final res = await AddDebtEntryModal.show(
                                  context,
                                  person: person,
                                  initialType: DebtEntryType.odeme,
                                );
                                if (res != null && res.triggerBurst && context.mounted) {
                                  MoodBurst.show(context, amount: res.amount, isIncome: res.isIncome);
                                }
                              },
                              icon: const Icon(Icons.check, size: 18, color: AppTheme.successColor),
                              label: const Text('Ödeme Düş'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Hareket Geçmişi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),

              entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Hareketler Yüklenemedi',
                  subtitle: '$err',
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Card(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz Hareket Yok',
                        subtitle: 'Yukarıdaki butonlardan borç ekleyebilir veya ödeme düşebilirsiniz.',
                      ),
                    );
                  }

                  return Column(
                    children: entries.map((entry) {
                      final isAdd = entry.isAddition;
                      final color = isAdd ? AppTheme.errorColor : AppTheme.successColor;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
                              color: color,
                            ),
                          ),
                          title: Text(
                            entry.description.isNotEmpty
                                ? entry.description
                                : entry.type.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                AppFormatters.formatDate(entry.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (entry.addedToLedger)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAdd ? 'Gelire Eklendi' : 'Gidere Eklendi',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isAdd ? '+' : '-'}${AppFormatters.formatCurrency(entry.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                                onPressed: () => _deleteEntry(context, ref, entry),
                              ),
                            ],
                          ),
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
    DebtEntry entry,
  ) async {
    bool deleteLinked = false;

    if (entry.addedToLedger && entry.transactionId != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hareketi Sil'),
          content: const Text(
            'Bu işlem Gelir Gider kasasına da eklenmiş. Bağlı kasa kaydı da silinsin mi?',
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
        message: 'Bu borç/ödeme hareketini silmek istediğinize emin misiniz? Bakiye otomatik güncellenecektir.',
      );
      if (!confirmed) return;
    }

    try {
      await ref.read(debtRepositoryProvider).deleteEntry(
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
