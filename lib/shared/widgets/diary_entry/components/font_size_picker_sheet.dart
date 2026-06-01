import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryFontSizePickerSheet extends StatelessWidget {
  final double currentFontSize;
  final String paperStyle;
  final ValueChanged<double> onApplyFontSize;

  const DiaryFontSizePickerSheet({
    super.key,
    required this.currentFontSize,
    required this.onApplyFontSize,
    this.paperStyle = 'standard',
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);

    final List<Map<String, dynamic>> sizes = [
      {'label': '极小', 'value': 14.0},
      {'label': '小', 'value': 17.0},
      {'label': '默认', 'value': 20.0},
      {'label': '大', 'value': 24.0},
      {'label': '极大', 'value': 28.0},
      {'label': '特大', 'value': 32.0},
    ];

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: isNight ? 15 : 0,
        sigmaY: isNight ? 15 : 0,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: DiaryUtils.getPopupDecoration(
          paperStyle,
          isNight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部装饰条
            DiaryUtils.buildPopupDragHandle(
              paperStyle,
              isNight,
              accentColor,
            ),
            const SizedBox(height: 20),
            Text(
              '设置文字大小',
              style: TextStyle(
                fontFamily: 'LXGWWenKai',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: sizes.map((size) {
                final isSelected = currentFontSize == size['value'];
                return GestureDetector(
                  onTap: () => onApplyFontSize(size['value']),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: accentColor.withValues(alpha: isSelected ? 1.0 : 0.15),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Text(
                      size['label'],
                      style: TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 15,
                        color: isSelected ? Colors.white : inkColor.withValues(alpha: 0.8),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // 滑块区域
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.text_fields_rounded, size: 22, color: accentColor.withValues(alpha: 0.7)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentColor,
                        inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 3),
                      ),
                      child: Slider(
                        value: currentFontSize.clamp(12.0, 40.0),
                        min: 12,
                        max: 40,
                        divisions: 28,
                        onChanged: onApplyFontSize,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${currentFontSize.toInt()}',
                      style: TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
