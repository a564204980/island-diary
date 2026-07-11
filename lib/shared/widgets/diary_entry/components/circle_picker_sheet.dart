import 'package:flutter/material.dart';

import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';
import 'diary_bottom_sheet.dart';
import 'style_color_picker.dart';

class CirclePickerSheet extends StatefulWidget {
  final String? currentStyle;
  final Color? currentColor;
  final String paperStyle;
  final void Function(String? style, Color? color) onApply;

  const CirclePickerSheet({
    super.key,
    required this.onApply,
    this.currentStyle,
    this.currentColor,
    this.paperStyle = 'classic',
  });

  @override
  State<CirclePickerSheet> createState() => _CirclePickerSheetState();
}

class _CirclePickerSheetState extends State<CirclePickerSheet> {
  String? _selectedStyle;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final style = widget.currentStyle;
    _selectedStyle = (style != null && style.startsWith('circle')) ? style : null;
    _selectedColor = widget.currentColor ?? const Color(0xFFFC2E1F);

    if (_selectedStyle == null) {
      _selectedStyle = 'circle';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onApply(_selectedStyle, _selectedColor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    final Color textColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);

    final List<Map<String, dynamic>> styles = [
      {'label': '单线圈', 'value': 'circle'},
      {'label': '双线圈', 'value': 'circle_double'},
      {'label': '虚线圈', 'value': 'circle_dashed'},
    ];

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: true,
      showDragHandle: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择线圈样式',
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

          // 1. 样式选择 (始终展示，以便在自定义颜色取色时，上方示例可以实时预览效果)
          ...[
            Text(
              "选择样式：",
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.3,
              ),
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final item = styles[index];
                final String val = item['value']!;
                final String label = item['label']!;
                final isSelected = _selectedStyle == val;
                final Color activeColor = _selectedColor;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedStyle = null;
                      } else {
                        _selectedStyle = val;
                      }
                    });
                    widget.onApply(_selectedStyle, _selectedColor);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isNight 
                          ? (isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02))
                          : (isSelected ? Colors.white : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? activeColor : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
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
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              child: Text(
                                "这是一段文字",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xDE000000),
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CirclePreviewPainter(
                                  val, 
                                  isSelected ? activeColor : (isNight ? Colors.white30 : Colors.black26)
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: activeColor,
                            size: 15,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          StyleColorPicker(
            selectedColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
              widget.onApply(_selectedStyle, _selectedColor);
            },
            fontFamily: fontFamily,
            textColor: textColor,
            isNight: isNight,
          ),
          const SizedBox(height: 6),
        ],
        ),
      ),
    );
  }
}

// 预览大椭圆圈绘制器
class _CirclePreviewPainter extends CustomPainter {
  final String style;
  final Color color;

  _CirclePreviewPainter(this.style, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final rect = Rect.fromLTRB(1.0, 1.0, w - 1.0, h - 1.0);

    if (style == 'circle_double') {
      canvas.drawOval(rect, paint);
      final innerRect = Rect.fromLTRB(3.5, 3.0, w - 3.5, h - 3.0);
      canvas.drawOval(innerRect, paint);
    } else if (style == 'circle_dashed') {
      final mainPath = Path()..addOval(rect);
      final dashPath = Path();
      for (final metric in mainPath.computeMetrics()) {
        double distance = 0.0;
        bool draw = true;
        while (distance < metric.length) {
          final double len = draw ? 4.5 : 3.0;
          if (draw) {
            dashPath.addPath(
              metric.extractPath(distance, (distance + len).clamp(0.0, metric.length)),
              Offset.zero,
            );
          }
          distance += len;
          draw = !draw;
        }
      }
      canvas.drawPath(dashPath, paint);
    } else {
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePreviewPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.color != color;
  }
}



