import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

/// 音符粒子数据模型
class NoteParticleData {
  final String id;
  final int keyIndex;
  final String noteText;

  NoteParticleData({
    required this.id,
    required this.keyIndex,
    required this.noteText,
  });
}

/// 近七日心情 - 琴键与音符联动组件
class PianoMoodSection extends StatefulWidget {
  final List<DateTime> last7Days;
  final DiaryEntry? Function(DateTime date) getEntryForDate;
  final Function(DateTime date, DiaryEntry? entry) openEditorWithDate;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;

  const PianoMoodSection({
    super.key,
    required this.last7Days,
    required this.getEntryForDate,
    required this.openEditorWithDate,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
  });

  @override
  State<PianoMoodSection> createState() => _PianoMoodSectionState();
}

class _PianoMoodSectionState extends State<PianoMoodSection> {
  // 7 个经典的音符名称符
  static const List<String> _notes = ['♪ Do', '♫ Re', '♬ Mi', '♩ Fa', '♭ Sol', '♮ La', '♯ Ti'];
  final List<NoteParticleData> _activeParticles = [];

  void _triggerNoteParticle(int index) {
    final noteText = _notes[index % _notes.length];
    final particle = NoteParticleData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      keyIndex: index,
      noteText: noteText,
    );

    setState(() {
      _activeParticles.add(particle);
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() {
          _activeParticles.removeWhere((p) => p.id == particle.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: widget.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                "近七日心情",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: widget.fontFamily,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final double keyWidth = constraints.maxWidth / 7.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. 7 个天数胶囊 (外观与形状 100% 保持完全不变)
                Row(
                  children: List.generate(7, (index) {
                    final date = widget.last7Days[index];
                    final entry = widget.getEntryForDate(date);
                    final moodIndex = entry?.moodIndex;
                    final mood = (moodIndex != null && moodIndex >= 0 && moodIndex < kMoods.length)
                        ? kMoods[moodIndex]
                        : null;

                    double gradientStart = 0.7;
                    if (entry != null && entry.content.isNotEmpty) {
                      final length = entry.content.length;
                      gradientStart = 0.7 - (length / 300) * 0.7;
                      if (gradientStart < 0.0) gradientStart = 0.0;
                    }

                    return Expanded(
                      child: BouncingButton(
                        onTap: () async {
                          // 按压琴键触发对应的蹦出音符离场动效
                          _triggerNoteParticle(index);

                          await Future.delayed(const Duration(milliseconds: 150));
                          if (context.mounted) {
                            widget.openEditorWithDate(date, entry);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: mood != null
                                ? null
                                : (widget.isNight
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.2)),
                            gradient: mood != null
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [gradientStart, 1.0],
                                    colors: [
                                      widget.isNight
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.65),
                                      (mood.glowColor ?? Colors.grey)
                                          .withValues(alpha: widget.isNight ? 0.25 : 0.15),
                                    ],
                                  )
                                : null,
                            border: Border.all(
                              color: mood != null
                                  ? (mood.glowColor ?? Colors.grey)
                                      .withValues(alpha: widget.isNight ? 0.3 : 0.2)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${date.day}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: widget.fontFamily,
                                  color: widget.textColor.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              mood != null && mood.iconPath != null
                                  ? Image.asset(mood.iconPath!, width: 28, height: 28)
                                  : Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: widget.subtitleColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                mood != null ? mood.label : " ",
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontFamily: widget.fontFamily,
                                  color: widget.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // 2. 按压琴键从顶端欢快蹦出的音符粒子层 (Do, Re, Mi, Fa, Sol, La, Ti)
                ..._activeParticles.map((particle) {
                  final double noteLeft = particle.keyIndex * keyWidth + (keyWidth / 2.0) - 20;

                  return Positioned(
                    key: ValueKey(particle.id),
                    left: noteLeft,
                    top: -6,
                    child: IgnorePointer(
                      child: Text(
                        particle.noteText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.isNight
                              ? const Color(0xFFE29578)
                              : widget.accentColor,
                          shadows: [
                            Shadow(
                              color: widget.isNight
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.8),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .moveY(begin: 0, end: -36, duration: 750.ms, curve: Curves.easeOutBack)
                    .scale(begin: const Offset(0.4, 0.4), end: const Offset(1.15, 1.15), duration: 750.ms, curve: Curves.easeOutBack)
                    .fadeOut(delay: 400.ms, duration: 350.ms),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}
