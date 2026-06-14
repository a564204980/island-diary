import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';

class DiaryBottomSheet extends StatelessWidget {
  final Widget child;
  final String paperStyle;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool showDragHandle;
  final bool isDiary;
  final Clip clipBehavior;

  const DiaryBottomSheet({
    super.key,
    required this.child,
    required this.paperStyle,
    this.height,
    this.padding,
    this.showDragHandle = true,
    this.isDiary = false,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    final Color inkColor;
    final Color bgColor;

    if (isDiary) {
      inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
      bgColor = DiaryUtils.getPopupBackgroundColor(paperStyle, isNight);
    } else {
      // 非日记相关页面：使用符合当前主题的纯色/中性配色，而非纸张材质色
      if (isNight) {
        bgColor = themeId == 'cotton_candy' 
            ? const Color(0xFF1E1B2E)
            : (themeId == 'lego' ? const Color(0xFF18181B) : const Color(0xFF162537));
        inkColor = Colors.white;
      } else {
        bgColor = themeId == 'cotton_candy' 
            ? const Color(0xFFFAF5FF)
            : (themeId == 'lego' ? const Color(0xFFF9FAFB) : Colors.white);
        inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
      }
    }

    Widget content = Container(
      height: height,
      clipBehavior: clipBehavior,
      padding: padding ?? EdgeInsets.only(
        left: 20,
        right: 20,
        top: showDragHandle ? 12 : 20,
        bottom: 24 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      margin: isLego ? const EdgeInsets.only(bottom: 6) : null,
      decoration: DiaryUtils.getPopupDecoration(paperStyle, isNight, customBgColor: bgColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) ...[
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: (themeId == 'cotton_candy' && isNight)
                      ? const Color(0xFFC0A6FF).withValues(alpha: 0.4)
                      : inkColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.25),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (height != null) Expanded(child: child) else child,
        ],
      ),
    );

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: isNight ? 15 : 0,
        sigmaY: isNight ? 15 : 0,
      ),
      child: content,
    );
  }
}
