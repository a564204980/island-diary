import 'package:flutter/material.dart';

/// 极简的单行精灵序列图（Sprite Sheet）播放组件
class SpriteAnimation extends StatefulWidget {
  final String assetPath;
  final int frameCount; // 序列图包含的总帧数（单行水平排列）
  final Duration duration; // 播放完整一轮需要的时间
  final double size; // 渲染出来的宽高尺寸

  const SpriteAnimation({
    super.key,
    required this.assetPath,
    required this.frameCount,
    this.duration = const Duration(milliseconds: 1000),
    this.size = 48.0,
  });

  @override
  State<SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<SpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(); // 无限循环播放
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // 根据动画进度，换算当前应该展示哪一帧 (0 到 frameCount - 1)
            final int frameIndex =
                (_controller.value * widget.frameCount).floor() %
                widget.frameCount;

            // 根据 Flutter Alignment 的特性 (-1.0 左边界到 1.0 右边界) 偏移图片
            final double xOffset = widget.frameCount <= 1
                ? 0.0
                : -1.0 + 2.0 * frameIndex / (widget.frameCount - 1);

            return FittedBox(
              // BoxFit.none 配合 alignment 可以在原本大小不变的情况下进行窗口级平移剪裁
              fit: BoxFit.none,
              alignment: Alignment(xOffset, 0.0),
              // 强制规定这张精灵图的逻辑大小！高度为单个窗口高，宽度为窗口宽的 N 倍
              // 因为通过 fill 强行撑满，每个切片的宽绝对精确等于 widget.size，彻底告别半脸错位！
              child: SizedBox(
                width: widget.size * widget.frameCount,
                height: widget.size,
                child: Image.asset(widget.assetPath, fit: BoxFit.fill),
              ),
            );
          },
        ),
      ),
    );
  }
}
