import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBento extends StatelessWidget {
  final bool isNight;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  const GlassBento({
    super.key,
    required this.isNight,
    required this.child,
    this.padding,
    this.blurSigma = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: isNight 
                  ? Colors.transparent 
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isNight 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );

  }
}
