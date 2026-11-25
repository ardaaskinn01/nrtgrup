import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum MoodType { happy, slightlyHappy, sad }

class MoodBurstResult {
  final MoodType type;
  final String assetPath;
  final String label;

  const MoodBurstResult({
    required this.type,
    required this.assetPath,
    required this.label,
  });
}

class MoodBurst {
  /// 50.000 TL ve üzeri gelirlerde tam mutlu, altında az mutlu gösterilir.
  static const double happyThreshold = 50000.0;
  static const Duration displayDuration = Duration(milliseconds: 2100);

  static OverlayEntry? _activeEntry;

  /// Tutara ve işlem türüne göre gösterilecek görsel ve metni belirler.
  static MoodBurstResult resolve({
    required double amount,
    required bool isIncome,
  }) {
    if (!isIncome) {
      return const MoodBurstResult(
        type: MoodType.sad,
        assetPath: AppConstants.iconMutsuz,
        label: 'N. Tutak Mutsuz',
      );
    }
    if (amount >= happyThreshold) {
      return const MoodBurstResult(
        type: MoodType.happy,
        assetPath: AppConstants.iconMutlu,
        label: 'N. Tutak Çok Mutlu',
      );
    }
    return const MoodBurstResult(
      type: MoodType.slightlyHappy,
      assetPath: AppConstants.iconAzMutlu,
      label: 'N. Tutak Mutlu',
    );
  }

  /// Ekranda patlama animasyonuyla kısa süreli overlay gösterir (~2 sn).
  /// Dokunulduğunda veya süre dolduğunda kendiliğinden kapanır.
  static void show(
    BuildContext context, {
    required double amount,
    required bool isIncome,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismissActive();

    final mood = resolve(amount: amount, isIncome: isIncome);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _MoodBurstOverlay(
        mood: mood,
        amount: amount,
        isIncome: isIncome,
        onDismiss: () {
          if (_activeEntry == entry) {
            _activeEntry = null;
          }
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void _dismissActive() {
    final active = _activeEntry;
    _activeEntry = null;
    if (active != null && active.mounted) {
      active.remove();
    }
  }
}

class _MoodBurstOverlay extends StatefulWidget {
  final MoodBurstResult mood;
  final double amount;
  final bool isIncome;
  final VoidCallback onDismiss;

  const _MoodBurstOverlay({
    required this.mood,
    required this.amount,
    required this.isIncome,
    required this.onDismiss,
  });

  @override
  State<_MoodBurstOverlay> createState() => _MoodBurstOverlayState();
}

class _MoodBurstOverlayState extends State<_MoodBurstOverlay> {
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(MoodBurst.displayDuration, _handleDismiss);
  }

  void _handleDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSad = widget.mood.type == MoodType.sad;
    final accentColor = isSad ? AppTheme.errorColor : AppTheme.primaryOrange;

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleDismiss,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hafif patlama / konfeti parçacıkları
              if (!isSad) ..._buildBurstParticles(accentColor),

              // Ana Görsel Kartı
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.45),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image.asset(
                              widget.mood.assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.darkSurface,
                                child: Icon(
                                  isSad ? Icons.sentiment_very_dissatisfied : Icons.sentiment_very_satisfied,
                                  size: 96,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .shimmer(
                                delay: 250.ms,
                                duration: 900.ms,
                                color: accentColor.withValues(alpha: 0.32),
                              ),

                          // Okunaklı yarı saydam siyah şerit ve beyaz-turuncu yazı
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.78),
                              border: Border(
                                top: BorderSide(
                                  color: accentColor.withValues(alpha: 0.8),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.mood.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: isSad ? AppTheme.pureWhite : AppTheme.primaryOrange,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.isIncome ? '+' : '-'}${AppFormatters.formatCurrency(widget.amount)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 180.ms)
                  .scale(
                    begin: const Offset(0.35, 0.35),
                    end: const Offset(1.0, 1.0),
                    duration: 550.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBurstParticles(Color baseColor) {
    const count = 12;
    final colors = [
      AppTheme.primaryOrange,
      AppTheme.primaryOrangeLight,
      AppTheme.pureWhite,
      baseColor,
    ];

    return List.generate(count, (i) {
      final angle = (2 * math.pi / count) * i;
      final distance = 155.0 + (i % 3) * 22.0;
      final dx = math.cos(angle) * distance;
      final dy = math.sin(angle) * distance;
      final size = (i % 2 == 0) ? 10.0 : 7.0;

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors[i % colors.length],
          shape: i % 3 == 0 ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: i % 3 == 0 ? BorderRadius.circular(2) : null,
        ),
      )
          .animate()
          .fadeIn(duration: 120.ms)
          .move(
            begin: Offset.zero,
            end: Offset(dx, dy),
            duration: 650.ms,
            curve: Curves.easeOutCubic,
          )
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.3, 1.3),
            duration: 500.ms,
          )
          .fadeOut(delay: 450.ms, duration: 350.ms);
    });
  }
}
