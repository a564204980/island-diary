import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:island_diary/core/state/user_state.dart';

class CameraWatermarkPreview extends StatelessWidget {
  final String watermarkStyle;
  final double displayW;
  final double displayH;
  final double topOffset;
  final double leftOffset;
  final double containerHeight;

  const CameraWatermarkPreview({
    super.key,
    required this.watermarkStyle,
    required this.displayW,
    required this.displayH,
    required this.topOffset,
    required this.leftOffset,
    required this.containerHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (watermarkStyle == 'none') return const SizedBox.shrink();

    final now = DateTime.now();
    final String dateStr = "${now.year.toString().substring(2)} ${now.month.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}";
    final String timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final double baseBottom = (containerHeight - (topOffset + displayH)).clamp(0.0, containerHeight);

    Widget previewContent;

    switch (watermarkStyle) {
      case 'film':
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: baseBottom + 12,
          right: leftOffset + 16,
          child: Text(
            "$dateStr  $timeStr",
            style: TextStyle(
              color: const Color(0xFFFF6E40),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              shadows: [
                Shadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
                const Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
        break;
      case 'simple_date':
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: baseBottom + 12,
          left: leftOffset + 16,
          child: Text(
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $timeStr",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontFamily: 'LXGWWenKai',
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        );
        break;
      case 'device_inner':
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: baseBottom + 12,
          left: leftOffset + 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "岛屿日记 x ${UserState().userName.value.isEmpty ? '我' : UserState().userName.value}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  fontFamily: 'LXGWWenKai',
                  shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 8,
                  fontFamily: 'LXGWWenKai',
                  shadows: const [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        );
        break;
      case 'polaroid':
        final double barHeight = displayH * 0.12;
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: topOffset + displayH,
          left: leftOffset,
          width: displayW,
          child: Container(
            height: barHeight,
            color: const Color(0xFFFDFBF7),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "海岛日记 ╳ 拍立得",
                  style: TextStyle(
                    fontFamily: 'WanWeiWei',
                    fontSize: 11.0,
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "50mm F/2.0 1/250s ISO100  |  ${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 6.0,
                    color: Color(0xFFA68565),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 'blur_border':
        final double barHeight = (displayH * 0.15).clamp(36.0, 999.0);
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: topOffset + displayH,
          left: leftOffset,
          width: displayW,
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                height: barHeight,
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "岛屿日记 x ${UserState().userName.value.isEmpty ? '我' : UserState().userName.value}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (displayW * 0.038).clamp(13.0, 28.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              fontFamily: 'LXGWWenKai',
                              shadows: [
                                Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(1, 1), blurRadius: 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: (displayW * 0.026).clamp(9.5, 18.0),
                              fontFamily: 'LXGWWenKai',
                              shadows: [
                                Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(1, 1), blurRadius: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      default:
        previewContent = const SizedBox.shrink();
    }

    return IgnorePointer(child: Stack(children: [previewContent]));
  }
}
