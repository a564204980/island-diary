import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'config/mood_config.dart';
import '../island_button.dart';

class MoodPopupPicker extends StatefulWidget {
  final int? initialIndex;
  final double initialIntensity;

  const MoodPopupPicker({
    super.key,
    this.initialIndex,
    this.initialIntensity = 6.0,
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
    final bgColor = isNight ? const Color(0xFF1E1E2C) : const Color(0xFFFDF7E9);
    final primaryColor = isNight ? const Color(0xFFE0C097) : const Color(0xFF8B5E3C);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
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
            // 心情网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: kMoods.length,
              itemBuilder: (context, index) {
                final mood = kMoods[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? mood.glowColor?.withOpacity(0.15) ?? primaryColor.withOpacity(0.08)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? primaryColor
                            : primaryColor.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: (mood.glowColor ?? primaryColor).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          mood.iconPath ?? 'assets/images/icons/sun.png',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? primaryColor : primaryColor.withOpacity(0.6),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // 自定义标签输入
            Text(
              '自定义心情 (可选)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor.withOpacity(0.7),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _tagController,
                style: TextStyle(color: primaryColor, fontFamily: 'LXGWWenKai', fontSize: 15),
                decoration: InputDecoration(
                  hintText: '想喝奶茶、打工中...',
                  hintStyle: TextStyle(color: primaryColor.withOpacity(0.3), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
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
                      children: history.map((tag) => GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _tagController.text = tag;
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withOpacity(0.1)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(color: primaryColor.withOpacity(0.6), fontSize: 12, fontFamily: 'LXGWWenKai'),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // 强度滑动
            if (_selectedIndex != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Text(
                      '情绪强度',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor.withOpacity(0.7),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_intensity.toInt()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: primaryColor.withOpacity(0.1),
                  thumbColor: primaryColor,
                  overlayColor: primaryColor.withOpacity(0.2),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _intensity,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _intensity = val);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            // 确认按钮
            IslandButton(
              text: '落地此情',
              width: double.infinity,
              backgroundColor: _selectedIndex == null && _tagController.text.trim().isEmpty 
                  ? primaryColor.withOpacity(0.3) 
                  : primaryColor,
              textStyle: TextStyle(
                color: _selectedIndex == null && _tagController.text.trim().isEmpty 
                    ? Colors.white70 
                    : Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: 'LXGWWenKai',
              ),
              onTap: () {
                final tag = _tagController.text.trim();
                // 只要选了心情或者填了标签就可以点确定
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
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
