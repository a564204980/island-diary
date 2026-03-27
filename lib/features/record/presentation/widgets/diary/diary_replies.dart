import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/models/diary_entry.dart';

class DiaryReplies extends StatelessWidget {
  final List<DiaryReply> replies;
  final bool isNight;

  const DiaryReplies({
    super.key,
    required this.replies,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    final accentColor = isNight
        ? const Color(0xFFD4A373)
        : const Color(0xFF8B5E3C);

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
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "时光回响",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white70 : const Color(0xFF5D4037),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...replies.map(
          (reply) => Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNight
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05),
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
                    color: isNight
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF4A342E),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${reply.dateTime.year}/${reply.dateTime.month}/${reply.dateTime.day} ${reply.dateTime.hour.toString().padLeft(2, '0')}:${reply.dateTime.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isNight ? Colors.white24 : Colors.black26,
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
