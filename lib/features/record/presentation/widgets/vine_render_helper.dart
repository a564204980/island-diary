import 'dart:ui';
import 'package:flutter/material.dart';
import 'vine_junction_pod_painter.dart';
import 'vine_glow_painter.dart';

/// 藤蔓渲染常量及核心算法助手
class VineRenderHelper {
  // 素材 1 (vine.png) 规格
  static const double kVine1TileHeight = 1086.5;
  // 素材 2 (vine2.png) 规格
  static const double kVine2TileHeight = 911.6;

  // --- 集中调节区 ---
  static const double kVine1To2Overlap = 42.0; // 首段 vine 与第二段 vine2 的重叠
  static const double kVine2To2Overlap = 60.0; // vine2 与 vine2 之间的重叠
  static const double kVine1ShiftX = 0.0; // vine1 的左右微调
  static const double kVine2ShiftX = 22.0; // 配合 SkewX 调整基础偏移
  static const double kVine2SkewX = -0.025; // 减小斜切感，让扭曲更温和
  static const double kVine2SkewOffset = -4.0; // 相应减小补偿值
  // ----------------

  static const double kVine1EffectiveHeight =
      kVine1TileHeight - kVine1To2Overlap;
  static const double kVine2EffectiveHeight =
      kVine2TileHeight - kVine2To2Overlap;

  /// 根据垂直坐标 Y，自动计算对应藤蔓主干的 X 偏移（含变形补偿）
  static double getVineXAt(double y) {
    final bool isFirstSegment = y < kVine1EffectiveHeight;
    double relativeY;
    List<Offset> lookupTable;
    double segmentShift;

    if (isFirstSegment) {
      relativeY = y;
      segmentShift = kVine1ShiftX;
      lookupTable = const [
        Offset(0.0, 30.0),
        Offset(36.2, 12.5),
        Offset(72.4, -5.4),
        Offset(108.7, -12.4),
        Offset(144.9, -21.8),
        Offset(181.1, -12.5),
        Offset(217.3, 24.9),
        Offset(253.5, 22.8),
        Offset(289.7, 71.5),
        Offset(326.0, 39.7),
        Offset(362.2, 10.7),
        Offset(398.4, -65.3),
        Offset(434.6, -73.7),
        Offset(470.8, -80.0),
        Offset(507.1, -74.9),
        Offset(543.3, -103.4),
        Offset(579.5, -113.3),
        Offset(615.7, -106.2),
        Offset(651.9, -130.3),
        Offset(688.1, -93.5),
        Offset(724.4, -16.2),
        Offset(760.6, 11.9),
        Offset(796.8, 10.8),
        Offset(833.0, 91.4),
        Offset(869.2, 98.8),
        Offset(905.4, 79.6),
        Offset(941.7, 65.3),
        Offset(977.9, 32.4),
        Offset(1014.1, 21.8),
        Offset(1050.3, 2.9),
        Offset(1086.5, -16.0),
      ];
    } else {
      relativeY = (y - kVine1EffectiveHeight) % kVine2EffectiveHeight;
      segmentShift = kVine2ShiftX;
      lookupTable = const [
        Offset(0.0, -20.0),
        Offset(23.3, -17.2),
        Offset(46.5, 21.6),
        Offset(69.8, 23.3),
        Offset(93.0, 16.3),
        Offset(116.3, 39.8),
        Offset(139.5, 64.8),
        Offset(162.8, 42.4),
        Offset(186.0, 11.7),
        Offset(209.3, 11.0),
        Offset(232.6, -46.9),
        Offset(255.8, -65.2),
        Offset(279.1, -40.6),
        Offset(302.3, -78.1),
        Offset(325.6, -65.6),
        Offset(348.8, -100.3),
        Offset(372.1, -99.9),
        Offset(395.3, -126.6),
        Offset(418.6, -86.4),
        Offset(441.9, -100.3),
        Offset(465.1, -121.2),
        Offset(488.4, -119.2),
        Offset(511.6, -84.1),
        Offset(534.9, -16.4),
        Offset(558.1, -6.7),
        Offset(581.4, -15.2),
        Offset(604.7, 30.5),
        Offset(627.9, 50.9),
        Offset(651.2, 97.8),
        Offset(674.4, 95.8),
        Offset(697.7, 89.1),
        Offset(720.9, 42.4),
        Offset(744.2, 62.8),
        Offset(767.4, 19.5),
        Offset(790.7, 40.8),
        Offset(814.0, 24.0),
        Offset(837.2, 5.4),
        Offset(860.5, -11.9),
        Offset(911.6, 5.0),
      ];
    }

    for (int i = 0; i < lookupTable.length - 1; i++) {
      final p1 = lookupTable[i];
      final p2 = lookupTable[i + 1];
      if (relativeY >= p1.dx && relativeY <= p2.dx) {
        final double t = (relativeY - p1.dx) / (p2.dx - p1.dx);
        double finalX = p1.dy + (p2.dy - p1.dy) * t + segmentShift;

        // 重要：针对 vine2 的变形进行 X 坐标补偿
        if (!isFirstSegment) {
          finalX += (relativeY * kVine2SkewX) + kVine2SkewOffset;
        }
        return finalX;
      }
    }
    return 6 + segmentShift;
  }

  /// 构建藤蔓背景层
  static Widget buildVineImages(double totalHeight, {bool isNight = false}) {
    final List<Widget> vines = [];
    final List<Widget> junctionPods = [];
    double currentTop = 0;
    int index = 0;

    // --- 动态色彩矩阵：春芽绿 (提升饱和度 + 暖黄调) ---
    // 白天模式下增加暖黄色相和饱和度
    final List<double> springGreenMatrix = isNight
        ? [
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ] // 夜晚保持原样
        : [
            1.02, 0, 0, 0, 2,   // R: 稍微增加红色（暖调），从 1.05/5 降至 1.02/2
            0, 1.05, 0, 0, 5,   // G: 增加绿色（春意），从 1.1/10 降至 1.05/5
            0, 0, 0.98, 0, 0,  // B: 稍微降低蓝色，从 0.95 升至 0.98（减少偏黄感）
            0, 0, 0, 1, 0,
          ];

    while (currentTop < totalHeight + 500) {
      final bool isFirst = index == 0;
      final double shiftX = isFirst ? kVine1ShiftX : kVine2ShiftX;

      // 1. 绘制藤蔓素材 (带滤镜)
      vines.add(
        Positioned(
          top: currentTop,
          left: shiftX,
          right: -shiftX,
          child: Transform(
            transform: isFirst
                ? Matrix4.identity()
                : (Matrix4.skewX(kVine2SkewX)..translate(kVine2SkewOffset)),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(springGreenMatrix),
              child: Stack(
                children: [
                  // 0. 底层投影 (NEW: 增加立体感)
                  Transform.translate(
                    offset: const Offset(2.5, 4.0), // 向右下角偏移
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Image.asset(
                        isFirst
                            ? 'assets/images/vine.png'
                            : 'assets/images/vine2.png',
                        width: 400,
                        fit: BoxFit.fitWidth,
                        color: Colors.black.withOpacity(isNight ? 0.35 : 0.2),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),

                  // 1. 底层边缘光 (ImageFiltered 实现位图描边感)
                  if (!isNight)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                      child: Image.asset(
                        isFirst
                            ? 'assets/images/vine.png'
                            : 'assets/images/vine2.png',
                        width: 400,
                        fit: BoxFit.fitWidth,
                        color: const Color(0xFFFFF8C0).withOpacity(0.4),
                        colorBlendMode: BlendMode.srcATop,
                      ),
                    ),
                  // 主干素材
                  Image.asset(
                    isFirst ? 'assets/images/vine.png' : 'assets/images/vine2.png',
                    width: 400,
                    fit: BoxFit.fitWidth,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 2. 计算下一段起始位置
      final double nextTop =
          currentTop +
          (isFirst ? kVine1EffectiveHeight : kVine2EffectiveHeight);

      // 3. 收集衔接点发光点 (Junction Pod) 用于视觉遮盖接缝
      if (nextTop < totalHeight + 300) {
        final double podX = getVineXAt(nextTop);
        // 向右下角微调一点点 (各增加 12px 偏移)
        junctionPods.add(
          Positioned(
            top: nextTop - 138, // -150 + 12
            left: 200 + podX - 138, // 400/2 + podX - 150 + 12
            child: IgnorePointer(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(painter: VineJunctionPodPainter()),
              ),
            ),
          ),
        );
      }

      currentTop = nextTop;
      index++;
    }

    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 400,
          height: totalHeight,
          child: Stack(
            children: [
              // 0. 发光底层 (NEW)
              Positioned.fill(
                child: CustomPaint(
                  painter: VineGlowPainter(
                    totalHeight: totalHeight,
                    isNight: isNight,
                  ),
                ),
              ),
              ...vines,
              // ...junctionPods, // 暂时隐藏连接处特效
            ],
          ),
        ),
      ),
    );
  }
}
