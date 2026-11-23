import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/staff.dart';
import '../repositories/staff_repository.dart';

final staffStreamProvider = StreamProvider<List<StaffMember>>((ref) {
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
          s.paymentType.displayName.toLowerCase().contains(query);
    }).toList();
  });
});

final staffByIdProvider = StreamProvider.family<StaffMember?, String>((ref, id) {
  return ref.watch(staffRepositoryProvider).watchStaffById(id);
});
