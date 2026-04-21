import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';

class DiaryFontPickerSheet extends StatelessWidget {
  final String currentFontFamily;
  final ValueChanged<String> onApplyFontFamily;

  const DiaryFontPickerSheet({
    super.key,
    required this.currentFontFamily,
    required this.onApplyFontFamily,
  });

  @override
  Widget build(BuildContext context) {
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

    final bool isNight = UserState().isNight;
    final Color bgColor = DiaryUtils.getPopupBackgroundColor('standard', isNight);
    final Color textColor = DiaryUtils.getInkColor('standard', isNight);

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: isNight ? 15 : 0,
        sigmaY: isNight ? 15 : 0,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '常用字体',
              style: TextStyle(
                fontFamily: 'LXGWWenKai',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: fonts.length,
              itemBuilder: (context, index) {
                final font = fonts[index];
                final isSelected = currentFontFamily == font['value'];
                return GestureDetector(
                  onTap: () => onApplyFontFamily(font['value']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isNight ? textColor.withValues(alpha: 0.8) : const Color(0xFF8B5E3C))
                          : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isNight 
                            ? (isSelected ? textColor : Colors.white10)
                            : (const Color(0xFF8B5E3C)).withValues(alpha: isSelected ? 1.0 : 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        font['label']!,
                        style: TextStyle(
                          fontFamily: font['value'],
                          fontSize: 14,
                          color: isSelected 
                              ? (isNight ? Colors.black87 : Colors.white) 
                              : (isNight ? textColor.withValues(alpha: 0.7) : const Color(0xFF8B5E3C)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
