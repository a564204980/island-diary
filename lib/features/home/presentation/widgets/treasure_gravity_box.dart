import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';

class TreasureItem {
  double x;
  double y;
  double lastX = 0;
  double lastY = 0;
  double angle;
  final double radius;
  final String imagePath;
  final double mass;

  bool isSleeping = false;
  int sleepCounter = 0;

  TreasureItem({
    required this.x,
    required this.y,
    required this.radius,
    required this.imagePath,
    double vx = 0.0,
    double vy = 0.0,
    this.angle = 0.0,
    this.mass = 1.0,
  }) : lastX = x - vx * 0.016,
       lastY = y - vy * 0.016;
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

  double _gx = 0.0;
  double _gy = 9.8;

  double _lastGx = 0.0;
  double _lastGy = 9.8;

  final List<TreasureItem> _items = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 动画控制器设置为 900 毫秒 (确保所有高空掉落物品全部落到底部平稳堆叠)
    _tickerController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 900),
          )
          ..addListener(_onTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _onAnimationComplete();
            }
          });

    _initItems();
    _tickerController.forward();

    // 监听重力感应
    _accelSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (mounted) {
        _gx = -event.x;
        _gy = event.y;

        // 手机大幅晃动倾斜时，唤醒动画重新播放
        if ((_gx - _lastGx).abs() > 3.0 || (_gy - _lastGy).abs() > 3.0) {
          if (!_tickerController.isAnimating) {
            _replayDropAnimation();
          }
        }
        _lastGx = _gx;
        _lastGy = _gy;
      }
    });
  }

  void _replayDropAnimation() {
    if (!mounted) return;
    setState(() {
      _items.clear();
      _initItems();
    });
    _tickerController.reset();
    _tickerController.forward();
  }

  void _onAnimationComplete() {
    if (!mounted) return;

    final double boxHeight = widget.height > 50.0 ? widget.height : 140.0;
    // 刚性防挂起安全校验：如果页面路由切换/延迟导致动画在半空 (y < boxHeight - 75) 提前完成，
    // 绝对禁止在半空 (y = 10) 锁死休眠！重置控制器继续下落直至全员安全落底！
    bool anyMidAir = _items.any((item) => item.y < boxHeight - 75.0);
    if (anyMidAir) {
      _tickerController.reset();
      _tickerController.forward();
      return;
    }

    // 全员安全触底后，将坐标四舍五入精确锁定，彻底断电休眠
    for (var item in _items) {
      item.isSleeping = true;
      item.x = item.x.roundToDouble();
      item.y = item.y.roundToDouble();
      item.lastX = item.x;
      item.lastY = item.y;
    }
    // 触发最后一次 setState 呈现完美静态图，此后 tickerController 彻底停止，零刷新！
    setState(() {});
  }

  void _initItems() {
    final userState = UserState();
    final ownedIds = userState.ownedDecorationIds.value;

    List<String> unlockedAssetPaths = [];

    // 从全局饰品注册表中获取用户已拥有的各类装饰道具 (眼镜/发型/帽子/头饰/耳饰)
    // 排除小软本体形象 (marshmallow)
    for (var deco in MascotDecoration.allDecorations) {
      if (ownedIds.contains(deco.id) && !deco.path.contains('marshmallow')) {
        unlockedAssetPaths.add(deco.path);
      }
    }

    // 道具全品类兜底资源池 (纯装饰道具：眼镜、发型、头饰、耳饰)
    final List<String> fallbackPool = [
      'assets/images/emoji/glasses/glasses1.png',
      'assets/images/emoji/glasses/glasses2.png',
      'assets/images/emoji/glasses/glasses3.png',
      'assets/images/emoji/hairstyle/hairstyle1.png',
      'assets/images/emoji/hairstyle/hairstyle2.png',
      'assets/images/emoji/decorate/decorate1.png',
      'assets/images/emoji/decorate/decorate2.png',
      'assets/images/emoji/arrings/arrings2.png',
    ];

    for (var fallback in fallbackPool) {
      if (!unlockedAssetPaths.contains(fallback)) {
        unlockedAssetPaths.add(fallback);
      }
    }

    // 随机打乱，抽取 9 个获得装饰道具入盒掉落
    unlockedAssetPaths.shuffle(_random);
    final int count = math.min(unlockedAssetPaths.length, 18);

    // 尺寸防御：防止初始化首帧尺寸未就绪导致计算负坐标
    final double safeWidth = widget.width > 50.0 ? widget.width : 160.0;

    for (int i = 0; i < count; i++) {
      final radius = 14.0 + _random.nextDouble() * 4.0;
      _items.add(
        TreasureItem(
          // 紧贴盒顶 (-15 ~ -45) 顺序排列，进入页面 0.01 秒内立刻显示并向下掉落
          x: 25.0 + (i % 3) * ((safeWidth - 50.0) / 2),
          y: -15.0 - (i % 3) * 12.0 - (i ~/ 3) * 10.0,
          vx: (_random.nextDouble() - 0.5) * 15.0,
          vy: 220.0 + _random.nextDouble() * 40.0,
          angle: (_random.nextDouble() - 0.5) * 0.8,
          radius: radius,
          imagePath: unlockedAssetPaths[i],
        ),
      );
    }
  }

  void _onTick() {
    _updatePhysics();
    if (mounted) {
      setState(() {});
    }
  }

  void _updatePhysics() {
    double dt = 0.016;

    final double boxWidth = widget.width;
    final double boxHeight = widget.height;
    final double adjustedGravityScale = 2500.0;

    // 1. Verlet Integration
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.isSleeping) continue;

      double appliedGx = _gx.abs() > 3.0 ? _gx : 0.0;
      double appliedGy = 9.8;

      double vx = item.x - item.lastX;
      double vy = item.y - item.lastY;

      // 道具在半空中高速顺畅下落 (0.98)，只有落到底部堆叠区 (y > boxHeight - 70) 才开启强动能吸收
      if (item.y > boxHeight - 70.0) {
        vx *= 0.85;
        vy *= 0.85;
      } else {
        vx *= 0.98;
        vy *= 0.98;
      }

      double nextX = item.x + vx + appliedGx * adjustedGravityScale * dt * dt;
      double nextY = item.y + vy + appliedGy * adjustedGravityScale * dt * dt;

      item.lastX = item.x;
      item.lastY = item.y;
      item.x = nextX;
      item.y = nextY;
    }

    // 2. Constraint Solving
    for (int iter = 0; iter < 8; iter++) {
      for (int i = 0; i < _items.length; i++) {
        for (int j = i + 1; j < _items.length; j++) {
          final a = _items[i];
          final b = _items[j];

          final dx = b.x - a.x;
          final dy = b.y - a.y;
          final distSq = dx * dx + dy * dy;
          final minDist = a.radius + b.radius;

          if (distSq < minDist * minDist && distSq > 0.0001) {
            if (a.isSleeping && b.isSleeping) continue;

            final dist = math.sqrt(distSq);
            final overlap = minDist - dist;

            final nx = dx / dist;
            final ny = dy / dist;

            // 睡眠物品质量无穷大：完全由活动物品承担 100% 的排斥位移，睡眠物品纹丝不动！
            if (a.isSleeping) {
              double corrYB = ny < 0 ? ny * overlap * 0.2 : ny * overlap;
              b.x += nx * overlap;
              b.y += corrYB;
              b.lastX += nx * overlap;
              b.lastY += corrYB;
            } else if (b.isSleeping) {
              double corrYA = ny > 0 ? ny * overlap * 0.2 : ny * overlap;
              a.x -= nx * overlap;
              a.y -= corrYA;
              a.lastX -= nx * overlap;
              a.lastY -= corrYA;
            } else {
              // 双方都未睡眠，各退一半
              final percent = 0.45;
              final correction = overlap * percent;

              double corrYB = ny < 0 ? ny * correction * 0.2 : ny * correction;
              double corrYA = ny > 0 ? ny * correction * 0.2 : ny * correction;

              a.x -= nx * correction;
              a.y -= corrYA;
              a.lastX -= nx * correction;
              a.lastY -= corrYA;

              b.x += nx * correction;
              b.y += corrYB;
              b.lastX += nx * correction;
              b.lastY += corrYB;
            }

            // 2. 表面魔术贴切向摩擦力：不论是否碰撞睡眠物体，切向滑动动能必须被吸收
            double tx = -ny;
            double ty = nx;
            double vax = a.x - a.lastX;
            double vay = a.y - a.lastY;
            double vbx = b.x - b.lastX;
            double vby = b.y - b.lastY;

            double dvx = vbx - vax;
            double dvy = vby - vay;
            double velTangent = dvx * tx + dvy * ty;

            double dampT = (velTangent.abs() > 4.0) ? 0.4 : 1.0;
            double friction = velTangent * dampT;

            if (!a.isSleeping) {
              a.lastX -= tx * friction * 0.5;
              a.lastY -= ty * friction * 0.5;
            }
            if (!b.isSleeping) {
              b.lastX += tx * friction * 0.5;
              b.lastY += ty * friction * 0.5;
            }

            // 3. 法向动能吸收：当物品砸在底部的睡眠堆叠区，必须强行抹平弹性动能！
            double velNormal = dvx * nx + dvy * ny;
            if (velNormal < 0 &&
                (a.y > boxHeight - 70 || b.y > boxHeight - 70)) {
              double dampN = (velNormal.abs() > 3.0) ? 0.3 : 1.0;
              double impulseN = velNormal * dampN;

              // 修复符号：为了减速，b.last 必须加上 nx * impulseN (因为 n 是从 a 指向 b，impulseN 是负值)
              // 如果其中一个是睡眠的“硬地面”，则另一个承担 100% 的动能吸收 (1.0)
              if (!a.isSleeping) {
                a.lastX -= nx * impulseN * (b.isSleeping ? 1.0 : 0.5);
                a.lastY -= ny * impulseN * (b.isSleeping ? 1.0 : 0.5);
              }
              if (!b.isSleeping) {
                b.lastX += nx * impulseN * (a.isSleeping ? 1.0 : 0.5);
                b.lastY += ny * impulseN * (a.isSleeping ? 1.0 : 0.5);
              }
            }
          }
        }
      }

      // 边界碰撞 (左、右、下三向全包围防裁剪限制)
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];

        // 恢复真实视觉半径，避免过度向内挤压导致全部堆在中心
        final double visualRadius = item.radius * 1.3;

        // 左边界：保留 8px 留白，留出足够宽度让道具平铺
        final double minX = visualRadius + 8.0;
        if (item.x < minX) {
          item.x = minX;
          if (!item.isSleeping) {
            double vx = item.x - item.lastX;
            item.lastX = item.x + vx * 0.4;
          }
        }

        // 右边界：保留 8px 留白，留出足够宽度让道具平铺
        final double maxX = boxWidth - visualRadius - 8.0;
        if (item.x > maxX) {
          item.x = maxX;
          if (!item.isSleeping) {
            double vx = item.x - item.lastX;
            item.lastX = item.x - vx * 0.4;
          }
        }

        // 下边界：真实视觉半径 + 8px 留白，刚好悬停在底边上方
        final double floorY = boxHeight - visualRadius - 8.0;
        final double topBound = -600.0;

        if (item.y - item.radius < topBound) {
          item.y = topBound + item.radius;
          if (!item.isSleeping) {
            double vy = item.y - item.lastY;
            item.lastY = item.y + vy * 0.5;
          }
        } else if (item.y > floorY) {
          item.y = floorY;
          if (!item.isSleeping) {
            double vy = item.y - item.lastY;
            item.lastY = item.y + (vy > 2.0 ? vy * 0.4 : 0.0);
            double vx = item.x - item.lastX;
            item.lastX = item.x - vx * 0.4;
          }
        }

        if (item.isSleeping) continue;
      }
    }

    // 3. 落地瞬发磁吸锁 (触底或落到底部堆叠区 2 帧内强制锁死，零延迟静止)
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.isSleeping) continue;

      final double speed =
          (item.x - item.lastX).abs() + (item.y - item.lastY).abs();
      final double visualRadius = item.radius * 1.3;
      final double floorY = boxHeight - visualRadius - 10.0;

      // 触底 (item.y >= floorY) 或在堆叠区低速 (speed < 1.5)，2 帧 (0.03s) 磁吸锁死！
      if (item.y >= floorY || (item.y > boxHeight - 75.0 && speed < 1.5)) {
        item.sleepCounter++;
        if (item.sleepCounter >= 2) {
          item.isSleeping = true;
          item.x = item.x.roundToDouble();
          item.y = item.y.roundToDouble();
          item.lastX = item.x;
          item.lastY = item.y;
        }
      } else {
        item.sleepCounter = 0;
      }
    }

    // 4. 如果全员已锁死休眠，强行关闭控制器切断 UI 刷新
    if (_items.isNotEmpty && _items.every((item) => item.isSleeping)) {
      if (_tickerController.isAnimating) {
        _tickerController.stop();
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _accelSubscription?.cancel();
    super.dispose();
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

    return GestureDetector(
      onTap: _replayDropAnimation,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                    // 白色贴纸描边效果
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
                    // 实体图片
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
    );
  }
}
