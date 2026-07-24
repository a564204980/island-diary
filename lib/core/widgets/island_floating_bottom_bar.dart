import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';

/// 岛屿全局通用悬浮胶囊底部菜单组件 (IslandFloatingBottomBar)
/// 适用于日记详情页、照片墙详情页等沉浸式页面，保证全局统一的毛玻璃样式与定位规范
class IslandFloatingBottomBar extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final Color? backgroundColor;
  final Color? borderColor;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Offset offset;
  final bool enableEntranceAnimation;

  const IslandFloatingBottomBar({
    super.key,
    required this.children,
    required this.isDark,
    this.backgroundColor,
    this.borderColor,
    this.height = 48.0,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.offset = Offset.zero,
    this.enableEntranceAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBgColor = isDark
        ? const Color(0x992C2E30)
        : const Color(0xB3FFFFFF);

    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    Widget content = Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? defaultBorderColor,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );

    if (enableEntranceAnimation) {
      content = content
          .animate()
          .fadeIn(delay: 200.ms)
          .scale(begin: const Offset(0.95, 0.95));
    }

    // 内部硬编码严格固定离底 30px，禁止外部修改
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30.0,
      child: AnimatedSlide(
        offset: offset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutBack,
        child: content,
      ),
    );
  }
}

/// 悬浮胶囊菜单中的单个 Icon 操作按钮 (IslandFloatingBottomBarItem)
class IslandFloatingBottomBarItem extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double iconSize;
  final double width;
  final double height;
  final String? tooltip;

  const IslandFloatingBottomBarItem({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
    this.iconSize = 22.0,
    this.width = 44.0,
    this.height = 48.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      scaleFactor: 0.82,
      child: Container(
        width: width,
        height: height,
        color: Colors.transparent,
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
