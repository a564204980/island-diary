import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../pages/decoration_page_constants.dart';

/// 等距坐标转换工具类，统一处理网格坐标 (r, c, z) 到屏幕像素坐标的转换模型。
class IsometricCoordinateConverter {
  final double centerX;
  final double centerY;
  final double tw; // 单元格宽度基准
  final double th; // 单元格高度基准

  IsometricCoordinateConverter({
    required this.centerX,
    required this.centerY,
    required this.tw,
    required this.th,
  });

  /// 获取指定网格坐标处的投影变形比例 (Taper)
  double getTaperScale(double r, double c) {
    final double u = (r / kGridRows).clamp(0, 1);
    final double v = (c / kGridCols).clamp(0, 1);
    
    return 1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;
  }

  /// 将网格坐标 (r, c, z) 转换为屏幕偏移量 Offset
  Offset getScreenPoint(double r, double c, [double z = 0]) {
    final double s = getTaperScale(r, c);

    // 基础等距投影坐标 (未旋转前)
    // x 轴：(r - c) 方向
    // y 轴：(r + c) 方向，并减去中心偏移
    final double x = (r - c) * (tw / 2) * s;
    final double y = (r + c - (kGridRows + kGridCols) / 2) * (th / 2) * s;
    
    // 垂直高度补偿 (Z 轴)
    final double hFactor = tw / 2;
    final double verticalY = -z * hFactor * s;

    // 应用网格整体旋转 (kGridRotationDegree)
    final double rad = kGridRotationDegree * math.pi / 180;
    final double cosR = math.cos(rad);
    final double sinR = math.sin(rad);

    final double rotatedX = x * cosR - (y + verticalY) * sinR;
    final double rotatedY = x * sinR + (y + verticalY) * cosR;

    return Offset(centerX + rotatedX, centerY + rotatedY);
  }

  /// 估算家具在当前坐标下的视觉宽度 (受 Taper 影响)
  double estimateVisualWidth(int gridW, int gridH, double r, double c, double visualScale) {
    final double s = getTaperScale(r, c);
    return tw * (gridW + gridH) * s * 0.5 * visualScale;
  }

  /// 计算家具在屏幕上的视觉矩形 (用于命中检测或 Overlay 定位)
  Rect getFurnitureRect({
    required int r,
    required int c,
    required int gw,
    required int gh,
    required double visualScale,
    required Offset visualOffset,
    required double intrinsicWidth,
    required double intrinsicHeight,
    double z = 0,
  }) {
    final pt = getScreenPoint(r + gw / 2.0, c + gh / 2.0, z);
    final double itemW = estimateVisualWidth(gw, gh, r + gw / 2.0, c + gh / 2.0, visualScale);
    final double spriteH = itemW * (intrinsicHeight / intrinsicWidth);
    final double verticalOffset = itemW / 4.0;

    return Rect.fromLTWH(
      pt.dx - itemW / 2 + visualOffset.dx,
      pt.dy + verticalOffset - spriteH + visualOffset.dy,
      itemW,
      spriteH,
    );
  }

  /// 核心命中检测：根据像素坐标反推最近的网格坐标 (r, c)
  (int, int)? getGridCell(Offset localPos, {double? customThresholdSq}) {
    (int, int)? bestCell;
    double minDistanceSq = double.infinity;

    // 搜索所有格子，找到中心点最接近鼠标位置的
    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kGridCols; c++) {
        final pt = getScreenPoint(r + 0.5, c + 0.5, 0);

        final double dx = localPos.dx - pt.dx;
        final double dy = localPos.dy - pt.dy;
        final double distSq = dx * dx + dy * dy;

        if (distSq < minDistanceSq) {
          minDistanceSq = distSq;
          bestCell = (r, c);
        }
      }
    }

    // 动态阈值：确保在高倍缩放（tw 很大）或极低缩放（tw 很小）时点击都有效
    // 使用 tw^2 作为基准容差，覆盖整个菱形区域
    final double thresholdSq = customThresholdSq ?? (tw * tw * 1.5);
    
    if (minDistanceSq > thresholdSq) return null;
    return bestCell;
  }
}
