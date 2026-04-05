import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../pages/decoration_page_constants.dart';
import 'furniture_sprite.dart';

class IsometricGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double fullWidth;
  final double fullHeight;
  final List<PlacedFurniture> placedItems;
  final (FurnitureItem, (int, int)?, int, bool, double)? ghostItem;
  final bool isInteracting;
  final double currentScale;
  final bool showGrid;
  final (int, int)? selectedCell;
  final PlacedFurniture? selectedFurniture;
  final PlacedFurniture? draggingOriginalPF;
  final double centerYFactor;
  final bool isCapturing;
  final PlacedFurniture? bouncingItem;
  final double bounceScale;

  IsometricGridPainter({
    required this.rows,
    required this.cols,
    required this.fullWidth,
    required this.fullHeight,
    this.selectedCell,
    this.placedItems = const [],
    this.ghostItem,
    this.selectedFurniture,
    required this.centerYFactor,
    this.isCapturing = false,
    this.showGrid = true,
    this.isInteracting = false,
    this.currentScale = 1.0,
    this.draggingOriginalPF,
    this.bouncingItem,
    this.bounceScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * centerYFactor;

    // 旋转整体网格
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(kGridRotationDegree * math.pi / 180);
    canvas.translate(-centerX, -centerY);

    // 单个菱形格子的尺寸
    final double tw = fullWidth / 28;
    final double th = tw * kGridAspectRatio;

    // 初始化统一的坐标转换工具
    final converter = IsometricCoordinateConverter(
      centerX: centerX,
      centerY: centerY,
      tw: tw,
      th: th,
    );

    // 如果正在截图或用户手动关闭网格，跳过网格线和序号的绘制
    if (showGrid && !isCapturing) {
      // --- 1. 绘制地面网格 (XY 平面) ---
      for (int j = 0; j <= cols; j++) {
        for (int i = 0; i < rows; i++) {
          final start = converter.getScreenPoint(i.toDouble(), j.toDouble());
          final end = converter.getScreenPoint(
            (i + 1).toDouble(),
            j.toDouble(),
          );
          canvas.drawLine(start, end, paint);
        }
      }
      for (int i = 0; i <= rows; i++) {
        for (int j = 0; j < cols; j++) {
          final start = converter.getScreenPoint(i.toDouble(), j.toDouble());
          final end = converter.getScreenPoint(
            i.toDouble(),
            (j + 1).toDouble(),
          );
          canvas.drawLine(start, end, paint);
        }
      }

      // --- 3. 绘制地面网格坐标序号 (性能大户：交互时或缩放过小时隐藏) ---
      final bool shouldShowLabels =
          showGrid && !isCapturing && !isInteracting && currentScale >= 1.2;

      if (shouldShowLabels) {
        final textStyle = TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 6.0,
          fontWeight: FontWeight.w300,
        );

        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < cols; j++) {
            final center = converter.getScreenPoint(i + 0.5, j + 0.5);

            final textPainter = TextPainter(
              text: TextSpan(text: '$i,$j', style: textStyle),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            textPainter.paint(
              canvas,
              center - Offset(textPainter.width / 2, textPainter.height / 2),
            );
          }
        }

        // --- 墙面网格坐标序号 ---
        final wallTextStyle = TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 6.0,
          fontWeight: FontWeight.w300,
        );

        // 左墙 XZ 面 (i, z)
        for (int i = 0; i < rows; i += 1) {
          for (int z = 0; z < kWallGridHeight; z += 1) {
            final center = converter.getScreenPoint(i + 0.5, 0, z + 0.5);
            final tp = TextPainter(
              text: TextSpan(text: '$i,$z', style: wallTextStyle),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
          }
        }

        // 右墙 YZ 面 (j, z)
        for (int j = 0; j < cols; j += 1) {
          for (int z = 0; z < kWallGridHeight; z += 1) {
            final center = converter.getScreenPoint(0, j + 0.5, z + 0.5);
            final tp = TextPainter(
              text: TextSpan(text: '$j,$z', style: wallTextStyle),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
          }
        }
      }

      // --- 2. 绘制墙面网格 (XZ 和 YZ 平面) ---
      final wallPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 左后墙 (XZ 面, 沿 j=0)
      for (int i = 0; i <= rows; i++) {
        final bottom = converter.getScreenPoint(i.toDouble(), 0);
        final top = converter.getScreenPoint(
          i.toDouble(),
          0,
          kWallGridHeight.toDouble(),
        );
        canvas.drawLine(bottom, top, wallPaint);
      }
      for (int z = 1; z <= kWallGridHeight; z++) {
        final start = converter.getScreenPoint(0, 0, z.toDouble());
        final end = converter.getScreenPoint(rows.toDouble(), 0, z.toDouble());
        canvas.drawLine(start, end, wallPaint);
      }

      // 右后墙 (YZ 面, 沿 i=0)
      for (int j = 0; j <= cols; j++) {
        final bottom = converter.getScreenPoint(0, j.toDouble());
        final top = converter.getScreenPoint(
          0,
          j.toDouble(),
          kWallGridHeight.toDouble(),
        );
        canvas.drawLine(bottom, top, wallPaint);
      }
      for (int z = 1; z <= kWallGridHeight; z++) {
        final start = converter.getScreenPoint(0, 0, z.toDouble());
        final end = converter.getScreenPoint(0, cols.toDouble(), z.toDouble());
        canvas.drawLine(start, end, wallPaint);
      }
    }

    // --- 分层渲染：将地板与其他物体分离，并过滤掉正在被搬动的“虚体” ---
    final floors = placedItems
        .where((pf) => pf.item.isFloor && pf != draggingOriginalPF)
        .toList();
    final others = placedItems
        .where((pf) => !pf.item.isFloor && pf != draggingOriginalPF)
        .toList();

    // 1. 绘制地板层
    for (final pf in floors) {
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    if (selectedFurniture != null && selectedFurniture!.item.isFloor) {
      _drawSelectionFootprint(canvas, selectedFurniture!, converter, tw, th);
    }

    // 2. 绘制其他物体层
    final sortedOthers = List<PlacedFurniture>.from(others)
      ..sort((a, b) {
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;
        if (a.r + gwA <= b.r || a.c + ghA <= b.c) return -1;
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) return 1;
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedOthers) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, converter, tw, th);
      }
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    // --- 绘制拖拽预览 (Ghost) ---
    if (ghostItem != null && ghostItem!.$2 != null) {
      _drawFurniture(
        canvas,
        ghostItem!.$1,
        ghostItem!.$2!.$1,
        ghostItem!.$2!.$2,
        ghostItem!.$5,
        converter,
        tw,
        th,
        0.5,
        ghostItem!.$3,
        ghostItem!.$4,
      );
    }

    if (selectedCell != null && selectedFurniture == null) {
      _drawSelectionCell(canvas, selectedCell!, converter, tw, th);
    }
    canvas.restore();
  }

  void _drawSelectionFootprint(
    Canvas canvas,
    PlacedFurniture pf,
    IsometricCoordinateConverter converter,
    double tw,
    double th,
  ) {
    final Offset p0, p1, p2, p3;
    if (pf.item.isWall) {
      final double h = pf.item.gridH.toDouble();
      final double l = pf.item.gridW.toDouble();
      final double baseZ = pf.z;
      if (pf.rotation % 2 == 0) {
        p0 = converter.getScreenPoint(
          pf.r.toDouble(),
          pf.c.toDouble(),
          baseZ + h,
        );
        p1 = converter.getScreenPoint(pf.r + l, pf.c.toDouble(), baseZ + h);
        p2 = converter.getScreenPoint(pf.r + l, pf.c.toDouble(), baseZ);
        p3 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ);
      } else {
        p0 = converter.getScreenPoint(
          pf.r.toDouble(),
          pf.c.toDouble(),
          baseZ + h,
        );
        p1 = converter.getScreenPoint(pf.r.toDouble(), pf.c + l, baseZ + h);
        p2 = converter.getScreenPoint(pf.r.toDouble(), pf.c + l, baseZ);
        p3 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ);
      }
    } else {
      int gw = pf.item.gridW;
      int gh = pf.item.gridH;
      if (pf.rotation % 2 != 0) {
        gw = pf.item.gridH;
        gh = pf.item.gridW;
      }
      p0 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), pf.z);
      p1 = converter.getScreenPoint(
        (pf.r + gw).toDouble(),
        pf.c.toDouble(),
        pf.z,
      );
      p2 = converter.getScreenPoint(
        (pf.r + gw).toDouble(),
        (pf.c + gh).toDouble(),
        pf.z,
      );
      p3 = converter.getScreenPoint(
        pf.r.toDouble(),
        (pf.c + gh).toDouble(),
        pf.z,
      );
    }
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.yellow.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  void _drawFurniture(
    Canvas canvas,
    FurnitureItem item,
    int r,
    int c,
    double z,
    IsometricCoordinateConverter converter,
    double tw,
    double th,
    double opacity, [
    int rotation = 0,
    bool isValid = true,
    double currentBounceScale = 1.0,
  ]) {
    int gw = item.gridW;
    int gh = item.gridH;
    if (rotation % 2 != 0) {
      gw = item.gridH;
      gh = item.gridW;
    }
    final bool isFlipped = rotation == 1;
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
    
    // 统一为单面素材，faceIndex 固定为 0
    const int faceIndex = 0;

    final p0 = converter.getScreenPoint(r.toDouble(), c.toDouble());
    final p1 = converter.getScreenPoint((r + gw).toDouble(), c.toDouble());
    final p2 = converter.getScreenPoint(
      (r + gw).toDouble(),
      (c + gh).toDouble(),
    );
    final p3 = converter.getScreenPoint(r.toDouble(), (c + gh).toDouble());
    final paint = Paint()
      ..color = (isValid ? Colors.black : Colors.red).withOpacity(0.6 * opacity)
      ..style = PaintingStyle.fill;
    if (!item.isWall) {
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
    final image = SpritePainter.getImage(item.imagePath);
    if (image != null) {
      if (item.isFloor) {
        final src = Rect.fromLTWH(
          (item.spriteRect.left + faceIndex * item.spriteRect.width) *
              image.width,
          item.spriteRect.top * image.height,
          item.spriteRect.width * image.width,
          item.spriteRect.height * image.height,
        );
        final clipPath = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();
        final double minX = [p0.dx, p1.dx, p2.dx, p3.dx].reduce(math.min);
        final double maxX = [p0.dx, p1.dx, p2.dx, p3.dx].reduce(math.max);
        final double minY = [p0.dy, p1.dy, p2.dy, p3.dy].reduce(math.min);
        final double maxY = [p0.dy, p1.dy, p2.dy, p3.dy].reduce(math.max);
        final dst = Rect.fromLTRB(minX, minY, maxX, maxY);
        canvas.save();
        canvas.clipPath(clipPath);
        if (item.visualRotationZ != 0 || currentBounceScale != 1.0) {
          final center = dst.center;
          canvas.translate(center.dx, center.dy);
          if (item.visualRotationZ != 0) canvas.rotate(item.visualRotationZ * math.pi / 180);
          if (currentBounceScale != 1.0) canvas.scale(currentBounceScale, currentBounceScale);
          canvas.translate(-center.dx, -center.dy);
        }
        canvas.drawImageRect(
          image,
          src,
          dst,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
      } else if (item.isWall) {
        // --- 墙面项专用：原图回归方案 (Treat as pre-rendered isometric) ---
        final double s = converter.getTaperScale(r.toDouble(), c.toDouble());
        final bool isLeftWall = rotation % 2 == 0;

        // 计算在墙面上的参考尺寸 (以格点跨度为基准)
        final double itemW = (item.gridW * tw / 2) * s * vScale;
        final double itemH =
            itemW * (item.intrinsicHeight / item.intrinsicWidth);

        // 计算底边中点 (同步 _drawSelectionFootprint 的坐标系)
        // 左墙底边中点坐标为 (r + gridW/2, c, z)
        // 右墙底边中点坐标为 (r, c + gridW/2, z)
        final double midR = isLeftWall ? r + item.gridW / 2.0 : r.toDouble();
        final double midC = isLeftWall ? c.toDouble() : c + item.gridW / 2.0;
        final Offset basePoint = converter.getScreenPoint(midR, midC, z);

        canvas.save();
        // 1. 移动到基准位置并应用 visualOffset
        // 为墙面项增加约 10 像素的默认下沉量，以补偿素材视觉落差，使其紧贴黄色底线
        const double wallBasePadding = 33.0;
        canvas.translate(
          basePoint.dx + vOffset.dx,
          basePoint.dy + wallBasePadding + vOffset.dy,
        );

        // 2. 镜像翻转处理 (如果是右墙则进行水平镜像)
        if (isFlipped) canvas.scale(-1, 1);
        if (vRotZ != 0) canvas.rotate(vRotZ * math.pi / 180);
        if (currentBounceScale != 1.0) {
          // Bottom center is the pivot (0,0) in current translation for walls
          canvas.scale(currentBounceScale, currentBounceScale);
        }

        // 4. 绘制原图贴图 (锚点设在底部中心)
        final dst = Rect.fromLTRB(-itemW / 2, -itemH, itemW / 2, 0);
        final src = Rect.fromLTWH(
          (item.spriteRect.left + faceIndex * item.spriteRect.width) *
              image.width,
          item.spriteRect.top * image.height,
          item.spriteRect.width * image.width,
          item.spriteRect.height * image.height,
        );

        canvas.drawImageRect(
          image,
          src,
          dst,
          Paint()
            ..color = (isValid ? Colors.white : Colors.redAccent).withOpacity(
              opacity,
            )
            ..filterQuality = FilterQuality.medium
            ..colorFilter = isValid
                ? null
                : const ColorFilter.mode(Colors.red, BlendMode.modulate),
        );
        canvas.restore();
      } else {
        final double baseS = converter.getTaperScale(
          r + gw / 2.0,
          c + gh / 2.0,
        );
        final double itemW = tw * (gw + gh) * baseS * 0.5 * vScale;
        final double itemH =
            itemW * (item.intrinsicHeight / item.intrinsicWidth);
        final basePoint = converter.getScreenPoint(r + gw / 2.0, c + gh / 2.0);
        canvas.save();
        
        // 软装和地毯属于平铺类的特殊装饰，其图像中心应该直接对齐网格菱形的中心，而不是由于 3D 模型假定那样底部对齐。
        double ty = basePoint.dy + (itemW / 4.0) - (itemH / 2.0);
        if (item.subCategory == '软装' || item.subCategory == '地毯') {
          // 消除底部对齐产生的垂直偏移，使图片中心严格对应着菱形网格中心
          ty = basePoint.dy;
        }
        
        canvas.translate(
          basePoint.dx + vOffset.dx,
          ty + vOffset.dy,
        );
        if (isFlipped) canvas.scale(-1, 1);
        final dst = Rect.fromCenter(
          center: Offset.zero,
          width: itemW,
          height: itemH,
        );
        if (vRotX != 0 || vRotY != 0 || vRotZ != 0 || currentBounceScale != 1.0) {
          final matrix = Matrix4.identity()
            ..translate(vPivot.dx, vPivot.dy);
          
          if (currentBounceScale != 1.0) {
            matrix.translate(0.0, itemH / 2.0);
            matrix.scale(currentBounceScale, currentBounceScale, 1.0);
            matrix.translate(0.0, -itemH / 2.0);
          }
          
          matrix..rotateX(vRotX * math.pi / 180)
            ..rotateY(vRotY * math.pi / 180)
            ..rotateZ(vRotZ * math.pi / 180)
            ..translate(-vPivot.dx, -vPivot.dy);
          canvas.transform(matrix.storage);
        }
        final src = Rect.fromLTWH(
          (item.spriteRect.left + faceIndex * item.spriteRect.width) *
              image.width,
          item.spriteRect.top * image.height,
          item.spriteRect.width * image.width,
          item.spriteRect.height * image.height,
        );
        canvas.drawImageRect(
          image,
          src,
          dst,
          Paint()
            ..color = (isValid ? Colors.white : Colors.redAccent).withOpacity(
              opacity,
            )
            ..filterQuality = FilterQuality.low
            ..colorFilter = isValid
                ? null
                : const ColorFilter.mode(Colors.red, BlendMode.modulate),
        );
        canvas.restore();
      }
    }
  }

  void _drawSelectionCell(
    Canvas canvas,
    (int, int) cell,
    IsometricCoordinateConverter converter,
    double tw,
    double th,
  ) {
    final p0 = converter.getScreenPoint(cell.$1.toDouble(), cell.$2.toDouble());
    final p1 = converter.getScreenPoint(
      (cell.$1 + 1).toDouble(),
      cell.$2.toDouble(),
    );
    final p2 = converter.getScreenPoint(
      (cell.$1 + 1).toDouble(),
      (cell.$2 + 1).toDouble(),
    );
    final p3 = converter.getScreenPoint(
      cell.$1.toDouble(),
      (cell.$2 + 1).toDouble(),
    );
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) {
    return oldDelegate.placedItems != placedItems ||
        oldDelegate.ghostItem != ghostItem ||
        oldDelegate.selectedFurniture != selectedFurniture ||
        oldDelegate.selectedCell != selectedCell ||
        oldDelegate.isInteracting != isInteracting ||
        oldDelegate.currentScale != currentScale ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.draggingOriginalPF != draggingOriginalPF ||
        oldDelegate.bouncingItem != bouncingItem ||
        oldDelegate.bounceScale != bounceScale;
  }
}
