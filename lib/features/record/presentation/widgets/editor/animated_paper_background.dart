import 'dart:math';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';

class AnimatedPaperBackground extends StatefulWidget {
  final String paperStyle;
  final Color bgColor;
  final bool isNight;
  final Color accentColor;

  const AnimatedPaperBackground({
    super.key,
    required this.paperStyle,
    required this.bgColor,
    required this.isNight,
    required this.accentColor,
  });

  @override
  State<AnimatedPaperBackground> createState() =>
      _AnimatedPaperBackgroundState();
}

class _AnimatedPaperBackgroundState extends State<AnimatedPaperBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _oldPaperStyle;
  Color? _oldBgColor;
  bool? _oldIsNight;
  Color? _oldAccentColor;

  late String _currentPaperStyle;
  late Color _currentBgColor;
  late bool _currentIsNight;
  late Color _currentAccentColor;

  @override
  void initState() {
    super.initState();
    _currentPaperStyle = widget.paperStyle;
    _currentBgColor = widget.bgColor;
    _currentIsNight = widget.isNight;
    _currentAccentColor = widget.accentColor;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _oldPaperStyle = null;
          });
        }
      }
    });
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedPaperBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paperStyle != widget.paperStyle ||
        oldWidget.isNight != widget.isNight) {
      _oldPaperStyle = oldWidget.paperStyle;
      _oldBgColor = oldWidget.bgColor;
      _oldIsNight = oldWidget.isNight;
      _oldAccentColor = oldWidget.accentColor;

      _currentPaperStyle = widget.paperStyle;
      _currentBgColor = widget.bgColor;
      _currentIsNight = widget.isNight;
      _currentAccentColor = widget.accentColor;

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLayer(
    String paperStyle,
    Color bgColor,
    bool isNight,
    Color accentColor,
  ) {
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          if (paperStyle.startsWith('note') ||
              (paperStyle == 'classic' &&
                  UserState().selectedIslandThemeId.value == 'cotton_candy'))
            Positioned.fill(
              child: Image.asset(
                paperStyle == 'classic'
                    ? (isNight
                          ? 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_night_bg.png'
                          : 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_bg.png')
                    : DiaryUtils.getPaperBackgroundPath(paperStyle, isNight),
                fit: BoxFit.cover,
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: PaperBackgroundPainter(
                style: paperStyle,
                isNight:
                    isNight &&
                    !paperStyle.startsWith('note') &&
                    !(paperStyle == 'classic' &&
                        UserState().selectedIslandThemeId.value ==
                            'cotton_candy'),
                accentColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnimating = _oldPaperStyle != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 底层：新背景
        _buildLayer(
          _currentPaperStyle,
          _currentBgColor,
          _currentIsNight,
          _currentAccentColor,
        ),

        // 2. 中层：老背景带遮罩（在新图之上挖个扩大的洞）
        if (isAnimating)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final curve = Curves.easeOutQuart;
              final val = curve.transform(_controller.value);

              return ShaderMask(
                blendMode: BlendMode.dstOut,
                shaderCallback: (Rect bounds) {
                  final maxRadius = sqrt(
                    pow(bounds.width / 2, 2) + pow(bounds.height, 2),
                  );
                  final currentRadius = maxRadius * val;
                  final fuzzyRadius = currentRadius + (val * 180.0);

                  final shortestSide = min(bounds.width, bounds.height);
                  final double effectiveRadius = maxRadius / shortestSide;

                  final double stop1 = max(
                    (currentRadius / maxRadius).clamp(0.0, 1.0),
                    0.0001,
                  );
                  final double stop2 = max(
                    (fuzzyRadius / maxRadius).clamp(0.0, 1.0),
                    stop1 + 0.0001,
                  );

                  return RadialGradient(
                    center: Alignment.bottomCenter,
                    radius: effectiveRadius,
                    colors: const [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, stop1, stop2],
                  ).createShader(bounds);
                },
                child: child,
              );
            },
            child: _buildLayer(
              _oldPaperStyle!,
              _oldBgColor!,
              _oldIsNight!,
              _oldAccentColor!,
            ),
          ),
      ],
    );
  }
}
