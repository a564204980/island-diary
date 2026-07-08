import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/theme/app_colors.dart';
import 'package:island_diary/core/theme/app_spacings.dart';

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
    final colors = AppColorsExtension.of(context);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: AppSpacings.dialogMaxWidth(context),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: AppSpacings.alertRadius,
            border: Border.all(
              color: colors.border,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.lightShadow,
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
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
