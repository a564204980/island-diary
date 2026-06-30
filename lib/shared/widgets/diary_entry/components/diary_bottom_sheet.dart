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
      bgColor = isNight
          ? DiaryUtils.getPopupBackgroundColor(paperStyle, isNight)
          : Colors.white;
    } else {
      // 非日记相关页面：使用符合当前主题的纯色/中性配色，而非纸张材质色
      if (isNight) {
        bgColor = themeId == 'cotton_candy' 
            ? const Color(0xFF1E1B2E)
            : (themeId == 'lego' ? const Color(0xFF18181B) : const Color(0xFF1F1F1F));
        inkColor = Colors.white;
      } else {
        bgColor = themeId == 'cotton_candy' 
            ? const Color(0xFFFAF5FF)
            : (themeId == 'lego' ? const Color(0xFFF9FAFB) : Colors.white);
        inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
      }
    }

    final double resolvedTopPadding = showDragHandle ? 12.0 : (padding is EdgeInsets ? (padding as EdgeInsets).top : 20.0);
    final double extraContentTopPadding = showDragHandle && (padding is EdgeInsets) ? (padding as EdgeInsets).top : 0.0;

    final resolvedPadding = EdgeInsets.only(
      left: padding is EdgeInsets ? (padding as EdgeInsets).left : 20,
      right: padding is EdgeInsets ? (padding as EdgeInsets).right : 20,
      top: resolvedTopPadding,
      bottom: padding is EdgeInsets ? (padding as EdgeInsets).bottom : (24 + MediaQuery.of(context).padding.bottom),
    );

    Widget content = Container(
      height: height,
      clipBehavior: clipBehavior,
      padding: resolvedPadding,
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
          if (extraContentTopPadding > 0) SizedBox(height: extraContentTopPadding),
          if (height != null) Expanded(child: child) else child,
        ],
      ),
    );
 
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: content,
    );
  }
}
