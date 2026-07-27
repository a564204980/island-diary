import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/theme/app_colors.dart';
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
        final themeColors = AppColorsExtension.current(themeId: themeId, isNight: isNight);

        Color activeColor = themeColors.controlActive;
        Color selectedIconColor = (themeId == 'lego' || isNight) ? const Color(0xFF1F1F1F) : Colors.white;
        Color unselectedIconColor = themeColors.controlUnselected;
        Color containerColor = themeColors.controlContainer;
        Color borderColor = themeColors.border;

        final List<DiaryLayoutMode> modes = [
          DiaryLayoutMode.masonry,
          DiaryLayoutMode.calendar,
        ];

        int rawIndex = modes.indexOf(
          DiaryLayoutMode.values[currentModeIndex.clamp(0, DiaryLayoutMode.values.length - 1)],
        );
        final selectedIndex = rawIndex < 0 ? 0 : rawIndex;

        final List<IconData> icons = [
          Icons.view_quilt_rounded,
          Icons.calendar_month_rounded,
        ];

        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 84,
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
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
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
          ),
        );
      },
    );
  }
}
