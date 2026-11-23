import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/attendance_record.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String staffId) =>
      _firestore.collection('staff').doc(staffId).collection('attendance');

  Stream<List<AttendanceRecord>> watchAttendance(String staffId) {
    return _collection(staffId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AttendanceRecord.fromFirestore).toList();
      list.sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return (b.startHour * 60 + b.startMinute)
            .compareTo(a.startHour * 60 + a.startMinute);
      });
      return list;
    });
  }

  Future<String> addAttendance(String staffId, AttendanceRecord record) async {
    final docRef = await _collection(staffId).add(record.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateAttendance(
    String staffId,
    String recordId,
    AttendanceRecord record,
  ) async {
    await _collection(staffId)
        .doc(recordId)
        .update(record.toFirestore(isNew: false));
  }

  Future<void> deleteAttendance(String staffId, String recordId) async {
    await _collection(staffId).doc(recordId).delete();
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AttendanceRepository(firestore);
});
