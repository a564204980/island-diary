import 'dart:math';
import 'package:flutter/material.dart';

class ZzzAnimation extends StatefulWidget {
  final Color color;
  const ZzzAnimation({super.key, this.color = const Color(0xFF999999)});

  @override
  State<ZzzAnimation> createState() => _ZzzAnimationState();
}

class _ZzzAnimationState extends State<ZzzAnimation> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _controller2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _controller3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));

    _startAnimations();
  }

  void _startAnimations() async {
    if (!mounted) return;
    _controller1.repeat();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _controller2.repeat();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _controller3.repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  Widget _buildZ(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        // 快速淡入，然后缓慢淡出
        final opacity = t < 0.2 ? (t / 0.2) : (1.0 - (t - 0.2) / 0.8);
        final scale = 0.5 + t * 0.8;
        
        return Positioned(
          left: 18 + t * 35 + sin(t * pi * 4) * 4, // 从稍远的位置开始，向右漂移并伴随轻微摆动
          bottom: 12 + t * 45, // 从较高处开始，向上漂移
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                'z',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildZ(_controller1),
          _buildZ(_controller2),
          _buildZ(_controller3),
        ],
      ),
    );
  }
}
