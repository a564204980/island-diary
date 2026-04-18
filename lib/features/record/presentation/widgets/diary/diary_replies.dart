import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/models/diary_entry.dart';

class DiaryReplies extends StatelessWidget {
  final List<DiaryReply> replies;
  final bool isNight;
  final Color? accentColor;
  final Color? inkColor;

  const DiaryReplies({
    super.key,
    required this.replies,
    required this.isNight,
    this.accentColor,
    this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    final effectiveAccentColor =
        accentColor ??
        (isNight ? const Color(0xFFD4A373) : const Color(0xFF8B5E3C));

    final effectiveInkColor =
        inkColor ?? (isNight ? Colors.white70 : const Color(0xFF5D4037));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: effectiveAccentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "时光回响",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: effectiveInkColor,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...replies.map(
          (reply) => Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNight
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: effectiveInkColor.withValues(alpha: 0.9),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${reply.dateTime.year}/${reply.dateTime.month}/${reply.dateTime.day} ${reply.dateTime.hour.toString().padLeft(2, '0')}:${reply.dateTime.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 12,
                    color: (isNight ? Colors.white : Colors.black).withValues(
                      alpha: 0.3,
                    ),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms, duration: 800.ms).moveY(begin: 10, end: 0);
  }
}
