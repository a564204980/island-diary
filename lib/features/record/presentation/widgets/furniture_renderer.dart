import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../pages/decoration_page_constants.dart';
import './furniture_sprite.dart';

class FurnitureRenderer {
  static void draw({
    required Canvas canvas,
    required FurnitureItem item,
    required int r,
    required int c,
    required double z,
    required int rotation,
    required IsometricCoordinateConverter converter,
    required double tw,
    required double th,
    double opacity = 1.0,
    bool isValid = true,
    double bounceScale = 1.0,
  }) {
    final image = SpritePainter.getImage(item.imagePath);
    if (image == null) return;

    final bool isFlipped = rotation % 2 != 0;
    final double vScale = isFlipped
        ? (item.flippedVisualScale ?? item.visualScale)
        : item.visualScale;
    final Offset vOffset = isFlipped
        ? (item.flippedVisualOffset ?? item.visualOffset)
        : item.visualOffset;
    final double vRotX = isFlipped
        ? (item.flippedVisualRotationX ?? item.visualRotationX)
        : item.visualRotationX;
    final double vRotY = isFlipped
        ? (item.flippedVisualRotationY ?? item.visualRotationY)
        : item.visualRotationY;
    final double vRotZ = isFlipped
        ? (item.flippedVisualRotationZ ?? item.visualRotationZ)
        : item.visualRotationZ;
    final Offset vPivot = isFlipped
        ? (item.flippedVisualPivot ?? item.visualPivot)
        : item.visualPivot;

    final int faceIndex = 0; // 可以扩展支持多面序列帧

    if (item.isWall) {
      final double s = converter.getTaperScale(r.toDouble(), c.toDouble());
      final double itemW = (item.gridW * tw / 2) * s * vScale;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);

      final bool isLeftWall = rotation % 2 == 0;
      final double midR = isLeftWall ? r + item.gridW / 2.0 : r.toDouble();
      final double midC = isLeftWall ? c.toDouble() : c + item.gridW / 2.0;
      final Offset basePoint = converter.getScreenPoint(midR, midC, z);

      canvas.save();
      const double wallBasePadding = 33.0;
      canvas.translate(
        basePoint.dx + vOffset.dx,
        basePoint.dy + wallBasePadding + vOffset.dy,
      );
      if (isFlipped) canvas.scale(-1, 1);
      if (vRotZ != 0) canvas.rotate(vRotZ * math.pi / 180);
      if (bounceScale != 1.0) canvas.scale(bounceScale, bounceScale);

      final dst = Rect.fromLTRB(-itemW / 2, -itemH, itemW / 2, 0);
      final src = _getSrcRect(item, faceIndex, image);
      _drawImage(canvas, image, src, dst, opacity, isValid);
      canvas.restore();
    } else {
      int gw = item.gridW;
      int gh = item.gridH;
      if (rotation % 2 != 0) {
        gw = item.gridH;
        gh = item.gridW;
      }
      final double baseS = converter.getTaperScale(
        r + gw / 2.0,
        c + gh / 2.0,
      );
      final double itemW =
          tw * (gw + gh) * baseS * 0.5 * vScale;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);
      final basePoint = converter.getScreenPoint(
        r + gw / 2.0,
        c + gh / 2.0,
        z,
      );

      canvas.save();
      double ty =
          basePoint.dy + (itemW * kGridAspectRatio / 2.0) - (itemH / 2.0);
      if (item.subCategory == '地毯') ty = basePoint.dy;

      canvas.translate(basePoint.dx + vOffset.dx, ty + vOffset.dy);
      if (isFlipped) canvas.scale(-1, 1);

      if (vRotX != 0 || vRotY != 0 || vRotZ != 0 || bounceScale != 1.0) {
        final matrix = Matrix4.identity()..translateByDouble(vPivot.dx, vPivot.dy, 0.0, 1.0);
        if (bounceScale != 1.0) {
          matrix.translateByDouble(0.0, itemH / 2.0, 0.0, 1.0);
          matrix.scaleByDouble(bounceScale, bounceScale, 1.0, 1.0);
          matrix.translateByDouble(0.0, -itemH / 2.0, 0.0, 1.0);
        }
        matrix
          ..rotateX(vRotX * math.pi / 180)
          ..rotateY(vRotY * math.pi / 180)
          ..rotateZ(vRotZ * math.pi / 180)
          ..translateByDouble(-vPivot.dx, -vPivot.dy, 0.0, 1.0);
        canvas.transform(matrix.storage);
      }

      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: itemW,
        height: itemH,
      );
      final src = _getSrcRect(item, faceIndex, image);
      _drawImage(canvas, image, src, dst, opacity, isValid);
      canvas.restore();
    }
  }

  static Rect _getSrcRect(FurnitureItem item, int faceIndex, dynamic image) {
    return Rect.fromLTWH(
      (item.spriteRect.left + faceIndex * item.spriteRect.width) * image.width,
      item.spriteRect.top * image.height,
      item.spriteRect.width * image.width,
      item.spriteRect.height * image.height,
    );
  }

  static void _drawImage(
    Canvas canvas,
    dynamic image,
    Rect src,
    Rect dst,
    double opacity,
    bool isValid,
  ) {
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..color = (isValid ? Colors.white : Colors.redAccent).withValues(
          alpha: opacity,
        )
        ..filterQuality = FilterQuality.low
        ..colorFilter = isValid
            ? null
            : const ColorFilter.mode(Colors.red, BlendMode.modulate),
    );
  }

  static void drawSelectionFootprint(
    Canvas canvas,
    PlacedFurniture pf,
    IsometricCoordinateConverter converter,
    double tw,
    double th,
  ) {
    final List<Offset> pts;
    final double radius = 4.0; 
    const double padding = 0.0; 

    if (pf.item.isWall) {
      final double h = pf.item.gridH.toDouble();
      final double l = pf.item.gridW.toDouble();

      if (pf.rotation % 2 == 0) {
        // 左墙 (XZ 面)
        pts = [
          converter.getScreenPoint(
            pf.r - padding,
            pf.c.toDouble(),
            pf.z - padding,
          ),
          converter.getScreenPoint(
            pf.r + l + padding,
            pf.c.toDouble(),
            pf.z - padding,
          ),
          converter.getScreenPoint(
            pf.r + l + padding,
            pf.c.toDouble(),
            pf.z + h + padding,
          ),
          converter.getScreenPoint(
            pf.r - padding,
            pf.c.toDouble(),
            pf.z + h + padding,
          ),
        ];
      } else {
        // 右墙 (YZ 面)
        pts = [
          converter.getScreenPoint(
            pf.r.toDouble(),
            pf.c - padding,
            pf.z - padding,
          ),
          converter.getScreenPoint(
            pf.r.toDouble(),
            pf.c + l + padding,
            pf.z - padding,
          ),
          converter.getScreenPoint(
            pf.r.toDouble(),
            pf.c + l + padding,
            pf.z + h + padding,
          ),
          converter.getScreenPoint(
            pf.r.toDouble(),
            pf.c - padding,
            pf.z + h + padding,
          ),
        ];
      }
    } else {
      int gw = pf.rotation % 2 == 0 ? pf.item.gridW : pf.item.gridH;
      int gh = pf.rotation % 2 == 0 ? pf.item.gridH : pf.item.gridW;

      pts = [
        converter.getScreenPoint(pf.r - padding, pf.c - padding, pf.z),
        converter.getScreenPoint(pf.r + gw + padding, pf.c - padding, pf.z),
        converter.getScreenPoint(
          pf.r + gw + padding,
          pf.c + gh + padding,
          pf.z,
        ),
        converter.getScreenPoint(pf.r - padding, pf.c + gh + padding, pf.z),
      ];
    }

    if (pts.length < 3) return;

    // 创建圆角路径
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      final p3 = pts[(i + 2) % pts.length];

      // 计算边缘向量并缩放以确定圆角起始点
      final v1 = p2 - p1;
      final v2 = p3 - p2;

      final len1 = v1.distance;
      final len2 = v2.distance;

      final actualRadius = [
        radius,
        len1 / 2,
        len2 / 2,
      ].reduce((a, b) => a < b ? a : b);

      final startPoint = p2 - v1 * (actualRadius / len1);
      final endPoint = p2 + v2 * (actualRadius / len2);

      if (i == 0) {
        path.moveTo(startPoint.dx, startPoint.dy);
      } else {
        path.lineTo(startPoint.dx, startPoint.dy);
      }
      path.quadraticBezierTo(p2.dx, p2.dy, endPoint.dx, endPoint.dy);
    }
    path.close();

    // 绘制填充
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
    // 绘制边框
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFDD835).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }
}
