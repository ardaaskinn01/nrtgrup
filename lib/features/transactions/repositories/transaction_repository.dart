import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/transaction.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('transactions');

  /// Tüm işlemleri tarih sırasına göre canlı stream olarak dinler.
  Stream<List<AppTransaction>> watchTransactions() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppTransaction.fromFirestore(doc))
          .toList();
      // Aynı tarihteki işlemleri oluşturma zamanına göre de sırala
      list.sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  /// Yeni işlem ekler ve doküman ID'sini döner.
  Future<String> addTransaction(AppTransaction transaction) async {
    final docRef = await _collection.add(transaction.toFirestore(isNew: true));
    return docRef.id;
  }

  /// Var olan işlemi günceller.
  Future<void> updateTransaction(String id, AppTransaction transaction) async {
    await _collection.doc(id).update(transaction.toFirestore(isNew: false));
  }

  /// İşlemi siler.
  Future<void> deleteTransaction(String id) async {
    await _collection.doc(id).delete();
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TransactionRepository(firestore);
});
