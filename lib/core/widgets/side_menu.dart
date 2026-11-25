import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../features/auth/services/auth_service.dart';

class SideMenu extends ConsumerWidget {
  final bool isDrawer;

  const SideMenu({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 290,
      height: double.infinity,
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          children: [
            // Header: Siyah & Turuncu vurgulu modern başlık
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppTheme.pureBlack, AppTheme.darkSurfaceElevated]
                      : [AppTheme.pureBlack, const Color(0xFF222222)],
                ),
                border: const Border(
                  bottom: BorderSide(color: AppTheme.primaryOrange, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pureWhite,
                      border: Border.all(color: AppTheme.primaryOrange, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppConstants.anaLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.account_balance,
                          color: AppTheme.primaryOrange,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: AppTheme.pureWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            user?.email != null
                                ? (user!.email!.contains('@')
                                    ? user.email!.split('@').first
                                    : user.email!)
                                : 'Oturum Açık',
                            style: const TextStyle(
                              color: AppTheme.primaryOrangeLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menü Öğeleri (İstenilen Sıra)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _MenuItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Ana Panel',
                    isActive: currentLocation == AppConstants.dashboardRoute,
                    onTap: () => _navigate(context, AppConstants.dashboardRoute),
                  ),
                  _MenuItem(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Gelir Gider',
                    isActive: currentLocation == AppConstants.gelirGiderRoute,
                    onTap: () => _navigate(context, AppConstants.gelirGiderRoute),
                  ),
                  _MenuItem(
                    icon: Icons.call_received_rounded,
                    title: 'Alacaklar',
                    isActive: currentLocation == AppConstants.alacaklarRoute,
                    onTap: () => _navigate(context, AppConstants.alacaklarRoute),
                  ),
                  _MenuItem(
                    icon: Icons.call_made_rounded,
                    title: 'Borçlar',
                    isActive: currentLocation == AppConstants.borclarRoute,
                    onTap: () => _navigate(context, AppConstants.borclarRoute),
                  ),
                  _MenuItem(
                    icon: Icons.groups_outlined,
                    title: 'Müşteriler',
                    isActive: currentLocation == AppConstants.musterilerRoute,
                    onTap: () => _navigate(context, AppConstants.musterilerRoute),
                  ),
                  _MenuItem(
                    icon: Icons.badge_outlined,
                    title: 'Personel',
                    isActive: currentLocation == AppConstants.personelRoute,
                    onTap: () => _navigate(context, AppConstants.personelRoute),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Çıkış Yap Butonu
            _MenuItem(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              iconColor: AppTheme.errorColor,
              onTap: () => _confirmSignOut(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    if (isDrawer) {
      Navigator.pop(context);
    }
    context.go(route);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
          'Çıkış yapmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.pureWhite,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isDrawer && context.mounted) {
        Navigator.pop(context);
      }
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    }
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const activeColor = AppTheme.primaryOrange;
    final inactiveColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black87);
    final activeTextColor = isDark ? AppTheme.primaryOrangeLight : AppTheme.primaryOrangeDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        onTap: onTap,
        selected: isActive,
        leading: Icon(
          icon,
          color: iconColor ?? (isActive ? activeColor : inactiveColor),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? activeTextColor : inactiveColor,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: activeColor.withValues(alpha: 0.14),
        dense: true,
      ),
    );
  }
}
