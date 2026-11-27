import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../models/transaction.dart';
import '../repositories/cheque_repository.dart';
import '../repositories/transaction_repository.dart';

enum TransactionFilterPeriod { all, daily, monthly, yearly }

/// Tüm işlemlerin canlı Firestore stream'i
/// Kullanıcı oturumu açık ve hazır olana kadar bekleterek PERMISSION_DENIED hatasını önler.
final transactionsStreamProvider = StreamProvider<List<AppTransaction>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return const Stream.empty();
  }
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactions();
});

/// Gelir Gider sayfası filtre state'leri
final transactionPeriodProvider = StateProvider<TransactionFilterPeriod>(
  (ref) => TransactionFilterPeriod.monthly,
);

final transactionSelectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final transactionTypeFilterProvider = StateProvider<TransactionType?>(
  (ref) => null,
);

/// Filtrelenmiş işlemler
final filteredTransactionsProvider = Provider<AsyncValue<List<AppTransaction>>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final period = ref.watch(transactionPeriodProvider);
  final selectedDate = ref.watch(transactionSelectedDateProvider);
  final typeFilter = ref.watch(transactionTypeFilterProvider);

  return transactionsAsync.whenData((list) {
    return list.where((tx) {
      if (typeFilter != null && tx.type != typeFilter) return false;

      switch (period) {
        case TransactionFilterPeriod.all:
          return true;
        case TransactionFilterPeriod.daily:
          return tx.date.year == selectedDate.year &&
              tx.date.month == selectedDate.month &&
              tx.date.day == selectedDate.day;
        case TransactionFilterPeriod.monthly:
          return tx.date.year == selectedDate.year &&
              tx.date.month == selectedDate.month;
        case TransactionFilterPeriod.yearly:
          return tx.date.year == selectedDate.year;
      }
    }).toList();
  });
});

class BalanceSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double cashBalance;
  final double chequeBalance;
  final int chequeCount;
  final double monthIncome;
  final double monthExpense;
  final double todayIncome;
  final double todayExpense;
  final int todayIncomeCount;
  final int todayExpenseCount;

  const BalanceSummary({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.netBalance = 0,
    this.cashBalance = 0,
    this.chequeBalance = 0,
    this.chequeCount = 0,
    this.monthIncome = 0,
    this.monthExpense = 0,
    this.todayIncome = 0,
    this.todayExpense = 0,
    this.todayIncomeCount = 0,
    this.todayExpenseCount = 0,
  });
}

/// Ana Panel için genel, aylık ve bugünkü bakiye özeti (Nakit + Çek dağılımı dahil)
final overallBalanceProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final inHandCheques = ref.watch(inHandChequesProvider).value ?? [];
  final now = DateTime.now();

  return transactionsAsync.whenData((list) {
    double totalIncome = 0;
    double totalExpense = 0;
    double monthIncome = 0;
    double monthExpense = 0;
    double todayIncome = 0;
    double todayExpense = 0;
    int todayIncomeCount = 0;
    int todayExpenseCount = 0;

    for (final tx in list) {
      final isThisMonth = tx.date.year == now.year && tx.date.month == now.month;
      final isToday = isThisMonth && tx.date.day == now.day;

      if (tx.isIncome) {
        totalIncome += tx.amount;
        if (isThisMonth) monthIncome += tx.amount;
        if (isToday) {
          todayIncome += tx.amount;
          todayIncomeCount++;
        }
      } else {
        totalExpense += tx.amount;
        if (isThisMonth) monthExpense += tx.amount;
        if (isToday) {
          todayExpense += tx.amount;
          todayExpenseCount++;
        }
      }
    }

    final netBalance = totalIncome - totalExpense;
    final chequeBalance = inHandCheques.fold<double>(0.0, (sum, c) => sum + c.amount);
    final cashBalance = netBalance - chequeBalance;

    return BalanceSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: netBalance,
      cashBalance: cashBalance,
      chequeBalance: chequeBalance,
      chequeCount: inHandCheques.length,
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      todayIncome: todayIncome,
      todayExpense: todayExpense,
      todayIncomeCount: todayIncomeCount,
      todayExpenseCount: todayExpenseCount,
    );
  });
});
