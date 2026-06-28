import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/models/life_line_profile.dart';
import 'package:island_diary/core/state/user_state.dart';

enum _WarpPhase { entry, cruise, exit }

class TimeWarpOverlay extends StatefulWidget {
  final LifeLineProfile nextProfile;
  final VoidCallback onComplete;
  final Future<void> switchFuture;

  const TimeWarpOverlay({
    super.key,
    required this.nextProfile,
    required this.onComplete,
    required this.switchFuture,
  });

  static void show(BuildContext context, LifeLineProfile nextProfile) {
    // 只有乐高主题才播放粒子跃迁特效
    if (UserState().selectedIslandThemeId.value != 'lego') {
      UserState().switchLifeLine(nextProfile.id);
      return;
    }

    final switchFuture = Future.delayed(
      const Duration(milliseconds: 900),
      () => UserState().switchLifeLine(nextProfile.id),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TimeWarpOverlay(
        nextProfile: nextProfile,
        switchFuture: switchFuture,
        onComplete: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<TimeWarpOverlay> createState() => _TimeWarpOverlayState();
}

class _TimeWarpOverlayState extends State<TimeWarpOverlay>
    with SingleTickerProviderStateMixin {

  // 帧时钟：每帧回调，提供真实经过时间（由 SingleTickerProviderStateMixin.createTicker 创建）
  // ignore: cancel_subscriptions
  late final ticker = createTicker(_onTickElapsed);

  // 真实物理时间（ms），驱动粒子位置
  double _physicsMs = 0.0;
  Duration _lastElapsed = Duration.zero;

  // 当前阶段和出场开始时间
  _WarpPhase _phase = _WarpPhase.entry;
  double _exitStartMs = 0.0;

  // 出场时用于累积 rotation（防止归零跳变）
  double _rotationAtExitStart = 0.0;

  // 粒子元数据（初始化后只读）
  final List<_WarpStreak> _streaks = [];
  final List<_LegoDebris> _debris = [];
  final math.Random _random = math.Random();

  static const _entryDurationMs = 1000.0;
  static const _exitDurationMs = 700.0;
  static const _cruiseSpeedPerMs = 9.0;   // 粒子每毫秒行进距离（巡航）
  static const _maxEntrySpeed = 9.0;

  static const List<Color> _colors = [
    Color(0xFF00FFFF),
    Color(0xFF0088FF),
    Color(0xFF44AAFF),
    Color(0xFFFFFFFF),
  ];
  static const List<List<int>> _brickTypes = [
    [1, 1], [1, 2], [2, 2], [2, 4],
  ];

  @override
  void initState() {
    super.initState();

    // 初始化粒子
    for (int i = 0; i < 130; i++) {
      _streaks.add(_WarpStreak(
        angle: _random.nextDouble() * math.pi * 2,
        spawnRadius: 30 + _random.nextDouble() * 2000,
        initialZ: _random.nextDouble() * 2000.0,
        speedMultiplier: 0.7 + _random.nextDouble() * 0.6,
        color: _colors[_random.nextInt(_colors.length)],
        size: 1.5 + _random.nextDouble() * 2.5,
      ));
    }
    for (int i = 0; i < 28; i++) {
      final type = _brickTypes[_random.nextInt(_brickTypes.length)];
      _debris.add(_LegoDebris(
        angle: _random.nextDouble() * math.pi * 2,
        spawnRadius: 60 + _random.nextDouble() * 1500,
        initialZ: _random.nextDouble() * 2000.0,
        speedMultiplier: 0.6 + _random.nextDouble() * 0.4,
        color: _colors[_random.nextInt(_colors.length)],
        cols: type[0],
        rows: type[1],
        initialRotate: _random.nextDouble() * math.pi * 2,
        spinSpeed: (_random.nextDouble() - 0.5) * 1.5,
      ));
    }

    // 用 Ticker 作为帧时钟（每帧回调，无需 duration）
    ticker.start();

    _triggerVibrationSequence();

    // 数据加载完成后触发出场（保证最少 1200ms 入场+巡航）
    widget.switchFuture.then((_) => _scheduleExit());
  }

  void _onTickElapsed(Duration elapsed) {
    if (!mounted) return;
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000.0; // ms
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _physicsMs += dt;

    // 自动进入巡航
    if (_phase == _WarpPhase.entry && _physicsMs >= _entryDurationMs) {
      _phase = _WarpPhase.cruise;
    }
    setState(() {});
  }

  void _scheduleExit() {
    if (!mounted) return;
    const minBeforeExit = 1200.0;
    final waitMs = (minBeforeExit - _physicsMs).clamp(0.0, minBeforeExit);
    Future.delayed(Duration(milliseconds: waitMs.round()), () {
      if (!mounted) return;
      setState(() {
        _phase = _WarpPhase.exit;
        _exitStartMs = _physicsMs;
        _rotationAtExitStart = _currentRotation(_physicsMs);
      });
      // 出场结束后关闭
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onComplete();
      });
    });
  }

  Future<void> _triggerVibrationSequence() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted) break;
      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) break;
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 110));
    }
  }

  @override
  void dispose() {
    ticker
      ..stop()
      ..dispose();
    super.dispose();
  }

  // 计算当前粒子行进总距离
  double get _travel {
    switch (_phase) {
      case _WarpPhase.entry:
        final t = Curves.easeIn.transform((_physicsMs / _entryDurationMs).clamp(0.0, 1.0));
        return t * _maxEntrySpeed * _entryDurationMs * 0.5; // 入场积分
      case _WarpPhase.cruise:
        final entryTravel = _maxEntrySpeed * _entryDurationMs * 0.5;
        return entryTravel + (_physicsMs - _entryDurationMs) * _cruiseSpeedPerMs;
      case _WarpPhase.exit:
        final entryTravel = _maxEntrySpeed * _entryDurationMs * 0.5;
        final cruiseTravel = (_exitStartMs - _entryDurationMs) * _cruiseSpeedPerMs;
        final exitElapsed = (_physicsMs - _exitStartMs).clamp(0.0, _exitDurationMs);
        final exitT = 1.0 - Curves.easeOut.transform(exitElapsed / _exitDurationMs);
        return entryTravel + cruiseTravel + exitT * _cruiseSpeedPerMs * exitElapsed;
    }
  }

  // 粒子整体缓慢旋转（平滑连续）
  double _currentRotation(double ms) => ms * 0.00015 * math.pi;

  // 当前视觉强度（控制发光/粗细）
  double get _intensity {
    switch (_phase) {
      case _WarpPhase.entry:
        return (_physicsMs / _entryDurationMs).clamp(0.0, 1.0);
      case _WarpPhase.cruise:
        return 1.0;
      case _WarpPhase.exit:
        final exitElapsed = (_physicsMs - _exitStartMs).clamp(0.0, _exitDurationMs + 100);
        return (1.0 - exitElapsed / _exitDurationMs).clamp(0.0, 1.0);
    }
  }

  // 整体透明度
  double get _opacity {
    switch (_phase) {
      case _WarpPhase.entry:
        return (_physicsMs / 200.0).clamp(0.0, 1.0);
      case _WarpPhase.cruise:
        return 1.0;
      case _WarpPhase.exit:
        final exitElapsed = (_physicsMs - _exitStartMs).clamp(0.0, _exitDurationMs + 100);
        return (1.0 - exitElapsed / (_exitDurationMs + 100)).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final font = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    final staticHud = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '跃迁至平行小岛...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: font,
              fontStyle: FontStyle.italic,
              letterSpacing: 4,
              shadows: [
                const Shadow(color: Color(0xFF00FFFF), blurRadius: 12),
                const Shadow(color: Color(0xFF0055FF), blurRadius: 24),
                Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2, 4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '时空节点：「${widget.nextProfile.name}」',
            style: TextStyle(
              color: const Color(0xFF00FFFF),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: font,
              letterSpacing: 2,
              shadows: [
                const Shadow(color: Color(0xFF0055FF), blurRadius: 10),
                Shadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(1, 2), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );

    final opacity = _opacity;
    final intensity = _intensity;
    final travel = _travel;
    final rotation = _phase == _WarpPhase.exit
        ? _rotationAtExitStart
        : _currentRotation(_physicsMs);

    // 震动效果（巡航阶段）
    double shakeX = 0, shakeY = 0;
    if (_phase == _WarpPhase.cruise) {
      shakeX = (_random.nextDouble() - 0.5) * 6 * intensity;
      shakeY = (_random.nextDouble() - 0.5) * 6 * intensity;
    }

    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LegoHyperspacePainter(
                    streaks: _streaks,
                    debris: _debris,
                    travel: travel,
                    intensity: intensity,
                    rotation: rotation,
                    physicsMs: _physicsMs,
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: staticHud,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarpStreak {
  final double angle;
  final double spawnRadius;
  final double initialZ;
  final double speedMultiplier;
  final Color color;
  final double size;

  const _WarpStreak({
    required this.angle,
    required this.spawnRadius,
    required this.initialZ,
    required this.speedMultiplier,
    required this.color,
    required this.size,
  });
}

class _LegoDebris {
  final double angle;
  final double spawnRadius;
  final double initialZ;
  final double speedMultiplier;
  final Color color;
  final int cols;
  final int rows;
  final double initialRotate;
  final double spinSpeed;

  const _LegoDebris({
    required this.angle,
    required this.spawnRadius,
    required this.initialZ,
    required this.speedMultiplier,
    required this.color,
    required this.cols,
    required this.rows,
    required this.initialRotate,
    required this.spinSpeed,
  });
}

class _LegoHyperspacePainter extends CustomPainter {
  final List<_WarpStreak> streaks;
  final List<_LegoDebris> debris;
  final double travel;
  final double intensity;
  final double rotation;
  final double physicsMs;

  final Paint _bgPaint = Paint()..color = const Color(0xFF020813);
  final Paint _haloPaint = Paint()..blendMode = BlendMode.screen;
  final Paint _streakPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final Paint _streakCorePaint = Paint()..style = PaintingStyle.fill;
  final Paint _debrisFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _debrisBorderPaint = Paint()..style = PaintingStyle.stroke;

  _LegoHyperspacePainter({
    required this.streaks,
    required this.debris,
    required this.travel,
    required this.intensity,
    required this.rotation,
    required this.physicsMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _bgPaint);

    if (intensity > 0.05) {
      _haloPaint.shader = RadialGradient(
        colors: [
          const Color(0xFF00FFFF).withValues(alpha: intensity * 0.35),
          const Color(0xFF0055FF).withValues(alpha: intensity * 0.12),
          Colors.transparent,
        ],
        stops: const [0.1, 0.5, 1.0],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _haloPaint);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final fov = size.width * 0.95;

    // 流光
    for (var streak in streaks) {
      double z = (streak.initialZ - travel * streak.speedMultiplier) % 2000.0;
      if (z < 0) z += 2000.0;
      if (z < 1) continue;

      double sx = (math.cos(streak.angle) * streak.spawnRadius / z) * fov;
      double sy = (math.sin(streak.angle) * streak.spawnRadius / z) * fov;
      if (sx.abs() > size.width * 1.5 || sy.abs() > size.height * 1.5) continue;

      double alpha = ((1.0 - z / 2000.0) + intensity * 0.4).clamp(0.0, 1.0);

      // 流光拉伸：用比例因子而非双投影（节省 cos/sin 计算）
      double stretchFactor = (0.80 + intensity * 0.08).clamp(0.70, 0.92);
      _streakPaint.color = streak.color.withValues(alpha: alpha * 0.95);
      _streakPaint.strokeWidth = streak.size * (1.0 + intensity * 2.5);
      canvas.drawLine(Offset(sx * stretchFactor, sy * stretchFactor), Offset(sx, sy), _streakPaint);

      if (z < 700) {
        _streakCorePaint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset(sx, sy), streak.size * 1.3, _streakCorePaint);
      }
    }

    // 积木碎片
    const baseSize = 14.0;
    for (var d in debris) {
      double z = (d.initialZ - travel * d.speedMultiplier * 0.8) % 2000.0;
      if (z < 0) z += 2000.0;
      if (z < 1) continue;

      double scale = fov / z;
      double sx = (math.cos(d.angle) * d.spawnRadius / z) * fov;
      double sy = (math.sin(d.angle) * d.spawnRadius / z) * fov;
      if (sx.abs() > size.width * 1.5 || sy.abs() > size.height * 1.5) continue;

      double alpha = (1.0 - z / 2000.0).clamp(0.0, 1.0);
      if (alpha < 0.1) continue;

      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(d.initialRotate + physicsMs * 0.001 * d.spinSpeed);

      double drawW = d.cols * baseSize * scale;
      double drawH = d.rows * baseSize * scale;

      _debrisFillPaint.color = d.color.withValues(alpha: alpha * 0.85);
      _debrisBorderPaint.color = Colors.white.withValues(alpha: alpha * 0.75);
      _debrisBorderPaint.strokeWidth = (1.0 * scale).clamp(0.5, 2.0);

      final rect = Rect.fromCenter(center: Offset.zero, width: drawW, height: drawH);
      canvas.drawRect(rect, _debrisFillPaint);
      canvas.drawRect(rect, _debrisBorderPaint);

      if (scale > 0.15) {
        double studRadius = baseSize * 0.3 * scale;
        for (int r = 0; r < d.rows; r++) {
          for (int c = 0; c < d.cols; c++) {
            final cx = -drawW / 2 + (c + 0.5) * (baseSize * scale);
            final cy = -drawH / 2 + (r + 0.5) * (baseSize * scale);
            canvas.drawCircle(Offset(cx, cy), studRadius, _debrisFillPaint);
            canvas.drawCircle(Offset(cx, cy), studRadius, _debrisBorderPaint);
          }
        }
      }
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LegoHyperspacePainter old) =>
      old.travel != travel || old.intensity != intensity;
}
