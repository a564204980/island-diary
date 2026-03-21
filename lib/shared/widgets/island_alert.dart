import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 简约药丸风格弹窗：采用居中玻璃拟态与缩放弹性设计
class IslandAlert extends StatelessWidget {
  final String message;
  final String icon;

  const IslandAlert({
    super.key,
    required this.message,
    this.icon = '✨',
  });

  /// 静态展示方法：居中缩放的药丸提示
  /// [withAnimation] 为 false 时无弹出动画（适合已有弹窗层级中使用）
  static Future<void> show(
    BuildContext context, {
    required String message,
    String icon = '✨',
    Duration duration = const Duration(seconds: 3),
    bool withAnimation = true,
    Alignment alignment = Alignment.center,
  }) {
    HapticFeedback.lightImpact();
    
    // 使用 showGeneralDialog 实现居中缩放弹窗
    bool isPopped = false;
    final dialog = showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'IslandAlert',
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: withAnimation
          ? const Duration(milliseconds: 400)
          : Duration.zero,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: alignment,
          child: IslandAlert(message: message, icon: icon),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        if (!withAnimation) return child;
        final curve = Curves.easeOutBack;
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: curve),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    dialog.then((_) => isPopped = true);

    // 默认 3 秒后自动关闭
    Future.delayed(duration, () {
      if (!isPopped && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    return dialog;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    spreadRadius: -10,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ).animate().scale(delay: 200.ms, duration: 400.ms),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
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
