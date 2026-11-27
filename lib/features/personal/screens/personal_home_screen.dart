import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/staff.dart';
import '../../../models/transaction.dart';
import '../../auth/services/auth_service.dart';
import '../../staff/providers/staff_providers.dart';
import '../../staff/widgets/add_attendance_modal.dart';
import '../../stock/widgets/add_stock_modal.dart';
import '../../transactions/widgets/add_transaction_modal.dart';

/// Bilgisayar (Desktop/Web) üzerinden 'personal' rolündeki hesabın kullanacağı,
/// kasa/bakiye gibi hassas finansal verilerin GİZLİ olduğu tek sayfalık operasyon merkezi.
class PersonalHomeScreen extends ConsumerStatefulWidget {
  const PersonalHomeScreen({super.key});

  @override
  ConsumerState<PersonalHomeScreen> createState() => _PersonalHomeScreenState();
}

class _PersonalHomeScreenState extends ConsumerState<PersonalHomeScreen> {
  Future<void> _openStaffAttendanceDialog() async {
    final staffList = ref.read(staffStreamProvider).value ?? [];
    if (staffList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sistemde kayıtlı personel bulunamadı.')),
        );
      }
      return;
    }

    StaffMember? selectedStaff = staffList.first;
    final chosen = await showDialog<StaffMember>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Personel Seçin'),
          content: SizedBox(
            width: 380,
            child: DropdownButtonFormField<StaffMember>(
              value: selectedStaff,
              dropdownColor: Theme.of(ctx).colorScheme.surface,
              decoration: const InputDecoration(
                labelText: 'Personel',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: staffList.map((s) {
                return DropdownMenuItem<StaffMember>(
                  value: s,
                  child: Text(
                    s.fullName,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedStaff = val),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selectedStaff),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ),
    );

    if (chosen != null && chosen.id != null && mounted) {
      await AddAttendanceModal.show(context, staffId: chosen.id!);
    }
  }

  Future<void> _openPinProtectedTransaction(TransactionType type) async {
    final pinController = TextEditingController();
    bool obscure = true;

    final authorized = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryOrange),
              const SizedBox(width: 10),
              Text(type == TransactionType.income
                  ? 'Yetkili Gelir Girişi'
                  : 'Yetkili Gider Girişi'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gelir / gider kaydı oluşturabilmek için yetkili PIN kodunu girin:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pinController,
                  obscureText: obscure,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Yetki Şifresi',
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  onSubmitted: (_) {
                    final ok = pinController.text.trim() == AppConstants.staffTransactionPin;
                    Navigator.pop(ctx, ok);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final ok = pinController.text.trim() == AppConstants.staffTransactionPin;
                if (!ok) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Hatalı şifre!'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Doğrula'),
            ),
          ],
        ),
      ),
    );

    pinController.dispose();

    if (authorized == true && mounted) {
      await AddTransactionModal.show(
        context,
        initialType: type,
        isPersonalEntry: true,
      );
    } else if (authorized == false && mounted) {
      // İptal edildiğinde uyarı gösterme, sadece hatalı enter basımında kontrol et
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).value;

    // Arka planda personel listesini hazır tut (dialog açılınca anında gelsin)
    ref.watch(staffStreamProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppConstants.anaLogo,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.business_rounded,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('${AppConstants.appName} • Personel Terminali'),
          ],
        ),
        actions: [
          if (user?.email != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user!.email!,
                  style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            onPressed: _confirmSignOut,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Karşılama Hero Kartı (Kasa bilgisi kesinlikle gösterilmez)
                HeroGradientCard(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Row(
                    children: [
                      const IconSquircle(
                        color: AppTheme.primaryOrangeLight,
                        icon: Icons.desktop_windows_rounded,
                        size: 58,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PERSONEL OPERASYON PANELİ',
                              style: TextStyle(
                                color: AppTheme.primaryOrangeLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Hoş Geldiniz',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bu ekrandan personel giriş-çıkış saati, stok alımı ve yetkili gelir-gider kaydı oluşturabilirsiniz.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Masaüstü 4'lü Operasyon Kartları
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 760;
                    final crossAxisCount = isWide ? 2 : 1;
                    final aspectRatio = isWide ? 2.15 : 2.3;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: aspectRatio,
                      children: [
                        _DesktopActionCard(
                          title: 'Personel Giriş - Çıkış Saati',
                          subtitle: 'Personel seçerek günlük giriş ve çıkış saatlerini kaydedin.',
                          icon: Icons.access_time_filled_rounded,
                          color: AdaptiveColors.orange(context),
                          buttonLabel: 'Saat Kaydı Ekle',
                          onTap: _openStaffAttendanceDialog,
                        ),
                        _DesktopActionCard(
                          title: 'Stok Girişi Yap',
                          subtitle: 'PVC, Cam, Aksesuar veya Diğer stok alımlarını tedarikçiyle kaydedin.',
                          icon: Icons.inventory_2_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          buttonLabel: 'Stok Ekle',
                          onTap: () => AddStockModal.show(context),
                        ),
                        _DesktopActionCard(
                          title: 'Gelir Ekle (Yetkili)',
                          subtitle: 'Şifre doğrulaması ile kasaya gelir girişi kaydedin.',
                          icon: Icons.south_west_rounded,
                          color: AdaptiveColors.success(context),
                          buttonLabel: 'Şifre ile Gelir Ekle',
                          isLocked: true,
                          onTap: () => _openPinProtectedTransaction(TransactionType.income),
                        ),
                        _DesktopActionCard(
                          title: 'Gider Ekle (Yetkili)',
                          subtitle: 'Şifre doğrulaması ile kasadan gider çıkışı kaydedin.',
                          icon: Icons.north_east_rounded,
                          color: AdaptiveColors.error(context),
                          buttonLabel: 'Şifre ile Gider Ekle',
                          isLocked: true,
                          onTap: () => _openPinProtectedTransaction(TransactionType.expense),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String buttonLabel;
  final bool isLocked;
  final VoidCallback onTap;

  const _DesktopActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.buttonLabel,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SurfaceCard(
      padding: const EdgeInsets.all(22),
      leftAccentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconSquircle(color: color, icon: icon, size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLocked)
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AdaptiveColors.subText(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AdaptiveColors.subText(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: onTap,
              icon: Icon(isLocked ? Icons.lock_open_rounded : Icons.add_rounded, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
