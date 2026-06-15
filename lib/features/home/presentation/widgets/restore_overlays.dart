import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class RestoreLoadingOverlay extends StatelessWidget {
  final String text;
  final bool isNight;
  final String fontFamily;

  const RestoreLoadingOverlay({
    super.key,
    required this.text,
    required this.isNight,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            color: Colors.black.withValues(alpha: isNight ? 0.5 : 0.35),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.transparent,
                          ),
                          gradient: const SweepGradient(
                            colors: [
                              Color(0xFF00ACC1),
                              Color(0xFF818CF8),
                              Color(0xFFCE93D8),
                              Color(0xFF00ACC1),
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 2.seconds),
                      
                      Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          color: isNight ? const Color(0xFF161513) : const Color(0xFFFAF7F0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      
                      Image.asset(
                        UserState().selectedMascotType.value,
                        width: 60,
                        height: 60,
                      )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .moveY(begin: -8, end: 8, duration: 800.ms, curve: Curves.easeInOutCubic)
                      .rotate(begin: -0.05, end: 0.05, duration: 800.ms, curve: Curves.easeInOutCubic),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF374151),
                      fontFamily: fontFamily,
                      letterSpacing: 0.8,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 1.seconds, curve: Curves.easeInOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RestoreSuccessDialog extends StatelessWidget {
  final String fontFamily;
  final bool isNight;

  const RestoreSuccessDialog({
    super.key,
    required this.fontFamily,
    required this.isNight,
  });

  static void show(BuildContext context, {
    required String fontFamily,
    required bool isNight,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });

        return RestoreSuccessDialog(
          fontFamily: fontFamily,
          isNight: isNight,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isNight ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isNight ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF00ACC1).withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00ACC1).withValues(alpha: isNight ? 0.3 : 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00ACC1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                const SizedBox(height: 20),
                Text(
                  '记忆复苏成功！',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : const Color(0xFF1A1A1A),
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '我们的岛屿已安全重建 ✨',
                  style: TextStyle(
                    fontSize: 13,
                    color: isNight ? Colors.white60 : Colors.black54,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
