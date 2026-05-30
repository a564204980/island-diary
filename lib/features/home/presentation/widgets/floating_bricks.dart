import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// 积木工坊主题专属：围绕在小岛周边的浮动积木块元件（支持真实的重力感应倾斜与位移动效）
class FloatingBricks extends StatefulWidget {
  const FloatingBricks({super.key});

  @override
  State<FloatingBricks> createState() => _FloatingBricksState();
}

class _FloatingBricksState extends State<FloatingBricks>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // 重力倾斜位移量（基于加速度计）
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // 每个积木的物理运行状态
  late List<_BrickPhysicalState> _brickStates;

  @override
  void initState() {
    super.initState();
    
    // 初始化积木的物理状态
    _brickStates = List.generate(_bricks.length, (index) => _BrickPhysicalState());

    // 5秒完成一次基础浮动循环
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      _updatePhysics();
    })..repeat();

    // 订阅重力加速度计事件，使方块随着手机倾斜产生类似“引力”的位移与旋转，并保持倾斜状态
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          double targetX = -event.x * 3.5;
          double targetY = (event.y - 6.0) * 3.5;

          // 使用低通滤波进行平滑插值，消除手部细微抖动，保证动画丝滑
          _tiltX = _tiltX * 0.9 + targetX * 0.1;
          _tiltY = _tiltY * 0.9 + targetY * 0.1;

          // 限制最大位移量，避免倾斜过度导致积木飘出屏幕
          _tiltX = _tiltX.clamp(-40.0, 40.0);
          _tiltY = _tiltY.clamp(-40.0, 40.0);
        });
      }
    }, onError: (_) {
      // 容错处理：无传感器设备静默忽略
    });
  }

  // 每一帧更新物理运动
  void _updatePhysics() {
    if (!mounted) return;
    bool needsRepaint = false;

    // 假设每帧时间间隔 dt 约为 16ms (60fps)
    const double dt = 0.016;

    for (int i = 0; i < _bricks.length; i++) {
      final state = _brickStates[i];
      if (state.isFlying) {
        needsRepaint = true;
        
        // 1. 应用位移
        state.offsetX += state.vx * dt;
        state.offsetY += state.vy * dt;

        // 2. 应用空气阻力（减速）
        state.vx *= 0.975;
        state.vy *= 0.975;

        // 3. 屏幕边界碰撞检测与反弹
        // 绝对坐标计算
        final brick = _bricks[i];
        final size = brick.size;
        
        // 算出基于原本锚点的位置，然后加上物理偏移 state.offsetX/Y
        double baseLeft = 0;
        double baseTop = 0;

        if (brick.leftPercent != null) {
          baseLeft = _lastWidth * brick.leftPercent!;
        } else if (brick.rightPercent != null) {
          baseLeft = _lastWidth - _lastWidth * brick.rightPercent! - size;
        }

        if (brick.topPercent != null) {
          baseTop = _lastHeight * brick.topPercent!;
        } else if (brick.bottomPercent != null) {
          baseTop = _lastHeight - _lastHeight * brick.bottomPercent! - size;
        }

        double absoluteX = baseLeft + _tiltX + state.offsetX;
        double absoluteY = baseTop + _tiltY + state.offsetY;

        // 碰撞边界反弹 (含少量能量损失)
        const double restitution = 0.85; // 弹性系数
        
        if (absoluteX < 0) {
          state.offsetX = -baseLeft - _tiltX;
          state.vx = -state.vx * restitution;
        } else if (absoluteX + size > _lastWidth) {
          state.offsetX = _lastWidth - baseLeft - _tiltX - size;
          state.vx = -state.vx * restitution;
        }

        if (absoluteY < 0) {
          state.offsetY = -baseTop - _tiltY;
          state.vy = -state.vy * restitution;
        } else if (absoluteY + size > _lastHeight) {
          state.offsetY = _lastHeight - baseTop - _tiltY - size;
          state.vy = -state.vy * restitution;
        }

        // 4. 速度极慢时，启动平滑归位
        double speed = math.sqrt(state.vx * state.vx + state.vy * state.vy);
        if (speed < 15.0) {
          state.isFlying = false;
          state.isReturning = true;
          state.returnProgress = 0.0;
          state.returnStartX = state.offsetX;
          state.returnStartY = state.offsetY;
        }
      } else if (state.isReturning) {
        needsRepaint = true;
        state.returnProgress += 0.05; // 约20帧完成归位
        if (state.returnProgress >= 1.0) {
          state.isReturning = false;
          state.offsetX = 0.0;
          state.offsetY = 0.0;
        } else {
          // 使用正弦缓动使得归位更加柔和
          double t = math.sin(state.returnProgress * math.pi / 2);
          state.offsetX = state.returnStartX * (1.0 - t);
          state.offsetY = state.returnStartY * (1.0 - t);
        }
      }
    }

    if (needsRepaint) {
      setState(() {});
    }
  }

  // 记录屏幕宽高，以用于物理边缘计算
  double _lastWidth = 360.0;
  double _lastHeight = 640.0;

  // 触发弹射力
  void _shootBrick(int index) {
    final state = _brickStates[index];
    
    // 随机弹射方向角度
    final random = math.Random();
    double angle = random.nextDouble() * 2 * math.pi;
    
    // 随机初速度大小 (500 ~ 900 像素每秒)
    double speed = 600.0 + random.nextDouble() * 300.0;

    setState(() {
      state.vx = math.cos(angle) * speed;
      state.vy = math.sin(angle) * speed;
      state.isFlying = true;
      state.isReturning = false;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // 精心配置的浮动积木块列表（参考设计图的位置分布，大小与错落的相位）
  final List<_BrickConfig> _bricks = [
    // 左上部
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai5.png', // 绿色积木
      topPercent: 0.16,
      leftPercent: 0.08,
      size: 32,
      phase: 0.0,
      floatDistance: 12.0,
    ),
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai1.png', // 粉色加号
      topPercent: 0.26,
      leftPercent: 0.21,
      size: 26,
      phase: 1.2,
      floatDistance: 8.0,
    ),
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai3.png', // 黄色透明大积木
      topPercent: 0.14,
      leftPercent: 0.42,
      size: 40,
      phase: 3.5,
      floatDistance: 14.0,
    ),
    // 右上部
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai6.png', // 绿色小方块
      topPercent: 0.09,
      rightPercent: 0.26,
      size: 22,
      phase: 2.1,
      floatDistance: 10.0,
    ),
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai15.png', // 绿色十字积木
      topPercent: 0.26,
      rightPercent: 0.04,
      size: 30,
      phase: 4.8,
      floatDistance: 9.0,
    ),
    // 左下部
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai11.png', // 蓝绿渐变方块
      bottomPercent: 0.22,
      leftPercent: 0.08,
      size: 34,
      phase: 1.7,
      floatDistance: 11.0,
    ),
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai14.png', // 绿色十字块
      bottomPercent: 0.14,
      leftPercent: 0.20,
      size: 28,
      phase: 5.5,
      floatDistance: 8.0,
    ),
    // 右下部
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai13.png', // 绿色大透明块
      bottomPercent: 0.06,
      rightPercent: 0.22,
      size: 42,
      phase: 0.8,
      floatDistance: 13.0,
    ),
    _BrickConfig(
      imagePath: 'assets/images/theme/legao/icons/fangkuai2.png', // 橙粉小方块
      bottomPercent: 0.15,
      rightPercent: 0.36,
      size: 20,
      phase: 3.0,
      floatDistance: 7.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastWidth = constraints.maxWidth;
        _lastHeight = constraints.maxHeight;

        return Stack(
          children: List.generate(_bricks.length, (index) {
            final brick = _bricks[index];
            final state = _brickStates[index];

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double t = _controller.value;
                // 1. 基础起伏位移
                final double offsetY =
                    math.sin(t * 2 * math.pi + brick.phase) *
                    brick.floatDistance;

                // 2. 结合重力倾斜量与弹射物理位移计算最终位置
                double? top;
                double? bottom;
                double? left;
                double? right;

                // 根据上下左右的百分比分配
                if (brick.topPercent != null) {
                  top = _lastHeight * brick.topPercent! + offsetY + _tiltY + state.offsetY;
                }
                if (brick.bottomPercent != null) {
                  bottom = _lastHeight * brick.bottomPercent! + offsetY - _tiltY - state.offsetY;
                }
                if (brick.leftPercent != null) {
                  left = _lastWidth * brick.leftPercent! + _tiltX + state.offsetX;
                }
                if (brick.rightPercent != null) {
                  right = _lastWidth * brick.rightPercent! - _tiltX - state.offsetX;
                }

                return Positioned(
                  top: top,
                  bottom: bottom,
                  left: left,
                  right: right,
                  child: GestureDetector(
                    onTap: () {
                      _shootBrick(index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), // 扩大手势热区
                      child: Transform.rotate(
                        // 随着手机左右倾斜或飞行速度产生旋转
                        angle: brick.phase * 0.15 + (_tiltX * 0.008) + (state.isFlying ? (state.vx * 0.005) : 0),
                        child: Image.asset(
                          brick.imagePath,
                          width: brick.size,
                          height: brick.size,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}

// 积木的物理运动状态类
class _BrickPhysicalState {
  double offsetX = 0.0;
  double offsetY = 0.0;
  double vx = 0.0;
  double vy = 0.0;
  bool isFlying = false;
  
  // 归位过渡属性
  bool isReturning = false;
  double returnProgress = 0.0;
  double returnStartX = 0.0;
  double returnStartY = 0.0;
}

class _BrickConfig {
  final String imagePath;
  final double? topPercent;
  final double? bottomPercent;
  final double? leftPercent;
  final double? rightPercent;
  final double size;
  final double phase;
  final double floatDistance;

  const _BrickConfig({
    required this.imagePath,
    this.topPercent,
    this.bottomPercent,
    this.leftPercent,
    this.rightPercent,
    required this.size,
    required this.phase,
    required this.floatDistance,
  });
}

