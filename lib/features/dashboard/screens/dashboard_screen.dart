import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/mood_burst.dart';
import '../../../core/widgets/side_menu.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../auth/services/auth_service.dart';
import '../../customers/widgets/add_customer_modal.dart';
import '../../debts/providers/debt_providers.dart';
import '../../debts/widgets/add_debt_person_modal.dart';
import '../../receivables/providers/receivable_providers.dart';
import '../../receivables/widgets/add_receivable_entry_modal.dart';
import '../../staff/providers/attendance_providers.dart';
import '../../todos/providers/todo_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/widgets/add_transaction_modal.dart';
import '../../transactions/widgets/cash_offset_modal.dart';
import '../../../models/transaction.dart';

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
    final upcomingTodosAsync = ref.watch(upcomingDashboardTodosProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final username = user?.email != null
        ? (user!.email!.contains('@')
            ? user.email!.split('@').first
            : user.email!)
        : 'Kullanıcı';

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
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
          padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Kasa & Karşılama Kartı
              HeroGradientCard(
                onTap: () => context.push(AppConstants.cashDetailRoute),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryOrange, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.pureWhite,
                            child: ClipOval(
                              child: Image.asset(
                                AppConstants.anaLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_balance,
                                  color: AppTheme.primaryOrange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hoş Geldiniz,',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                username,
                                style: const TextStyle(
                                  color: AppTheme.pureWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kasa Detayı',
                                style: TextStyle(
                                  color: AppTheme.primaryOrangeLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: AppTheme.primaryOrangeLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'TOPLAM KASA BAKİYESİ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    balanceAsync.when(
                      loading: () => const SizedBox(
                        height: 36,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      error: (_, __) => const Text(
                        '-',
                        style: TextStyle(color: Colors.white, fontSize: 28),
                      ),
                      data: (summary) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppFormatters.formatCurrency(summary.netBalance),
                              style: TextStyle(
                                color: summary.netBalance >= 0
                                    ? AppTheme.pureWhite
                                    : const Color(0xFFF87171),
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nakit / Çek Dağılımı
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.payments_outlined, color: Color(0xFF4ADE80), size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Nakit: ${AppFormatters.formatCurrency(summary.cashBalance)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryOrangeLight, size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Çek (${summary.chequeCount}): ${AppFormatters.formatCurrency(summary.chequeBalance)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _HeroSubMetric(
                                    label: 'Bu Ay Gelir',
                                    value: AppFormatters.formatCurrency(summary.monthIncome),
                                    color: const Color(0xFF4ADE80),
                                    icon: Icons.south_west_rounded,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _HeroSubMetric(
                                    label: 'Bu Ay Gider',
                                    value: AppFormatters.formatCurrency(summary.monthExpense),
                                    color: const Color(0xFFF87171),
                                    icon: Icons.north_east_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 380.ms).slideY(begin: -0.04, end: 0),

              const SizedBox(height: 22),

              // Hızlı İşlemler
              Text(
                'Hızlı İşlemler',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickActionTile(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Gelir Ekle',
                    color: AdaptiveColors.success(context),
                    onTap: () async {
                      final res = await AddTransactionModal.show(
                        context,
                        initialType: TransactionType.income,
                      );
                      if (res != null && context.mounted) {
                        MoodBurst.show(context, amount: res.amount, isIncome: true);
                      }
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Gider Ekle',
                    color: AdaptiveColors.error(context),
                    onTap: () async {
                      final res = await AddTransactionModal.show(
                        context,
                        initialType: TransactionType.expense,
                      );
                      if (res != null && context.mounted) {
                        MoodBurst.show(context, amount: res.amount, isIncome: false);
                      }
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.call_received_rounded,
                    label: 'Alacak Ekle',
                    color: AdaptiveColors.warning(context),
                    onTap: () async {
                      final res = await AddReceivableEntryModal.show(context);
                      if (res != null && res.triggerHappyBurst && context.mounted) {
                        MoodBurst.show(context, amount: res.amount, isIncome: true);
                      }
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.call_made_rounded,
                    label: 'Borç Ekle',
                    color: AdaptiveColors.error(context),
                    onTap: () => AddDebtPersonModal.show(context),
                  ),
                  _QuickActionTile(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Müşteri Ekle',
                    color: AdaptiveColors.orange(context),
                    onTap: () => AddCustomerModal.show(context),
                  ),
                  _QuickActionTile(
                    icon: Icons.balance_rounded,
                    label: 'Kasa Eşitle',
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    onTap: () => CashOffsetModal.show(context),
                  ),
                ],
              ),

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
                error: (err, _) => SurfaceCard(
                  child: Text('Özet yüklenemedi: $err'),
                ),
                data: (summary) => LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : (constraints.maxWidth > 320 ? 2 : 1);
                    final aspectRatio = constraints.maxWidth > 900 ? 1.5 : 1.32;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: aspectRatio,
                      children: [
                        _BentoStatCard(
                          title: 'Bugün Gelir',
                          value: AppFormatters.formatCurrency(summary.todayIncome),
                          subtitle: 'Ay: ${AppFormatters.formatCurrency(summary.monthIncome)}',
                          icon: Icons.south_west_rounded,
                          color: AdaptiveColors.success(context),
                          onTap: () => context.push(AppConstants.gelirGiderRoute),
                        ),
                        _BentoStatCard(
                          title: 'Bugün Gider',
                          value: AppFormatters.formatCurrency(summary.todayExpense),
                          subtitle: 'Ay: ${AppFormatters.formatCurrency(summary.monthExpense)}',
                          icon: Icons.north_east_rounded,
                          color: AdaptiveColors.error(context),
                          onTap: () => context.push(AppConstants.gelirGiderRoute),
                        ),
                        _BentoStatCard(
                          title: 'Toplam Alacak',
                          value: totalReceivablesAsync.when(
                            data: AppFormatters.formatCurrency,
                            loading: () => '...',
                            error: (_, __) => '-',
                          ),
                          subtitle: 'Alacak Defteri',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AdaptiveColors.warning(context),
                          onTap: () => context.push(AppConstants.alacaklarRoute),
                        ),
                        _BentoStatCard(
                          title: 'Toplam Borç',
                          value: totalDebtsAsync.when(
                            data: AppFormatters.formatCurrency,
                            loading: () => '...',
                            error: (_, __) => '-',
                          ),
                          subtitle: 'Borç Defteri',
                          icon: Icons.credit_card_outlined,
                          color: AdaptiveColors.error(context),
                          onTap: () => context.push(AppConstants.borclarRoute),
                        ),
                        _BentoStatCard(
                          title: 'Bugün Çalışan',
                          value: todayStaffCountAsync.when(
                            data: (count) => '$count Kişi',
                            loading: () => '...',
                            error: (_, __) => '0 Kişi',
                          ),
                          subtitle: 'Personel Puantajı',
                          icon: Icons.badge_outlined,
                          color: AdaptiveColors.orange(context),
                          onTap: () => context.push(AppConstants.personelRoute),
                        ),
                        _BentoStatCard(
                          title: 'Müşteri Portföyü',
                          value: 'İş & Galeri',
                          subtitle: 'Müşterileri Gör',
                          icon: Icons.groups_outlined,
                          color: AdaptiveColors.orange(context),
                          onTap: () => context.push(AppConstants.musterilerRoute),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Hareketler',
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppConstants.gelirGiderRoute),
                    icon: const Text('Tümünü Gör'),
                    label: const Icon(Icons.arrow_forward_rounded, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              transactionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => SurfaceCard(
                  child: Text('Hareketler yüklenemedi: $err'),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const SurfaceCard(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz Kayıtlı İşlem Yok',
                        subtitle: 'Yukarıdaki "Yeni Gelir" veya "Yeni Gider" butonlarından ilk kaydı ekleyebilirsiniz.',
                      ),
                    );
                  }

                  final recent = transactions.take(5).toList();
                  return Column(
                    children: recent.map((tx) {
                      final color = tx.isIncome
                          ? AdaptiveColors.success(context)
                          : AdaptiveColors.error(context);
                      return SurfaceCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        leftAccentColor: color,
                        onTap: () => context.push(AppConstants.gelirGiderRoute),
                        child: Row(
                          children: [
                            IconSquircle(
                              color: color,
                              size: 42,
                              icon: tx.isIncome
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description.isNotEmpty ? tx.description : tx.category,
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tx.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AdaptiveColors.subText(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        ' • ${AppFormatters.formatDate(tx.date)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AdaptiveColors.subText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            StatusPill(
                              label: '${tx.isIncome ? '+' : '-'}${AppFormatters.formatCurrency(tx.amount)}',
                              color: color,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 26),

              // Bugün ve Yarınki Yapılacaklar Özeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bugün & Yarın Yapılacaklar',
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppConstants.yapilacaklarRoute),
                    icon: const Text('Tümünü Gör'),
                    label: const Icon(Icons.arrow_forward_rounded, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              upcomingTodosAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => SurfaceCard(
                  child: Text('Yapılacaklar yüklenemedi: $err'),
                ),
                data: (todos) {
                  if (todos.isEmpty) {
                    return SurfaceCard(
                      onTap: () => context.push(AppConstants.yapilacaklarRoute),
                      child: Row(
                        children: [
                          IconSquircle(
                            color: AdaptiveColors.orange(context),
                            icon: Icons.checklist_rounded,
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bugün veya yarın için bekleyen görev yok',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Yapılacaklar listesini açmak için dokunun',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AdaptiveColors.subText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AdaptiveColors.subText(context),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: todos.map((todo) {
                      final color = todo.isToday
                          ? AdaptiveColors.orange(context)
                          : (theme.brightness == Brightness.dark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB));
                      return SurfaceCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        leftAccentColor: color,
                        onTap: () => context.push(AppConstants.yapilacaklarRoute),
                        child: Row(
                          children: [
                            IconSquircle(
                              color: color,
                              size: 40,
                              icon: Icons.task_alt_rounded,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todo.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (todo.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      todo.description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AdaptiveColors.subText(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(
                              label: todo.isToday ? 'Bugün' : 'Yarın',
                              color: color,
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
        ),
      ),
    );
  }
}

class _HeroSubMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeroSubMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BentoStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _BentoStatCard({
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
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconSquircle(color: color, icon: icon, size: 38),
              Icon(
                Icons.north_east_rounded,
                size: 16,
                color: AdaptiveColors.subText(context).withValues(alpha: 0.6),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AdaptiveColors.subText(context),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AdaptiveColors.subText(context),
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
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AdaptiveColors.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AdaptiveColors.cardBorder(context), width: 1.1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
