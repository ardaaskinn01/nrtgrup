import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'Nrt Grup';
  static const String appVersion = '1.0.0';

  // Default Admin User
  static const String defaultAdminUsername = 'yönetici';
  static const String defaultDomain = '@example.com';
  static const String defaultAdminEmail = 'yönetici@example.com';

  // Supabase Configuration (.env üzerinden yüklenir)
  static String get supabaseUrl => dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? '';
  static String get workPhotosBucket => dotenv.env['SUPABASE_WORK_PHOTOS_BUCKET'] ?? 'customer-photos';

  // Asset Paths
  static const String anaLogo = 'assets/analogo.jpeg';
  static const String drawerLogo = 'assets/drawerlogo.jpg';
  static const String iconMutlu = 'assets/mutlu.jpeg';
  static const String iconAzMutlu = 'assets/azmutlu.jpeg';
  static const String iconMutsuz = 'assets/mutsuz.jpeg';

  // Routes
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String gelirGiderRoute = '/gelir-gider';
  static const String alacaklarRoute = '/alacaklar';
  static const String borclarRoute = '/borclar';
  static const String musterilerRoute = '/musteriler';
  static const String personelRoute = '/personel';
  static const String ayarlarRoute = '/ayarlar';
}
