import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../pages/custom_camera_painters.dart';

/// 三分法辅助网格线
class CameraGridlines extends StatelessWidget {
  final double displayW;
  final double displayH;
  final double topOffset;
  final double leftOffset;
  final bool isBlurBorder;

  const CameraGridlines({
    super.key,
    required this.displayW,
    required this.displayH,
    required this.topOffset,
    required this.leftOffset,
    required this.isBlurBorder,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = isBlurBorder ? 0.92 : 1.0;
    final double borderWidth = displayW * scale;
    final double borderHeight = displayH * scale;
    final double finalTop = topOffset + (isBlurBorder ? displayW * 0.04 : 0.0);
    final double finalLeft = leftOffset + (isBlurBorder ? displayW * 0.04 : 0.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: finalTop,
      left: finalLeft,
      width: borderWidth,
      height: borderHeight,
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(left: borderWidth / 3, top: 0, bottom: 0, width: 0.5, child: Container(color: Colors.white30)),
            Positioned(left: borderWidth * 2 / 3, top: 0, bottom: 0, width: 0.5, child: Container(color: Colors.white30)),
            Positioned(top: borderHeight / 3, left: 0, right: 0, height: 0.5, child: Container(color: Colors.white30)),
            Positioned(top: borderHeight * 2 / 3, left: 0, right: 0, height: 0.5, child: Container(color: Colors.white30)),
          ],
        ),
      ),
    );
  }
}

/// 抠图指示层（四个角白色转角框及居中提示文字）
class CameraMattingOverlay extends StatelessWidget {
  final double displayW;
  final double displayH;
  final double topOffset;
  final double leftOffset;

  const CameraMattingOverlay({
    super.key,
    required this.displayW,
    required this.displayH,
    required this.topOffset,
    required this.leftOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: leftOffset,
      width: displayW,
      height: displayH,
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: MattingFramePainter()),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '请将抠图主体置于框内',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'LXGWWenKai'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 局部高斯模糊遮罩边框
class CameraBlurFrame extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final double height;

  const CameraBlurFrame({
    super.key,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: top,
      left: left,
      width: width > 0 ? width : 0,
      height: height > 0 ? height : 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
