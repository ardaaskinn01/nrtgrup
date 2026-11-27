import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/debt.dart';
import '../repositories/debt_repository.dart';

final debtsStreamProvider = StreamProvider<List<DebtPerson>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(debtRepositoryProvider).watchDebts();
});

final debtSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredDebtsProvider = Provider<AsyncValue<List<DebtPerson>>>((ref) {
  final listAsync = ref.watch(debtsStreamProvider);
  final query = ref.watch(debtSearchQueryProvider).trim().toLowerCase();

  return listAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.phone.toLowerCase().contains(query);
    }).toList();
  });
});

final totalDebtsProvider = Provider<AsyncValue<double>>((ref) {
  final listAsync = ref.watch(debtsStreamProvider);
  return listAsync.whenData(
    (list) => list.fold<double>(0.0, (sum, p) => sum + p.balance),
  );
});

final debtByIdProvider = StreamProvider.family<DebtPerson?, String>((ref, id) {
  return ref.watch(debtRepositoryProvider).watchPersonById(id);
});

final debtEntriesProvider =
    StreamProvider.family<List<DebtEntry>, String>((ref, personId) {
  return ref.watch(debtRepositoryProvider).watchEntries(personId);
});
