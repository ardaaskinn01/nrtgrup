import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/side_menu.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      drawer: isDesktop ? null : const Drawer(child: SideMenu(isDrawer: true)),
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Görünüm / Tema
          Text(
            'Görünüm',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uygulama Teması',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Açık'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Koyu'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.settings_brightness_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (sel) {
                      ref.read(themeModeProvider.notifier).setTheme(sel.first);
                    },
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Hesap ve Oturum
          Text(
            'Hesap ve Oturum',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppTheme.primaryOrange),
                  title: const Text('Aktif Kullanıcı'),
                  subtitle: Text(user?.email ?? 'Bilinmiyor'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.all_inclusive, color: AppTheme.primaryOrange),
                  title: Text('Oturum Süresi'),
                  subtitle: Text('Bu cihazda süresiz açık (çıkış yapılana kadar)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                  title: const Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _confirmSignOut(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Uygulama Bilgileri
          Text(
            'Uygulama Hakkında',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.pureWhite,
                    child: ClipOval(
                      child: Image.asset(
                        AppConstants.anaLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                  title: const Text(AppConstants.appName),
                  subtitle: const Text('Sürüm ${AppConstants.appVersion}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
          'Oturumunuzdan çıkış yapmak istediğinize emin misiniz?',
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
      await ref.read(authServiceProvider).signOut();
    }
  }
}
