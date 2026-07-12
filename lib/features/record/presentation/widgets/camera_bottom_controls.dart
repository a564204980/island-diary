import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraBottomControls extends StatelessWidget {
  final bool isNight;
  final String mattingMode;
  final Animation<double> shutterAnimation;
  final VoidCallback onToggleMatting;
  final VoidCallback onTakePicture;
  final VoidCallback onToggleCamera;

  const CameraBottomControls({
    super.key,
    required this.isNight,
    required this.mattingMode,
    required this.shutterAnimation,
    required this.onToggleMatting,
    required this.onTakePicture,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseIconColor = isNight ? Colors.white : Colors.black87;
    final Color inactiveBg = isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05);
    final Color inactiveBorder = isNight ? Colors.white24 : Colors.black12;

    return Container(
      padding: EdgeInsets.only(
        top: 36,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. 抠像开关
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -26,
                child: Text(
                  '抠图',
                  style: TextStyle(
                    color: mattingMode == 'cloud' ? const Color(0xFFD4A373) : baseIconColor.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontFamily: 'LXGWWenKai',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  onToggleMatting();
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: mattingMode == 'cloud'
                        ? const Color(0xFFD4A373).withValues(alpha: 0.25)
                        : inactiveBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: mattingMode == 'cloud' ? const Color(0xFFD4A373) : inactiveBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    color: mattingMode == 'cloud' ? const Color(0xFFD4A373) : baseIconColor.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          // 2. 快门按钮
          GestureDetector(
            onTap: onTakePicture,
            child: AnimatedBuilder(
              animation: shutterAnimation,
              builder: (context, child) {
                final double scale = 1.0 - (shutterAnimation.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4A373).withValues(alpha: 0.5), width: 4.5),
                    ),
                    padding: const EdgeInsets.all(4.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4A373),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. 翻转前后摄像头按钮
          GestureDetector(
            onTap: () {
              onToggleCamera();
              HapticFeedback.lightImpact();
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: inactiveBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: inactiveBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.cached,
                color: baseIconColor.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
