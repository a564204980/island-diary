import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class StyleColorPicker extends StatefulWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final String fontFamily;
  final Color textColor;
  final bool isNight;
  final bool disableColorSelection;

  const StyleColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.fontFamily,
    required this.textColor,
    required this.isNight,
    this.disableColorSelection = false,
  });

  @override
  State<StyleColorPicker> createState() => _StyleColorPickerState();
}

class _StyleColorPickerState extends State<StyleColorPicker> {
  bool _showCustomColorPicker = false;

  static const List<Map<String, dynamic>> _circleColors = [
    {'name': '红', 'value': 0xFFFC2E1F},
    {'name': '橙', 'value': 0xFFFE9027},
    {'name': '黄', 'value': 0xFFFECE34},
    {'name': '绿', 'value': 0xFF93D140},
    {'name': '青', 'value': 0xFF28C0B5},
    {'name': '蓝', 'value': 0xFF3A8AFD},
    {'name': '紫', 'value': 0xFF9168FA},
    {'name': '粉', 'value': 0xFFFC7CBA},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _showCustomColorPicker ? "HSV 调色盘：" : "选择颜色：",
              style: TextStyle(
                fontFamily: widget.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.textColor.withValues(alpha: 0.7),
              ),
            ),
            IconButton(
              icon: Icon(
                _showCustomColorPicker ? Icons.grid_view_rounded : Icons.colorize_rounded,
                color: widget.textColor.withValues(alpha: 0.6),
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
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _circleColors.map((colorMap) {
                final int value = colorMap['value']!;
                final Color color = Color(value);
                final bool isColorSelected = widget.selectedColor == color && !widget.disableColorSelection;

                return GestureDetector(
                  onTap: () {
                    widget.onColorChanged(color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.all(isColorSelected ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isColorSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          if (!isColorSelected) // Only show shadow when not selected to keep it clean
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: isColorSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hsvColor = HSVColor.fromColor(widget.selectedColor);
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth * 0.6,
                        child: ColorPickerArea(
                          hsvColor,
                          (hsv) {
                            widget.onColorChanged(hsv.toColor());
                          },
                          PaletteType.hsvWithHue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      width: constraints.maxWidth,
                      child: ColorPickerSlider(
                        TrackType.hue,
                        hsvColor,
                        (hsv) {
                          widget.onColorChanged(hsv.toColor());
                        },
                        displayThumbColor: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
