import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/cheque.dart';

class ChequeRepository {
  final FirebaseFirestore _firestore;

  ChequeRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('cheques');

  Stream<List<Cheque>> watchAllCheques() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Cheque.fromFirestore).toList());
  }

  Future<String> addCheque(Cheque cheque) async {
    final docRef = await _collection.add(cheque.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> markChequeGiven(String chequeId, String givenToName) async {
    await _collection.doc(chequeId).update({
      'status': ChequeStatus.given.value,
      'givenToName': givenToName,
    });
  }

  Future<void> deleteCheque(String chequeId) async {
    await _collection.doc(chequeId).delete();
  }

  /// Offset işlemi sırasında mevcut kasadaki eski çekleri temizler ve yenilerini kaydeder.
  Future<void> replaceInHandCheques(List<double> amounts, DateTime date) async {
    final snap = await _collection
        .where('status', isEqualTo: ChequeStatus.inHand.value)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    for (final amt in amounts) {
      if (amt <= 0) continue;
      final docRef = _collection.doc();
      batch.set(
        docRef,
        Cheque(
          amount: amt,
          sourceName: 'Kasa Eşitleme',
          note: 'Offset ile tanımlandı',
          status: ChequeStatus.inHand,
          date: date,
          createdAt: DateTime.now(),
        ).toFirestore(isNew: true),
      );
    }
    await batch.commit();
  }
}

final chequeRepositoryProvider = Provider<ChequeRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ChequeRepository(firestore);
});

final chequesStreamProvider = StreamProvider<List<Cheque>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(chequeRepositoryProvider).watchAllCheques();
});

/// Sadece kasada aktif olarak duran (henüz borca verilmemiş) çekler
final inHandChequesProvider = Provider<AsyncValue<List<Cheque>>>((ref) {
  return ref.watch(chequesStreamProvider).whenData(
        (list) => list.where((c) => c.isInHand).toList(),
      );
});
