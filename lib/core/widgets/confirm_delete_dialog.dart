import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const ConfirmDeleteDialog({
    super.key,
    this.title = 'Silme Onayı',
    this.message = 'Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
    this.confirmLabel = 'Sil',
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Silme Onayı',
    String message = 'Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
    String confirmLabel = 'Sil',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
