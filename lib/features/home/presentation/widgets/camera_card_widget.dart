import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/animations/shared_axis_page_route.dart';
import 'package:island_diary/features/record/presentation/pages/custom_camera/custom_camera_page.dart';

/// 首页相机小组件 (岛屿快照卡片)
class CameraCardWidget extends StatefulWidget {
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;
  final bool isTall;
  final bool isEditMode;

  const CameraCardWidget({
    super.key,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
    this.isTall = false,
    this.isEditMode = false,
  });

  @override
  State<CameraCardWidget> createState() => _CameraCardWidgetState();
}

class _CameraCardWidgetState extends State<CameraCardWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openCamera(BuildContext context) {
    if (widget.isEditMode) return;
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      SharedAxisPageRoute(
        page: const CustomCameraPage(
          enableDynamicViewfinder: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isNight
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.35);
    final borderColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.5);

    return BouncingButton(
      scaleFactor: 0.97,
      onTap: widget.isEditMode ? null : () => _openCamera(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: widget.isTall ? 296 : 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.isNight
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部标题栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: widget.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "岛屿快照",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: widget.fontFamily,
                            color: widget.textColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "相机",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: widget.fontFamily,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),

                // 核心拍照视觉中心 (镜头取景框/快门)
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.04);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: widget.isTall ? 90 : 52,
                      height: widget.isTall ? 90 : 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accentColor.withValues(alpha: 0.25),
                            widget.accentColor.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: widget.isTall ? 60 : 34,
                          height: widget.isTall ? 60 : 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor.withValues(alpha: 0.85),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 底部提示标签
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "点击一键开启相机",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontFamily: widget.fontFamily,
                        color: widget.subtitleColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: widget.subtitleColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
