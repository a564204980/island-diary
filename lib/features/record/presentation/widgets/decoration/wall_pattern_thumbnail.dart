import 'package:flutter/material.dart';
import '../../pages/decoration_page_constants.dart';
import '../../utils/wall_pattern_painter.dart';
import '../../utils/isometric_coordinate_utils.dart';

class WallPatternThumbnail extends StatelessWidget {
  final String itemId;
  final double width;
  final double height;

  const WallPatternThumbnail({
    super.key,
    required this.itemId,
    this.width = 100,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    WallPattern pattern = WallPattern.none;
    Color baseColor = Colors.grey;

    if (itemId.contains('stripes_pink')) {
      pattern = WallPattern.stripes;
      baseColor = const Color(0xFFF0E5D8);
    } else if (itemId.contains('dual_color')) {
      pattern = WallPattern.dualColor;
      baseColor = const Color(0xFFBC5860);
    } else if (itemId.contains('stripes_lavender')) {
      pattern = WallPattern.lavenderStripes;
      baseColor = const Color(0xFFD5CEDD);
    } else if (itemId.contains('wainscoting')) {
      pattern = WallPattern.wainscoting;
      baseColor = const Color(0xFFF0C9CF);
    } else if (itemId.contains('clouds')) {
      pattern = WallPattern.clouds;
      baseColor = const Color(0xFF87CEEB);
    } else if (itemId.contains('gradient')) {
      pattern = WallPattern.gradient;
      baseColor = const Color(0xFFDBF3F4);
    } else if (itemId.contains('sparkle')) {
      pattern = WallPattern.sparkle;
      baseColor = const Color(0xFF9181C9);
    } else if (itemId.contains('melting_drips')) {
      pattern = WallPattern.meltingDrips;
      baseColor = const Color(0xFFF3E9D2);
    }

    return ClipRect(
      child: CustomPaint(
        size: Size(width, height),
        painter: _WallThumbnailPainter(pattern, baseColor),
      ),
    );
  }
}

class _WallThumbnailPainter extends CustomPainter {
  final WallPattern pattern;
  final Color baseColor;

  _WallThumbnailPainter(this.pattern, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    // 采用更小的单位，确保整体比例缩小
    final double tw = size.width / 12; 
    final double th = tw * kGridAspectRatio;
    final double yOffsetComp = (kGridRows + kGridCols) / 2.0 * (th / 2);

    // 墙面宽度约为 rows * (tw/2)
    const double wallRows = 8;
    const double wallHeight = 12;
    final double visualWidth = wallRows * (tw / 2);

    final thumbnailConverter = IsometricCoordinateConverter(
      centerX: size.width / 2 - (visualWidth / 2), // 水平居中
      centerY: size.height / 2 + (16 * th), // 垂直居中修正：(4-24)*th/2 - 6*th = -16th
      tw: tw,
      th: th,
    );

    // 绘制墙面区域 (减小格子数)
    final wallPath = Path()
      ..addPolygon([
        thumbnailConverter.getScreenPoint(0, 0, 0),
        thumbnailConverter.getScreenPoint(8, 0, 0),
        thumbnailConverter.getScreenPoint(8, 0, 12),
        thumbnailConverter.getScreenPoint(0, 0, 12),
      ], true);

    canvas.drawPath(wallPath, Paint()..color = baseColor..style = PaintingStyle.fill);

    canvas.save();
    canvas.clipPath(wallPath);

    // 绘制纹理
    WallPatternPainter.paint(
      canvas: canvas,
      converter: thumbnailConverter,
      pattern: pattern,
      isLeft: true,
      rows: 8,
      cols: 8,
      baseColor: baseColor,
    );

    canvas.restore();

    // 绘制边框
    canvas.drawPath(
      wallPath,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
