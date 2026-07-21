import 'package:flutter/material.dart';

class FrameSequenceAnimation extends StatefulWidget {
  final String assetFolderPath;
  final String framePrefix;
  final String frameSuffix;
  final int frameCount;
  final double width;
  final int fps;
  final int loopIntervalSeconds; // 循环间隔时间（秒）

  const FrameSequenceAnimation({
    super.key,
    required this.assetFolderPath,
    required this.framePrefix,
    required this.frameSuffix,
    required this.frameCount,
    required this.width,
    this.fps = 24, // 默认 24 帧
    this.loopIntervalSeconds = 0, // 默认不间断
  });

  @override
  State<FrameSequenceAnimation> createState() => _FrameSequenceAnimationState();
}

class _FrameSequenceAnimationState extends State<FrameSequenceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // 根据 fps 和总帧数计算动画总时长
    final duration = Duration(
      milliseconds: (widget.frameCount * 1000 / widget.fps).round(),
    );

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    _animation = IntTween(
      begin: 1,
      end: widget.frameCount,
    ).animate(_controller);

    _startAnimationLoop();
  }
  
  Future<void> _startAnimationLoop() async {
    while (mounted && _isPlaying) {
      await _controller.forward(from: 0.0);
      if (!mounted || !_isPlaying) break;
      
      if (widget.loopIntervalSeconds > 0) {
        await Future.delayed(Duration(seconds: widget.loopIntervalSeconds));
      }
    }
  }

  @override
  void dispose() {
    _isPlaying = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 构建帧文件名，例如 frame_0001.png
        final frameNumber = _animation.value.toString().padLeft(4, '0');
        final framePath =
            '${widget.assetFolderPath}/${widget.framePrefix}$frameNumber${widget.frameSuffix}';
        return SizedBox(
          width: widget.width,
          child: Image.asset(
            framePath,
            width: widget.width,
            fit: BoxFit.contain,
            gaplessPlayback: true, // 防止切换图片时闪烁
          ),
        );
      },
    );
  }
}
