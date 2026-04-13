import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_painters.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

/// 日记信纸容器组件，封装底图与边框效果
class DiaryPaperCanvas extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? shadowColor;
  final String style;
  final Color? accentColor;

  const DiaryPaperCanvas({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(32, 40, 32, 32),
    this.shadowColor,
    this.style = 'note1',
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, _, __) {
        final bool isNight = UserState().isNight;
        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? Colors.black).withValues(alpha: 0.15),
                offset: const Offset(0, 20),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 信纸背景绘制器
              Positioned.fill(
                child: ValueListenableBuilder<DiaryDraft?>(
                  valueListenable: UserState().diaryDraft,
                  builder: (context, draft, _) {
                    final mood = (draft?.moodIndex != null && draft!.moodIndex! >= 0) 
                        ? kMoods[draft.moodIndex!] 
                        : null;
                    final effectiveAccentColor = accentColor ?? (isNight 
                        ? (mood?.glowColor ?? const Color(0xFFE0C097))
                        : (mood?.glowColor != null 
                            ? Color.lerp(mood!.glowColor, Colors.black, 0.45)!
                            : const Color(0xFF8B5E3C)));

                    final bool effectiveIsNight = isNight && !style.startsWith('note');
                    return Stack(
                      children: [
                        if (style.startsWith('note'))
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/note/${style.replaceFirst('note', 'note_bg')}${['note1', 'note2', 'note3', 'note4', 'note5'].contains(style) ? '.png' : '.jpg'}',
                              fit: BoxFit.cover,
                              color: effectiveIsNight ? Colors.black.withValues(alpha: 0.3) : null,
                              colorBlendMode: effectiveIsNight ? BlendMode.darken : null,
                            ),
                          ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PaperBackgroundPainter(
                              style: style,
                              isNight: effectiveIsNight,
                              accentColor: effectiveAccentColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // 内容层
              Padding(padding: padding, child: child),
            ],
          ),
        );
      },
    );
  }
}
