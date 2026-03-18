import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// 专门用于日记文字和背景颜色选择的底栏面板
class DiaryColorPickerSheet extends StatefulWidget {
  final String title;
  final Color currentTextColor;
  final ValueChanged<Color> onApplyColor;
  final VoidCallback onClear;
  final List<Color> colors;

  const DiaryColorPickerSheet({
    super.key,
    required this.title,
    required this.currentTextColor,
    required this.onApplyColor,
    required this.onClear,
    required this.colors,
  });

  @override
  State<DiaryColorPickerSheet> createState() => _DiaryColorPickerSheetState();
}

class _DiaryColorPickerSheetState extends State<DiaryColorPickerSheet> {
  late bool showCustom;
  late Color pickerColor;

  @override
  void initState() {
    super.initState();
    showCustom = false;
    pickerColor = widget.currentTextColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showCustom ? '自定义颜色' : widget.title,
                style: const TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5E3C),
                ),
              ),
              IconButton(
                icon: Icon(
                  showCustom ? Icons.grid_view : Icons.colorize_rounded,
                  color: const Color(0xFF8B5E3C),
                ),
                onPressed: () => setState(() => showCustom = !showCustom),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!showCustom)
            // 模式 A：快捷预设网格
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ...widget.colors.map((color) {
                    final isSelected = widget.currentTextColor == color;
                    return GestureDetector(
                      onTap: () => widget.onApplyColor(color),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5E3C)
                                : Colors.white.withOpacity(0.5),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    );
                  }),
                  // 清除按钮
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5E3C).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.block,
                        color: Color(0xFFC0392B),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // 模式 B：方阵专业取色
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) =>
                        setState(() => pickerColor = color),
                    pickerAreaHeightPercent: 0.6,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [], // 隐藏数字标签，保持简洁
                    paletteType: PaletteType.hsvWithHue,
                    pickerAreaBorderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      // 颜色预览块
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: pickerColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5E3C).withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => widget.onApplyColor(pickerColor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5E3C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '落地此色',
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
