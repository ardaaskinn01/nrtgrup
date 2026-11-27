import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Temaya duyarlı yüksek kontrastlı durum renkleri döndürür.
class AdaptiveColors {
  static Color success(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  }

  static Color error(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  }

  static Color warning(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  }

  static Color orange(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.primaryOrangeLight : AppTheme.primaryOrangeDark;
  }

  static Color cardBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF171717) : AppTheme.pureWhite;
  }

  static Color cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE6E8EC);
  }

  static Color subText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFA3A3A3) : const Color(0xFF6B7280);
  }
}

/// Ana özet kartları için koyu obsidyen & turuncu vurgulu hero kart.
class HeroGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accentColor;
  final VoidCallback? onTap;

  const HeroGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accentColor = AppTheme.primaryOrange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0E0E0E),
            Color.lerp(const Color(0xFF141414), accentColor, 0.14)!,
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tüm liste ve detay ekranları için temiz, derinlikli yüzey kartı.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? leftAccentColor;
  final double borderRadius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.leftAccentColor,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AdaptiveColors.cardBg(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AdaptiveColors.cardBorder(context),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : const Color(0xFF0F172A).withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leftAccentColor != null)
                    Container(
                      width: 4.5,
                      color: leftAccentColor,
                    ),
                  Expanded(
                    child: Padding(
                      padding: padding,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuvarlatılmış kare ikon / monogram / avatar rozeti.
class IconSquircle extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String? text;
  final String? imageUrl;
  final double size;

  const IconSquircle({
    super.key,
    required this.color,
    this.icon,
    this.text,
    this.imageUrl,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.42 : 0.28),
            width: 1.1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              alignment: Alignment.center,
              child: Text(
                text ?? '',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.42 : 0.28),
          width: 1.1,
        ),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: color, size: size * 0.48)
          : Text(
              text ?? '',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}

/// Okunaklı durum/etiket hapı.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.38 : 0.22),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Temizleme butonlu modern arama alanı.
class SearchFieldBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const SearchFieldBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<SearchFieldBar> createState() => _SearchFieldBarState();
}

class _SearchFieldBarState extends State<SearchFieldBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (val) {
        setState(() {});
        widget.onChanged(val);
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 19),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
