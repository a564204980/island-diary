import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../diary_entry/utils/diary_utils.dart';
import 'config/mood_config.dart';

class MoodPopupPicker extends StatefulWidget {
  final int? initialIndex;
  final double initialIntensity;

  final String? paperStyle;

  const MoodPopupPicker({
    super.key,
    this.initialIndex,
    this.initialIntensity = 6.0,
    this.paperStyle,
  });

  @override
  State<MoodPopupPicker> createState() => _MoodPopupPickerState();
}

class _MoodPopupPickerState extends State<MoodPopupPicker> {
  late TextEditingController _tagController;
  int? _selectedIndex;
  double _intensity = 6.0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _intensity = widget.initialIntensity;
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String effectiveStyle = widget.paperStyle ?? 'note1';

    final bool effectiveIsNight = isNight && !effectiveStyle.startsWith('note');
    
    final bgColor = DiaryUtils.getPopupBackgroundColor(effectiveStyle, effectiveIsNight);
    final primaryColor = DiaryUtils.getAccentColor(effectiveStyle, effectiveIsNight);
    final inkColor = DiaryUtils.getInkColor(effectiveStyle, effectiveIsNight);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            20 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '记录此刻...',
                  style: TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: primaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 心情选择：一行 8 个，正方形分布
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.85, // 稍微高一点，防止在窄屏下图标+文字高度溢出
              ),
              itemCount: kMoods.length,
              itemBuilder: (context, index) {
                final mood = kMoods[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedIndex = index;
                      _tagController.clear(); // 选中图标时清空自定义输入
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood.glowColor?.withValues(alpha: 0.15) ??
                                 primaryColor.withValues(alpha: 0.08)
                          : (effectiveIsNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (effectiveIsNight ? Colors.white.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          mood.iconPath ?? 'assets/images/icons/sun.png',
                          width: 20,
                          height: 20,
                        ),
                        Text(
                          mood.label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected 
                                ? primaryColor 
                                : (effectiveIsNight ? Colors.white60 : inkColor.withValues(alpha: 0.7)),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // 自定义标签输入
            Text(
              '自定义心情 (可选)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isNight ? Colors.white38 : primaryColor.withValues(alpha: 0.7),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: effectiveIsNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: effectiveIsNight ? Colors.white.withValues(alpha: 0.1) : inkColor.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _tagController,
                maxLength: 10,
                onChanged: (val) {
                  if (val.trim().isNotEmpty && _selectedIndex != null) {
                    setState(() => _selectedIndex = null);
                  }
                },
                style: TextStyle(
                  color: effectiveIsNight ? Colors.white : inkColor,
                  fontFamily: 'LXGWWenKai',
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '想喝奶茶、打工中...',
                  hintStyle: TextStyle(
                    color: effectiveIsNight ? Colors.white24 : inkColor.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  counterText: "", // 隐藏计数器，保持极简
                ),
              ),
            ),
            // 历史记录
            ValueListenableBuilder<List<String>>(
              valueListenable: UserState().moodTagHistory,
              builder: (context, history, _) {
                if (history.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: history
                          .map(
                            (tag) => GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedIndex = null;
                                  _tagController.text = tag;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: effectiveIsNight ? Colors.white.withValues(alpha: 0.05) : inkColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: effectiveIsNight ? Colors.white.withValues(alpha: 0.1) : inkColor.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: effectiveIsNight ? Colors.white54 : inkColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // 感受强度（始终显示）
            Row(
              children: [
                Text(
                  '感受强度',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: effectiveIsNight ? Colors.white38 : inkColor.withValues(alpha: 0.6),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const Spacer(),
                Text(
                  _intensity < 0.33 ? '微弱' : (_intensity < 0.66 ? '适中' : '强烈'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: primaryColor,
                inactiveTrackColor: effectiveIsNight ? Colors.white10 : inkColor.withValues(alpha: 0.1),
                thumbColor: Colors.white,
                overlayColor: primaryColor.withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                  elevation: 4,
                ),
              ),
              child: Slider(
                value: (_intensity / 10).clamp(0.0, 1.0),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _intensity = val * 10);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IntensityLabel(label: '微弱', value: 0.1, current: _intensity / 10, color: primaryColor),
                  _IntensityLabel(label: '适中', value: 0.5, current: _intensity / 10, color: primaryColor),
                  _IntensityLabel(label: '强烈', value: 0.9, current: _intensity / 10, color: primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 高颜值确认按钮：落地此情
            Builder(
              builder: (context) {
                final mood = _selectedIndex != null ? kMoods[_selectedIndex!] : null;
                final bool canSave = _selectedIndex != null || _tagController.text.trim().isNotEmpty;
                final glowColor = mood?.glowColor ?? primaryColor;
                
                return GestureDetector(
                  onTap: () {
                    final tag = _tagController.text.trim();
                    if (_selectedIndex != null || tag.isNotEmpty) {
                      if (tag.isNotEmpty) {
                        UserState().addMoodTag(tag);
                      }
                      Navigator.pop(context, {
                        'index': _selectedIndex,
                        'intensity': _intensity,
                        'tag': tag.isEmpty ? null : tag,
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: canSave 
                            ? [primaryColor, primaryColor.withBlue(primaryColor.blue + 20).withRed(primaryColor.red - 10)]
                            : [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        if (canSave && isNight)
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: -2,
                            offset: const Offset(0, 4),
                          ),
                        if (canSave && !isNight)
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                      border: Border.all(
                        color: canSave ? Colors.white24 : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '落地此情',
                      style: TextStyle(
                        color: canSave ? Colors.white : (effectiveIsNight ? Colors.white24 : inkColor.withValues(alpha: 0.2)),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                        letterSpacing: 2,
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

class _IntensityLabel extends StatelessWidget {
  final String label;
  final double value;
  final double current;
  final Color color;

  const _IntensityLabel({
    required this.label,
    required this.value,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    if (value < 0.33) {
      isActive = current < 0.33;
    } else if (value < 0.66) {
      isActive = current >= 0.33 && current < 0.66;
    } else {
      isActive = current >= 0.66;
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? color : color.withValues(alpha: 0.3),
        fontFamily: 'LXGWWenKai',
      ),
    );
  }
}
