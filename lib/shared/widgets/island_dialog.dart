import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/shared/widgets/island_button.dart';
import 'package:island_diary/core/theme/app_colors.dart';
import 'package:island_diary/core/theme/app_spacings.dart';
import 'package:island_diary/core/constants/app_strings.dart';

/// 全局通用的交互式弹窗，符合岛屿日记的主题风格（圆角、毛玻璃、精美排版）
class IslandDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final String contentText;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final bool isDestructive;

  const IslandDialog({
    super.key,
    required this.title,
    this.content,
    this.contentText = '',
    this.confirmText = AppStrings.confirm,
    this.cancelText = AppStrings.cancel,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.isDestructive = false,
  });

  /// 静态展示方法
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    Widget? content,
    String contentText = '',
    String confirmText = AppStrings.confirm,
    String? cancelText = AppStrings.cancel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    HapticFeedback.lightImpact();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'IslandDialog',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: IslandDialog(
            title: title,
            content: content,
            contentText: contentText,
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: onConfirm,
            onCancel: onCancel,
            confirmColor: confirmColor,
            isDestructive: isDestructive,
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: AppSpacings.dialogRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: AppSpacings.dialogMaxWidth(context),
            decoration: BoxDecoration(
              color: colors.glassBackground,
              borderRadius: AppSpacings.dialogRadius,
              border: Border.all(
                color: colors.border,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'LXGWWenKai',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (content != null)
                  content!
                else if (contentText.isNotEmpty)
                  Text(
                    contentText,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (cancelText != null) ...[
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (onCancel != null) {
                              onCancel!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            cancelText!,
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: IslandButton(
                        text: confirmText,
                        height: 48,
                        backgroundColor: confirmColor ?? (isDestructive ? Colors.redAccent : null),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (onConfirm != null) {
                            onConfirm!();
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
