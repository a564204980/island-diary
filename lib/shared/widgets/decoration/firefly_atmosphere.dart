import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 萤火虫数据模型 —— 每只萤火虫独立持有物理状态
class _Firefly {
  // 当前世界坐标（归一化 0~1）
  double x;
  double y;

  // 运动速度（每帧位移，归一化）
  double vx;
  double vy;

  // 当前透明度
  double opacity;

  // 闪烁相位（0~2π），控制亮灭节奏
  double phase;

  // 个体闪烁频率（弧度/帧）
  final double blinkSpeed;

  // 个体漫游速度上限
  final double maxSpeed;

  // 目标位置（用于 Seek 行为）
  double targetX;
  double targetY;

  // 计时器：到达目标后多久重新选目的地
  int seekTimer;

  // 颜色
  final Color color;

  // 尺寸（px）
  final double size;

  // 当前朝向角（弧度），平滑跟随速度方向
  double angle;

  // 是否处于刚入场阶段（从外往里飞）
  bool isEntering;

  // 入场延迟帧数
  int spawnDelay;

  _Firefly({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.opacity,
    required this.phase,
    required this.blinkSpeed,
    required this.maxSpeed,
    required this.targetX,
    required this.targetY,
    required this.seekTimer,
    required this.color,
    required this.size,
    required this.angle,
    this.isEntering = true,
    this.spawnDelay = 0,
  });
}

/// 萤火虫氛围组件
/// 使用 CustomPainter + Ticker 实现真正的逐帧物理漫游，永不停止
class FireflyAtmosphere extends StatefulWidget {
  /// 萤火虫数量
  final int count;

  /// 是否显示
  final bool show;

  /// 自定义颜色组
  final List<Color>? colors;

  /// 最小尺寸
  final double minSize;

  /// 最大尺寸
  final double maxSize;

  /// 最小速度
  final double minSpeed;

  /// 最大速度
  final double maxSpeed;

  const FireflyAtmosphere({
    super.key,
    this.count = 30,
    this.show = true,
    this.colors,
    this.minSize = 6.0,
    this.maxSize = 8.0,
    this.minSpeed = 0.0002,
    this.maxSpeed = 0.0007,
  });

  @override
  State<FireflyAtmosphere> createState() => _FireflyAtmosphereState();
}

class _FireflyAtmosphereState extends State<FireflyAtmosphere>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Firefly> _fireflies = [];
  final _random = Random();

  static const _defaultColors = [
    Color(0xFFFACC15), // 金黄
    Color(0xFFADFF2F), // 荧光绿
    Color(0xFF4ADE80), // 翠绿
    Color(0xFF86EFAC), // 淡绿
    Color(0xFFFDE68A), // 浅金
  ];

  @override
  void initState() {
    super.initState();
    _spawnFireflies();
    _ticker = createTicker(_onTick)..start();
  }

  void _spawnFireflies() {
    final colors = widget.colors ?? _defaultColors;
    _fireflies.clear();
    for (int i = 0; i < widget.count; i++) {
      _fireflies.add(_newFirefly(colors[i % colors.length]));
    }
  }

  _Firefly _newFirefly(Color color) {
    // 随机选择一条边出生：0:Top, 1:Bottom, 2:Left, 3:Right
    final edge = _random.nextInt(4);
    double startX, startY;
    
    switch (edge) {
      case 0: // Top
        startX = _random.nextDouble();
        startY = -0.05;
        break;
      case 1: // Bottom
        startX = _random.nextDouble();
        startY = 1.05;
        break;
      case 2: // Left
        startX = -0.05;
        startY = _random.nextDouble();
        break;
      default: // Right
        startX = 1.05;
        startY = _random.nextDouble();
    }

    // 初始目标设在屏幕中央区域，引导其自然“游”进来
    final targetX = 0.2 + _random.nextDouble() * 0.6;
    final targetY = 0.2 + _random.nextDouble() * 0.6;

    final dx = targetX - startX;
    final dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);
    
    // 初始速度在设定的范围内随机
    final speed = widget.minSpeed + _random.nextDouble() * (widget.maxSpeed - widget.minSpeed);
    final vx = (dx / dist) * speed;
    final vy = (dy / dist) * speed;

    return _Firefly(
      x: startX,
      y: startY,
      vx: vx,
      vy: vy,
      opacity: 0.0,
      phase: _random.nextDouble() * 2 * pi,
      blinkSpeed: 0.02 + _random.nextDouble() * 0.03,
      maxSpeed: widget.maxSpeed * (0.8 + _random.nextDouble() * 0.4), // 巡航上限也随机化
      targetX: targetX,
      targetY: targetY,
      seekTimer: _random.nextInt(100) + 50,
      color: color,
      size: widget.minSize + _random.nextDouble() * (widget.maxSize - widget.minSize),
      angle: atan2(vy, vx) + pi / 2,
      isEntering: true,
      // 30% 的概率立即出现，其余的在 0~120 帧（2秒）内出现
      spawnDelay: _random.nextDouble() < 0.3 ? 0 : _random.nextInt(120),
    );
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    for (final f in _fireflies) {
      // 只有过了延迟时间才开始更新
      if (f.spawnDelay > 0) {
        f.spawnDelay--;
        continue;
      }

      // ① 闪烁：sin 波形 → opacity 自然呼吸
      f.phase += f.blinkSpeed;
      final baseOpacity = (sin(f.phase) * 0.5 + 0.5).clamp(0.05, 1.0);
      
      // 始终执行淡入检查，确保出生时平滑
      if (f.opacity < baseOpacity) {
        f.opacity += 0.005; // 极慢的淡入，像幻化出来的一样
      } else {
        f.opacity = baseOpacity;
      }

      // ② Seek 行为
      f.seekTimer--;
      if (f.seekTimer <= 0) {
        // 如果还在边缘，继续向中心漫游，否则完全随机
        if (f.x < 0.1 || f.x > 0.9 || f.y < 0.1 || f.y > 0.9) {
          f.targetX = 0.3 + _random.nextDouble() * 0.4;
          f.targetY = 0.3 + _random.nextDouble() * 0.4;
        } else {
          f.targetX = _random.nextDouble();
          f.targetY = _random.nextDouble();
        }
        f.seekTimer = _random.nextInt(400) + 200;
        f.isEntering = false; // 进入中心后就不再是入场状态
      }
      final dx = f.targetX - f.x;
      final dy = f.targetY - f.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > 0.001) {
        // 施加微小转向力
        f.vx += (dx / dist) * 0.000015;
        f.vy += (dy / dist) * 0.000015;
      }

      // ③ 限速
      final speed = sqrt(f.vx * f.vx + f.vy * f.vy);
      if (speed > f.maxSpeed) {
        f.vx = (f.vx / speed) * f.maxSpeed;
        f.vy = (f.vy / speed) * f.maxSpeed;
      }

      // ④ 移动
      f.x += f.vx;
      f.y += f.vy;

      // ⑤ 边界反弹（带缓冲）
      if (f.x < 0.02) {
        f.x = 0.02;
        f.vx = f.vx.abs();
      }
      if (f.x > 0.98) {
        f.x = 0.98;
        f.vx = -f.vx.abs();
      }
      if (f.y < 0.02) {
        f.y = 0.02;
        f.vy = f.vy.abs();
      }
      if (f.y > 0.98) {
        f.y = 0.98;
        f.vy = -f.vy.abs();
      }

      // ⑥ 平滑旋转朝向速度方向
      final targetAngle = atan2(f.vy, f.vx) + pi / 2;
      // 计算最短角度差（处理 ±π 跳变）
      double diff = (targetAngle - f.angle + 3 * pi) % (2 * pi) - pi;
      f.angle += diff * 0.04; // 平滑系数：越小转向越慢
    }
    // 用最轻量方式触发重绘（不 setState，直接让 CustomPaint repaint）
    _repaintNotifier.value++;
  }

  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  @override
  void dispose() {
    _ticker.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: ValueListenableBuilder<int>(
          valueListenable: _repaintNotifier,
          builder: (context, _, child) =>
              CustomPaint(painter: _FireflyPainter(_fireflies)),
        ),
      ),
    );
  }
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> fireflies;

  _FireflyPainter(this.fireflies);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fireflies) {
      _drawFirefly(
        canvas,
        f.x * size.width,
        f.y * size.height,
        f.size,
        f.color,
        f.opacity,
        f.angle,
      );
    }
  }

  /// 在 (cx, cy) 处绘制一只完整的小萤火虫
  /// [s]     基准尺寸（px）
  /// [color] 腹部发光颜色
  /// 在 (cx, cy) 处绘制一只完整的小萤火虫（俯视·上下结构）
  ///
  /// 布局（Y 轴向下）：
  ///   头部  —— 顶部小圆
  ///   胸部  —— 短椭圆
  ///   翅膀  —— 左右对称大椭圆
  ///   腹部  —— 底部发光椭圆（核心光源）
  ///   腿    —— 从胸部两侧向外伸
  void _drawFirefly(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    Color color,
    double alpha,
    double angle,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle); // 头部朝向运动方向

    // ── 外层大光晕（以腹部为中心） ──────────────
    canvas.drawCircle(
      Offset(0, s * 0.5),
      s * 3.2,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 3.0),
    );
    canvas.drawCircle(
      Offset(0, s * 0.5),
      s * 1.2,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 1.0),
    );

    // ── 翅膀（左右对称，位于胸部两侧） ───────────
    final wingPaint = Paint()..color = color.withValues(alpha: alpha * 0.18);
    final wingEdge = Paint()
      ..color = color.withValues(alpha: alpha * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 左翅（向左上展开）
    final leftWing = Rect.fromCenter(
      center: Offset(-s * 0.90, -s * 0.10),
      width: s * 1.10,
      height: s * 0.55,
    );
    canvas.drawOval(leftWing, wingPaint);
    canvas.drawOval(leftWing, wingEdge);

    // 右翅（向右上展开，对称）
    final rightWing = Rect.fromCenter(
      center: Offset(s * 0.90, -s * 0.10),
      width: s * 1.10,
      height: s * 0.55,
    );
    canvas.drawOval(rightWing, wingPaint);
    canvas.drawOval(rightWing, wingEdge);

    // ── 三对细腿（从胸部两侧向外伸） ──────────────
    final legPaint = Paint()
      ..color = const Color(0xFF1A3010).withValues(alpha: alpha * 0.55)
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;
    // 前腿
    canvas.drawLine(
      Offset(-s * 0.22, -s * 0.05),
      Offset(-s * 0.55, -s * 0.35),
      legPaint,
    );
    canvas.drawLine(
      Offset(s * 0.22, -s * 0.05),
      Offset(s * 0.55, -s * 0.35),
      legPaint,
    );
    // 中腿
    canvas.drawLine(
      Offset(-s * 0.25, s * 0.05),
      Offset(-s * 0.62, s * 0.10),
      legPaint,
    );
    canvas.drawLine(
      Offset(s * 0.25, s * 0.05),
      Offset(s * 0.62, s * 0.10),
      legPaint,
    );
    // 后腿
    canvas.drawLine(
      Offset(-s * 0.20, s * 0.18),
      Offset(-s * 0.52, s * 0.45),
      legPaint,
    );
    canvas.drawLine(
      Offset(s * 0.20, s * 0.18),
      Offset(s * 0.52, s * 0.45),
      legPaint,
    );

    // ── 胸部（身体椭圆，头尾之间） ──────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.05),
        width: s * 0.52,
        height: s * 0.72,
      ),
      Paint()..color = const Color(0xFF2A4A18).withValues(alpha: alpha * 0.92),
    );
    // 胸部高光
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-s * 0.08, -s * 0.08),
        width: s * 0.18,
        height: s * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.12),
    );

    // ── 腹部发光节（底部，核心光源） ─────────────
    // 外晕
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.60),
        width: s * 0.46,
        height: s * 0.52,
      ),
      Paint()
        ..color = color.withValues(alpha: alpha * 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.65),
    );
    // 实心发光体
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.60),
        width: s * 0.34,
        height: s * 0.40,
      ),
      Paint()..color = color.withValues(alpha: (alpha * 1.1).clamp(0.0, 1.0)),
    );

    // ── 头部（顶部小圆） ─────────────────────────
    canvas.drawCircle(
      Offset(0, -s * 0.52),
      s * 0.24,
      Paint()..color = const Color(0xFF1A3010).withValues(alpha: alpha * 0.95),
    );
    // 复眼（左右各一点）
    canvas.drawCircle(
      Offset(-s * 0.10, -s * 0.56),
      s * 0.06,
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.80),
    );
    canvas.drawCircle(
      Offset(s * 0.10, -s * 0.56),
      s * 0.06,
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.80),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FireflyPainter oldDelegate) => true;
}
