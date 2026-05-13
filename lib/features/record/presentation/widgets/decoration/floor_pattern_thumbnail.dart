import 'package:flutter/material.dart';
import '../../pages/decoration_page_constants.dart';
import '../../utils/floor_pattern_painter.dart';
import '../../utils/isometric_coordinate_utils.dart';

class FloorPatternThumbnail extends StatelessWidget {
  final String itemId;
  final double width;
  final double height;

  const FloorPatternThumbnail({
    super.key,
    required this.itemId,
    this.width = 100,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    FloorPattern pattern = FloorPattern.none;
    Color color = Colors.grey;

    if (itemId.contains('triple_herringbone')) {
      pattern = FloorPattern.tripleHerringbone;
    } else if (itemId.contains('plaid')) {
      pattern = FloorPattern.plaid;
      color = Colors.white;
    } else if (itemId.contains('herringbone')) {
      pattern = FloorPattern.herringbone;
    }

    // 只有在不是格纹地板时，才根据 ID 应用特定颜色或默认色
    if (pattern != FloorPattern.plaid) {
      if (itemId.contains('mint')) {
        color = const Color(0xFFB9DCC8);
      } else if (itemId.contains('sage')) {
        color = const Color(0xFFA8B49F);
      } else {
        // 默认绿色（herringbone 等使用）
        color = const Color(0xFFA0BA8F);
      }
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _ThumbnailPainter(pattern, color),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  final FloorPattern pattern;
  final Color floorColor;

  _ThumbnailPainter(this.pattern, this.floorColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = floorColor
      ..style = PaintingStyle.fill;

    // 绘制等轴测菱形背景
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);

    // 裁剪区域，防止纹理超出菱形
    canvas.clipPath(path);

    // 绘制纹理
    // 为缩略图创建一个临时的坐标转换器
    final thumbnailConverter = IsometricCoordinateConverter(
      centerX: size.width / 2,
      centerY: size.height / 2,
      tw: size.width / 3, // 调整缩略图的网格密度
      th: size.width / 6,
    );

    FloorPatternPainter.paint(
      canvas: canvas,
      converter: thumbnailConverter,
      pattern: pattern,
      rows: 6,
      cols: 6,
      baseColor: floorColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
