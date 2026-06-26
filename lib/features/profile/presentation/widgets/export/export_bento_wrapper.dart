import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/statistics/presentation/widgets/glass_bento.dart';

class ExportBentoWrapper extends StatelessWidget {
  final String title;
  final String? helpContent;
  final Widget? rightAction;
  final Widget child;

  const ExportBentoWrapper({
    super.key,
    required this.title,
    this.helpContent,
    this.rightAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';
    final bool isLego = themeId == 'lego';

    final Color? cardBg = isCottonCandy ? const Color(0xFFFFF4EF) : null;

    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isNight ? Colors.white : const Color(0xFF5A3E28),
      letterSpacing: 0.5,
      fontFamily: 'LXGWWenKai',
    );

    final action = rightAction;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.info_circle,
                  size: 14,
                  color: isNight
                      ? Colors.white24
                      : Colors.black.withValues(alpha: 0.2),
                ),
              ],
            ),
            // ignore: use_null_aware_elements
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: child),
      ],
    );

    if (isLego) {
      return Container(
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF1E2024) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNight
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isNight ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ExportLegoStudPainter(isNight: isNight),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: cardContent,
              ),
            ],
          ),
        ),
      );
    }

    return GlassBento(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      backgroundColor: cardBg,
      blurSigma: 0.0,
      child: cardContent,
    );
  }
}

class _ExportLegoStudPainter extends CustomPainter {
  final bool isNight;
  _ExportLegoStudPainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = 13.0;
    final int cols = (size.width / cellSize).ceil();
    final int rows = (size.height / cellSize).ceil();

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final double cx = c * cellSize + cellSize / 2;
        final double cy = r * cellSize + cellSize / 2;
        final double radius = cellSize * 0.28;

        final double ratio = cy / size.height;
        double factor = 1.0;
        if (ratio < 0.5) {
          factor = 1.0 - (ratio / 0.5);
        } else {
          factor = 0.0;
        }

        if (factor <= 0.0) continue;

        final Color currentStudColor = isNight
            ? const Color(0xFF2C2F36).withValues(alpha: 0.12 * factor)
            : const Color(0xFFF9F9FB).withValues(alpha: 0.15 * factor);

        final Paint paint = Paint()..color = currentStudColor;
        canvas.drawCircle(Offset(cx, cy), radius, paint);

        final Paint highlightPaint = Paint()
          ..color = isNight
              ? Colors.white.withValues(alpha: 0.01 * factor)
              : Colors.white.withValues(alpha: 0.2 * factor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          -3.14 * 0.75,
          3.14,
          false,
          highlightPaint,
        );

        final Paint shadowPaint = Paint()
          ..color = isNight
              ? Colors.black.withValues(alpha: 0.08 * factor)
              : Colors.black.withValues(alpha: 0.04 * factor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          3.14 * 0.25,
          3.14,
          false,
          shadowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExportLegoStudPainter oldDelegate) =>
      oldDelegate.isNight != isNight;
}
