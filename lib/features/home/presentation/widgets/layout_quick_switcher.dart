import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_overlay.dart';

class LayoutQuickSwitcher extends StatelessWidget {
  final bool isNight;

  const LayoutQuickSwitcher({
    super.key,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UserState().diaryLayoutMode,
      builder: (context, currentModeIndex, _) {
        final themeId = UserState().selectedIslandThemeId.value;

        Color activeColor;
        Color selectedIconColor;
        Color unselectedIconColor;
        Color containerColor;
        Color borderColor;

        if (themeId == 'cotton_candy') {
          activeColor = const Color(0xFFFF94B8);
          selectedIconColor = Colors.white;
          unselectedIconColor = isNight
              ? Colors.white.withValues(alpha: 0.6)
              : const Color(0xFF6F5E63).withValues(alpha: 0.6);
          containerColor = isNight
              ? const Color(0xFF8676FF).withValues(alpha: 0.25)
              : const Color(0xFFFFCADB).withValues(alpha: 0.45);
          borderColor = isNight
              ? const Color(0xFFB19FFB).withValues(alpha: 0.3)
              : const Color(0xFFFFD1E1).withValues(alpha: 0.45);
        } else if (themeId == 'lego') {
          activeColor = const Color(0xFFFFD54F);
          selectedIconColor = const Color(0xFF3B2E25);
          unselectedIconColor = isNight
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.5);
          containerColor = isNight
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.15);
          borderColor = isNight
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08);
        } else {
          // 默认水蓝色主题
          activeColor = isNight ? const Color(0xFF00ACC1) : const Color(0xFF83B7C5);
          selectedIconColor = Colors.white;
          unselectedIconColor = isNight
              ? Colors.white.withValues(alpha: 0.6)
              : const Color(0xFF83B7C5);
          containerColor = isNight
              ? const Color(0xFF1B2A4A).withValues(alpha: 0.4)
              : const Color(0xFFEDF5F7).withValues(alpha: 0.7);
          borderColor = isNight
              ? const Color(0xFF80D8FF).withValues(alpha: 0.25)
              : const Color(0xFF83B7C5).withValues(alpha: 0.65);
        }

        final List<DiaryLayoutMode> modes = [
          DiaryLayoutMode.masonry,
          DiaryLayoutMode.timeline,
          DiaryLayoutMode.calendar,
        ];

        final selectedIndex = modes.indexOf(
          DiaryLayoutMode.values[currentModeIndex.clamp(0, DiaryLayoutMode.values.length - 1)],
        ).clamp(0, 2);

        final List<IconData> icons = [
          Icons.view_quilt_rounded,
          Icons.format_list_bulleted_rounded,
          Icons.calendar_month_rounded,
        ];

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 120,
              height: 36,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: 0.8,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    alignment: selectedIndex == 0
                        ? Alignment.centerLeft
                        : (selectedIndex == 1
                            ? Alignment.center
                            : Alignment.centerRight),
                    child: FractionallySizedBox(
                      widthFactor: 0.33,
                      child: Container(
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: List.generate(modes.length, (i) {
                        final isSelected = i == selectedIndex;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              UserState().setDiaryLayoutMode(modes[i].index);
                            },
                            child: Center(
                              child: Icon(
                                icons[i],
                                size: 18,
                                color: isSelected
                                    ? selectedIconColor
                                    : unselectedIconColor,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
