import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/receivable.dart';
import '../../../models/transaction.dart';

class ReceivableRepository {
  final FirebaseFirestore _firestore;

  ReceivableRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _peopleCollection =>
      _firestore.collection('receivables');

  CollectionReference<Map<String, dynamic>> _entriesCollection(String personId) =>
      _peopleCollection.doc(personId).collection('entries');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('transactions');

  Stream<List<ReceivablePerson>> watchReceivables() {
    return _peopleCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReceivablePerson.fromFirestore).toList());
  }

  Stream<ReceivablePerson?> watchPersonById(String id) {
    return _peopleCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ReceivablePerson.fromFirestore(doc);
    });
  }

  Stream<List<ReceivableEntry>> watchEntries(String personId) {
    return _entriesCollection(personId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ReceivableEntry.fromFirestore).toList();
      list.sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<String> addPerson({
    required String name,
    String phone = '',
  }) async {
    final person = ReceivablePerson(
      name: name,
      phone: phone,
      balance: 0,
      createdAt: DateTime.now(),
    );
    final docRef = await _peopleCollection.add(person.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updatePerson(
    String id, {
    required String name,
    required String phone,
  }) async {
    await _peopleCollection.doc(id).update({
      'name': name,
      'phone': phone,
    });
  }

  /// Alacak veya tahsilat hareketi ekler.
  /// Tahsilat + [addToIncome] seçiliyse `transactions` koleksiyonuna gelir olarak yazar.
  Future<({bool addedToIncome, double amount})> addEntry({
    required String personId,
    required String personName,
    required ReceivableEntryType type,
    required double amount,
    required DateTime date,
    required String description,
    required bool addToIncome,
  }) async {
    String? linkedTxId;
    final shouldAddIncome = type == ReceivableEntryType.tahsilat && addToIncome;

    final entryRef = _entriesCollection(personId).doc();

    if (shouldAddIncome) {
      final txDesc = description.isNotEmpty
          ? '$personName - $description'
          : '$personName (Alacak Tahsilatı)';
      final tx = AppTransaction(
        amount: amount,
        type: TransactionType.income,
        category: 'Alacak Tahsilatı',
        paymentMethod: PaymentMethod.cash,
        description: txDesc,
        date: date,
        createdAt: DateTime.now(),
        sourceType: 'receivable',
        sourceId: entryRef.id,
        sourceParentId: personId,
      );
      final txDoc = await _transactionsCollection.add(tx.toFirestore(isNew: true));
      linkedTxId = txDoc.id;
    }

    final entry = ReceivableEntry(
      id: entryRef.id,
      type: type,
      amount: amount,
      date: date,
      description: description,
      addedToIncome: shouldAddIncome,
      transactionId: linkedTxId,
      createdAt: DateTime.now(),
    );

    await entryRef.set(entry.toFirestore(isNew: true));

    final delta = type == ReceivableEntryType.alacakEkle ? amount : -amount;
    await _peopleCollection.doc(personId).update({
      'balance': FieldValue.increment(delta),
    });

    return (addedToIncome: shouldAddIncome, amount: amount);
  }

  /// Hareketi siler, bakiyeyi kalan hareketlerden yeniden hesaplar.
  /// İstenirse bağlı Gelir Gider kaydını da siler.
  Future<void> deleteEntry({
    required String personId,
    required ReceivableEntry entry,
    required bool deleteLinkedTransaction,
  }) async {
    if (entry.id != null) {
      await _entriesCollection(personId).doc(entry.id!).delete();
    }

    if (deleteLinkedTransaction && entry.transactionId != null) {
      await _transactionsCollection.doc(entry.transactionId!).delete();
    }

    final remainingSnap = await _entriesCollection(personId).get();
    final remaining = remainingSnap.docs.map(ReceivableEntry.fromFirestore).toList();
    final newBalance = ReceivableEntry.calculateBalance(remaining);

    await _peopleCollection.doc(personId).update({'balance': newBalance});
  }

  /// Alacaklı kişiyi ve tüm alt hareketlerini siler.
  Future<void> deletePerson(String personId) async {
    final entriesSnap = await _entriesCollection(personId).get();
    final batch = _firestore.batch();
    for (final doc in entriesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_peopleCollection.doc(personId));
    await batch.commit();
  }
}

final receivableRepositoryProvider = Provider<ReceivableRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ReceivableRepository(firestore);
});
