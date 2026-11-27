import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseStorageService {
  final SupabaseClient _client;

  SupabaseStorageService(this._client);

  String get _bucket => AppConstants.workPhotosBucket;

  /// Personel kimlik fotoğrafını Supabase Storage'a yükler.
  /// Geriye storage path'i ve public URL'ini döner.
  Future<({String path, String publicUrl})> uploadStaffIdCard({
    required String staffId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'staff/$staffId/idcard_${timestamp}_$sanitizedName';

    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    final publicUrl = getPublicUrl(storagePath);
    return (path: storagePath, publicUrl: publicUrl);
  }

  /// Müşteri avatar resmini Supabase Storage'a yükler.
  /// Geriye storage path'i ve public URL'ini döner.
  Future<({String path, String publicUrl})> uploadCustomerAvatar({
    required String customerId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'customers/$customerId/avatar_${timestamp}_$sanitizedName';

    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    final publicUrl = getPublicUrl(storagePath);
    return (path: storagePath, publicUrl: publicUrl);
  }

  /// Yapılan iş / ürün fotoğrafını Supabase Storage'a yükler.
  /// Geriye storage path'i ve public URL'ini döner.
  Future<({String path, String publicUrl})> uploadWorkPhoto({
    required String customerId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'customers/$customerId/${timestamp}_$sanitizedName';

    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    final publicUrl = getPublicUrl(storagePath);
    return (path: storagePath, publicUrl: publicUrl);
  }

  /// Storage path'inden public URL döner.
  String getPublicUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Fotoğrafı Supabase Storage'dan siler.
  Future<void> deleteWorkPhoto(String path) async {
    if (path.isEmpty) return;
    await _client.storage.from(_bucket).remove([path]);
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseStorageService(client);
});
