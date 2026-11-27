import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/stock_item.dart';
import '../../../models/supplier.dart';
import '../repositories/stock_repository.dart';

final stocksStreamProvider = StreamProvider<List<StockItem>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  return ref.watch(stockRepositoryProvider).watchStocks();
});

final stockSearchQueryProvider = StateProvider<String>((ref) => '');
final stockCategoryFilterProvider = StateProvider<SupplierCategory?>((ref) => null);

final filteredStocksProvider = Provider<AsyncValue<List<StockItem>>>((ref) {
  final stocksAsync = ref.watch(stocksStreamProvider);
  final query = ref.watch(stockSearchQueryProvider).trim().toLowerCase();
  final categoryFilter = ref.watch(stockCategoryFilterProvider);

  return stocksAsync.whenData((list) {
    return list.where((item) {
      if (categoryFilter != null && item.category != categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.quantityText.toLowerCase().contains(query) ||
          item.supplierName.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query) ||
          item.category.displayName.toLowerCase().contains(query);
    }).toList();
  });
});
