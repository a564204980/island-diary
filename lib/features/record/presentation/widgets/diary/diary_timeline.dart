import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/models/diary_entry.dart';

class DiaryTimeline extends StatelessWidget {
  final List<DiaryReply> replies;
  final bool isNight;
  final Color? inkColor;
  final Color? accentColor;

  const DiaryTimeline({
    super.key,
    required this.replies,
    required this.isNight,
    this.inkColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    final effectiveInkColor = inkColor ?? (isNight ? Colors.white70 : const Color(0xFF5D4037));
    final effectiveAccentColor = accentColor ?? (isNight ? const Color(0xFFD4A373) : const Color(0xFF8B5E3C));

    final lineColor = effectiveInkColor.withValues(alpha: 0.1);
    final tickColor = effectiveAccentColor.withValues(alpha: 0.2);
    final timeColor = effectiveInkColor.withValues(alpha: 0.4);
    final contentColor = effectiveInkColor.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 背景长横线
              Positioned(
                left: 0,
                right: 0,
                top: 32, // 处于 tick 刻度的位置
                child: Container(height: 1, color: lineColor),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: replies.map((reply) {
                  final timeStr =
                      "${reply.dateTime.hour.toString().padLeft(2, '0')}:${reply.dateTime.minute.toString().padLeft(2, '0')}";
                  // 截取简短内容
                  String snippet = reply.content.trim();
                  if (snippet.length > 10) {
                    snippet = "${snippet.substring(0, 10)}...";
                  }

                  return Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 上部：时间
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: timeColor,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 中部：刻度线
                        Container(width: 1.5, height: 8, color: tickColor),
                        const SizedBox(height: 8),
                        // 下部：简短内容
                        Text(
                          snippet,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: contentColor,
                            fontFamily: 'LXGWWenKai',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 800.ms).moveX(begin: 20, end: 0);
  }
}
