import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env yükleme uyarısı: $e');
  }

  // Türkçe tarih formatı
  try {
    await initializeDateFormatting('tr_TR', null);
  } catch (e) {
    debugPrint('Date formatting init error: $e');
  }

  // Firebase Başlatma
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase başarıyla başlatıldı.');
  } catch (e) {
    debugPrint('Firebase başlatma uyarısı: $e');
  }

  // Supabase Başlatma (Storage için)
  try {
    final supabaseUrl = AppConstants.supabaseUrl;
    final supabaseAnonKey = AppConstants.supabaseAnonKey;
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      debugPrint('Supabase Storage başarıyla başlatıldı.');
    } else {
      debugPrint('Supabase .env bilgileri eksik.');
    }
  } catch (e) {
    debugPrint('Supabase başlatma hatası: $e');
  }

  // SharedPreferences başlatma
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NrtApp(),
    ),
  );
}

class NrtApp extends ConsumerWidget {
  const NrtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
    );
  }
}
