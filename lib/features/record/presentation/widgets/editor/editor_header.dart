import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/hand_drawn_divider.dart';

class EditorHeader extends StatelessWidget {
  final String paperStyle;
  final bool isNight;
  final String quote;

  const EditorHeader({
    super.key,
    required this.paperStyle,
    required this.isNight,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                DiaryUtils.getFormattedTime(),
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: inkColor,
                  fontFamily: 'LXGWWenKai',
                  letterSpacing: -1,
                ),
              ),
              Text(
                DiaryUtils.getFormattedDate(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: inkColor.withValues(alpha: 0.7),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: inkColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          CustomPaint(
            size: const Size(double.infinity, 2),
            painter: HandDrawnLinePainter(
              color: isNight
                  ? inkColor.withValues(alpha: 0.1)
                  : inkColor.withValues(alpha: 0.3),
              strokeWidth: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
