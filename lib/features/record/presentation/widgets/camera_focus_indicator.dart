import 'package:flutter/material.dart';

/// 点击对焦时的黄色对焦指示框
class CameraFocusIndicator extends StatelessWidget {
  final Offset focusPoint;
  final Animation<double> animation;

  const CameraFocusIndicator({
    super.key,
    required this.focusPoint,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: focusPoint.dx - 30,
      top: focusPoint.dy - 30,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final scale = 1.2 - (animation.value * 0.2);
          final opacity = 1.0 - animation.value;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.center_focus_strong, color: Color(0xFFD4A373), size: 16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 纵向曝光度亮度微调滑动条
class CameraExposureSlider extends StatelessWidget {
  final double currentExposure;
  final double minExposure;
  final double maxExposure;
  final ValueChanged<double> onChanged;

  const CameraExposureSlider({
    super.key,
    required this.currentExposure,
    required this.minExposure,
    required this.maxExposure,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          width: 36,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Icon(Icons.light_mode, color: Color(0xFFD4A373), size: 14),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: const Color(0xFFD4A373),
                      inactiveTrackColor: Colors.white30,
                      thumbColor: const Color(0xFFD4A373),
                    ),
                    child: Slider(
                      value: currentExposure,
                      min: minExposure,
                      max: maxExposure,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.hdr_strong, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
