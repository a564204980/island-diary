import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 精致居中提示弹窗：图标 + 文字竖向排列，毛玻璃卡片风格
class IslandAlert extends StatelessWidget {
  final String message;
  final String icon;

  const IslandAlert({
    super.key,
    required this.message,
    this.icon = '✨',
  });

  /// 静态展示方法
  static Future<void> show(
    BuildContext context, {
    required String message,
    String icon = '✨',
    Duration duration = const Duration(seconds: 3),
    bool withAnimation = true,
    Alignment alignment = Alignment.center,
  }) {
    HapticFeedback.lightImpact();

    bool isPopped = false;
    final dialog = showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'IslandAlert',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: withAnimation
          ? const Duration(milliseconds: 360)
          : Duration.zero,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: alignment,
          child: IslandAlert(message: message, icon: icon),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        if (!withAnimation) return child;
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    dialog.then((_) => isPopped = true);

    Future.delayed(duration, () {
      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      if (!isPopped && navigator.canPop()) {
        navigator.pop();
      }
    });

    return dialog;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final textColor = isDark ? const Color(0xFFE5E5EA) : const Color(0xFF5D4037);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 40,
              spreadRadius: -5,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            )
                .animate()
                .scale(
                  delay: 80.ms,
                  duration: 450.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.55,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
