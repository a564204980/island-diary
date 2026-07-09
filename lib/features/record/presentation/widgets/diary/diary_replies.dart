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
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: effectiveAccentColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "时光回响",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: effectiveInkColor,
                fontFamily: 'LXGWWenKai',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...replies.map(
          (reply) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              // 描图纸般的半透明背景
              color: isNight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 20,
                      color: effectiveAccentColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2), // 稍微下沉对齐首行文字
                        child: Text(
                          reply.content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: effectiveInkColor.withValues(alpha: 0.95),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "${reply.dateTime.year}/${reply.dateTime.month}/${reply.dateTime.day} ${reply.dateTime.hour.toString().padLeft(2, '0')}:${reply.dateTime.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 11,
                        color: effectiveInkColor.withValues(alpha: 0.4),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms, duration: 800.ms).moveY(begin: 10, end: 0);
  }
}
