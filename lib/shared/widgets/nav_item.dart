import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NavItem extends StatefulWidget {
  final String assetPath;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;

  const NavItem({
    super.key,
    required this.assetPath,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.isNight = false,
  });

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.currentIndex == widget.index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap(widget.index);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 选中的辉光背景 (仅限日间)
                if (isSelected && !widget.isNight)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE082).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms),
                Image.asset(
                      widget.assetPath,
                      width: 40.0,
                      height: 40.0,
                      fit: BoxFit.contain,
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    )
                    .custom(
                      duration: 3000.ms,
                      builder: (context, value, child) {
                        if (!isSelected) return child;
                        final sineValue = sin(value * 2 * pi) * 0.015;
                        return Transform.scale(
                          scale: 1.0 + sineValue,
                          child: child,
                        );
                      },
                    ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (widget.isNight
                        ? const Color(0xFFFFEFA1)
                        : const Color(0xFF7B5C2E))
                    : (widget.isNight
                        ? const Color(0xFFB5B5C9)
                        : const Color(0xFF8B7763)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
