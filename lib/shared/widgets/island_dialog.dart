import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局通用的 iOS 风格交互式弹窗，支持毛玻璃背景和左右文本按钮
class IslandDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final String? contentText;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const IslandDialog({
    super.key,
    this.title,
    this.content,
    this.contentText,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? content,
    String? contentText,
    String confirmText = '确定',
    String? cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    HapticFeedback.lightImpact();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'IslandDialog',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 250),
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
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isNight 
                    ? const Color(0xFF2C2C2E).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 20, left: 24, right: 24),
                    child: Column(
                      children: [
                        if (title != null && title!.isNotEmpty) ...[
                          Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isNight ? Colors.white : Colors.black,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          if (content != null || (contentText != null && contentText!.isNotEmpty))
                            const SizedBox(height: 12),
                        ],
                        if (content != null)
                          content!
                        else if (contentText != null && contentText!.isNotEmpty)
                          Text(
                            contentText!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isNight ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    height: 0.5,
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                  ),
                  Row(
                    children: [
                      if (cancelText != null) ...[
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (onCancel != null) {
                                onCancel!();
                              } else {
                                Navigator.of(context).pop(false);
                              }
                            },
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                cancelText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 50,
                          color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                        ),
                      ],
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (onConfirm != null) {
                              onConfirm!();
                            } else {
                              Navigator.of(context).pop(true);
                            }
                          },
                          borderRadius: BorderRadius.only(
                            bottomRight: const Radius.circular(16),
                            bottomLeft: cancelText == null ? const Radius.circular(16) : Radius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              confirmText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
