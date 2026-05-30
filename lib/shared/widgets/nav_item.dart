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
    final isLego = themeId == 'lego';

    // 定义各主题下的颜色
    final Color activeColor = isCottonCandy
        ? (widget.isNight ? const Color(0xFFFFE8A3) : const Color(0xFFE6607A))
        : (isLego
            ? (widget.isNight
                ? (widget.index == 0
                    ? const Color(0xFFF37D3B)
                    : widget.index == 1
                        ? const Color(0xFF5FAA73)
                        : widget.index == 3
                            ? const Color(0xFF629DE4)
                            : const Color(0xFFB4AED7))
                : (widget.index == 0
                    ? const Color(0xFFF37D3B)
                    : widget.index == 1
                        ? const Color(0xFF5FAA73)
                        : widget.index == 3
                            ? const Color(0xFF629DE4)
                            : const Color(0xFFB4AED7)))
            : (isLanternFestival
                ? const Color(0xFFFFEFA1)
                : (widget.isNight ? const Color(0xFFFFEFA1) : const Color(0xFF7B5C2E))));

    final Color inactiveColor = isCottonCandy
        ? (widget.isNight ? const Color(0xFFD3C6FF) : const Color(0xFF9E7777))
        : (isLego
            ? (widget.isNight ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E))
            : (isLanternFestival
                ? const Color(0xFFB5A492)
                : (widget.isNight ? const Color(0xFFB5B5C9) : const Color(0xFF8B7763))));

    final List<Shadow>? strokeShadows = isSelected && isCottonCandy
        ? (widget.isNight
            ? [
                Shadow(
                  color: const Color(0xFFFFE8A3).withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ]
            : const [
                Shadow(color: Colors.white, offset: Offset(-1.2, -1.2)),
                Shadow(color: Colors.white, offset: Offset(1.2, -1.2)),
                Shadow(color: Colors.white, offset: Offset(1.2, 1.2)),
                Shadow(color: Colors.white, offset: Offset(-1.2, 1.2)),
                Shadow(color: Colors.white, offset: Offset(0, -1.5)),
                Shadow(color: Colors.white, offset: Offset(0, 1.5)),
                Shadow(color: Colors.white, offset: Offset(-1.5, 0)),
                Shadow(color: Colors.white, offset: Offset(1.5, 0)),
              ])
        : null;

    String? customIconPath;
    if (isCottonCandy) {
      if (widget.index == 0) {
        customIconPath = 'assets/images/theme/miamhuadao/caidan1.png';
      } else if (widget.index == 1) {
        customIconPath = 'assets/images/theme/miamhuadao/caidan2.png';
      } else if (widget.index == 3) {
        customIconPath = 'assets/images/theme/miamhuadao/caidan3.png';
      } else if (widget.index == 4) {
        customIconPath = 'assets/images/theme/miamhuadao/caidan4.png';
      }
    } else if (isLego) {
      if (widget.index == 0) {
        customIconPath = 'assets/images/theme/legao/caidan1.png';
      } else if (widget.index == 1) {
        customIconPath = 'assets/images/theme/legao/caidan2.png';
      } else if (widget.index == 3) {
        customIconPath = 'assets/images/theme/legao/caidan3.png';
      } else if (widget.index == 4) {
        customIconPath = 'assets/images/theme/legao/caidan4.png';
      }
    }

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
                // 选中的辉光背景 (仅限日间，积木工坊主题选中时不显示该发光)
                if (isSelected && !widget.isNight && !isLego)
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
                customIconPath != null
                    ? Opacity(
                        opacity: isSelected ? 1.0 : 0.7,
                        child: Image.asset(
                          customIconPath,
                          width: 32.0,
                          height: 32.0,
                        ),
                      )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          begin: const Offset(0.9, 0.9),
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
                        )
                    : Icon(
                        isSelected ? (widget.activeIcon ?? widget.defaultIcon) : widget.defaultIcon,
                        size: 28.0,
                        color: isSelected ? activeColor : inactiveColor,
                        shadows: strokeShadows,
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
                shadows: strokeShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
