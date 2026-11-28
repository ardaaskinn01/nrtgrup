import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../widgets/adaptive_shell.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/personal/screens/personal_home_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/debts/screens/debt_detail_screen.dart';
import '../../features/debts/screens/debts_list_screen.dart';
import '../../features/receivables/screens/receivable_detail_screen.dart';
import '../../features/receivables/screens/receivables_list_screen.dart';
import '../../features/staff/screens/staff_detail_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../../features/stock/screens/stock_list_screen.dart';
import '../../features/suppliers/screens/suppliers_list_screen.dart';
import '../../features/todos/screens/todos_list_screen.dart';
import '../../features/transactions/screens/cash_detail_screen.dart';
import '../../features/transactions/screens/cheques_screen.dart';
import '../../features/transactions/screens/gelir_gider_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final isAdminAsync = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final user = authService.currentUser;
      final currentLocation = state.matchedLocation;
      final isSplashRoute = currentLocation == AppConstants.splashRoute;
      final isLoginRoute = currentLocation == AppConstants.loginRoute;

      // Splash ekranındayken yönlendirmeyi splash'in kendi zamanlaması yapsın
      if (isSplashRoute) {
        return null;
      }

      if (user == null && !isLoginRoute) {
        return AppConstants.loginRoute;
      }

      if (user != null) {
        final isAdmin = isAdminAsync.value;
        // Rol henüz çözülmediyse bekle
        if (isAdmin == null) {
          return null;
        }

        if (!isAdmin) {
          // Personal rolündeki kullanıcı yalnızca personalHomeRoute'a erişebilir
          if (currentLocation != AppConstants.personalHomeRoute) {
            return AppConstants.personalHomeRoute;
          }
          return null;
        }

        if (isLoginRoute || currentLocation == AppConstants.personalHomeRoute) {
          return AppConstants.dashboardRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.personalHomeRoute,
        builder: (context, state) => const PersonalHomeScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.dashboardRoute,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppConstants.cashDetailRoute,
            builder: (context, state) => const CashDetailScreen(),
          ),
          GoRoute(
            path: AppConstants.ceklerimRoute,
            builder: (context, state) => const ChequesScreen(),
          ),
          GoRoute(
            path: AppConstants.gelirGiderRoute,
            builder: (context, state) => const GelirGiderScreen(),
          ),
          GoRoute(
            path: AppConstants.alacaklarRoute,
            builder: (context, state) => const ReceivablesListScreen(),
          ),
          GoRoute(
            path: '${AppConstants.alacaklarRoute}/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ReceivableDetailScreen(personId: id);
            },
          ),
          GoRoute(
            path: AppConstants.borclarRoute,
            builder: (context, state) => const DebtsListScreen(),
          ),
          GoRoute(
            path: '${AppConstants.borclarRoute}/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DebtDetailScreen(personId: id);
            },
          ),
          GoRoute(
            path: AppConstants.musterilerRoute,
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '${AppConstants.musterilerRoute}/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerDetailScreen(customerId: id);
            },
          ),
          GoRoute(
            path: AppConstants.tedarikcilerRoute,
            builder: (context, state) => const SuppliersListScreen(),
          ),
          GoRoute(
            path: AppConstants.stokRoute,
            builder: (context, state) => const StockListScreen(),
          ),
          GoRoute(
            path: AppConstants.personelRoute,
            builder: (context, state) => const StaffListScreen(),
          ),
          GoRoute(
            path: '${AppConstants.personelRoute}/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return StaffDetailScreen(staffId: id);
            },
          ),
          GoRoute(
            path: AppConstants.yapilacaklarRoute,
            builder: (context, state) => const TodosListScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
