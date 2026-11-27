import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/supplier.dart';
import '../repositories/supplier_repository.dart';

final suppliersStreamProvider = StreamProvider<List<Supplier>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(supplierRepositoryProvider).watchSuppliers();
});

final supplierSearchQueryProvider = StateProvider<String>((ref) => '');
final supplierCategoryFilterProvider = StateProvider<SupplierCategory?>((ref) => null);

final filteredSuppliersProvider = Provider<AsyncValue<List<Supplier>>>((ref) {
  final suppliersAsync = ref.watch(suppliersStreamProvider);
  final query = ref.watch(supplierSearchQueryProvider).trim().toLowerCase();
  final categoryFilter = ref.watch(supplierCategoryFilterProvider);

  return suppliersAsync.whenData((list) {
    return list.where((s) {
      if (categoryFilter != null && s.category != categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.phone.toLowerCase().contains(query) ||
          s.notes.toLowerCase().contains(query) ||
          s.category.displayName.toLowerCase().contains(query);
    }).toList();
  });
});
