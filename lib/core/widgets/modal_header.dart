import 'package:flutter/material.dart';

/// Modal alt sayfaları (Bottom Sheet) için standart başlık bileşeni.
/// iOS ve Android'de hem sürükleme çubuğu hem de belirgin kapatma (X) butonu sunar.
class ModalHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const ModalHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sürükleme Tutamağı (Drag Handle)
        Center(
          child: Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        // Başlık ve Sağ Üst Kapat (X) butonu
        Row(
          children: [
            const SizedBox(width: 44), // Başlığı tam ortalamak için sol denge boşluğu
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 18),
              ),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              tooltip: 'Kapat / Geri',
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
