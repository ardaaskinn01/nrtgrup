import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

final attendanceStreamProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, staffId) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(attendanceRepositoryProvider).watchAttendance(staffId);
});

/// Seçili Ay ve Yıl filtresi (Personel ekranında ay ay listeleme için)
final attendanceMonthYearProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Seçili ay/yıla göre filtrelenmiş puantaj kayıtları
final filteredAttendanceProvider =
    Provider.family<AsyncValue<List<AttendanceRecord>>, String>((ref, staffId) {
  final recordsAsync = ref.watch(attendanceStreamProvider(staffId));
  final selectedMonthYear = ref.watch(attendanceMonthYearProvider);

  return recordsAsync.whenData((list) {
    return list.where((r) {
      return r.date.year == selectedMonthYear.year &&
          r.date.month == selectedMonthYear.month;
    }).toList();
  });
});

/// Seçili ay için toplam çalışılan süre (dakika)
final monthlyTotalMinutesProvider =
    Provider.family<AsyncValue<int>, String>((ref, staffId) {
  final filteredAsync = ref.watch(filteredAttendanceProvider(staffId));
  return filteredAsync.whenData(
    (list) => list.fold<int>(0, (total, r) => total + r.durationMinutes),
  );
});

/// Bugün giriş yapmış benzersiz personel sayısı
final todayCheckedInStaffCountProvider = StreamProvider<int>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }

  final firestore = ref.watch(firestoreProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  return firestore
      .collectionGroup('attendance')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
      .where('date', isLessThan: Timestamp.fromDate(todayEnd))
      .snapshots()
      .map((snap) {
    final staffIds = <String>{};
    for (final doc in snap.docs) {
      final parentStaffId = doc.reference.parent.parent?.id;
      if (parentStaffId != null) {
        staffIds.add(parentStaffId);
      }
    }
    return staffIds.length;
  }).handleError((_) => 0);
});
