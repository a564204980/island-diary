import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // 用于 Ticker 定义
import 'dart:math' as math;
import 'package:island_diary/core/state/user_state.dart'; // 导入 UserState

class FloatingClouds extends StatelessWidget {
  final bool isNight;
  final bool isForeground;
  final bool shouldAnimate;
  final String? themeId;

  const FloatingClouds({
    super.key,
    required this.isNight,
    this.isForeground = false,
    this.shouldAnimate = true,
    this.themeId,
  });

  @override
  Widget build(BuildContext context) {


    // 基础配置表：降低云朵密度
    final List<Map<String, dynamic>> bgConfigs = themeId == 'cotton_candy'
        ? [
            {'scale': 0.6, 'duration': 50, 'initialTop': 0.08},
            {'scale': 0.8, 'duration': 75, 'initialTop': 0.25},
          ]
        : [
            {'scale': 0.7, 'duration': 45, 'initialTop': 0.05},
            {'scale': 1.1, 'duration': 65, 'initialTop': 0.20},
            {'scale': 0.5, 'duration': 40, 'initialTop': 0.35},
          ];

    final List<Map<String, dynamic>> fgConfigs = themeId == 'cotton_candy'
        ? [
            {'scale': 0.9, 'duration': 60, 'initialTop': 0.55},
          ]
        : [
            {'scale': 1.3, 'duration': 55, 'initialTop': 0.55},
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
            shouldAnimate: shouldAnimate,
            themeId: themeId,
            // 背景层由组件内部随机，不再使用固定索引
            forcedIndex: null,
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
  final bool shouldAnimate;
  final String? themeId;

  const _SingleCloud({
    required this.isNight,
    required this.isForeground,
    required this.scale,
    required this.duration,
    required this.initialTop,
    this.forcedIndex,
    this.shouldAnimate = true,
    this.themeId,
  });

  @override
  State<_SingleCloud> createState() => _SingleCloudState();
}

class _SingleCloudState extends State<_SingleCloud>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late double _currentTop;
  late int _currentIndex;
  final math.Random _random = math.Random();

  // 当前云朵在 1.0 倍速下走完一圈所需时长
  late Duration _currentBaseDuration;

  // 物理模拟的当前速度倍率与目标倍率，用于 Lerp 自然过渡
  double _currentSpeedMultiplier = 1.0;
  double _targetSpeedMultiplier = 1.0;

  // 上一次 Ticker 触发时的总时间，用于计算高精度 dt
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentTop = widget.initialTop;
    _currentIndex = widget.forcedIndex ?? _getRandomIndex();
    _currentBaseDuration = _getRandomDuration();

    // 随机一个初始的位移进度，防止云朵在刚打开页面时同步从右侧钻出
    _animationNotifier.value = _random.nextDouble();

    // 监听全局云朵速度倍率
    UserState().cloudSpeedMultiplier.addListener(_onSpeedMultiplierChanged);
    _targetSpeedMultiplier = UserState().cloudSpeedMultiplier.value;
    _currentSpeedMultiplier = _targetSpeedMultiplier;

    // 创建 Ticker 驱动高精度、极度平滑的物理位移与平滑变速过渡
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (!widget.shouldAnimate) return;

      // 1. 计算这一帧的真实时间间隔 dt
      double dt = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
      _lastElapsed = elapsed;

      // 安全限制 dt 的大小，防止应用退后台后突发大跳跃
      if (dt <= 0.0 || dt > 0.1) {
        dt = 0.01667;
      }

      // 2. 极其平滑的变速过渡 Lerp
      _currentSpeedMultiplier = _currentSpeedMultiplier * 0.94 + _targetSpeedMultiplier * 0.06;

      // 3. 高精度速度增量更新
      final double speed = (1.0 / _currentBaseDuration.inSeconds) * _currentSpeedMultiplier;
      
      // 每一帧直接更新 _animationValue，不再使用全量 setState()，由下方的 ValueNotifier/AnimatedBuilder 进行精准局部重绘以消除渲染卡顿
      _animationNotifier.value = (_animationNotifier.value + speed * dt);
      if (_animationNotifier.value >= 1.0) {
        _animationNotifier.value = 0.0;
        _randomize();
      }
    });

    if (widget.shouldAnimate) {
      _ticker.start();
    }
  }

  // 精准重绘监听器，避免全量局部刷新
  final ValueNotifier<double> _animationNotifier = ValueNotifier<double>(0.0);

  void _onSpeedMultiplierChanged() {
    if (mounted) {
      _targetSpeedMultiplier = UserState().cloudSpeedMultiplier.value;
    }
  }

  int _getRandomIndex() {
    if (widget.themeId == 'cotton_candy') {
      return _random.nextInt(7) + 2;
    }
    return _random.nextInt(9) + 1;
  }

  @override
  void didUpdateWidget(covariant _SingleCloud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate != oldWidget.shouldAnimate) {
      if (widget.shouldAnimate) {
        if (!_ticker.isActive) {
          _lastElapsed = Duration.zero;
          _ticker.start();
        }
      } else {
        if (_ticker.isActive) {
          _ticker.stop();
        }
      }
    }
    if (widget.themeId != oldWidget.themeId) {
      setState(() {
        _currentIndex = _getRandomIndex();
      });
    }
  }

  Duration _getRandomDuration() {
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
      _currentBaseDuration = _getRandomDuration();

      // 根据主题获取随机索引
      _currentIndex = _getRandomIndex();
    });
  }

  @override
  void dispose() {
    UserState().cloudSpeedMultiplier.removeListener(_onSpeedMultiplierChanged);
    _animationNotifier.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final Size screenSize = MediaQueryData.fromView(view).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double cloudWidth = widget.themeId == 'cotton_candy'
        ? 400.0 * 2 / 3
        : 400.0; // 云朵尺寸

    String basePath = 'assets/images/icons/';
    String suffix = widget.isNight ? '_night' : '';

    if (widget.themeId == 'cotton_candy') {
      basePath = 'assets/images/theme/miamhuadao/clouds/';
    }

    // 使用 ValueListenableBuilder 精准监听并重绘位置偏移，使渲染性能和帧连贯度完美起飞
    return ValueListenableBuilder<double>(
      valueListenable: _animationNotifier,
      builder: (context, animValue, child) {
        final double xPos = screenWidth - (animValue * (screenWidth + cloudWidth));
        
        return Positioned(
          top: screenHeight * _currentTop,
          left: xPos,
          child: Transform.scale(
            scale: widget.scale,
            child: Image.asset(
              '${basePath}clouds$_currentIndex$suffix.png',
              width: cloudWidth,
              fit: BoxFit.contain,
              color: Colors.white.withValues(
                alpha: widget.isForeground ? 0.85 : 0.65,
              ),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
        );
      },
    );
  }
}
