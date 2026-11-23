import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/customer.dart';

class PhotoViewerScreen extends StatelessWidget {
  final CustomerWorkPhoto photo;
  final VoidCallback onDelete;

  const PhotoViewerScreen({
    super.key,
    required this.photo,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required CustomerWorkPhoto photo,
    required VoidCallback onDelete,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(photo: photo, onDelete: onDelete),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: AppTheme.pureWhite,
        title: Text(
          AppFormatters.formatDate(photo.date),
          style: const TextStyle(color: AppTheme.pureWhite),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            tooltip: 'Fotoğrafı Sil',
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.5,
              child: Image.network(
                photo.url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                border: const Border(
                  top: BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.description,
                      style: const TextStyle(
                        color: AppTheme.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tarih: ${AppFormatters.formatLongDate(photo.date)}',
                      style: const TextStyle(
                        color: AppTheme.primaryOrangeLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
