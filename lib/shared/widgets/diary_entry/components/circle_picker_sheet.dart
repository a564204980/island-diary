import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';
import 'diary_bottom_sheet.dart';

class CirclePickerSheet extends StatefulWidget {
  final String? currentStyle;
  final Color? currentColor;
  final String paperStyle;
  final void Function(String style, Color color) onApply;
  final VoidCallback onClear;

  const CirclePickerSheet({
    super.key,
    required this.onApply,
    required this.onClear,
    this.currentStyle,
    this.currentColor,
    this.paperStyle = 'classic',
  });

  @override
  State<CirclePickerSheet> createState() => _CirclePickerSheetState();
}

class _CirclePickerSheetState extends State<CirclePickerSheet> {
  late String _selectedStyle;
  late Color _selectedColor;
  bool _showCustomColorPicker = false;

  static const List<Map<String, dynamic>> _circleColors = [
    {'name': '暖红', 'value': 0xFFFF5A5A},
    {'name': '橘橙', 'value': 0xFFFF9E79},
    {'name': '芥黄', 'value': 0xFFF5C445},
    {'name': '森绿', 'value': 0xFF2ECC71},
    {'name': '海蓝', 'value': 0xFF3498DB},
    {'name': '罗紫', 'value': 0xFF9B59B6},
    {'name': '水灰', 'value': 0xFF7F8C8D},
  ];

  @override
  void initState() {
    super.initState();
    final style = widget.currentStyle;
    _selectedStyle = (style != null && style.startsWith('circle')) ? style : 'circle';
    _selectedColor = widget.currentColor ?? const Color(0xFFFF5A5A);
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
                _showCustomColorPicker ? '自定义圈线颜色' : '设置圈线样式与颜色',
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
                      _selectedStyle = val;
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
                                "示例",
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

          // 2. 颜色选择栏 (包含自定义颜色吸管切换按钮)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showCustomColorPicker ? "HSV 调色盘：" : "选择颜色：",
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showCustomColorPicker ? Icons.grid_view_rounded : Icons.colorize_rounded,
                  color: textColor.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showCustomColorPicker = !_showCustomColorPicker;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _showCustomColorPicker
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _circleColors.map((colorMap) {
                    final int value = colorMap['value']!;
                    final Color color = Color(value);
                    final bool isSelected = _selectedColor == color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                        widget.onApply(_selectedStyle, _selectedColor);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14.0, top: 6, bottom: 6),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isSelected)
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CustomPaint(
                                  painter: _SelectedColorOuterPainter(color),
                                ),
                              ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            secondChild: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 175,
                  height: 175,
                  child: _CustomHueRingPicker(
                    pickerColor: _selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        _selectedColor = color;
                      });
                      widget.onApply(_selectedStyle, _selectedColor);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. 一键清除
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isNight ? const Color(0xFF3E3A36) : const Color(0xFFF5F5F5),
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
              ),
              onPressed: () {
                widget.onClear();
                Navigator.pop(context);
              },
              child: Center(
                child: Text(
                  "清除圈线效果",
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD35D5D),
                  ),
                ),
              ),
            ),
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

// 选中颜色外围虚线光环绘制器
class _SelectedColorOuterPainter extends CustomPainter {
  final Color color;

  _SelectedColorOuterPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? 3.0 : 2.5;
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
  }

  @override
  bool shouldRepaint(covariant _SelectedColorOuterPainter oldDelegate) => oldDelegate.color != color;
}

// 轻量级自定义环形取色器，剔除了包默认附带的所有文本框和冗余的预览块，防止溢出
class _CustomHueRingPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const _CustomHueRingPicker({
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hsvColor = HSVColor.fromColor(pickerColor);
    final double ringStrokeWidth = 14.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 外围色相环
        Positioned.fill(
          child: ColorPickerHueRing(
            hsvColor,
            (hsv) => onColorChanged(hsv.toColor()),
            displayThumbColor: true,
            strokeWidth: ringStrokeWidth,
          ),
        ),
        // 中间饱和度与明度选择区域（赋予 12dp 的圆角以符合卡片美学）
        SizedBox(
          width: 95,
          height: 95,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorPickerArea(
              hsvColor,
              (hsv) => onColorChanged(hsv.toColor()),
              PaletteType.hsv,
            ),
          ),
        ),
      ],
    );
  }
}

