import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/customer.dart';
import '../repositories/customer_repository.dart';

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(customerRepositoryProvider).watchCustomers();
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customersAsync = ref.watch(customersStreamProvider);
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();

  return customersAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.workSummary.toLowerCase().contains(query);
    }).toList();
  });
});

final customerByIdProvider = StreamProvider.family<Customer?, String>((ref, id) {
  return ref.watch(customerRepositoryProvider).watchCustomerById(id);
});

final customerPhotosProvider =
    StreamProvider.family<List<CustomerWorkPhoto>, String>((ref, customerId) {
  return ref.watch(customerRepositoryProvider).watchPhotos(customerId);
});

final customerNotesProvider =
    StreamProvider.family<List<CustomerNote>, String>((ref, customerId) {
  return ref.watch(customerRepositoryProvider).watchNotes(customerId);
});
