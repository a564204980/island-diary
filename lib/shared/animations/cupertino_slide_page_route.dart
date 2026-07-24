import 'package:flutter/material.dart';

/// iOS 原生平滑右滑推入转场组件 (Cupertino Slide Page Route)
class CupertinoSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  CupertinoSlidePageRoute({
    required this.page,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // iOS 高级 Ease-Out Cubic 曲线
            final curveAnimation = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.2, 0.9, 0.1, 1.0),
              reverseCurve: Curves.easeInCubic,
            );

            // 新页面：从右侧 (1.0, 0.0) 平滑滑入到 (0.0, 0.0)
            final primarySlideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curveAnimation);

            // 旧页面（被推入后台）：向左平移 30% 并微弱变暗
            final secondaryCurveAnimation = CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Cubic(0.2, 0.9, 0.1, 1.0),
              reverseCurve: Curves.easeInCubic,
            );
            final secondarySlideAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(secondaryCurveAnimation);

            final secondaryDimAnimation = Tween<double>(
              begin: 0.0,
              end: 0.25,
            ).animate(secondaryCurveAnimation);

            return SlideTransition(
              position: secondarySlideAnimation,
              child: Stack(
                children: [
                  // 旧页面左推时的黑色遮罩暗影
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: secondaryDimAnimation,
                      builder: (context, _) {
                        return Container(
                          color: Colors.black.withValues(
                            alpha: secondaryDimAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // 新页面从右侧推入 + 左侧边缘微阴影
                  SlideTransition(
                    position: primarySlideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            );
          },
        );
}
