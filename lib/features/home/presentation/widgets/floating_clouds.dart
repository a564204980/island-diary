import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingClouds extends StatelessWidget {
  final bool isNight;
  final bool isForeground;
  const FloatingClouds({
    super.key,
    required this.isNight,
    this.isForeground = false,
  });

  @override
  Widget build(BuildContext context) {
    // 基础配置表
    final List<Map<String, dynamic>> bgConfigs = [
      {'scale': 0.7, 'duration': 35, 'initialTop': 0.12},
      {'scale': 1.1, 'duration': 50, 'initialTop': 0.28},
      {'scale': 0.4, 'duration': 30, 'initialTop': 0.08},
    ];

    final List<Map<String, dynamic>> fgConfigs = [
      {'scale': 1.2, 'duration': 45, 'initialTop': 0.45},
    ];

    final configs = isForeground ? fgConfigs : bgConfigs;

    return IgnorePointer(
      child: Stack(
        children: configs.map((config) {
          return _SingleCloud(
            isNight: isNight,
            isForeground: isForeground,
            scale: config['scale'],
            duration: Duration(seconds: config['duration']),
            initialTop: config['initialTop'],
            // 背景层使用固定索引，前景层由组件内部随机
            forcedIndex: isForeground
                ? null
                : (configs.indexOf(config) % 4 + 1),
          );
        }).toList(),
      ),
    );
  }
}

class _SingleCloud extends StatefulWidget {
  final bool isNight;
  final bool isForeground;
  final double scale;
  final Duration duration;
  final double initialTop;
  final int? forcedIndex;

  const _SingleCloud({
    required this.isNight,
    required this.isForeground,
    required this.scale,
    required this.duration,
    required this.initialTop,
    this.forcedIndex,
  });

  @override
  State<_SingleCloud> createState() => _SingleCloudState();
}

class _SingleCloudState extends State<_SingleCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _currentTop;
  late int _currentIndex;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _currentTop = widget.initialTop;
    _currentIndex = widget.forcedIndex ?? (_random.nextInt(4) + 1);

    // 初始化控制器，并随机一个初始速度
    _controller = AnimationController(
      vsync: this,
      duration: _getRandomDuration(),
    );

    // 监听动画状态，在每次重置时随机垂直位置、索引和速度
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _randomize();
        _controller.forward(from: 0.0);
      }
    });

    // 随机起始点，防止所有云朵同步刷新
    _controller.forward(from: _random.nextDouble());
  }

  Duration _getRandomDuration() {
    // 在传入的基础时长上下浮动 40%
    final baseSeconds = widget.duration.inSeconds;
    final int variation = (baseSeconds * 0.4).toInt();
    final randomSeconds =
        baseSeconds + (_random.nextInt(variation * 2) - variation);
    return Duration(seconds: randomSeconds.clamp(15, 90));
  }

  void _randomize() {
    setState(() {
      // 在初始位置上下浮动
      final range = widget.isForeground ? 0.3 : 0.15;
      _currentTop =
          (widget.initialTop + (_random.nextDouble() * range - (range / 2)))
              .clamp(0.05, 0.85);

      // 更新速度（时长）
      _controller.duration = _getRandomDuration();

      // 如果没有强制索引，则随机切换云朵样式
      if (widget.forcedIndex == null) {
        _currentIndex = _random.nextInt(4) + 1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        const cloudWidth = 400.0;

        // 线性位移：从右侧进，左侧出
        final double t = _controller.value;
        final double xPos = screenWidth - (t * (screenWidth + cloudWidth));

        return Positioned(
          top: screenHeight * _currentTop,
          left: xPos,
          child: Opacity(
            // 增加不透明度（特别是前景层）以确保有效遮挡星星
            opacity: widget.isForeground ? 0.85 : 0.65,
            child: Transform.scale(
              scale: widget.scale,
              child: Image.asset(
                'assets/images/icons/clouds${_currentIndex}${widget.isNight ? '_night' : ''}.png',
                width: cloudWidth,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
