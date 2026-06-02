import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

class GlassBento extends StatelessWidget {
  final bool isNight;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final Color? backgroundColor;

  const GlassBento({
    super.key,
    required this.isNight,
    required this.child,
    this.padding,
    this.blurSigma = 16.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isNight
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                color: isCottonCandyDark
                    ? const Color(0xCC2A3771)
                    : (isNight
                        ? (backgroundColor ?? Colors.transparent)
                        : const Color(0xFFFDFBFE)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCottonCandyDark
                      ? const Color(0xFF9986E1).withValues(alpha: 0.5)
                      : (isNight
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.8)),
                  width: isCottonCandyDark ? 3.0 : 1.5,
                ),
              ),
              padding: padding ?? const EdgeInsets.all(10),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
