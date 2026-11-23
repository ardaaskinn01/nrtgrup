import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/staff.dart';

class StaffRepository {
  final FirebaseFirestore _firestore;

  StaffRepository(this._firestore);

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

  /// Personeli ve altındaki tüm puantaj (`attendance`) kayıtlarını siler.
  Future<void> deleteStaff(String id) async {
    final attendanceSnap = await _collection.doc(id).collection('attendance').get();
    final batch = _firestore.batch();
    for (final doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_collection.doc(id));
    await batch.commit();
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return StaffRepository(firestore);
});
