import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_bottom_sheet.dart';
import '../utils/diary_utils.dart';

/// 专门用于日记文字和背景颜色选择的底栏面板
class DiaryColorPickerSheet extends StatefulWidget {
  final Color currentTextColor;
  final Color currentBgColor;
  final String paperStyle;
  final void Function(Color color, bool isBackground) onApplyColor;
  final void Function(bool isBackground) onClear;
  final bool initialIsBackground;

  const DiaryColorPickerSheet({
    super.key,
    required this.currentTextColor,
    required this.currentBgColor,
    required this.paperStyle,
    required this.onApplyColor,
    required this.onClear,
    this.initialIsBackground = false,
  });

  @override
  State<DiaryColorPickerSheet> createState() => _DiaryColorPickerSheetState();
}

class _DiaryColorPickerSheetState extends State<DiaryColorPickerSheet> {
  late bool showCustom;
  late Color pickerColor;
  late bool isBackground; // 当前是否为背景色模式

  @override
  void initState() {
    super.initState();
    showCustom = false;
    isBackground = widget.initialIsBackground;
    pickerColor = isBackground ? widget.currentBgColor : widget.currentTextColor;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    // 使用统一的主题取色逻辑
    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color textColor = DiaryUtils.getInkColor(widget.paperStyle, isNight).withValues(alpha: 0.9);

    final List<Color> currentColors = DiaryUtils.presetTextColors;
    
    final Color effectiveCurrentColor = isBackground 
        ? widget.currentBgColor 
        : widget.currentTextColor;

    // 分割预设色彩为两行，每行固定 8 个元素（第二行最后放置重置按钮），以此免除 GridView 所产生的任何横向滚动和拖拽条边界问题
    final List<Color> row1Colors = currentColors.sublist(0, 8);
    final List<Color> row2Colors = currentColors.sublist(8, 15);

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      showDragHandle: false,
      isDiary: true,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      showCustom ? Icons.grid_view_rounded : Icons.colorize_rounded,
                      color: accentColor,
                      size: 20,
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
                  const SizedBox(width: 4),
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
            ],
          ),
          const SizedBox(height: 16),
          
          // Tab 切换区（iOS Segmented Control 高级毛玻璃悬浮风格）
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    label: "文字颜色",
                    active: !isBackground,
                    color: accentColor,
                    textColor: textColor,
                    isNight: isNight,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildTab(
                    label: "背景颜色",
                    active: isBackground,
                    color: accentColor,
                    textColor: textColor,
                    isNight: isNight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          if (!showCustom)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: row1Colors.map((color) {
                    final bool isSelected = effectiveCurrentColor == color;
                    return _buildColorItem(color, isSelected, accentColor, isNight);
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...row2Colors.map((color) {
                      final bool isSelected = effectiveCurrentColor == color;
                      return _buildColorItem(color, isSelected, accentColor, isNight);
                    }),
                    _buildResetItem(isNight, textColor),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic)
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 动态获取宽度，保证在各种大小的屏幕上，横向拖动条都能被完美包裹，不再发生溢出和跑偏
                        return ColorPicker(
                          pickerColor: pickerColor,
                          onColorChanged: (color) => setState(() => pickerColor = color),
                          pickerAreaHeightPercent: 0.55,
                          enableAlpha: false,
                          displayThumbColor: true,
                          labelTypes: const [],
                          paletteType: PaletteType.hsvWithHue,
                          colorPickerWidth: constraints.maxWidth,
                          pickerAreaBorderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        );
                      },
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

  Widget _buildTab({
    required String label,
    required bool active,
    required Color color,
    required Color textColor,
    required bool isNight,
  }) {
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
        duration: 250.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (active)
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 14,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? color : textColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorItem(Color color, bool isSelected, Color accentColor, bool isNight) {
    return GestureDetector(
      onTap: () => widget.onApplyColor(color, isBackground),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: AnimatedContainer(
          duration: 200.ms,
          width: isSelected ? 26 : 28,
          height: isSelected ? 26 : 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.computeLuminance() > 0.9
                  ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08))
                  : Colors.transparent,
              width: 0.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: isSelected
              ? Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildResetItem(bool isNight, Color textColor) {
    return GestureDetector(
      onTap: () => widget.onClear(isBackground),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(
            color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
        child: Icon(
          Icons.format_color_reset_rounded,
          color: Colors.redAccent.withValues(alpha: 0.8),
          size: 16,
        ),
      ),
    );
  }
}

