import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';

/// 专门用于日记文字和背景颜色选择的底栏面板
class DiaryColorPickerSheet extends StatefulWidget {
  final Color currentTextColor;
  final Color currentBgColor;
  final void Function(Color color, bool isBackground) onApplyColor;
  final void Function(bool isBackground) onClear;

  const DiaryColorPickerSheet({
    super.key,
    required this.currentTextColor,
    required this.currentBgColor,
    required this.onApplyColor,
    required this.onClear,
  });

  @override
  State<DiaryColorPickerSheet> createState() => _DiaryColorPickerSheetState();
}

class _DiaryColorPickerSheetState extends State<DiaryColorPickerSheet> {
  late bool showCustom;
  late Color pickerColor;
  bool isBackground = false; // 当前是否为背景色模式

  @override
  void initState() {
    super.initState();
    showCustom = false;
    pickerColor = widget.currentTextColor;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color bgColor = isNight ? const Color(0xFF2D2A26) : const Color(0xFFFDF7E9);
    final Color textColor = isNight ? Colors.white70 : const Color(0xFF5D4037);
    final Color accentColor = isNight ? const Color(0xFFE0C097) : const Color(0xFF8B5E3C);

    final List<Color> currentColors = isBackground 
        ? DiaryUtils.presetBgColors 
        : DiaryUtils.presetTextColors;
    
    final Color effectiveCurrentColor = isBackground 
        ? widget.currentBgColor 
        : widget.currentTextColor;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showCustom ? '自定义取色' : '色彩工具',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      showCustom ? Icons.grid_view : Icons.colorize_rounded,
                      color: accentColor,
                    ),
                    onPressed: () {
                      setState(() {
                        showCustom = !showCustom;
                        if (showCustom) {
                          pickerColor = effectiveCurrentColor;
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor.withOpacity(0.3)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTab(label: "文字墨水", active: !isBackground, color: accentColor, textColor: textColor)),
                Expanded(child: _buildTab(label: "高亮底色", active: isBackground, color: accentColor, textColor: textColor)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!showCustom)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ...currentColors.map((color) {
                    final bool isSelected = effectiveCurrentColor == color;
                    return GestureDetector(
                      onTap: () => widget.onApplyColor(color, isBackground),
                      child: AnimatedContainer(
                        duration: 300.ms,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.white24,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected 
                            ? Icon(Icons.check, size: 24, color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
                            : null,
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => widget.onClear(isBackground),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.format_color_reset_rounded,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) => setState(() => pickerColor = color),
                    pickerAreaHeightPercent: 0.6,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [],
                    paletteType: PaletteType.hsvWithHue,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: pickerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: textColor.withOpacity(0.2)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => widget.onApplyColor(pickerColor, isBackground),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('应用此色', style: TextStyle(fontFamily: 'LXGWWenKai', fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTab({required String label, required bool active, required Color color, required Color textColor}) {
    return GestureDetector(
      onTap: () {
        if (!active) {
          setState(() {
            isBackground = !isBackground;
            if (showCustom) {
              pickerColor = isBackground ? widget.currentBgColor : widget.currentTextColor;
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 15,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.white : textColor.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
