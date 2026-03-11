import 'package:flutter/material.dart';

/// 极简的单行精灵序列图（Sprite Sheet）播放组件
class SpriteAnimation extends StatefulWidget {
  final String assetPath;
  final int frameCount;
  final Duration duration;
  final double size;
  final int? startFrame; // 起始帧 (含)
  final int? endFrame; // 结束帧 (含)
  final int? repeatCount; // 重复次数，null表示无限循环
  final bool isPlaying;

  const SpriteAnimation({
    super.key,
    required this.assetPath,
    required this.frameCount,
    this.duration = const Duration(milliseconds: 1000),
    this.size = 48.0,
    this.startFrame,
    this.endFrame,
    this.repeatCount,
    this.isPlaying = true,
  });

  @override
  State<SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<SpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentCycle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentCycle++;
        if (widget.repeatCount == null || _currentCycle < widget.repeatCount!) {
          _controller.forward(from: 0.0);
        } else {
          // 停止在起点
          _controller.value = 0.0;
        }
      }
    });

    if (widget.isPlaying) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果播放状态改变
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.forward(from: _controller.value);
      } else {
        _controller.stop();
        // 归位到第一帧
        _controller.value = 0.0;
      }
    }

    if (widget.assetPath != oldWidget.assetPath ||
        widget.startFrame != oldWidget.startFrame ||
        widget.endFrame != oldWidget.endFrame ||
        widget.repeatCount != oldWidget.repeatCount) {
      _currentCycle = 0;
      _controller.duration = widget.duration;
      if (widget.isPlaying) {
        _controller.forward(from: 0.0);
      }
    }
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
            final start = widget.startFrame ?? 0;
            final end = widget.endFrame ?? (widget.frameCount - 1);
            final range = end - start + 1;

            // 根据动画进度，换算当前应该展示哪一帧
            final int relativeIndex =
                (_controller.value * range).floor() % range;
            final int frameIndex = start + relativeIndex;

            // 根据 Flutter Alignment 的特性 (-1.0 左边界到 1.0 右边界) 偏移图片
            final double xOffset = widget.frameCount <= 1
                ? 0.0
                : -1.0 + 2.0 * frameIndex / (widget.frameCount - 1);

            return FittedBox(
              fit: BoxFit.none,
              alignment: Alignment(xOffset, 0.0),
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
