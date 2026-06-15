import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/barrage/mood_barrage_wall.dart';

class MoodBarrageLayer extends StatefulWidget {
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;

  const MoodBarrageLayer({
    super.key,
    required this.groupedEntries,
  });

  @override
  State<MoodBarrageLayer> createState() => _MoodBarrageLayerState();
}

class _MoodBarrageLayerState extends State<MoodBarrageLayer> {
  late PageController _barragePageController;
  int _barrageCurrentIndex = 0;

  @override
  void initState() {
    super.initState();
    _barragePageController = PageController();
  }

  @override
  void dispose() {
    _barragePageController.dispose();
    super.dispose();
  }

  void _autoNextDay() {
    if (_barrageCurrentIndex < widget.groupedEntries.length - 1) {
      _barragePageController.nextPage(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _formatBarrageDate(DateTime dt) {
    return "${dt.year}年${dt.month}月${dt.day}日";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _barragePageController,
          itemCount: widget.groupedEntries.length,
          onPageChanged: (index) {
            setState(() {
              _barrageCurrentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final dateGroup = widget.groupedEntries[index];
            final dayEntries = dateGroup.values.first;

            return BarrageDayScene(
              entries: dayEntries,
              date: dateGroup.keys.first,
              onFinished: () {
                if (index == _barrageCurrentIndex) {
                  _autoNextDay();
                }
              },
            );
          },
        ),

        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatBarrageDate(
                  widget.groupedEntries[_barrageCurrentIndex].keys.first,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'LXGWWenKai',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }
}
