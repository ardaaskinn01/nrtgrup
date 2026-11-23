import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'side_menu.dart';
import '../../features/auth/services/auth_service.dart';

class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final user = ref.watch(currentUserProvider).value;

    if (isDesktop) {
      return Scaffold(
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
      );
    }

    // Mobil ve iOS ekranlarında alt sayfalar kendi Scaffold / Drawer'larını yönetir
    return child;
  }
}
