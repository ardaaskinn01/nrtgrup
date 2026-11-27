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
import '../../../models/customer.dart';
import '../providers/customer_providers.dart';
import '../repositories/customer_repository.dart';
import '../widgets/add_customer_modal.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final customersAsync = ref.watch(filteredCustomersProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Müşteriler'),
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
        label: 'Müşteri Ekle',
        onPressed: () => AddCustomerModal.show(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SearchFieldBar(
              hintText: 'Müşteri ara (isim, telefon, yapılan iş)...',
              onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).state = val,
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Müşteriler Yüklenemedi',
                subtitle: '$err',
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Kayıtlı Müşteri Yok',
                    subtitle: 'Sağ alttaki "Müşteri Ekle" butonundan yeni müşteri ekleyebilirsiniz.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 96),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerCard(
                      customer: customer,
                      onTap: () {
                        if (customer.id != null) {
                          context.push('${AppConstants.musterilerRoute}/${customer.id}');
                        }
                      },
                      onEdit: () => AddCustomerModal.show(context, initialCustomer: customer),
                      onDelete: () => _deleteCustomer(context, ref, customer),
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

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref, Customer customer) async {
    if (customer.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Müşteriyi Sil',
      message:
          '"${customer.name}" müşterisini, tüm iş fotoğraflarını ve iş notlarını kalıcı olarak silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(customerRepositoryProvider).deleteCustomer(customer.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri ve tüm iş kayıtları silindi')),
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

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                color: orange,
                imageUrl: customer.avatarUrl.isNotEmpty ? customer.avatarUrl : null,
                text: customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'M',
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (customer.phone.isNotEmpty) ...[
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: AdaptiveColors.subText(context),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              customer.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: AdaptiveColors.subText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AdaptiveColors.subText(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppFormatters.formatDate(customer.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AdaptiveColors.subText(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: '${customer.photoCount} Fotoğraf',
                color: orange,
                icon: Icons.photo_library_outlined,
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
          if (customer.workSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AdaptiveColors.cardBorder(context),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.handyman_outlined,
                    size: 14,
                    color: orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.workSummary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AdaptiveColors.subText(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
