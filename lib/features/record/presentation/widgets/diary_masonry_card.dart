import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import '../pages/diary_detail_page.dart';

enum MasonryCardStyle {
  fullImage,   // 大图全覆盖 (文字在底部渐变蒙层上)
  imageTop,    // 图文上下结构
  textOnly,    // 纯文本
}

class DiaryMasonryCard extends StatelessWidget {
  final DiaryEntry entry;
  final bool isNight;
  final int index;

  const DiaryMasonryCard({
    super.key,
    required this.entry,
    this.isNight = false,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    
    MasonryCardStyle style = MasonryCardStyle.textOnly;
    if (images.isNotEmpty) {
      style = index % 3 == 0 ? MasonryCardStyle.fullImage : MasonryCardStyle.imageTop;
    }

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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF212831) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNight ? 0.3 : 0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _buildCardContent(context, style, images),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, MasonryCardStyle style, List<Map<String, dynamic>> images) {
    if (style == MasonryCardStyle.fullImage && images.isNotEmpty) {
      return _buildFullImageCard(images.first['path']);
    } else if (style == MasonryCardStyle.imageTop && images.isNotEmpty) {
      return _buildImageTopCard(images.first['path']);
    } else {
      return _buildTextOnlyCard();
    }
  }

  Widget _buildFullImageCard(String imagePath) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 240,
          child: DiaryUtils.buildImage(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Icon(Icons.bookmark_rounded, color: const Color(0xFFD4A373).withValues(alpha: 0.9), size: 28),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(isWhiteText: true),
              const SizedBox(height: 8),
              _buildExcerpt(isWhiteText: true),
              const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTagsRow(isWhiteText: true),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTime(isWhiteText: true),
                          _buildLocation(isWhiteText: true),
                        ],
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTopCard(String imagePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 160,
          child: DiaryUtils.buildImage(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 8),
              _buildExcerpt(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTagsRow(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTime(),
                      _buildLocation(),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextOnlyCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNight
            ? [const Color(0xFF2C2E35), const Color(0xFF212329)]
            : [const Color(0xFFF9F7F3), const Color(0xFFF4EFE6)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 8),
          _buildExcerpt(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTagsRow(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTime(),
                  _buildLocation(),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTitle({bool isWhiteText = false}) {
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final Color textColor = isWhiteText ? Colors.white : (isNight ? Colors.white : const Color(0xFF060606));

    String plainText = DiaryUtils.getFilteredContent(entry.content).replaceAll('\n', ' ').trim();
    String displayTitle = plainText.length > 10 ? plainText.substring(0, 10) : plainText;
    if (displayTitle.isEmpty) displayTitle = mood.label;

    return Row(
      children: [
        Image.asset(
          mood.iconPath ?? 'assets/images/icons/sun.png',
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildExcerpt({bool isWhiteText = false}) {
    final Color textColor = isWhiteText ? Colors.white : (isNight ? Colors.white70 : const Color(0xFF8B7763));
    String plainText = DiaryUtils.getFilteredContent(entry.content).trim();
    if (plainText.isEmpty) return const SizedBox.shrink();

    return Text(
      plainText,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.5,
        color: textColor,
              ),
    );
  }

  Widget _buildTime({bool isWhiteText = false}) {
    final Color textColor = isWhiteText ? Colors.white : (isNight ? Colors.white54 : const Color(0xFFB5A89A));
    final timeStr = "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}";
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'ArphicKaiti',
          ),
        ),
        if (entry.weather != null && entry.weather!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Icon(Icons.wb_sunny_rounded, size: 12, color: isWhiteText ? Colors.amber.withValues(alpha: 0.8) : const Color(0xFFD4A373)),
        ],
      ],
    );
  }

  Widget _buildLocation({bool isWhiteText = false}) {
    if (entry.location == null || entry.location!.isEmpty) return const SizedBox.shrink();
    
    final Color textColor = isWhiteText ? Colors.white : (isNight ? Colors.white54 : const Color(0xFFB5A89A));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        Icon(Icons.location_on_rounded, size: 10, color: textColor),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            entry.location!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontFamily: 'ArphicKaiti',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow({bool isWhiteText = false}) {
    List<Widget> tagWidgets = [];
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    tagWidgets.add(_buildTagPill(mood.label, isWhiteText: isWhiteText, iconPath: mood.iconPath));

    if (entry.tag != null && entry.tag!.isNotEmpty) {
      tagWidgets.add(const SizedBox(width: 6));
      tagWidgets.add(_buildTagPill(entry.tag!, isWhiteText: isWhiteText, icon: Icons.local_florist_rounded));
    }

    return Wrap(
      spacing: 0,
      children: tagWidgets,
    );
  }

  Widget _buildTagPill(String text, {required bool isWhiteText, IconData? icon, String? iconPath}) {
    final bgColor = isWhiteText 
        ? Colors.white.withValues(alpha: 0.2) 
        : (isNight ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1EDE6));
    final textColor = isWhiteText ? Colors.white : (isNight ? Colors.white70 : const Color(0xFF8B7763));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            Image.asset(
              iconPath,
              width: 16,
              height: 16,
            )
          else if (icon != null)
            Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
