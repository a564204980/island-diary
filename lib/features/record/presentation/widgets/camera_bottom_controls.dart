import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraBottomControls extends StatelessWidget {
  final String mattingMode;
  final Animation<double> shutterAnimation;
  final VoidCallback onToggleMatting;
  final VoidCallback onTakePicture;
  final VoidCallback onToggleCamera;

  const CameraBottomControls({
    super.key,
    required this.mattingMode,
    required this.shutterAnimation,
    required this.onToggleMatting,
    required this.onTakePicture,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: 36,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. 抠像开关
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
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: mattingMode == 'cloud' ? const Color(0xFFD4A373) : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.auto_fix_high_rounded,
                color: mattingMode == 'cloud' ? const Color(0xFFD4A373) : Colors.white70,
                size: 24,
              ),
            ),
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
                      border: Border.all(color: Colors.white, width: 4.5),
                    ),
                    padding: const EdgeInsets.all(4.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: null,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. 翻转前后摄像头按钮
          IconButton(
            icon: const Icon(Icons.cached, color: Colors.white, size: 30),
            onPressed: onToggleCamera,
          ),
        ],
      ),
    );
  }
}
