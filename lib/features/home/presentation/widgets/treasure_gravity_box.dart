import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';

/// 2D 物理重力盒内部贴纸项（基于标准速度与动量物理模型）
class TreasureItem {
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double angularVelocity;
  final double radius;
  final String imagePath;

  bool isSleeping = false;
  int sleepCounter = 0;

  TreasureItem({
    required this.x,
    required this.y,
    required this.radius,
    required this.imagePath,
    this.vx = 0.0,
    this.vy = 0.0,
    this.angle = 0.0,
    this.angularVelocity = 0.0,
  });
}

class TreasureGravityBoxWidget extends StatefulWidget {
  final double width;
  final double height;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;

  const TreasureGravityBoxWidget({
    super.key,
    required this.width,
    required this.height,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
  });

  @override
  State<TreasureGravityBoxWidget> createState() =>
      _TreasureGravityBoxWidgetState();
}

class _TreasureGravityBoxWidgetState extends State<TreasureGravityBoxWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  // 重力感应分量（单位：m/s²）
  double _gx = 0.0;
  double _gy = 9.8;

  double _lastGx = 0.0;
  double _lastGy = 9.8;

  final List<TreasureItem> _items = [];
  final math.Random _random = math.Random();

  /// 全局持久保存的物理饰品列表与高矮形态标识，
  /// 保证长按、拖拽手势、Rebuild 以及卸载重新挂载时 100% 保持饰品物理位置，绝对不误触发掉落刷新
  static List<TreasureItem>? _persistentItems;
  static bool? _persistentIsTall;

  @override
  void initState() {
    super.initState();

    // 持续物理循环 Ticker
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    final bool currentIsTall = widget.height > 200;

    // 只要高/矮形态没有发生改变，一律无缝继承现有的饰品列表及其当前位置/速度！
    if (_persistentItems != null &&
        _persistentItems!.isNotEmpty &&
        _persistentIsTall == currentIsTall) {
      _items.addAll(_persistentItems!);
    } else {
      _initItems();
    }
    _startPhysicsEngine();

    // 监听设备加速度传感器：实时感知手机 360 度任意角度倾斜与旋转
    _accelSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (mounted) {
        _gx = -event.x;
        _gy = event.y;

        // 当倾斜角度发生明显改变 (> 0.5) 时唤醒物理引擎
        if ((_gx - _lastGx).abs() > 0.5 || (_gy - _lastGy).abs() > 0.5) {
          _wakeUpPhysics();
        }
        _lastGx = _gx;
        _lastGy = _gy;
      }
    });
  }

  @override
  void dispose() {
    // 卸载时把最新的物品运动位置写回全局持久缓存
    if (_items.isNotEmpty) {
      _persistentItems = _items;
      _persistentIsTall = widget.height > 200;
    }
    _tickerController.dispose();
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TreasureGravityBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在明确的高/矮形态切换时才重新掉落物品；长按/拖拽/setState 刷新绝对静默
    final bool heightModeChanged =
        (widget.height > 200) != (oldWidget.height > 200);

    if (heightModeChanged) {
      _replayDropAnimation();
    }
  }

  void _startPhysicsEngine() {
    if (!_tickerController.isAnimating) {
      _tickerController.repeat();
    }
  }

  void _wakeUpPhysics() {
    bool hasAwakened = false;
    for (var item in _items) {
      if (item.isSleeping) {
        item.isSleeping = false;
        item.sleepCounter = 0;
        hasAwakened = true;
      }
    }
    if (hasAwakened || !_tickerController.isAnimating) {
      _startPhysicsEngine();
    }
  }

  void _replayDropAnimation() {
    if (!mounted) return;
    setState(() {
      _items.clear();
      _initItems();
    });
    _startPhysicsEngine();
  }

  void _initItems() {
    final userState = UserState();
    final ownedIds = userState.ownedDecorationIds.value;

    List<String> unlockedAssetPaths = [];

    // 获取已解锁的装饰道具
    for (var deco in MascotDecoration.allDecorations) {
      if (ownedIds.contains(deco.id) && !deco.path.contains('marshmallow')) {
        unlockedAssetPaths.add(deco.path);
      }
    }

    // 兜底丰富资源池
    final List<String> fallbackPool = [
      'assets/images/emoji/glasses/glasses1.png',
      'assets/images/emoji/glasses/glasses2.png',
      'assets/images/emoji/glasses/glasses3.png',
      'assets/images/emoji/hairstyle/hairstyle1.png',
      'assets/images/emoji/hairstyle/hairstyle2.png',
      'assets/images/emoji/hairstyle/hairstyle3.png',
      'assets/images/emoji/decorate/decorate1.png',
      'assets/images/emoji/decorate/decorate2.png',
      'assets/images/emoji/arrings/arrings2.png',
      'assets/images/sticker/bp_sweet_bunny1.png',
      'assets/images/sticker/bp_sweet_bunny2.png',
      'assets/images/sticker/bp_sweet_bunny3.png',
      'assets/images/sticker/bp_sweet_bunny4.png',
      'assets/images/sticker/bp_sweet_bunny5.png',
    ];

    for (var fallback in fallbackPool) {
      if (!unlockedAssetPaths.contains(fallback)) {
        unlockedAssetPaths.add(fallback);
      }
    }

    unlockedAssetPaths.shuffle(_random);

    final bool isTall = widget.height > 200;
    final int count = isTall ? 25 : 9; // 当高度为长方块时，物品数量增加到 3 倍(25个)！
    final double safeWidth = widget.width > 50.0 ? widget.width : 160.0;

    _items.clear();
    for (int i = 0; i < count; i++) {
      final radius = 13.0 + _random.nextDouble() * 4.0;
      final assetPath = unlockedAssetPaths[i % unlockedAssetPaths.length];

      _items.add(
        TreasureItem(
          x: 22.0 + (i % 4) * ((safeWidth - 44.0) / 3),
          y: -15.0 - (i % 4) * 15.0 - (i ~/ 4) * 12.0,
          vx: (_random.nextDouble() - 0.5) * 25.0,
          vy: 60.0 + _random.nextDouble() * 40.0,
          angle: (_random.nextDouble() - 0.5) * 1.0,
          angularVelocity: (_random.nextDouble() - 0.5) * 0.12,
          radius: radius,
          imagePath: assetPath,
        ),
      );
    }

    // 保存最新物理物品集合到持久化缓存
    _persistentItems = _items;
    _persistentIsTall = isTall;
  }

  void _onTick() {
    _updatePhysics();
    if (mounted) {
      setState(() {});
    }
  }

  void _updatePhysics() {
    const double dt = 0.016; // 固定 60fps 时间步长
    const double gravityScale = 120.0; // 重力加速度缩放
    const double damping = 0.96; // 空气阻尼
    const double bounce = 0.25; // 碰撞恢复系数

    final double boxWidth = widget.width;
    final double boxHeight = widget.height;

    // 1. 动力学更新 (位置与速度集成)
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.isSleeping) continue;

      // 施加重力加速度
      item.vx += _gx * gravityScale * dt;
      item.vy += _gy * gravityScale * dt;

      // 空气阻尼
      item.vx *= damping;
      item.vy *= damping;

      // 更新位置与自转角
      item.x += item.vx * dt;
      item.y += item.vy * dt;
      item.angle += item.angularVelocity;
      item.angularVelocity *= 0.95;
    }

    // 2. 约束与碰撞求解 (迭代 5 次以保证坚固堆叠)
    for (int iter = 0; iter < 5; iter++) {
      // 2.1 物品与物品碰撞检测及冲量解算
      for (int i = 0; i < _items.length; i++) {
        for (int j = i + 1; j < _items.length; j++) {
          final a = _items[i];
          final b = _items[j];

          if (a.isSleeping && b.isSleeping) continue;

          final dx = b.x - a.x;
          final dy = b.y - a.y;
          final distSq = dx * dx + dy * dy;
          final minDist = a.radius + b.radius;

          if (distSq < minDist * minDist && distSq > 0.0001) {
            final dist = math.sqrt(distSq);
            final overlap = minDist - dist;

            // 碰撞法线向量
            final nx = dx / dist;
            final ny = dy / dist;

            // 1) 位置分离 (防止重叠重叠穿模)
            if (a.isSleeping) {
              b.x += nx * overlap;
              b.y += ny * overlap;
            } else if (b.isSleeping) {
              a.x -= nx * overlap;
              a.y -= ny * overlap;
            } else {
              a.x -= nx * overlap * 0.5;
              a.y -= ny * overlap * 0.5;
              b.x += nx * overlap * 0.5;
              b.y += ny * overlap * 0.5;
            }

            // 2) 动量与冲量交换
            final dvx = b.vx - a.vx;
            final dvy = b.vy - a.vy;
            final velAlongNormal = dvx * nx + dvy * ny;

            // 仅在物品相互靠近时解算碰撞响应
            if (velAlongNormal < 0) {
              final impulse = -(1.0 + bounce) * velAlongNormal * 0.5;
              if (!a.isSleeping) {
                a.vx -= nx * impulse;
                a.vy -= ny * impulse;
              }
              if (!b.isSleeping) {
                b.vx += nx * impulse;
                b.vy += ny * impulse;
              }
            }
          }
        }
      }

      // 2.2 4 向墙壁边界碰撞解算
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.isSleeping) continue;

        final double visualRadius = item.radius * 1.3;
        const double safePadding = 14.0; // 舒适的安全内边距
        final double minX = visualRadius + safePadding;
        final double maxX = boxWidth - visualRadius - safePadding;
        final double minY = visualRadius + safePadding;
        final double maxY = boxHeight - visualRadius - safePadding;

        // 左边界
        if (item.x < minX) {
          item.x = minX;
          if (item.vx < 0) item.vx = -item.vx * bounce;
        }
        // 右边界
        else if (item.x > maxX) {
          item.x = maxX;
          if (item.vx > 0) item.vx = -item.vx * bounce;
        }

        // 上边界
        if (item.y < minY) {
          item.y = minY;
          if (item.vy < 0) item.vy = -item.vy * bounce;
        }
        // 下边界
        else if (item.y > maxY) {
          item.y = maxY;
          if (item.vy > 0) item.vy = -item.vy * bounce;
        }
      }
    }

    // 3. 静止检测与自动休眠 (只有连续 12 帧极微速时，才锁死休眠)
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.isSleeping) continue;

      final double speedSq = item.vx * item.vx + item.vy * item.vy;

      // 速度平方 < 15.0 (速度约 < 3.8px/s) 时判定为趋于静止
      if (speedSq < 15.0) {
        item.sleepCounter++;
        if (item.sleepCounter >= 12) {
          item.isSleeping = true;
          item.vx = 0.0;
          item.vy = 0.0;
          item.x = item.x.roundToDouble();
          item.y = item.y.roundToDouble();
        }
      } else {
        item.sleepCounter = 0;
      }
    }

    // 4. 当全部物品皆处于稳定休眠状态时，自动暂停物理引擎 Ticker 节约 CPU
    if (_items.isNotEmpty && _items.every((item) => item.isSleeping)) {
      if (_tickerController.isAnimating) {
        _tickerController.stop();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double strokeWidth = 2.0;
    final List<Offset> strokeOffsets = [
      const Offset(-strokeWidth, 0),
      const Offset(strokeWidth, 0),
      const Offset(0, -strokeWidth),
      const Offset(0, strokeWidth),
      const Offset(-strokeWidth, -strokeWidth),
      const Offset(-strokeWidth, strokeWidth),
      const Offset(strokeWidth, -strokeWidth),
      const Offset(strokeWidth, strokeWidth),
    ];

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTap: _replayDropAnimation,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 统一在卡片顶端展示精炼引导描述信息（无遮挡）
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: widget.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "倾斜手机 · 打捞配件",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontFamily: widget.fontFamily,
                          color: widget.subtitleColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 物理渲染层
            ..._items.map((item) {
              final visualRadius = item.radius * 1.3;
              final size = visualRadius * 2;

              return Positioned(
                left: item.x - visualRadius,
                top: item.y - visualRadius,
                child: Transform.rotate(
                  angle: item.angle,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 白色描边效果
                      ...strokeOffsets.map(
                        (offset) => Positioned(
                          left: offset.dx,
                          top: offset.dy,
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: Image.asset(
                              item.imagePath,
                              color: Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      // 实体贴纸图片
                      SizedBox(
                        width: size,
                        height: size,
                        child: Image.asset(item.imagePath),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
