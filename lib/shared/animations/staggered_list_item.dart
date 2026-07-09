import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 列表瀑布流加载时的阶梯式上浮显现包裹器。
/// 
/// 传入当前项的 index，自动计算延迟时间，让卡片像发牌一样优雅进入视野。
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayStep = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final delay = delayStep * index;
    
    return child
        .animate(delay: delay)
        .fade(duration: duration)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: Curves.easeOutQuad,
        );
  }
}
