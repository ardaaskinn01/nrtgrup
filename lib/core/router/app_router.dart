import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../widgets/adaptive_shell.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/debts/screens/debt_detail_screen.dart';
import '../../features/debts/screens/debts_list_screen.dart';
import '../../features/receivables/screens/receivable_detail_screen.dart';
import '../../features/receivables/screens/receivables_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/staff/screens/staff_detail_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../../features/transactions/screens/gelir_gider_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: AppConstants.loginRoute,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final user = authService.currentUser;
      final isLoginRoute = state.matchedLocation == AppConstants.loginRoute;

      if (user == null && !isLoginRoute) {
        return AppConstants.loginRoute;
      }

      if (user != null && isLoginRoute) {
        return AppConstants.dashboardRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.dashboardRoute,
            builder: (context, state) => const DashboardScreen(),
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
            path: AppConstants.ayarlarRoute,
            builder: (context, state) => const SettingsScreen(),
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
