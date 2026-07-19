import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_bottom_sheet.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryTextStylePickerSheet extends StatefulWidget {
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
  State<DiaryTextStylePickerSheet> createState() => _DiaryTextStylePickerSheetState();
}

class _DiaryTextStylePickerSheetState extends State<DiaryTextStylePickerSheet> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    // 采用与通用弹窗一致的非信纸配色，跟随主题颜色
    final Color inkColor = isNight 
        ? Colors.white 
        : (themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937));
        
    final Color accentColor = themeId == 'cotton_candy'
        ? (isNight ? const Color(0xFFC0A6FF) : const Color(0xFF7C3AED))
        : (themeId == 'lego' ? const Color(0xFF3B82F6) : (isNight ? const Color(0xFFD4A373) : const Color(0xFF8B5E3C)));

    final List<Map<String, dynamic>> sizes = [
      {'label': '极小', 'value': 14.0, 'min': 12.0, 'max': 16.0},
      {'label': '小', 'value': 17.0, 'min': 16.0, 'max': 19.0},
      {'label': '默认', 'value': 20.0, 'min': 19.0, 'max': 22.0},
      {'label': '大', 'value': 24.0, 'min': 22.0, 'max': 26.0},
      {'label': '极大', 'value': 28.0, 'min': 26.0, 'max': 30.0},
      {'label': '特大', 'value': 32.0, 'min': 30.0, 'max': 41.0},
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

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      showDragHandle: true,
      isDiary: false,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一部分：文字大小
          DiaryBottomSheetHeader(
            title: '设置文字大小',
            fontFamily: fontFamily,
            textColor: inkColor.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final int selectedIndex = sizes.indexWhere((size) => widget.currentFontSize >= size['min'] && widget.currentFontSize < size['max']);
                final validIndex = selectedIndex >= 0 ? selectedIndex : 2; // Default fallback
                final double itemWidth = constraints.maxWidth / sizes.length;

                return SizedBox(
                  height: 36, // Fixed height to contain the Stack
                  child: Stack(
                    children: [
                      // 1. Sliding thumb (Physical sliding animation)
                      AnimatedPositioned(
                        duration: 350.ms,
                        curve: Curves.easeOutCubic, // Elegant physics
                        left: validIndex * itemWidth,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isNight ? const Color(0xFF333333) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !isNight ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ] : null,
                          ),
                        ),
                      ),
                      
                      // 2. Text Labels
                      Row(
                        children: [
                          for (int i = 0; i < sizes.length; i++)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onApplyFontSize(sizes[i]['value']),
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: 250.ms,
                                    curve: Curves.easeOutCubic,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 13,
                                      color: (validIndex == i) 
                                          ? (isNight ? Colors.white : accentColor) 
                                          : inkColor.withValues(alpha: 0.6),
                                      fontWeight: (validIndex == i) ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    child: Text(
                                      sizes[i]['label'],
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 滑块
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015),
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: widget.currentFontSize.clamp(12.0, 40.0),
                        end: widget.currentFontSize.clamp(12.0, 40.0),
                      ),
                      duration: _isDragging ? Duration.zero : 350.ms,
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, child) {
                        return Slider(
                          value: animatedValue,
                          min: 12,
                          max: 40,
                          onChangeStart: (val) {
                            setState(() => _isDragging = true);
                          },
                          onChangeEnd: (val) {
                            setState(() => _isDragging = false);
                            widget.onApplyFontSize(val);
                          },
                          onChanged: (val) {
                            widget.onApplyFontSize(val);
                          },
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  '${widget.currentFontSize.toInt()}',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, thickness: 0.5, color: inkColor.withValues(alpha: 0.1)),
          const SizedBox(height: 20),

          // 第二部分：常用字体
          _buildSectionTitle('常用字体', accentColor, inkColor, fontFamily),
          const SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.zero,
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
              final isSelected = widget.currentFontFamily == font['value'];
              return GestureDetector(
                onTap: () => widget.onApplyFontFamily(font['value']!),
                child: AnimatedContainer(
                  duration: 200.ms,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.08)
                        : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? accentColor.withValues(alpha: 0.8) : inkColor.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: AnimatedDefaultTextStyle(
                          duration: 250.ms,
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontFamily: font['value'],
                            fontSize: 13,
                            color: isSelected ? accentColor : inkColor.withValues(alpha: 0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          child: Text(font['label']!),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ).animate(target: isSelected ? 1 : 0).scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                          duration: 250.ms,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSectionTitle(String title, Color accentColor, Color inkColor, String fontFamily) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: inkColor.withValues(alpha: 0.9),
        letterSpacing: 1.0,
      ),
    );
  }
}
