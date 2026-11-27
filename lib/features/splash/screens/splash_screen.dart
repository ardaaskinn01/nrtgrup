import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppAndNavigate() async {
    final startTime = DateTime.now();

    // 1. Firebase Auth durumunu ve token'ını garantilemek için stream'i dinle
    final authService = ref.read(authServiceProvider);

    try {
      // iOS Keychain'den token'ın yüklenmesi için authStateChanges'ın ilk geçerli yanıtını bekle (max 2 sn)
      await authService.authStateChanges
          .firstWhere((_) => true)
          .timeout(const Duration(seconds: 2), onTimeout: () => authService.currentUser);

      // Kullanıcı varsa token yenilemesini tetikleyerek Firestore oturumunu hazır et
      if (authService.currentUser != null) {
        try {
          await authService.currentUser!.getIdToken(false).timeout(
            const Duration(seconds: 1),
            onTimeout: () => null,
          );
        } catch (_) {}
      }
    } catch (_) {}

    // Splash ekranının oturması ve token senkronizasyonu için en az 2 saniyeye tamamla
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 2000);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    // Yönlendirme: Kullanıcı varsa rolüne göre dashboard veya personalHome'a, yoksa login ekranına
    final user = authService.currentUser;
    if (user != null) {
      final isAdmin = await authService.isAdmin();
      if (!mounted) return;
      context.go(isAdmin ? AppConstants.dashboardRoute : AppConstants.personalHomeRoute);
    } else {
      context.go(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : AppTheme.pureWhite;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SizedBox.expand(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Ana Logo & Şirket Başlığı
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            AppConstants.anaLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.apartment_rounded,
                              size: 56,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.pureBlack,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'İnşaat & Taahhüt Yönetim Sistemi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Yükleniyor Göstergesi
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Alt Logo (assets/drawerlogo.jpg)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        AppConstants.drawerLogo,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
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
