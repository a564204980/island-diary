import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';
import 'diary_bottom_sheet.dart';

class UnderlinePickerSheet extends StatelessWidget {
  final ValueChanged<String?> onSelectStyle;
  final String? currentStyle;
  final String paperStyle;

  const UnderlinePickerSheet({
    super.key,
    required this.onSelectStyle,
    this.currentStyle,
    this.paperStyle = 'standard',
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> styles = [
      {'index': '01', 'label': '细直', 'value': 'solid', 'text': '这是一段文字', 'color': const Color(0xFF4A90E2)},
      {'index': '02', 'label': '粗直', 'value': 'thick', 'text': '这是一段文字', 'color': const Color(0xFF2ECC71)},
      {'index': '03', 'label': '双线', 'value': 'double', 'text': '这是一段文字', 'color': const Color(0xFF9B59B6)},
      {'index': '04', 'label': '虚线', 'value': 'dashed', 'text': '这是一段文字', 'color': const Color(0xFFE67E22)},
      {'index': '05', 'label': '点线', 'value': 'dotted', 'text': '这是一段文字', 'color': const Color(0xFFE91E63)},
      {'index': '06', 'label': '波浪', 'value': 'wavy', 'text': '这是一段文字', 'color': const Color(0xFF1ABC9C)},
      {'index': '07', 'label': '手写', 'value': 'handdrawn', 'text': '这是一段文字', 'color': const Color(0xFFE74C3C)},
      {'index': '08', 'label': '渐变', 'value': 'gradient', 'text': '这是一段文字', 'color': const Color(0xFF3498DB)},
    ];

    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    final Color textColor = DiaryUtils.getInkColor(paperStyle, isNight);

    return DiaryBottomSheet(
      paperStyle: paperStyle,
      isDiary: true,
      showDragHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择划线样式',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.4, // 双列比例
            ),
            itemCount: styles.length,
            itemBuilder: (context, index) {
              final item = styles[index];
              final String val = item['value']!;
              final String label = item['label']!;
              final String previewText = item['text']!;
              final Color indexColor = item['color']!;
              final isSelected = currentStyle == val;

              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    onSelectStyle(null);
                  } else {
                    onSelectStyle(val);
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isNight 
                        ? (isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02))
                        : (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? indexColor : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Label
                      Text(
                        "$label：",
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Underlined text preview
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xDE000000),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          const SizedBox(height: 2),
                          CustomPaint(
                            size: const Size(69, 6),
                            painter: _UnderlinePreviewPainter(val, indexColor),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: indexColor,
                          size: 15,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UnderlinePreviewPainter extends CustomPainter {
  final String style;
  final Color color;

  _UnderlinePreviewPainter(this.style, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;

    if (style == 'wavy') {
      paint.strokeWidth = 1.8;
      paint.strokeCap = StrokeCap.round;
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 12) {
        path.quadraticBezierTo(x + 3, y - 2.2, x + 6, y);
        path.quadraticBezierTo(x + 9, y + 2.2, x + 12, y);
      }
      canvas.drawPath(path, paint);
    } else if (style == 'handdrawn') {
      paint.strokeWidth = 2.0;
      paint.strokeCap = StrokeCap.round;
      final path = Path();
      path.moveTo(0, y + 0.4);
      for (double x = 0; x < size.width; x += 12) {
        path.quadraticBezierTo(x + 3, y - 0.8, x + 6, y + 0.6);
        path.quadraticBezierTo(x + 9, y - 0.6, x + 12, y + 0.3);
      }
      canvas.drawPath(path, paint);
    } else if (style == 'dashed') {
      paint.strokeWidth = 1.8;
      paint.strokeCap = StrokeCap.round;
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x + 1, y), Offset(x + 6, y), paint);
      }
    } else if (style == 'dotted') {
      paint.strokeWidth = 2.4;
      paint.strokeCap = StrokeCap.round;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x + 2, y), Offset(x + 2.1, y), paint);
      }
    } else if (style == 'double') {
      paint.strokeWidth = 1.0;
      canvas.drawLine(Offset(0, y - 1.5), Offset(size.width, y - 1.5), paint);
      canvas.drawLine(Offset(0, y + 1.5), Offset(size.width, y + 1.5), paint);
    } else if (style == 'thick') {
      paint.strokeWidth = 3.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else if (style == 'gradient') {
      paint.strokeWidth = 2.0;
      paint.shader = const LinearGradient(
        colors: [
          Color(0xFFFF5E62), // 红
          Color(0xFFFF9966), // 橙
          Color(0xFFFFD97D), // 黄
          Color(0xFFC8E688), // 黄绿
          Color(0xFF6DE195), // 绿
          Color(0xFF4DE2C6), // 青
          Color(0xFF3498DB), // 蓝
          Color(0xFF667EEA), // 靛
          Color(0xFF9B59B6), // 紫
          Color(0xFF667EEA), // 靛
          Color(0xFF3498DB), // 蓝
          Color(0xFF4DE2C6), // 青
          Color(0xFF6DE195), // 绿
          Color(0xFFC8E688), // 黄绿
          Color(0xFFFFD97D), // 黄
          Color(0xFFFF9966), // 橙
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      // solid
      paint.strokeWidth = 1.2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UnderlinePreviewPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.color != color;
  }
}
