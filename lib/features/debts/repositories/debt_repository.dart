import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/debt.dart';
import '../../../models/transaction.dart';

class DebtRepository {
  final FirebaseFirestore _firestore;

  DebtRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _peopleCollection =>
      _firestore.collection('debts');

  CollectionReference<Map<String, dynamic>> _entriesCollection(String personId) =>
      _peopleCollection.doc(personId).collection('entries');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('transactions');

  Stream<List<DebtPerson>> watchDebts() {
    return _peopleCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DebtPerson.fromFirestore).toList());
  }

  Stream<DebtPerson?> watchPersonById(String id) {
    return _peopleCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DebtPerson.fromFirestore(doc);
    });
  }

  Stream<List<DebtEntry>> watchEntries(String personId) {
    return _entriesCollection(personId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(DebtEntry.fromFirestore).toList();
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
    double? initialDebt,
    String note = '',
  }) async {
    final initialAmount = (initialDebt != null && initialDebt > 0) ? initialDebt : 0.0;
    final person = DebtPerson(
      name: name,
      phone: phone,
      balance: initialAmount,
      note: note,
      createdAt: DateTime.now(),
    );

    final docRef = await _peopleCollection.add(person.toFirestore(isNew: true));

    if (initialAmount > 0) {
      final entry = DebtEntry(
        type: DebtEntryType.borcEkle,
        amount: initialAmount,
        date: DateTime.now(),
        description: note.isNotEmpty ? note : 'Başlangıç borcu',
        addedToLedger: false,
        createdAt: DateTime.now(),
      );
      await _entriesCollection(docRef.id).add(entry.toFirestore(isNew: true));
    }

    return docRef.id;
  }

  Future<void> updatePerson(
    String id, {
    required String name,
    required String phone,
    required String note,
  }) async {
    await _peopleCollection.doc(id).update({
      'name': name,
      'phone': phone,
      'note': note,
    });
  }

  /// Borç veya ödeme hareketi ekler.
  /// [addToLedger] işaretliyse:
  /// - ödeme -> Gelir Gider'e gider olarak eklenir (mutsuz animasyonu).
  /// - borç ekle -> Gelir Gider'e gelir olarak eklenir (kasaya giren para).
  Future<({bool addedToLedger, bool isIncome, double amount})> addEntry({
    required String personId,
    required String personName,
    required DebtEntryType type,
    required double amount,
    required DateTime date,
    required String description,
    required bool addToLedger,
  }) async {
    String? linkedTxId;
    final isPayment = type == DebtEntryType.odeme;
    final txIsIncome = !isPayment;

    final entryRef = _entriesCollection(personId).doc();

    if (addToLedger) {
      final txDesc = description.isNotEmpty
          ? '$personName - $description'
          : (isPayment ? '$personName (Borç Ödemesi)' : '$personName (Alınan Borç)');
      final tx = AppTransaction(
        amount: amount,
        type: txIsIncome ? TransactionType.income : TransactionType.expense,
        category: isPayment ? 'Borç Ödemesi' : 'Alınan Borç',
        paymentMethod: PaymentMethod.cash,
        description: txDesc,
        date: date,
        createdAt: DateTime.now(),
        sourceType: 'debt',
        sourceId: entryRef.id,
        sourceParentId: personId,
      );
      final txDoc = await _transactionsCollection.add(tx.toFirestore(isNew: true));
      linkedTxId = txDoc.id;
    }

    final entry = DebtEntry(
      id: entryRef.id,
      type: type,
      amount: amount,
      date: date,
      description: description,
      addedToLedger: addToLedger,
      transactionId: linkedTxId,
      createdAt: DateTime.now(),
    );

    await entryRef.set(entry.toFirestore(isNew: true));

    final delta = type == DebtEntryType.borcEkle ? amount : -amount;
    await _peopleCollection.doc(personId).update({
      'balance': FieldValue.increment(delta),
    });

    return (addedToLedger: addToLedger, isIncome: txIsIncome, amount: amount);
  }

  Future<void> deleteEntry({
    required String personId,
    required DebtEntry entry,
    required bool deleteLinkedTransaction,
  }) async {
    if (entry.id != null) {
      await _entriesCollection(personId).doc(entry.id!).delete();
    }

    if (deleteLinkedTransaction && entry.transactionId != null) {
      await _transactionsCollection.doc(entry.transactionId!).delete();
    }

    final remainingSnap = await _entriesCollection(personId).get();
    final remaining = remainingSnap.docs.map(DebtEntry.fromFirestore).toList();
    final newBalance = DebtEntry.calculateBalance(remaining);

    await _peopleCollection.doc(personId).update({'balance': newBalance});
  }

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

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return DebtRepository(firestore);
});
