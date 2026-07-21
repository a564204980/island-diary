import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WebmCatAnimation extends StatefulWidget {
  final String assetPath;
  final double width;

  const WebmCatAnimation({
    super.key,
    required this.assetPath,
    required this.width,
  });

  @override
  State<WebmCatAnimation> createState() => _WebmCatAnimationState();
}

class _WebmCatAnimationState extends State<WebmCatAnimation> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        // 确保视频初始化完成后刷新状态以显示首帧
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      }).catchError((error) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.width,
        child: Center(
          child: Text(
            'Err: ${_controller.value.errorDescription}',
            style: const TextStyle(color: Colors.red, fontSize: 10),
          ),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return SizedBox(
        width: widget.width,
        // 在加载时，提供一个正方形的占位占位符，防止高度塌陷
        child: const AspectRatio(
          aspectRatio: 1.0, 
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
