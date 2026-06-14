import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 极简温馨浮空版 伪 3D 道具展示组件
class Pseudo3DPropWidget extends StatefulWidget {
  final String imagePath;
  final double size;
  final Color glowColor;

  const Pseudo3DPropWidget({
    super.key,
    required this.imagePath,
    this.size = 180.0,
    required this.glowColor,
  });

  @override
  State<Pseudo3DPropWidget> createState() => _Pseudo3DPropWidgetState();
}

class _Pseudo3DPropWidgetState extends State<Pseudo3DPropWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _autoAnimController;
  
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isInteracting = false;
  final double _maxTiltAngle = 24.0 * math.pi / 180.0;

  @override
  void initState() {
    super.initState();
    _autoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _autoAnimController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size widgetSize) {
    final centerX = widgetSize.width / 2;
    final centerY = widgetSize.height / 2;
    final localPos = details.localPosition;
    
    final dx = ((localPos.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final dy = ((localPos.dy - centerY) / centerY).clamp(-1.0, 1.0);

    setState(() {
      _isInteracting = true;
      _tiltY = dx * _maxTiltAngle;
      _tiltX = -dy * _maxTiltAngle;
    });
  }

  void _onPanEnd() {
    setState(() {
      _isInteracting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _autoAnimController,
      builder: (context, child) {
        double currentX = _tiltX;
        double currentY = _tiltY;

        if (!_isInteracting) {
          final t = _autoAnimController.value * 2 * math.pi;
          // 柔和优雅的漂浮呼吸起伏
          currentX = math.sin(t) * 0.09;
          currentY = math.cos(t) * 0.09;
        }

        final double highlightOffsetX = currentY * 2.0;
        final double highlightOffsetY = -currentX * 2.0;

        return GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, Size(widget.size, widget.size)),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: () => _onPanEnd(),
          child: MouseRegion(
            onExit: (_) => _onPanEnd(),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. 底部的极软模糊光晕 (非生硬的彩色圈，模拟环境反光)
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(currentX * 0.4)
                      ..rotateY(currentY * 0.4),
                    alignment: Alignment.center,
                    child: Container(
                      width: widget.size * 0.9,
                      height: widget.size * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.glowColor.withValues(alpha: 0.28),
                            widget.glowColor.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. 悬空漂浮的道具主体 (无厚重黑卡边框阻碍，直观展示道具)
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0016)
                      ..rotateX(currentX)
                      ..rotateY(currentY)
                      ..translate(highlightOffsetX * 5.0, highlightOffsetY * 5.0, 15.0),
                    alignment: Alignment.center,
                    child: Container(
                      width: widget.size * 0.78,
                      height: widget.size * 0.78,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
