import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';

/// 专门用于日记文字和背景颜色选择的底栏面板
class DiaryColorPickerSheet extends StatefulWidget {
  final Color currentTextColor;
  final Color currentBgColor;
  final String paperStyle;
  final void Function(Color color, bool isBackground) onApplyColor;
  final void Function(bool isBackground) onClear;

  const DiaryColorPickerSheet({
    super.key,
    required this.currentTextColor,
    required this.currentBgColor,
    required this.paperStyle,
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
    // 使用统一的主题取色逻辑
    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(widget.paperStyle, isNight);
    final Color textColor = DiaryUtils.getInkColor(widget.paperStyle, isNight).withValues(alpha: 0.9);

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
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部区域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showCustom ? '自定义取色' : '色彩工具',
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
              Row(
                children: [
                  _buildHeaderButton(
                    icon: showCustom ? Icons.grid_view_rounded : Icons.colorize_rounded,
                    onPressed: () {
                      setState(() {
                        showCustom = !showCustom;
                        if (showCustom) {
                          pickerColor = effectiveCurrentColor;
                        }
                      });
                    },
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(context),
                    color: textColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tab 切换区
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTab(label: "文字墨水", active: !isBackground, color: accentColor, textColor: textColor)),
                const SizedBox(width: 4),
                Expanded(child: _buildTab(label: "高亮底色", active: isBackground, color: accentColor, textColor: textColor)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          if (!showCustom)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Wrap(
                spacing: 14,
                runSpacing: 18,
                alignment: WrapAlignment.start, // 改为靠左，更有规律
                children: [
                   ...currentColors.map((color) {
                    final bool isSelected = effectiveCurrentColor == color;
                    return GestureDetector(
                      onTap: () => widget.onApplyColor(color, isBackground),
                      child: Tooltip(
                        message: "选择此色",
                        child: AnimatedContainer(
                          duration: 300.ms,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.3),
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isSelected 
                              ? Icon(Icons.check_rounded, size: 24, color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
                              : null,
                        ),
                      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                    );
                  }),
                  // 重置按钮
                  GestureDetector(
                    onTap: () => widget.onClear(isBackground),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.format_color_reset_rounded,
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scaleY(begin: 0.9, curve: Curves.easeOutBack)
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isNight ? 0.05 : 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentColor.withValues(alpha: 0.1)),
                    ),
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
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: pickerColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: textColor.withValues(alpha: 0.15), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: pickerColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => widget.onApplyColor(pickerColor, isBackground),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: accentColor.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('定义此刻色彩', style: TextStyle(fontFamily: 'LXGWWenKai', fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onPressed, required Color color}) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
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
        duration: 400.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (active)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 15,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? Colors.white : textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
