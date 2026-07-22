import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/core/services/wind_service.dart';

/// 狂风天气下“竹子遇大风弯腰”弹性物理变形包裹器
///
/// 当海岛风速处于狂风 (Gale) 或强风状态时，卡片底部扎根固定，
/// 卡片中上部与顶端顺应风向柔顺地向左/右弯曲 (skewX)，并伴随弹性回弹晃荡。
class WindBendCardWrapper extends StatefulWidget {
  final Widget child;

  /// 是否为竖长条卡片 (如重力盒、照片墙等高卡片，弯腰效果更显著)
  final bool isTall;

  const WindBendCardWrapper({
    super.key,
    required this.child,
    this.isTall = false,
  });

  @override
  State<WindBendCardWrapper> createState() => _WindBendCardWrapperState();
}

class _WindBendCardWrapperState extends State<WindBendCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // 持续的正弦波风吹打浪周期
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WindMode>(
      valueListenable: WindService.currentWind,
      builder: (context, wind, child) {
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final double time = _animController.value * 2 * math.pi;

            double baseSkew = 0.0;
            double swingRange = 0.0;
            double windTilt = 0.0;

            switch (wind) {
              case WindMode.none:
                baseSkew = 0.0;
                swingRange = 0.0;
                windTilt = 0.0;
                break;
              case WindMode.breeze:
                baseSkew = widget.isTall ? 0.015 : 0.008;
                swingRange = 0.005;
                windTilt = 0.008;
                break;
              case WindMode.moderate:
                baseSkew = widget.isTall ? 0.05 : 0.025;
                swingRange = 0.015;
                windTilt = 0.02;
                break;
              case WindMode.gale:
                // 风从右往左吹：顶部向屏幕左侧自然弯腰屈服 (baseSkew > 0, windTilt > 0)
                baseSkew = widget.isTall ? 0.18 : 0.08;
                swingRange = widget.isTall ? 0.045 : 0.02;
                windTilt = widget.isTall ? 0.05 : 0.025;
                break;
            }

            // 正弦波震荡模拟阵风一阵阵刮过的软萌回弹
            final double gustOscillation = math.sin(time) * swingRange;
            final double finalSkew = baseSkew + gustOscillation;
            final double finalTilt = windTilt + (gustOscillation * 0.5);

            // 构造底部扎根 (Alignment.bottomCenter) 的切变变形矩阵
            final Matrix4 bendTransform = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D 透视视差
              ..rotateZ(finalTilt) // 整体顺风轻微倾斜
              ..setEntry(0, 1, math.tan(finalSkew)); // 核心：底部扎根、顶部被吹弯腰切变！

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: bendTransform,
              transformAlignment: Alignment.bottomCenter, // 底部锚点：底部固定，顶部弯腰
              child: widget.child,
            );
          },
        );
      },
      child: widget.child,
    );
  }
}
