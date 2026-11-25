import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/mood_burst.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/transaction.dart';
import '../../auth/services/auth_service.dart';
import '../../customers/widgets/add_customer_modal.dart';
import '../../debts/providers/debt_providers.dart';
import '../../debts/widgets/add_debt_person_modal.dart';
import '../../receivables/providers/receivable_providers.dart';
import '../../receivables/widgets/add_receivable_entry_modal.dart';
import '../../staff/providers/attendance_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/widgets/add_transaction_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final user = ref.watch(currentUserProvider).value;
    final balanceAsync = ref.watch(overallBalanceProvider);
    final totalReceivablesAsync = ref.watch(totalReceivablesProvider);
    final totalDebtsAsync = ref.watch(totalDebtsProvider);
    final todayStaffCountAsync = ref.watch(todayCheckedInStaffCountProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menü',
                ),
              ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          ref.invalidate(transactionsStreamProvider);
          ref.invalidate(receivablesStreamProvider);
          ref.invalidate(debtsStreamProvider);
          ref.invalidate(todayCheckedInStaffCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Karşılama Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.pureBlack, Color(0xFF222222)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryOrange, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.pureWhite,
                        child: ClipOval(
                          child: Image.asset(
                            AppConstants.anaLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hoş Geldiniz,',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            user?.email != null
                                ? (user!.email!.contains('@')
                                    ? user.email!.split('@').first
                                    : user.email!)
                                : 'Kullanıcı',
                            style: const TextStyle(
                              color: AppTheme.pureWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),

              const SizedBox(height: 24),

              Text(
                'Genel Durum',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              balanceAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Özet yüklenemedi: $err'),
                  ),
                ),
                data: (summary) => LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 3
                        : (constraints.maxWidth > 520 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.1,
                      children: [
                        _StatCard(
                          title: 'Kasa Bakiyesi',
                          value: AppFormatters.formatCurrency(summary.netBalance),
                          subtitle: 'Toplam Net Kasa',
                          icon: Icons.account_balance_wallet,
                          color: AppTheme.primaryOrange,
                          onTap: () => context.go(AppConstants.gelirGiderRoute),
                        ),
                        _StatCard(
                          title: 'Bu Ay Gelir',
                          value: AppFormatters.formatCurrency(summary.monthIncome),
                          subtitle: 'Bugün: ${AppFormatters.formatCurrency(summary.todayIncome)}',
                          icon: Icons.arrow_downward_rounded,
                          color: AppTheme.successColor,
                          onTap: () => context.go(AppConstants.gelirGiderRoute),
                        ),
                        _StatCard(
                          title: 'Bu Ay Gider',
                          value: AppFormatters.formatCurrency(summary.monthExpense),
                          subtitle: 'Bugün: ${AppFormatters.formatCurrency(summary.todayExpense)}',
                          icon: Icons.arrow_upward_rounded,
                          color: AppTheme.errorColor,
                          onTap: () => context.go(AppConstants.gelirGiderRoute),
                        ),
                        _StatCard(
                          title: 'Toplam Alacak',
                          value: totalReceivablesAsync.when(
                            data: AppFormatters.formatCurrency,
                            loading: () => '...',
                            error: (_, __) => '-',
                          ),
                          subtitle: 'Alacak Defteri',
                          icon: Icons.call_received_rounded,
                          color: AppTheme.warningColor,
                          onTap: () => context.go(AppConstants.alacaklarRoute),
                        ),
                        _StatCard(
                          title: 'Toplam Borç',
                          value: totalDebtsAsync.when(
                            data: AppFormatters.formatCurrency,
                            loading: () => '...',
                            error: (_, __) => '-',
                          ),
                          subtitle: 'Borç Defteri',
                          icon: Icons.call_made_rounded,
                          color: AppTheme.errorColor,
                          onTap: () => context.go(AppConstants.borclarRoute),
                        ),
                        _StatCard(
                          title: 'Bugün Çalışan Personel',
                          value: todayStaffCountAsync.when(
                            data: (count) => '$count Kişi',
                            loading: () => '...',
                            error: (_, __) => '0 Kişi',
                          ),
                          subtitle: 'Puantaj Kayıtları',
                          icon: Icons.badge_outlined,
                          color: AppTheme.primaryOrange,
                          onTap: () => context.go(AppConstants.personelRoute),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Hızlı İşlemler',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Yeni Gelir',
                    color: AppTheme.successColor,
                    onTap: () async {
                      final result = await AddTransactionModal.show(
                        context,
                        initialType: TransactionType.income,
                      );
                      if (result != null && result.isNew && context.mounted) {
                        MoodBurst.show(
                          context,
                          amount: result.amount,
                          isIncome: result.isIncome,
                        );
                      }
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Yeni Gider',
                    color: AppTheme.errorColor,
                    onTap: () async {
                      final result = await AddTransactionModal.show(
                        context,
                        initialType: TransactionType.expense,
                      );
                      if (result != null && result.isNew && context.mounted) {
                        MoodBurst.show(
                          context,
                          amount: result.amount,
                          isIncome: result.isIncome,
                        );
                      }
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.call_received_rounded,
                    label: 'Alacak Ekle',
                    color: AppTheme.warningColor,
                    onTap: () async {
                      final res = await AddReceivableEntryModal.show(context);
                      if (res != null && res.triggerHappyBurst && context.mounted) {
                        MoodBurst.show(context, amount: res.amount, isIncome: true);
                      }
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.call_made_rounded,
                    label: 'Borç Ekle',
                    color: AppTheme.errorColor,
                    onTap: () => AddDebtPersonModal.show(context),
                  ),
                  _QuickActionButton(
                    icon: Icons.person_add_outlined,
                    label: 'Müşteri Ekle',
                    color: AppTheme.primaryOrange,
                    onTap: () => AddCustomerModal.show(context),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Hareketler',
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppConstants.gelirGiderRoute),
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Hareketler yüklenemedi: $err'),
                  ),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Card(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz Kayıtlı İşlem Yok',
                        subtitle: 'Yukarıdaki "Yeni Gelir" veya "Yeni Gider" butonlarından ilk kaydı ekleyebilirsiniz.',
                      ),
                    );
                  }

                  final recent = transactions.take(5).toList();
                  return Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = recent[index];
                        final color = tx.isIncome ? AppTheme.successColor : AppTheme.errorColor;
                        return ListTile(
                          onTap: () => context.go(AppConstants.gelirGiderRoute),
                          leading: Icon(
                            tx.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: color,
                          ),
                          title: Text(
                            tx.description.isNotEmpty ? tx.description : tx.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${AppFormatters.formatDate(tx.date)} • ${tx.category}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Text(
                            '${tx.isIncome ? '+' : '-'}${AppFormatters.formatCurrency(tx.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
