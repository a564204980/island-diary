import 'dart:io';
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../pages/diary_detail_page.dart';
import 'diary_masonry_card.dart';


class DiaryFeaturedCard extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNight;

  const DiaryFeaturedCard({
    super.key,
    required this.entry,
    this.isNight = false,
  });

  @override
  State<DiaryFeaturedCard> createState() => _DiaryFeaturedCardState();
}

class _DiaryFeaturedCardState extends State<DiaryFeaturedCard> {
  int _currentImageIndex = 0;

  void _cycleImage(int totalImages) {
    if (totalImages <= 1) return;
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % totalImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isNight = widget.isNight;
    
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    // 确保索引不越界
    if (images.isNotEmpty && _currentImageIndex >= images.length) {
      _currentImageIndex = 0;
    }
    final imagePath = images.isNotEmpty ? images[_currentImageIndex]['path'] : null;
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];

    // In full-overlay mode, we generally use white text with a dark gradient overlay
    final Color textColor = Colors.white;

    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailPage(
              entry: entry,
              isNight: isNight,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isNight && isCottonCandy)
                ? const Color(0xFF9AE0CD).withValues(alpha: 0.5)
                : const Color(0xFFD4A373).withValues(alpha: isNight ? 0.8 : 0.6),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNight ? 0.30 : 0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: SizedBox(
                      key: ValueKey<String>(imagePath),
                      width: double.infinity,
                      height: double.infinity,
                      child: DiaryUtils.buildImage(imagePath, fit: BoxFit.cover),
                    ),
                  ),
                )
              else if (isCottonCandy)
                Positioned.fill(
                  child: Container(
                    color: isNight ? const Color(0xFF282240) : const Color(0xFFFFF9F0),
                    child: Opacity(
                      opacity: isNight ? 0.35 : 0.75,
                      child: Image.asset(
                        'assets/images/background/page_banner_bg.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
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
                      // Top-Left: Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                      
                      const Spacer(),

                      // Body Text (First Sentence)
                      Builder(
                        builder: (context) {
                          final firstSentence = _getFirstSentence(
                            DiaryUtils.getFilteredContent(entry.content).trim(),
                          );
                          if (firstSentence.isEmpty) return const SizedBox.shrink();
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, right: 140.0),
                            child: Text(
                              firstSentence,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ArphicKaiti',
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
  
                    // Tags Row (Left aligned)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Builder(
                          builder: (context) {
                            final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
                            final String moodLabel = parsed.customMood ?? mood.label;
                            final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;
                            final String iconPath = (entry.moodIndex >= 0 && entry.moodIndex <= 23)
                                ? 'assets/icons/custom${entry.moodIndex + 1}.png'
                                : (mood.iconPath ?? 'assets/icons/happy.png');

                            return _buildTag(
                              moodLabel,
                              iconPath: iconPath,
                              isCustomFile: hasCustomIcon,
                              customFilePath: parsed.customMoodIconPath,
                              isOverlay: true,
                            );
                          }
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
  
              // 5. Bottom Right Overlapping Circular Images (if multiple images)
              if (images.length > 1)
                Positioned(
                  bottom: 16, // 下移，由于时间已移走，直接贴近底部对齐标签
                  right: 24,
                  child: Builder(
                    builder: (context) {
                      final remainingImages = [];
                      for (int i = 0; i < images.length; i++) {
                        if (i != _currentImageIndex) remainingImages.add(images[i]);
                      }

                      final int maxImages = 4;
                      final int count = remainingImages.length.clamp(0, maxImages);
                      final double size = 38.0; // 进一步缩小，更像精致的小头像
                      final double overlapFactor = 0.7; // 重叠比例
                      
                      return GestureDetector(
                        onTap: () => _cycleImage(images.length),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: size + (count - 1) * (size * overlapFactor),
                          height: size,
                          child: Stack(
                            children: List.generate(count, (index) {
                              // 为了让左边的图片压在右边的图片上面
                              // 我们需要让右边（索引大）的图片先绘制（即在 Stack 的底层）
                              final reversedIndex = count - 1 - index;
                              final image = remainingImages[reversedIndex];
                              return Positioned(
                                left: reversedIndex * (size * overlapFactor),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: Container(
                                    key: ValueKey<String>(image['path']),
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: DiaryUtils.buildImage(
                                        image['path'],
                                        width: size,
                                        height: size,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(
    String text, {
    String? iconPath,
    bool isCustomFile = false,
    String? customFilePath,
    IconData? icon,
    bool isOverlay = false,
  }) {
    final entry = widget.entry;
    final isNight = widget.isNight;
    
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final themeColor = mood.glowColor ?? const Color(0xFFD4A373);
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final themeColorConfig = getMoodThemeColor(moodIdx, mood.label, isNight: isNight, isCottonCandy: isCottonCandy);

    final Color bgColor = isOverlay
        ? Colors.black.withValues(alpha: 0.5)
        : ((isNight && isCottonCandy)
            ? Colors.black.withValues(alpha: 0.45)
            : themeColor.withValues(alpha: 0.3));

    final Color textColor = isOverlay
        ? Colors.white
        : ((isNight && isCottonCandy)
            ? (themeColorConfig.borderColor ?? Colors.white)
            : Colors.white);

    final Color borderColor = isOverlay
        ? Colors.white.withValues(alpha: 0.75)
        : ((isNight && isCottonCandy)
            ? (themeColorConfig.borderColor?.withValues(alpha: 0.5) ?? Colors.white.withValues(alpha: 0.15))
            : const Color(0xFFD4A373).withValues(alpha: isNight ? 0.6 : 0.4));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCustomFile && customFilePath != null) ...[
            Image.file(File(customFilePath), width: 14, height: 14),
            const SizedBox(width: 4),
          ] else if (iconPath != null) ...[
            Image.asset(iconPath, width: 14, height: 14),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
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
