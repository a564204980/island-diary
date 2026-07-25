import 'package:flutter/material.dart';

/// 正念呼吸小组件
class MindfulBreathingWidget extends StatefulWidget {
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;

  const MindfulBreathingWidget({
    super.key,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
  });

  @override
  State<MindfulBreathingWidget> createState() => _MindfulBreathingWidgetState();
}

class _MindfulBreathingWidgetState extends State<MindfulBreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 10秒一个呼吸循环 (4秒吸气，2秒屏息，4秒呼气)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.55, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              Icons.spa_outlined,
              size: 16,
              color: widget.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              "正念空间",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: widget.fontFamily,
                color: widget.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "吸气... 呼气...",
          style: TextStyle(
            fontSize: 11,
            fontFamily: widget.fontFamily,
            color: widget.subtitleColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = _scaleAnimation.value;
                final opacity = _opacityAnimation.value;
                return Container(
                  width: 52 * scale,
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor.withValues(alpha: opacity * 0.5),
                        widget.accentColor.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: opacity * 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: opacity * 0.15),
                        blurRadius: 12 * scale,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
