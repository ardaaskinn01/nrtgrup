import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import 'side_menu.dart';
import '../../features/auth/services/auth_service.dart';

class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final user = ref.watch(currentUserProvider).value;
    final location = GoRouterState.of(context).matchedLocation;
    final isDashboard = location == AppConstants.dashboardRoute;
    final router = GoRouter.of(context);
    final canPopRouter = router.canPop();

    final Widget content = isDesktop
        ? Scaffold(
            body: Row(
              children: [
                SideMenu(
                  key: ValueKey(user?.uid ?? 'no-user'),
                  isDrawer: false,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child),
              ],
            ),
          )
        : child;

    return PopScope(
      canPop: isDashboard && !canPopRouter,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (router.canPop()) {
          router.pop();
        } else if (!isDashboard) {
          context.go(AppConstants.dashboardRoute);
        }
      },
      child: content,
    );
  }
}
