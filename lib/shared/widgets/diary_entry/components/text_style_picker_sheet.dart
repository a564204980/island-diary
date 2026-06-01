import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryTextStylePickerSheet extends StatelessWidget {
  final double currentFontSize;
  final String currentFontFamily;
  final String paperStyle;
  final ValueChanged<double> onApplyFontSize;
  final ValueChanged<String> onApplyFontFamily;

  const DiaryTextStylePickerSheet({
    super.key,
    required this.currentFontSize,
    required this.currentFontFamily,
    required this.onApplyFontSize,
    required this.onApplyFontFamily,
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

    final List<Map<String, String>> fonts = [
      {'label': '霞鹜文楷', 'value': 'LXGWWenKai'},
      {'label': '方正楷体', 'value': 'FZKai'},
      {'label': '阿里巴巴普惠', 'value': 'Alibaba'},
      {'label': '抖音真体', 'value': 'Douyin'},
      {'label': '荆南波波黑', 'value': 'JingNan'},
      {'label': '西木手写', 'value': 'Nishiki'},
      {'label': '万伟伟手写', 'value': 'WanWeiWei'},
      {'label': '仓耳果秒黑', 'value': 'CangErGuoMiao'},
      {'label': '猫啃珠圆体', 'value': 'MaoKenZhuYuan'},
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
          bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
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

            // 第一部分：文字大小
            _buildSectionTitle('设置文字大小', accentColor),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: sizes.map((size) {
                final isSelected = (currentFontSize - size['value']).abs() < 0.5;
                return GestureDetector(
                  onTap: () => onApplyFontSize(size['value']),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: isSelected ? 1.0 : 0.1),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      size['label'],
                      style: TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 14,
                        color: isSelected ? Colors.white : inkColor.withValues(alpha: 0.7),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 滑块
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.text_fields_rounded, size: 20, color: accentColor.withValues(alpha: 0.6)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentColor,
                        inactiveTrackColor: accentColor.withValues(alpha: 0.1),
                        thumbColor: accentColor,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                  Text(
                    '${currentFontSize.toInt()}',
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12),
            const SizedBox(height: 24),

            // 第二部分：常用字体
            _buildSectionTitle('常用字体', accentColor),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: fonts.length,
              itemBuilder: (context, index) {
                final font = fonts[index];
                final isSelected = currentFontFamily == font['value'];
                return GestureDetector(
                  onTap: () => onApplyFontFamily(font['value']!),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : accentColor.withValues(alpha: 0.1),
                        width: 1.2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        font['label']!,
                        style: TextStyle(
                          fontFamily: font['value'],
                          fontSize: 13,
                          color: isSelected ? Colors.white : inkColor.withValues(alpha: 0.8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSectionTitle(String title, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentColor.withValues(alpha: 0.9),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
