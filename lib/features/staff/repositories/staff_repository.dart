import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../models/staff.dart';
import '../../../models/transaction.dart';

class StaffRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storage;

  StaffRepository(this._firestore, this._storage);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('staff');

  Stream<List<StaffMember>> watchStaff() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StaffMember.fromFirestore).toList());
  }

  Stream<StaffMember?> watchStaffById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StaffMember.fromFirestore(doc);
    });
  }

  Future<String> addStaff(StaffMember staff) async {
    final docRef = await _collection.add(staff.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateStaff(String id, StaffMember staff) async {
    await _collection.doc(id).update(staff.toFirestore(isNew: false));
  }

  /// Personel kimlik fotoğrafını Supabase'e yükler ve Firestore'u günceller.
  Future<StaffMember> updateStaffIdCard({
    required String staffId,
    required Uint8List bytes,
    required String fileName,
    String? oldIdCardPath,
  }) async {
    // Varsa eski kimlik görselini Storage'dan sil
    if (oldIdCardPath != null && oldIdCardPath.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(oldIdCardPath);
      } catch (_) {}
    }

    final uploaded = await _storage.uploadStaffIdCard(
      staffId: staffId,
      bytes: bytes,
      fileName: fileName,
    );

    await _collection.doc(staffId).update({
      'idCardUrl': uploaded.publicUrl,
      'idCardPath': uploaded.path,
    });

    final doc = await _collection.doc(staffId).get();
    return StaffMember.fromFirestore(doc);
  }

  /// Personel kimlik fotoğrafını kaldırır.
  Future<void> removeStaffIdCard(String staffId, String idCardPath) async {
    if (idCardPath.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(idCardPath);
      } catch (_) {}
    }
    await _collection.doc(staffId).update({
      'idCardUrl': '',
      'idCardPath': '',
    });
  }

  /// Personeli, kimlik dosyasını ve altındaki tüm puantaj (`attendance`) ile ödeme (`payments`) kayıtlarını siler.
  Future<void> deleteStaff(String id) async {
    final staffDoc = await _collection.doc(id).get();
    final idCardPath = staffDoc.data()?['idCardPath'] as String?;
    if (idCardPath != null && idCardPath.isNotEmpty) {
      try {
        await _storage.deleteWorkPhoto(idCardPath);
      } catch (_) {}
    }

    final attendanceSnap = await _collection.doc(id).collection('attendance').get();
    final paymentsSnap = await _collection.doc(id).collection('payments').get();
    final batch = _firestore.batch();
    for (final doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in paymentsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_collection.doc(id));
    await batch.commit();
  }

  // --- Personel Avans / Ödeme Takibi ---

  CollectionReference<Map<String, dynamic>> _paymentsCollection(String staffId) =>
      _collection.doc(staffId).collection('payments');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('transactions');

  Stream<List<StaffPayment>> watchPayments(String staffId) {
    return _paymentsCollection(staffId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(StaffPayment.fromFirestore).toList();
      list.sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<void> addPayment(
    String staffId,
    StaffPayment payment, {
    String staffName = '',
  }) async {
    final paymentRef = _paymentsCollection(staffId).doc();
    final txDesc = payment.note.isNotEmpty
        ? '$staffName - ${payment.note}'
        : (staffName.isNotEmpty ? '$staffName (Personel Ödemesi)' : 'Personel Ödemesi');

    final tx = AppTransaction(
      amount: payment.amount,
      type: TransactionType.expense,
      category: 'Personel Ödemesi',
      paymentMethod: PaymentMethod.cash,
      description: txDesc,
      date: payment.date,
      createdAt: DateTime.now(),
      sourceType: 'staff_payment',
      sourceId: paymentRef.id,
      sourceParentId: staffId,
    );

    final txDoc = await _transactionsCollection.add(tx.toFirestore(isNew: true));

    final data = payment.toFirestore(isNew: true);
    data['transactionId'] = txDoc.id;
    await paymentRef.set(data);
  }

  Future<void> deletePayment(String staffId, String paymentId) async {
    final doc = await _paymentsCollection(staffId).doc(paymentId).get();
    final txId = doc.data()?['transactionId'] as String?;
    if (txId != null && txId.isNotEmpty) {
      try {
        await _transactionsCollection.doc(txId).delete();
      } catch (_) {}
    }
    await _paymentsCollection(staffId).doc(paymentId).delete();
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(supabaseStorageServiceProvider);
  return StaffRepository(firestore, storage);
});
