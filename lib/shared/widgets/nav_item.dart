import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class NavItem extends StatefulWidget {
  final IconData defaultIcon;
  final IconData? activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;

  const NavItem({
    super.key,
    required this.defaultIcon,
    this.activeIcon,
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
    final themeId = UserState().selectedIslandThemeId.value;
    final isLanternFestival = themeId == 'lantern_festival';
    final isCottonCandy = themeId == 'cotton_candy';

    // 定义各主题下的颜色
    final Color activeColor = isLanternFestival || isCottonCandy
        ? (isCottonCandy ? const Color(0xFF7B5C2E) : const Color(0xFFFFEFA1))
        : (widget.isNight ? const Color(0xFFFFEFA1) : const Color(0xFF7B5C2E));

    final Color inactiveColor = isLanternFestival || isCottonCandy
        ? (isCottonCandy ? const Color(0xFF9E7777) : const Color(0xFFB5A492))
        : (widget.isNight ? const Color(0xFFB5B5C9) : const Color(0xFF8B7763));

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
                          color: isCottonCandy 
                              ? const Color(0xFFFFCADB).withValues(alpha: 0.6)
                              : const Color(0xFFFFE082).withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms),
                Icon(
                  isSelected ? (widget.activeIcon ?? widget.defaultIcon) : widget.defaultIcon,
                  size: 28.0,
                  color: isSelected ? activeColor : inactiveColor,
                  shadows: isSelected && isCottonCandy
                      ? [
                          const Shadow(color: Colors.white, blurRadius: 8),
                          const Shadow(color: Colors.white, blurRadius: 4),
                        ]
                      : null,
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
                color: isSelected ? activeColor : inactiveColor,
                shadows: isSelected && isCottonCandy
                    ? [
                        const Shadow(color: Colors.white, blurRadius: 6),
                        const Shadow(color: Colors.white, blurRadius: 3),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
