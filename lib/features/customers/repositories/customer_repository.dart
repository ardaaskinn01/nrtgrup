import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../models/customer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storage;

  CustomerRepository(this._firestore, this._storage);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> _photosCollection(String customerId) =>
      _collection.doc(customerId).collection('photos');

  CollectionReference<Map<String, dynamic>> _notesCollection(String customerId) =>
      _collection.doc(customerId).collection('notes');

  Stream<List<Customer>> watchCustomers() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Customer.fromFirestore).toList());
  }

  Stream<Customer?> watchCustomerById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Customer.fromFirestore(doc);
    });
  }

  Future<String> addCustomer(Customer customer) async {
    final docRef = await _collection.add(customer.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    await _collection.doc(id).update(customer.toFirestore(isNew: false));
  }

  /// Müşteri avatarını Supabase Storage'a yükleyip Firestore'daki müşteri dokümanını günceller.
  Future<Customer> updateCustomerAvatar({
    required String customerId,
    required Uint8List bytes,
    required String fileName,
    String? oldAvatarPath,
  }) async {
    // Varsa eski avatarı temizle
    if (oldAvatarPath != null && oldAvatarPath.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(oldAvatarPath);
      } catch (_) {}
    }

    final uploaded = await _storage.uploadCustomerAvatar(
      customerId: customerId,
      bytes: bytes,
      fileName: fileName,
    );

    await _collection.doc(customerId).update({
      'avatarUrl': uploaded.publicUrl,
      'avatarPath': uploaded.path,
    });

    final doc = await _collection.doc(customerId).get();
    return Customer.fromFirestore(doc);
  }

  /// Müşterinin avatarını kaldırır.
  Future<void> removeCustomerAvatar(String customerId, String avatarPath) async {
    if (avatarPath.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(avatarPath);
      } catch (_) {}
    }
    await _collection.doc(customerId).update({
      'avatarUrl': '',
      'avatarPath': '',
    });
  }

  /// Müşteriyi, altındaki notları, fotoğraf kayıtlarını ve Supabase Storage'daki dosyaları siler.
  Future<void> deleteCustomer(String id) async {
    final customerDoc = await _collection.doc(id).get();
    final avatarPath = customerDoc.data()?['avatarPath'] as String?;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(avatarPath);
      } catch (_) {}
    }

    final photosSnap = await _photosCollection(id).get();
    final notesSnap = await _notesCollection(id).get();

    for (final doc in photosSnap.docs) {
      final path = doc.data()['path'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          await _storage.deleteWorkPhoto(path);
        } catch (_) {
          // Storage dosyası zaten silinmişse devam et
        }
      }
    }

    final batch = _firestore.batch();
    for (final doc in photosSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in notesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_collection.doc(id));
    await batch.commit();
  }

  // --- Yapılan İşler & Ürün Fotoğrafları ---

  Stream<List<CustomerWorkPhoto>> watchPhotos(String customerId) {
    return _photosCollection(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CustomerWorkPhoto.fromFirestore).toList());
  }

  Future<void> addWorkPhoto({
    required String customerId,
    required Uint8List bytes,
    required String fileName,
    required String description,
    required DateTime date,
  }) async {
    final uploaded = await _storage.uploadWorkPhoto(
      customerId: customerId,
      bytes: bytes,
      fileName: fileName,
    );

    final photo = CustomerWorkPhoto(
      url: uploaded.publicUrl,
      path: uploaded.path,
      description: description,
      date: date,
      createdAt: DateTime.now(),
    );

    await _photosCollection(customerId).add(photo.toFirestore());
    await _collection.doc(customerId).update({
      'photoCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteWorkPhoto(String customerId, CustomerWorkPhoto photo) async {
    if (photo.path.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(photo.path);
      } catch (_) {}
    }
    if (photo.id != null) {
      await _photosCollection(customerId).doc(photo.id!).delete();
    }
    await _collection.doc(customerId).update({
      'photoCount': FieldValue.increment(-1),
    });
  }

  // --- İş Notları ---

  Stream<List<CustomerNote>> watchNotes(String customerId) {
    return _notesCollection(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CustomerNote.fromFirestore).toList());
  }

  Future<void> addNote(String customerId, CustomerNote note) async {
    await _notesCollection(customerId).add(note.toFirestore(isNew: true));
  }

  Future<void> updateNote(String customerId, String noteId, CustomerNote note) async {
    await _notesCollection(customerId).doc(noteId).update(note.toFirestore(isNew: false));
  }

  Future<void> deleteNote(String customerId, String noteId) async {
    await _notesCollection(customerId).doc(noteId).delete();
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(supabaseStorageServiceProvider);
  return CustomerRepository(firestore, storage);
});
