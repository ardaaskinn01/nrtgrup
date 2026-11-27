import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/staff.dart';
import '../repositories/staff_repository.dart';

final staffStreamProvider = StreamProvider<List<StaffMember>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(staffRepositoryProvider).watchStaff();
});

final staffSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredStaffProvider = Provider<AsyncValue<List<StaffMember>>>((ref) {
  final staffAsync = ref.watch(staffStreamProvider);
  final query = ref.watch(staffSearchQueryProvider).trim().toLowerCase();

  return staffAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((s) {
      return s.fullName.toLowerCase().contains(query) ||
          s.phone.toLowerCase().contains(query) ||
          'maaş günü ${s.salaryDay}'.contains(query);
    }).toList();
  });
});

final staffByIdProvider = StreamProvider.family<StaffMember?, String>((ref, id) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(staffRepositoryProvider).watchStaffById(id).handleError((_) => null);
});

final staffPaymentsStreamProvider =
    StreamProvider.family<List<StaffPayment>, String>((ref, staffId) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(staffRepositoryProvider).watchPayments(staffId).handleError((_) => <StaffPayment>[]);
});
