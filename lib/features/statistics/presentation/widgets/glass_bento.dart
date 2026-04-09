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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: isNight 
                ? Colors.black.withOpacity(0.3) 
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNight 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isNight 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}
