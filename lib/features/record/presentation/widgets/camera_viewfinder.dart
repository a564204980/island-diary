import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_overlay_widgets.dart';
import 'camera_focus_indicator.dart';
import 'camera_watermark_preview.dart';

/// 相机全屏取景框区域
class CameraViewfinder extends StatelessWidget {
  final CameraController controller;
  final String currentRatio;
  final String watermarkStyle;
  final bool showGrid;
  final bool isMattingMode;
  final bool isCountingDown;
  final int countdownValue;
  final Offset? focusPoint;
  final bool showExposureSlider;
  final double currentExposure;
  final double minExposure;
  final double maxExposure;
  final Animation<double> focusAnimation;
  final String? slideOutPath;
  final Animation<Offset> slideOutAnimation;
  final List<double> colorMatrix;
  final ColorFilter colorFilter;
  final void Function(TapUpDetails, BoxConstraints) onTapToFocus;
  final void Function(ScaleStartDetails) onScaleStart;
  final void Function(ScaleUpdateDetails) onScaleUpdate;
  final ValueChanged<double> onExposureChanged;

  const CameraViewfinder({
    super.key,
    required this.controller,
    required this.currentRatio,
    required this.watermarkStyle,
    required this.showGrid,
    required this.isMattingMode,
    required this.isCountingDown,
    required this.countdownValue,
    required this.focusPoint,
    required this.showExposureSlider,
    required this.currentExposure,
    required this.minExposure,
    required this.maxExposure,
    required this.focusAnimation,
    required this.slideOutPath,
    required this.slideOutAnimation,
    required this.colorMatrix,
    required this.colorFilter,
    required this.onTapToFocus,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onExposureChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final bool isBlurBorder = watermarkStyle == 'blur_border';
        final bool isPolaroid = watermarkStyle == 'polaroid';
        final double extraScale = isBlurBorder ? 1.15 : (isPolaroid ? 1.12 : 1.0);

        double targetRatio = 1.0;
        if (currentRatio == '4:3') {
          targetRatio = 4 / 3;
        } else if (currentRatio == '16:9') {
          targetRatio = 16 / 9;
        }

        double displayW = width;
        double displayH = width * targetRatio;

        if (displayH * extraScale > height) {
          displayH = height / extraScale;
          displayW = displayH / targetRatio;
        }

        final double topOffset = (height - displayH * extraScale) / 2;
        final double leftOffset = (width - displayW) / 2;

        return GestureDetector(
          onTapUp: (details) => onTapToFocus(details, constraints),
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          child: Stack(
            children: [
              // 原始相机取景器画面 (恒定满屏)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                width: width,
                height: height,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.previewSize?.height ?? 1080,
                      height: controller.value.previewSize?.width ?? 1920,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(colorMatrix),
                        child: ColorFiltered(
                          colorFilter: colorFilter,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 上边框模糊
              CameraBlurFrame(
                top: topOffset,
                left: leftOffset,
                width: displayW,
                height: isBlurBorder ? displayW * 0.06 : 0,
              ),
              // 下边框模糊 (包含水印区域)
              CameraBlurFrame(
                top: topOffset + (isBlurBorder ? (displayW * 0.06 + displayH * 0.88) : displayH),
                left: leftOffset,
                width: displayW,
                height: isBlurBorder ? (displayH * 0.27 - displayW * 0.06) : 0,
              ),
              // 左边框模糊
              CameraBlurFrame(
                top: topOffset + (isBlurBorder ? displayW * 0.06 : 0),
                left: leftOffset,
                width: isBlurBorder ? displayW * 0.06 : 0,
                height: isBlurBorder ? displayH * 0.88 : 0,
              ),
              // 右边框模糊
              CameraBlurFrame(
                top: topOffset + (isBlurBorder ? displayW * 0.06 : 0),
                left: leftOffset + (isBlurBorder ? displayW * 0.94 : displayW),
                width: isBlurBorder ? displayW * 0.06 : 0,
                height: isBlurBorder ? displayH * 0.88 : 0,
              ),

              // 实时水印悬浮预览
              CameraWatermarkPreview(
                watermarkStyle: watermarkStyle,
                displayW: displayW,
                displayH: displayH,
                topOffset: topOffset,
                leftOffset: leftOffset,
                containerHeight: constraints.maxHeight,
              ),

              // 辅助三分法网格线
              if (showGrid)
                CameraGridlines(
                  displayW: displayW,
                  displayH: displayH,
                  topOffset: topOffset,
                  leftOffset: leftOffset,
                  isBlurBorder: isBlurBorder,
                ),

              // 抠图指示层
              if (isMattingMode)
                CameraMattingOverlay(
                  displayW: displayW,
                  displayH: displayH,
                  topOffset: topOffset,
                  leftOffset: leftOffset,
                ),

              // 对焦框动效
              if (focusPoint != null)
                CameraFocusIndicator(
                  focusPoint: focusPoint!,
                  animation: focusAnimation,
                ),

              // 曝光调节纵向滑动条
              if (showExposureSlider)
                CameraExposureSlider(
                  currentExposure: currentExposure,
                  minExposure: minExposure,
                  maxExposure: maxExposure,
                  onChanged: onExposureChanged,
                ),

              // 延时摄影倒计时大数字遮罩
              if (isCountingDown)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey<int>(countdownValue),
                        tween: Tween<double>(begin: 1.6, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, val, child) {
                          return Transform.scale(
                            scale: val,
                            child: Text(
                              '$countdownValue',
                              style: TextStyle(
                                color: const Color(0xFFD4A373),
                                fontSize: 100,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LXGWWenKai',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    offset: const Offset(2, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // 拍照后滑出动画
              if (slideOutPath != null)
                Builder(
                  builder: (context) {
                    final double margin = displayW * 0.06;
                    return Positioned(
                      top: topOffset + (isBlurBorder ? margin : 0),
                      left: leftOffset + (isBlurBorder ? margin : 0),
                      width: displayW - (isBlurBorder ? margin * 2 : 0),
                      height: displayH - (isBlurBorder ? margin * 2 : 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SlideTransition(
                          position: slideOutAnimation,
                          child: Image.file(File(slideOutPath!), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
