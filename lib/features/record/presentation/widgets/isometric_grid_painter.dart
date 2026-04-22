import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  final Color wallColorLeft;
  final Color wallColorRight;

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
    this.wallColorLeft = const Color(0xFFDEDCCE),
    this.wallColorRight = const Color(0xFFDEDCCE),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
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
    final double tw = fullWidth / 50;
    final double th = tw * kGridAspectRatio;

    // 初始化统一的坐标转换工具
    final converter = IsometricCoordinateConverter(
      centerX: centerX,
      centerY: centerY,
      tw: tw,
      th: th,
    );

    // --- 0. 绘制墙面底层染色 ---
    // 宸﹀鍖哄煙 (XZ 闈?
    final leftWallPath = Path()
      ..moveTo(
        converter.getScreenPoint(0, 0, 0).dx,
        converter.getScreenPoint(0, 0, 0).dy,
      )
      ..lineTo(
        converter.getScreenPoint(rows.toDouble(), 0, 0).dx,
        converter.getScreenPoint(rows.toDouble(), 0, 0).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble())
            .dy,
      )
      ..lineTo(
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx,
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy,
      )
      ..close();

    // 鍙冲鍖哄煙 (YZ 闈?
    final rightWallPath = Path()
      ..moveTo(
        converter.getScreenPoint(0, 0, 0).dx,
        converter.getScreenPoint(0, 0, 0).dy,
      )
      ..lineTo(
        converter.getScreenPoint(0, cols.toDouble(), 0).dx,
        converter.getScreenPoint(0, cols.toDouble(), 0).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble())
            .dy,
      )
      ..lineTo(
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx,
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy,
      )
      ..close();

    // 缁撴瀯杞粨绾跨敾绗?(娣卞挅鑹诧紝鐭㈤噺鎵嬬粯鎰?
    final outlinePaint = Paint()
      ..color = const Color(0xFF3B3B36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      leftWallPath,
      Paint()
        ..color = wallColorLeft
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      rightWallPath,
      Paint()
        ..color = wallColorRight
        ..style = PaintingStyle.fill,
    );

    // 缁樺埗澧欓潰涓昏疆寤撶嚎
    canvas.drawPath(leftWallPath, outlinePaint);
    canvas.drawPath(rightWallPath, outlinePaint);

    // --- 0.1 缁樺埗澧欎綋鍘氬害鏁堟灉 (3D 绔嬩綋鎰? ---
    final hslLeft = HSLColor.fromColor(wallColorLeft);
    final hslRight = HSLColor.fromColor(wallColorRight);

    // 椤堕儴鍘氬害闈?(鐣ヤ寒)
    final topPaintLeft = Paint()
      ..color = hslLeft
          .withLightness((hslLeft.lightness + 0.12).clamp(0.0, 1.0))
          .toColor()
      ..style = PaintingStyle.fill;
    final topPaintRight = Paint()
      ..color = hslRight
          .withLightness((hslRight.lightness + 0.12).clamp(0.0, 1.0))
          .toColor()
      ..style = PaintingStyle.fill;

    // 渚ч潰鎴柇闈?(鐣ユ殫)
    final sidePaintLeft = Paint()
      ..color = hslLeft
          .withLightness((hslLeft.lightness - 0.08).clamp(0.0, 1.0))
          .toColor()
      ..style = PaintingStyle.fill;
    final sidePaintRight = Paint()
      ..color = hslRight
          .withLightness((hslRight.lightness - 0.08).clamp(0.0, 1.0))
          .toColor()
      ..style = PaintingStyle.fill;

    // A. 宸﹀椤堕儴闈?
    final leftTopPath = Path()
      ..moveTo(
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx,
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble())
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(
              rows.toDouble(),
              -kWallThickness,
              kWallGridHeight.toDouble(),
            )
            .dx,
        converter
            .getScreenPoint(
              rows.toDouble(),
              -kWallThickness,
              kWallGridHeight.toDouble(),
            )
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble())
            .dy,
      )
      ..close();
    canvas.drawPath(leftTopPath, topPaintLeft);
    canvas.drawPath(leftTopPath, outlinePaint);

    // B. 鍙冲椤堕儴闈?
    final rightTopPath = Path()
      ..moveTo(
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx,
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble())
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(
              -kWallThickness,
              cols.toDouble(),
              kWallGridHeight.toDouble(),
            )
            .dx,
        converter
            .getScreenPoint(
              -kWallThickness,
              cols.toDouble(),
              kWallGridHeight.toDouble(),
            )
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble())
            .dy,
      )
      ..close();
    canvas.drawPath(rightTopPath, topPaintRight);
    canvas.drawPath(rightTopPath, outlinePaint);

    // C. 杩滅渚ч潰鎴柇 (浠呭綋 rows/cols 杈冨ぇ鏃跺彲瑙?
    final leftEndPath = Path()
      ..moveTo(
        converter.getScreenPoint(rows.toDouble(), 0, 0).dx,
        converter.getScreenPoint(rows.toDouble(), 0, 0).dy,
      )
      ..lineTo(
        converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dx,
        converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(
              rows.toDouble(),
              -kWallThickness,
              kWallGridHeight.toDouble(),
            )
            .dx,
        converter
            .getScreenPoint(
              rows.toDouble(),
              -kWallThickness,
              kWallGridHeight.toDouble(),
            )
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble())
            .dy,
      )
      ..close();
    canvas.drawPath(leftEndPath, sidePaintLeft);
    canvas.drawPath(leftEndPath, outlinePaint);

    final rightEndPath = Path()
      ..moveTo(
        converter.getScreenPoint(0, cols.toDouble(), 0).dx,
        converter.getScreenPoint(0, cols.toDouble(), 0).dy,
      )
      ..lineTo(
        converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dx,
        converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(
              -kWallThickness,
              cols.toDouble(),
              kWallGridHeight.toDouble(),
            )
            .dx,
        converter
            .getScreenPoint(
              -kWallThickness,
              cols.toDouble(),
              kWallGridHeight.toDouble(),
            )
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble())
            .dy,
      )
      ..close();
    canvas.drawPath(rightEndPath, sidePaintRight);
    canvas.drawPath(rightEndPath, outlinePaint);

    // D. 澧欒杩炴帴澶?(Corner Cap)
    final cornerPath = Path()
      ..moveTo(
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx,
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble())
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(
              -kWallThickness,
              -kWallThickness,
              kWallGridHeight.toDouble(),
            )
            .dx,
        converter
            .getScreenPoint(
              -kWallThickness,
              -kWallThickness,
              kWallGridHeight.toDouble(),
            )
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble())
            .dx,
        converter
            .getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble())
            .dy,
      )
      ..close();
    canvas.drawPath(cornerPath, topPaintLeft); // 浣跨敤宸︿晶鏄庡害鍗冲彲锛屼繚鎸佷竴鑷?
    canvas.drawPath(cornerPath, outlinePaint);

    // --- 0.2 缁樺埗鍦伴潰鍘氬害鏁堟灉 (3D 鍩哄骇) ---
    // 宸﹀墠渚ч潰 (鑰冭檻澧欎綋鍘氬害寤朵几锛岃捣濮嬬偣璁句负 (rows, -kWallThickness))
    final floorLeftFacePath = Path()
      ..moveTo(
        converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dx,
        converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dy,
      )
      ..lineTo(
        converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dx,
        converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness)
            .dx,
        converter
            .getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness)
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(rows.toDouble(), -kWallThickness, -kWallThickness)
            .dx,
        converter
            .getScreenPoint(rows.toDouble(), -kWallThickness, -kWallThickness)
            .dy,
      )
      ..close();

    // 鍙冲墠渚ч潰 (鑰冭檻澧欎綋鍘氬害寤朵几锛岃捣濮嬬偣璁句负 (-kWallThickness, cols))
    final floorRightFacePath = Path()
      ..moveTo(
        converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dx,
        converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dy,
      )
      ..lineTo(
        converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dx,
        converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness)
            .dx,
        converter
            .getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness)
            .dy,
      )
      ..lineTo(
        converter
            .getScreenPoint(-kWallThickness, cols.toDouble(), -kWallThickness)
            .dx,
        converter
            .getScreenPoint(-kWallThickness, cols.toDouble(), -kWallThickness)
            .dy,
      )
      ..close();

    // 鍦伴潰渚ч潰棰滆壊 (浣跨敤涓€х殑鐏拌鑹?Foundation Color)
    final floorSideColor = const Color(0xFFD2D0C5);
    final hslFloorSide = HSLColor.fromColor(floorSideColor);
    final floorSidePaintLeft = Paint()
      ..color = hslFloorSide.toColor()
      ..style = PaintingStyle.fill;
    final floorSidePaintRight = Paint()
      ..color = hslFloorSide
          .withLightness((hslFloorSide.lightness - 0.05).clamp(0.0, 1.0))
          .toColor()
      ..style = PaintingStyle.fill;

    canvas.drawPath(floorLeftFacePath, floorSidePaintLeft);
    canvas.drawPath(floorRightFacePath, floorSidePaintRight);
    canvas.drawPath(floorLeftFacePath, outlinePaint);
    canvas.drawPath(floorRightFacePath, outlinePaint);

    // 濡傛灉姝ｅ湪鎴浘鎴栫敤鎴锋墜鍔ㄥ叧闂綉鏍硷紝璺宠繃缃戞牸绾垮拰搴忓彿鐨勭粯鍒?
    if (showGrid && !isCapturing) {
      // --- 1. 缁樺埗鍦伴潰缃戞牸 (XY 骞抽潰) ---
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

      // --- 3. 缁樺埗鍦伴潰缃戞牸鍧愭爣搴忓彿 (鎬ц兘鍏抽敭锛氫氦浜掓椂鎴栫缉鏀捐繃灏忔椂蹇呴』闅愯棌锛岄伩鍏?TextPainter.layout 闃诲涓荤嚎绋? ---
      final bool shouldShowLabels =
          showGrid && !isCapturing && !isInteracting && currentScale >= 2.0;

      if (shouldShowLabels) {
        final textStyle = TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
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

        // --- 澧欓潰缃戞牸鍧愭爣搴忓彿 ---
        final wallTextStyle = TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 6.0,
          fontWeight: FontWeight.w300,
        );

        // 宸﹀ XZ 闈?(i, z)
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

        // 鍙冲 YZ 闈?(j, z)
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

      // --- 2. 缁樺埗澧欓潰缃戞牸 (XZ 鍜?YZ 骞抽潰) ---
      final wallPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 宸﹀悗澧?(XZ 闈? 娌?j=0)
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

      // 鍙冲悗澧?(YZ 闈? 娌?i=0)
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

    // --- 鎬ц兘浼樺寲锛氫竴娆¤凯浠ｅ畬鎴愭墍鏈夊垎绫伙紝閬垮厤 4 娆?.where().toList() 瀵艰嚧鐨?GC 鍘嬪姏 ---
    final List<PlacedFurniture> floors = [];
    final List<PlacedFurniture> carpets = [];
    final List<PlacedFurniture> wallItems = [];
    final List<PlacedFurniture> others = [];
    final List<PlacedFurniture> softDecorations = [];

    for (final pf in placedItems) {
      if (pf == draggingOriginalPF) continue;
      final sub = pf.item.subCategory;
      if (pf.item.isFloor) {
        floors.add(pf);
      } else if (pf.item.isWall) {
        wallItems.add(pf);
      } else if (sub == '地毯') {
        carpets.add(pf);
      } else if (sub == '软装' || sub == '饰品' || sub == '饰物' || sub == '盆栽') {
        softDecorations.add(pf);
      } else {
        others.add(pf);
      }
    }

    // 1. 缁樺埗鍦版澘灞?
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

    // 2. 缁樺埗澧欓潰灞?(姝ゆ椂澧欓潰鏄儗鏅紝搴旀棭浜庡湴姣拰瀹跺叿缁樺埗)
    final sortedWalls = List<PlacedFurniture>.from(wallItems)
      ..sort((a, b) {
        // 淇澧欓潰瓒宠抗璁＄畻锛氭部澧欓暱搴︿负 gridW锛屽帤搴︿负 1
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : 1;
        int ghA = a.rotation % 2 == 0 ? 1 : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : 1;
        int ghB = b.rotation % 2 == 0 ? 1 : b.item.gridW;

        if (a.r + gwA <= b.r || a.c + ghA <= b.c) return -1;
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) return 1;
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedWalls) {
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

    // 3. 缁樺埗鍦版灞?
    for (final pf in carpets) {
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

    // 4. 缁樺埗涓讳綋瀹跺叿灞?
    final sortedOthers = List<PlacedFurniture>.from(others)
      ..sort((a, b) {
        // 涓讳綋瀹跺叿鍧囦负鍦伴潰鐗╁搧锛実w/gh 鐩存帴鏍规嵁鏃嬭浆鐘舵€佸垏鎹?
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;
        if (a.r + gwA <= b.r || a.c + ghA <= b.c) return -1;
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) return 1;
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0 + a.z;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0 + b.z;
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

    // 4. 缁樺埗杞楗板搧灞?(鎶ユ灂銆佹憜鏀剧墿浠?
    final sortedSoftDecorations = List<PlacedFurniture>.from(softDecorations)
      ..sort((a, b) {
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;
        if (a.r + gwA <= b.r || a.c + ghA <= b.c) {
          return -1;
        }
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) {
          return 1;
        }
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0 + a.z;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0 + b.z;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedSoftDecorations) {
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

    // --- 缁樺埗鎷栨嫿棰勮 (Ghost) ---
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
      // 鍏佽 footprint 搴旂敤 Z 杞撮珮搴﹀亸绉?
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
        ..color = Colors.yellow.withValues(alpha: 0.2)
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

    const int faceIndex = 0;
    final image = SpritePainter.getImage(item.imagePath);
    if (image == null) {
      return;
    }

    final p0 = converter.getScreenPoint(r.toDouble(), c.toDouble());
    final p1 = converter.getScreenPoint((r + gw).toDouble(), c.toDouble());
    final p2 = converter.getScreenPoint(
      (r + gw).toDouble(),
      (c + gh).toDouble(),
    );
    final p3 = converter.getScreenPoint(r.toDouble(), (c + gh).toDouble());

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
        if (item.visualRotationZ != 0) {
          canvas.rotate(item.visualRotationZ * math.pi / 180);
        }
        if (currentBounceScale != 1.0) {
          canvas.scale(currentBounceScale, currentBounceScale);
        }
        canvas.translate(-center.dx, -center.dy);
      }
      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else if (item.isWall) {
      final double s = converter.getTaperScale(r.toDouble(), c.toDouble());
      final bool isLeftWall = rotation % 2 == 0;
      final double itemW = (item.gridW * tw / 2) * s * vScale;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);
      final double midR = isLeftWall ? r + item.gridW / 2.0 : r.toDouble();
      final double midC = isLeftWall ? c.toDouble() : c + item.gridW / 2.0;
      final Offset basePoint = converter.getScreenPoint(midR, midC, z);

      canvas.save();
      const double wallBasePadding = 33.0;
      canvas.translate(
        basePoint.dx + vOffset.dx,
        basePoint.dy + wallBasePadding + vOffset.dy,
      );
      if (isFlipped) {
        canvas.scale(-1, 1);
      }
      if (vRotZ != 0) {
        canvas.rotate(vRotZ * math.pi / 180);
      }
      if (currentBounceScale != 1.0) {
        canvas.scale(currentBounceScale, currentBounceScale);
      }

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
          ..color = (isValid ? Colors.white : Colors.redAccent).withValues(
            alpha: opacity,
          )
          ..filterQuality = FilterQuality.medium
          ..colorFilter = isValid
              ? null
              : const ColorFilter.mode(Colors.red, BlendMode.modulate),
      );
      canvas.restore();
    } else {
      final double baseS = converter.getTaperScale(r + gw / 2.0, c + gh / 2.0);
      final double itemW = tw * (gw + gh) * baseS * 0.5 * vScale;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);
      final basePoint = converter.getScreenPoint(r + gw / 2.0, c + gh / 2.0, z);
      canvas.save();

      double ty = basePoint.dy + (itemW / 4.0) - (itemH / 2.0);
      if (item.subCategory == '地毯') {
        ty = basePoint.dy;
      }

      canvas.translate(basePoint.dx + vOffset.dx, ty + vOffset.dy);
      if (isFlipped) {
        canvas.scale(-1, 1);
      }
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: itemW,
        height: itemH,
      );
      if (vRotX != 0 || vRotY != 0 || vRotZ != 0 || currentBounceScale != 1.0) {
        final matrix = Matrix4.identity()
          ..translateByDouble(vPivot.dx, vPivot.dy, 0.0, 1.0);
        if (currentBounceScale != 1.0) {
          matrix.translateByDouble(0.0, itemH / 2.0, 0.0, 1.0);
          matrix.scaleByDouble(
            currentBounceScale,
            currentBounceScale,
            1.0,
            1.0,
          );
          matrix.translateByDouble(0.0, -itemH / 2.0, 0.0, 1.0);
        }
        matrix
          ..rotateX(vRotX * math.pi / 180)
          ..rotateY(vRotY * math.pi / 180)
          ..rotateZ(vRotZ * math.pi / 180)
          ..translateByDouble(-vPivot.dx, -vPivot.dy, 0.0, 1.0);
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
          ..color = (isValid ? Colors.white : Colors.redAccent).withValues(
            alpha: opacity,
          )
          ..filterQuality = FilterQuality.low
          ..colorFilter = isValid
              ? null
              : const ColorFilter.mode(Colors.red, BlendMode.modulate),
      );
      canvas.restore();
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
        ..color = Colors.blue.withValues(alpha: 0.3)
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
