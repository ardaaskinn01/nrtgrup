import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
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

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Müşteriler'),
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
        label: 'Müşteri Ekle',
        onPressed: () => AddCustomerModal.show(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).state = val,
              decoration: const InputDecoration(
                hintText: 'Müşteri ara (isim, telefon, yapılan iş)...',
                prefixIcon: Icon(Icons.search),
              ),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
    final isDark = theme.brightness == Brightness.dark;

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
        onTap: onTap,
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
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'M',
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                    : AppTheme.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 13,
                    color: isDark ? AppTheme.primaryOrangeLight : AppTheme.primaryOrangeDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.photoCount}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.primaryOrangeLight : AppTheme.primaryOrangeDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (customer.workSummary.isNotEmpty)
                Text(
                  customer.workSummary,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
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
      ),
    );
  }
}
