import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/stock_item.dart';

class StockRepository {
  final FirebaseFirestore _firestore;

  StockRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('stocks');

  Stream<List<StockItem>> watchStocks() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(StockItem.fromFirestore).toList();
      list.sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<String> addStock(StockItem item) async {
    final docRef = await _collection.add(item.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateStock(String id, StockItem item) async {
    await _collection.doc(id).update(item.toFirestore(isNew: false));
  }

  Future<void> deleteStock(String id) async {
    await _collection.doc(id).delete();
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return StockRepository(firestore);
});
