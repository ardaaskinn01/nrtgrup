import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const AppFab({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.primaryOrange,
      foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
