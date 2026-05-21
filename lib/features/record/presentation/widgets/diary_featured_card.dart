import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

class DiaryFeaturedCard extends StatelessWidget {
  final DiaryEntry entry;
  final bool isNight;

  const DiaryFeaturedCard({
    super.key,
    required this.entry,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    final imagePath = images.isNotEmpty ? images.first['path'] : null;
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];

    // In full-overlay mode, we generally use white text with a dark gradient overlay
    final Color textColor = Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4A373).withValues(alpha: isNight ? 0.8 : 0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isNight ? 0.4 : 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Background (Image or Mood Gradient)
            if (imagePath != null)
              Positioned.fill(
                child: DiaryUtils.buildImage(imagePath, fit: BoxFit.cover),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        mood.glowColor?.withValues(alpha: 0.8) ??
                            const Color(0xFFD4A373),
                        mood.glowColor?.withValues(alpha: 0.4) ??
                            const Color(0xFFD4A373).withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Gradient Overlay for readability (Left to Right)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 0.9],
                  ),
                ),
              ),
            ),

            // 3. Content Column (Left Side)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Body Text
                    FractionallySizedBox(
                      widthFactor: 0.55, // Keep text on the left half
                      alignment: Alignment.topLeft,
                      child: Text(
                        _getFirstSentence(
                          DiaryUtils.getFilteredContent(entry.content).trim(),
                        ),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.6,
                          fontFamily: 'ArphicKaiti',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Tags & Info Row (Parallel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tags (Left)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTag(
                            mood.label,
                            isOverlay: true,
                          ),
                          if (entry.tag != null && entry.tag!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildTag(
                              entry.tag!,
                              isOverlay: true,
                            ),
                          ],
                        ],
                      ),

                      // Time & Weather (Right)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontFamily: 'ArphicKaiti',
                            ),
                          ),
                          if (entry.weather != null &&
                              entry.weather!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.wb_sunny_rounded,
                              size: 16,
                              color: Colors.amber.withValues(alpha: 0.9),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),

            // 4. Top Right Bookmark
            Positioned(
              top: 0,
              right: 20,
              child: ClipPath(
                clipper: _BookmarkClipper(),
                child: Container(
                  width: 32,
                  height: 44,
                  color: const Color(0xFFD4A373),
                  padding: const EdgeInsets.only(top: 8),
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // 5. Bottom Right Circular Image (if multiple images)
            if (images.length > 1)
              Positioned(
                bottom: 56, // 上移，避免遮挡底部的时间
                right: 24,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: DiaryUtils.buildImage(
                      images.last['path'],
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    String text, {
    String? iconPath,
    IconData? icon,
    bool isOverlay = false,
  }) {
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final themeColor = mood.glowColor ?? const Color(0xFFD4A373);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOverlay
            ? Colors.white.withValues(alpha: 0.15)
            : themeColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4A373).withValues(alpha: isNight ? 0.6 : 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null) ...[
            Image.asset(iconPath, width: 18, height: 18),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'ArphicKaiti',
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstSentence(String text) {
    if (text.isEmpty) return "";
    // 找到第一个句末标点符号或换行符
    final RegExp re = RegExp(r'[。！？.!?\n]');
    final match = re.firstMatch(text);
    if (match != null) {
      return text.substring(0, match.end).trim();
    }
    return text.trim();
  }
}

class _BookmarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double radius = 3.0;

    path.moveTo(0, 0);
    path.lineTo(0, size.height - radius);
    path.quadraticBezierTo(0, size.height, radius, size.height - 2);
    path.lineTo(size.width / 2 - radius, size.height * 0.8 + 2);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.8,
      size.width / 2 + radius,
      size.height * 0.8 + 2,
    );
    path.lineTo(size.width - radius, size.height - 2);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - radius,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
