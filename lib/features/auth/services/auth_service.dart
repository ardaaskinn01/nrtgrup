import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_providers.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  // Güncel kullanıcı
  User? get currentUser => _auth.currentUser;

  // Kimlik doğrulama değişiklik akışı (Oturumun sonsuz kalmasını sağlar)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kullanıcı adı veya tam e-posta ile giriş.
  /// Kullanıcı örneğin sadece "yönetici" girdiğinde otomatik olarak "@example.com" eklenir.
  Future<UserCredential> signInWithIdentifier({
    required String rawInput,
    required String password,
  }) async {
    final input = rawInput.trim();
    String email;

    if (input.contains('@')) {
      email = input;
    } else {
      // @ içermiyorsa otomatik olarak @example.com ekle
      // Türkçe karakter ve boşluk düzenlemesi
      final formattedUsername = input.toLowerCase().replaceAll(' ', '');
      email = '$formattedUsername${AppConstants.defaultDomain}';
    }

    debugPrint('AuthService: Giriş deneniyor -> $email');

    try {
      // Firebase Auth, varsayılan olarak mobil (iOS/Android) ve web üzerinde
      // token'ları Keychain/SharedPreferences'da sonsuz olarak saklar (Persistent Session).
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı oturumu başarılı, profil dokümanını hazırla/güncelle
      if (credential.user != null) {
        await _ensureUserProfile(credential.user!, email);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Firebase Error: ${e.code} - ${e.message}');
      
      // Eğer kullanıcı adı Türkçe karakter veya karakter uyumsuzluğu nedeniyle
      // yönetici / yonetici farkı yaşadıysa alternatif formatı dene
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (!rawInput.contains('@')) {
          final normalized = rawInput
              .toLowerCase()
              .replaceAll('ı', 'i')
              .replaceAll('ğ', 'g')
              .replaceAll('ü', 'u')
              .replaceAll('ş', 's')
              .replaceAll('ö', 'o')
              .replaceAll('ç', 'c')
              .replaceAll(' ', '');
          final altEmail = '$normalized${AppConstants.defaultDomain}';
          
          if (altEmail != email) {
            debugPrint('AuthService: Alternatif normalize e-posta deneniyor -> $altEmail');
            final credential = await _auth.signInWithEmailAndPassword(
              email: altEmail,
              password: password,
            );
            if (credential.user != null) {
              await _ensureUserProfile(credential.user!, altEmail);
            }
            return credential;
          }
        }
      }
      rethrow;
    }
  }

  // Profil dokümanını garantiye al
  Future<void> _ensureUserProfile(User user, String email) async {
    try {
      final docRef = _firestore.collection('profiles').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final isAdmin = email.toLowerCase().startsWith('yonetici') ||
            email.toLowerCase().startsWith('yönetici');
        await docRef.set({
          'email': email,
          'displayName': isAdmin ? 'Yönetici' : (user.displayName ?? 'Personel'),
          'role': isAdmin ? 'admin' : 'personal',
          'lastLogin': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('AuthService _ensureUserProfile hatası (ihmal edilebilir): $e');
    }
  }

  // Kullanıcının Yönetici olup olmadığını kontrol et
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final email = (user.email ?? '').toLowerCase();
    if (email.startsWith('yonetici') || email.startsWith('yönetici')) {
      return true;
    }

    try {
      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['role'] == 'admin';
      }
    } catch (e) {
      debugPrint('AuthService isAdmin hatası: $e');
    }
    return false;
  }

  /// Kullanıcının rolünü döndürür ('admin' veya 'personal')
  Future<String> getUserRole() async {
    final admin = await isAdmin();
    return admin ? 'admin' : 'personal';
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthService(auth, firestore);
});

final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  // Oturum durumu değiştiğinde tekrar hesapla
  ref.watch(currentUserProvider);
  return await authService.isAdmin();
});
