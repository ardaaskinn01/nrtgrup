import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/supplier.dart';

class SupplierRepository {
  final FirebaseFirestore _firestore;

  SupplierRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('suppliers');

  Stream<List<Supplier>> watchSuppliers() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Supplier.fromFirestore).toList());
  }

  Future<String> addSupplier(Supplier supplier) async {
    final docRef = await _collection.add(supplier.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateSupplier(String id, Supplier supplier) async {
    await _collection.doc(id).update(supplier.toFirestore(isNew: false));
  }

  Future<void> deleteSupplier(String id) async {
    await _collection.doc(id).delete();
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SupplierRepository(firestore);
});
