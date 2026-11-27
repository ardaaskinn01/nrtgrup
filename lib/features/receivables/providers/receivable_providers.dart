import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/receivable.dart';
import '../repositories/receivable_repository.dart';

final receivablesStreamProvider = StreamProvider<List<ReceivablePerson>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(receivableRepositoryProvider).watchReceivables();
});

final receivableSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredReceivablesProvider = Provider<AsyncValue<List<ReceivablePerson>>>((ref) {
  final listAsync = ref.watch(receivablesStreamProvider);
  final query = ref.watch(receivableSearchQueryProvider).trim().toLowerCase();

  return listAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.phone.toLowerCase().contains(query);
    }).toList();
  });
});

final totalReceivablesProvider = Provider<AsyncValue<double>>((ref) {
  final listAsync = ref.watch(receivablesStreamProvider);
  return listAsync.whenData(
    (list) => list.fold<double>(0.0, (sum, p) => sum + p.balance),
  );
});

final receivableByIdProvider =
    StreamProvider.family<ReceivablePerson?, String>((ref, id) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return const Stream.empty();
  return ref.watch(receivableRepositoryProvider).watchPersonById(id).handleError((_) => null);
});

final receivableEntriesProvider =
    StreamProvider.family<List<ReceivableEntry>, String>((ref, personId) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return const Stream.empty();
  return ref.watch(receivableRepositoryProvider).watchEntries(personId).handleError((_) => <ReceivableEntry>[]);
});
