import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/cheque.dart';
import '../repositories/cheque_repository.dart';
import '../widgets/add_cheque_modal.dart';

enum ChequeFilter { all, inHand, given }

class ChequesScreen extends ConsumerStatefulWidget {
  const ChequesScreen({super.key});

  @override
  ConsumerState<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends ConsumerState<ChequesScreen> {
  ChequeFilter _filter = ChequeFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chequesAsync = ref.watch(chequesStreamProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çeklerimiz'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFab(
        onPressed: () => AddChequeModal.show(context),
        label: 'Çek Ekle',
        icon: Icons.add_rounded,
      ),
      body: chequesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Çekler Yüklenemedi',
          subtitle: '$err',
        ),
        data: (allCheques) {
          final inHand = allCheques.where((c) => c.isInHand).toList();
          final given = allCheques.where((c) => !c.isInHand).toList();
          final inHandTotal = inHand.fold<double>(0.0, (s, c) => s + c.amount);
          final givenTotal = given.fold<double>(0.0, (s, c) => s + c.amount);

          final filtered = switch (_filter) {
            ChequeFilter.all => allCheques,
            ChequeFilter.inHand => inHand,
            ChequeFilter.given => given,
          };

          return Column(
            children: [
              // Özet Kartı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: HeroGradientCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KASADAKİ ÇEKLER',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatCurrency(inHandTotal),
                              style: const TextStyle(
                                color: AppTheme.primaryOrangeLight,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${inHand.length} adet çek',
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 46,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERİLEN ÇEKLER',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatCurrency(givenTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${given.length} adet çek',
                              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filtre Chipleri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tümü (${allCheques.length})',
                      selected: _filter == ChequeFilter.all,
                      onTap: () => setState(() => _filter = ChequeFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Kasada (${inHand.length})',
                      selected: _filter == ChequeFilter.inHand,
                      onTap: () => setState(() => _filter = ChequeFilter.inHand),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Verildi (${given.length})',
                      selected: _filter == ChequeFilter.given,
                      onTap: () => setState(() => _filter = ChequeFilter.given),
                    ),
                  ],
                ),
              ),

              // Çek Listesi
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Çek Bulunamadı',
                        subtitle: 'Sağ alttaki "Çek Ekle" butonundan yeni çek ekleyebilirsiniz.',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset + 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final cheque = filtered[index];
                          return _ChequeCard(
                            cheque: cheque,
                            theme: theme,
                            onEdit: () => AddChequeModal.show(context, initialCheque: cheque),
                            onDelete: () => _deleteCheque(context, cheque),
                            onImageTap: cheque.hasImage
                                ? () => _showImagePreview(context, cheque.imageUrl!)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCheque(BuildContext context, Cheque cheque) async {
    if (cheque.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Çeki Sil',
      message:
          '${AppFormatters.formatCurrency(cheque.amount)} tutarındaki çeki silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(chequeRepositoryProvider).deleteCheque(cheque.id!);
      if (cheque.imagePath != null && cheque.imagePath!.isNotEmpty) {
        try {
          await ref.read(supabaseStorageServiceProvider).deleteWorkPhoto(cheque.imagePath!);
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çek silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppTheme.primaryOrange : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ChequeCard extends StatelessWidget {
  final Cheque cheque;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onImageTap;

  const _ChequeCard({
    required this.cheque,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = cheque.isInHand
        ? AdaptiveColors.orange(context)
        : AdaptiveColors.subText(context);

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      leftAccentColor: statusColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Görsel Thumbnail veya İkon
          GestureDetector(
            onTap: onImageTap ?? onEdit,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: cheque.hasImage
                    ? Image.network(
                        cheque.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.receipt_long_rounded,
                          color: statusColor,
                        ),
                      )
                    : Icon(
                        Icons.receipt_long_rounded,
                        color: statusColor,
                        size: 26,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppFormatters.formatCurrency(cheque.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cheque.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (cheque.sourceName.isNotEmpty)
                  Text(
                    'Alınan: ${cheque.sourceName}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                if (!cheque.isInHand && (cheque.givenToName?.isNotEmpty ?? false))
                  Text(
                    'Verilen: ${cheque.givenToName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AdaptiveColors.error(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  'Tarih: ${AppFormatters.formatDate(cheque.date)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (cheque.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      cheque.note,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AdaptiveColors.subText(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Düzenle',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: AdaptiveColors.error(context)),
                tooltip: 'Sil',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
