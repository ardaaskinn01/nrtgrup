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
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/staff.dart';
import '../providers/staff_providers.dart';
import '../repositories/staff_repository.dart';
import '../widgets/add_staff_modal.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final staffAsync = ref.watch(filteredStaffProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Personel'),
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
        label: 'Personel Ekle',
        onPressed: () => AddStaffModal.show(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SearchFieldBar(
              hintText: 'Personel ara (isim, telefon, ödeme tipi)...',
              onChanged: (val) => ref.read(staffSearchQueryProvider.notifier).state = val,
            ),
          ),
          Expanded(
            child: staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Personel Listesi Yüklenemedi',
                subtitle: '$err',
              ),
              data: (staffList) {
                if (staffList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.badge_outlined,
                    title: 'Kayıtlı Personel Yok',
                    subtitle: 'Sağ alttaki "Personel Ekle" butonundan yeni personel ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 96),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return _StaffCard(
                      staff: staff,
                      onTap: () {
                        if (staff.id != null) {
                          context.push('${AppConstants.personelRoute}/${staff.id}');
                        }
                      },
                      onEdit: () => AddStaffModal.show(context, initialStaff: staff),
                      onDelete: () => _deleteStaff(context, ref, staff),
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

  Future<void> _deleteStaff(BuildContext context, WidgetRef ref, StaffMember staff) async {
    if (staff.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Personeli Sil',
      message:
          '"${staff.fullName}" adlı personeli ve tüm çalışma (puantaj) kayıtlarını kalıcı olarak silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(staffRepositoryProvider).deleteStaff(staff.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personel ve kayıtları silindi')),
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

class _StaffCard extends StatelessWidget {
  final StaffMember staff;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orange = AdaptiveColors.orange(context);

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      leftAccentColor: orange,
      onTap: onTap,
      child: Row(
        children: [
          IconSquircle(
            color: orange,
            text: staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'P',
            size: 46,
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
                        staff.fullName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: staff.paymentType.displayName,
                      color: orange,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      AppFormatters.formatCurrency(staff.wage),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      ' / ${staff.paymentType.displayName.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AdaptiveColors.subText(context),
                      ),
                    ),
                    if (staff.phone.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: AdaptiveColors.subText(context),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          staff.phone,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AdaptiveColors.subText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AdaptiveColors.subText(context),
            ),
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
