import 'package:flutter/material.dart';

/// iOS 风格共享轴微缩放与淡入淡出转场路由 (Shared Axis Scale & Fade Page Route)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SharedAxisPageRoute({
    required this.page,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // iOS 极佳 Ease-Out Cubic 弹性贝塞尔曲线
            final curveAnimation = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.2, 0.9, 0.1, 1.0),
              reverseCurve: Curves.easeInCubic,
            );

            // 入场：0.95 -> 1.0 展开与 0.0 -> 1.0 淡入
            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(curveAnimation);
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curveAnimation);

            // 被推入后台页面：1.0 -> 0.96 微缩与淡出
            final secondaryCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Cubic(0.2, 0.9, 0.1, 1.0),
              reverseCurve: Curves.easeInCubic,
            );
            final secondaryScaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(secondaryCurve);
            final secondaryFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(secondaryCurve);

            return FadeTransition(
              opacity: secondaryFadeAnimation,
              child: ScaleTransition(
                scale: secondaryScaleAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
