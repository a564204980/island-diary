import 'dart:io';
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import '../pages/diary_detail_page.dart';

enum MasonryCardStyle {
  fullImage,   // 大图全覆盖 (文字在底部渐变蒙层上)
  imageTop,    // 图文上下结构
  textOnly,    // 纯文本
}

class MoodThemeColor {
  final Color bgColor;
  final Color tagColor;
  final Color? borderColor;
  const MoodThemeColor({required this.bgColor, required this.tagColor, this.borderColor});
}

MoodThemeColor getMoodThemeColor(int moodIndex, String label, {bool isNight = false, bool isCottonCandy = false}) {
  if (isNight && isCottonCandy) {
    switch (label) {
      case '开心':
        return const MoodThemeColor(bgColor: Color(0x66746B4A), tagColor: Color(0xFF746B4A), borderColor: Color(0xFFD8C27A));
      case '平静':
        return const MoodThemeColor(bgColor: Color(0x665B6C66), tagColor: Color(0xFF5B6C66), borderColor: Color(0xFF8FC9C0));
      case '低落':
        return const MoodThemeColor(bgColor: Color(0x6655657A), tagColor: Color(0xFF55657A), borderColor: Color(0xFF89A6D6));
      case '烦躁':
        return const MoodThemeColor(bgColor: Color(0x667B5C60), tagColor: Color(0xFF7B5C60), borderColor: Color(0xFFD18C94));
      case '焦虑':
        return const MoodThemeColor(bgColor: Color(0x665E6678), tagColor: Color(0xFF5E6678), borderColor: Color(0xFF9EACC0));
      case '疲惫':
        return const MoodThemeColor(bgColor: Color(0x66655D7C), tagColor: Color(0xFF655D7C), borderColor: Color(0xFFB9A0E6));
      case '惊喜':
        return const MoodThemeColor(bgColor: Color(0x668C6F4E), tagColor: Color(0xFF8C6F4E), borderColor: Color(0xFFE0B072));
      case '害羞':
        return const MoodThemeColor(bgColor: Color(0x668B5D78), tagColor: Color(0xFF8B5D78), borderColor: Color(0xFFE39AB6));
      case '放松':
        return const MoodThemeColor(bgColor: Color(0x6674628A), tagColor: Color(0xFF74628A), borderColor: Color(0xFFB19AE5));
      case '怀旧':
        return const MoodThemeColor(bgColor: Color(0x6663616E), tagColor: Color(0xFF63616E), borderColor: Color(0xFFA79DA8));
      case '沉思':
        return const MoodThemeColor(bgColor: Color(0x668E7A52), tagColor: Color(0xFF8E7A52), borderColor: Color(0xFFE3C27A));
    }

    switch (moodIndex) {
      case 0:
        return const MoodThemeColor(bgColor: Color(0x66746B4A), tagColor: Color(0xFF746B4A), borderColor: Color(0xFFD8C27A));
      case 1:
        return const MoodThemeColor(bgColor: Color(0x665B6C66), tagColor: Color(0xFF5B6C66), borderColor: Color(0xFF8FC9C0));
      case 2:
        return const MoodThemeColor(bgColor: Color(0x6655657A), tagColor: Color(0xFF55657A), borderColor: Color(0xFF89A6D6));
      case 3:
        return const MoodThemeColor(bgColor: Color(0x667B5C60), tagColor: Color(0xFF7B5C60), borderColor: Color(0xFFD18C94));
      case 4:
        return const MoodThemeColor(bgColor: Color(0x66655D7C), tagColor: Color(0xFF655D7C), borderColor: Color(0xFFB9A0E6));
      case 5:
        return const MoodThemeColor(bgColor: Color(0x668C6F4E), tagColor: Color(0xFF8C6F4E), borderColor: Color(0xFFE0B072));
      case 6:
        return const MoodThemeColor(bgColor: Color(0x668B5D78), tagColor: Color(0xFF8B5D78), borderColor: Color(0xFFE39AB6));
      case 7:
        return const MoodThemeColor(bgColor: Color(0x665E6678), tagColor: Color(0xFF5E6678), borderColor: Color(0xFF9EACC0));
      case 8:
        return const MoodThemeColor(bgColor: Color(0x6674628A), tagColor: Color(0xFF74628A), borderColor: Color(0xFFB19AE5));
      case 9:
        return const MoodThemeColor(bgColor: Color(0x6663616E), tagColor: Color(0xFF63616E), borderColor: Color(0xFFA79DA8));
      case 10:
        return const MoodThemeColor(bgColor: Color(0x668E7A52), tagColor: Color(0xFF8E7A52), borderColor: Color(0xFFE3C27A));
      default:
        return const MoodThemeColor(bgColor: Color(0x665E6678), tagColor: Color(0xFF5E6678), borderColor: Color(0xFF9EACC0));
    }
  }

  switch (label) {
    case '开心':
      return const MoodThemeColor(bgColor: Color(0xFFFFF7D8), tagColor: Color(0xFFF5C95A));
    case '平静':
      return const MoodThemeColor(bgColor: Color(0xFFEAF8F3), tagColor: Color(0xFF8BCDBA));
    case '低落':
      return const MoodThemeColor(bgColor: Color(0xFFEEF3FF), tagColor: Color(0xFF9FB4DD));
    case '烦躁':
      return const MoodThemeColor(bgColor: Color(0xFFFFECEF), tagColor: Color(0xFFE99AAA));
    case '焦虑':
      return const MoodThemeColor(bgColor: Color(0xFFF0F1F2), tagColor: Color(0xFFA9ADB3));
    case '疲惫':
      return const MoodThemeColor(bgColor: Color(0xFFF4EEFA), tagColor: Color(0xFFB9A3D4));
    case '惊喜':
      return const MoodThemeColor(bgColor: Color(0xFFFFF1D9), tagColor: Color(0xFFF2B56B));
    case '害羞':
      return const MoodThemeColor(bgColor: Color(0xFFFFEFF4), tagColor: Color(0xFFE9A6BB));
    case '放松':
      return const MoodThemeColor(bgColor: Color(0xFFEAF7FF), tagColor: Color(0xFF93C8EA));
    case '怀旧':
      return const MoodThemeColor(bgColor: Color(0xFFF7EFE3), tagColor: Color(0xFFC9A982));
    case '沉思':
      return const MoodThemeColor(bgColor: Color(0xFFF0ECF8), tagColor: Color(0xFFA99BCB));
  }

  switch (moodIndex) {
    case 0:
      return const MoodThemeColor(bgColor: Color(0xFFFFF7D8), tagColor: Color(0xFFF5C95A));
    case 1:
      return const MoodThemeColor(bgColor: Color(0xFFEAF8F3), tagColor: Color(0xFF8BCDBA));
    case 2:
      return const MoodThemeColor(bgColor: Color(0xFFEEF3FF), tagColor: Color(0xFF9FB4DD));
    case 3:
      return const MoodThemeColor(bgColor: Color(0xFFFFECEF), tagColor: Color(0xFFE99AAA));
    case 4:
      return const MoodThemeColor(bgColor: Color(0xFFF4EEFA), tagColor: Color(0xFFB9A3D4));
    case 5:
      return const MoodThemeColor(bgColor: Color(0xFFFFF1D9), tagColor: Color(0xFFF2B56B));
    case 6:
      return const MoodThemeColor(bgColor: Color(0xFFFFEFF4), tagColor: Color(0xFFE9A6BB));
    case 7:
      return const MoodThemeColor(bgColor: Color(0xFFF0F1F2), tagColor: Color(0xFFA9ADB3));
    case 8:
      return const MoodThemeColor(bgColor: Color(0xFFEAF7FF), tagColor: Color(0xFF93C8EA));
    case 9:
      return const MoodThemeColor(bgColor: Color(0xFFF7EFE3), tagColor: Color(0xFFC9A982));
    case 10:
      return const MoodThemeColor(bgColor: Color(0xFFF0ECF8), tagColor: Color(0xFFA99BCB));
    default:
      return const MoodThemeColor(bgColor: Color(0xFFF4EFE6), tagColor: Color(0xFFD4A373));
  }
}


class DiaryMasonryCard extends StatelessWidget {
  final DiaryEntry entry;
  final bool isNight;
  final int index;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;

  const DiaryMasonryCard({
    super.key,
    required this.entry,
    this.isNight = false,
    required this.index,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    
    MasonryCardStyle style = MasonryCardStyle.textOnly;
    if (images.isNotEmpty) {
      // 只有单图且 index 符合条件时才使用 fullImage，多图一律使用 imageTop 保证文字清晰
      style = (images.length == 1 && index % 3 == 0) ? MasonryCardStyle.fullImage : MasonryCardStyle.imageTop;
    }

    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final themeColorConfig = getMoodThemeColor(moodIdx, mood.label, isNight: isNight, isCottonCandy: isCottonCandy);
    final Color cardBgColor = (isNight && isCottonCandy)
        ? themeColorConfig.bgColor
        : (isNight ? const Color(0xFF212831) : themeColorConfig.bgColor.withValues(alpha: 0.60));

    // 获取信纸背景
    String bgAsset = DiaryUtils.getPaperBackgroundPath(entry.paperStyle, isNight);
    if (bgAsset.isEmpty) {
      bgAsset = isNight
          ? 'assets/images/note/note_night_bg1.png'
          : 'assets/images/note/note_bg1.png';
    }

    return GestureDetector(
      onTap: isSelectMode
          ? onTap
          : () {
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
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isNight 
              ? (isCottonCandy 
                  ? (themeColorConfig.borderColor?.withValues(alpha: 0.85) ?? themeColorConfig.tagColor.withValues(alpha: 0.25))
                  : Colors.white.withValues(alpha: 0.1)) 
              : Colors.black.withValues(alpha: 0.05),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isNight 
                ? (isCottonCandy 
                    ? themeColorConfig.bgColor.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.35)) 
                : Colors.black.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(bgAsset),
            fit: BoxFit.cover,
            opacity: 0.82, // 降低透明度，让底色心情色微透出来
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildCardContent(context, style, images),
            ),
            if (isSelectMode)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD4A373)
                        : Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, MasonryCardStyle style, List<Map<String, dynamic>> images) {
    if (style == MasonryCardStyle.fullImage && images.isNotEmpty) {
      return _buildFullImageCard(images);
    } else if (style == MasonryCardStyle.imageTop && images.isNotEmpty) {
      return _buildImageTopCard(images);
    } else {
      return _buildTextOnlyCard();
    }
  }

  Widget _buildFullImageCard(List<Map<String, dynamic>> images) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.0, // 全图模式采用正方形
          child: _buildImageCarousel(images),
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
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExcerpt(isWhiteText: true),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildTagsRow(isWhiteText: true),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTime(isWhiteText: true),
                        _buildLocation(isWhiteText: true),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTopCard(List<Map<String, dynamic>> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          // 动态比例：根据 index 切换长图/宽图比例
          aspectRatio: (index % 5 == 0) ? 0.8 : 1.5, 
          child: _buildImageCarousel(images),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExcerpt(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildTagsRow(),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTime(),
                        _buildLocation(),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(List<Map<String, dynamic>> images) {
    if (images.length <= 1) {
      return DiaryUtils.buildImage(
        images.first['path'],
        fit: BoxFit.cover,
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, i) {
            return DiaryUtils.buildImage(
              images[i]['path'],
              fit: BoxFit.cover,
            );
          },
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                images.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextOnlyCard() {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExcerpt(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTagsRow(),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTime(),
                      _buildLocation(),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExcerpt({bool isWhiteText = false}) {
    final bool forceWhite = isWhiteText || isNight;
    final bool hasImages = entry.blocks.any((b) => b['type'] == 'image');
    final Color textColor = forceWhite ? Colors.white70 : const Color(0xFF5F5563);
    String plainText = DiaryUtils.getFilteredContent(entry.content).trim();
    if (plainText.isEmpty) return const SizedBox.shrink();

    int maxLines = 3;
    if (index % 4 == 0) maxLines = 1;
    if (index % 4 == 3) {
      maxLines = hasImages ? 6 : 3;
    }

    final baseStyle = TextStyle(
      fontSize: 13,
      height: 1.5,
      color: textColor,
      fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
    );

    final List<InlineSpan> spans = EmojiMapping.parseText(plainText).map((chunk) {
      if (chunk.isEmoji) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Image.asset(
              chunk.emojiPath!,
              width: baseStyle.fontSize! * 1.2,
              height: baseStyle.fontSize! * 1.2,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
      return TextSpan(text: chunk.text, style: baseStyle);
    }).toList();

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildTime({bool isWhiteText = false}) {
    final bool forceWhite = isWhiteText || isNight;
    final Color textColor = forceWhite ? Colors.white54 : const Color(0xFFA798A5);
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
            fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'ArphicKaiti',
          ),
        ),
      ],
    );
  }

  Widget _buildLocation({bool isWhiteText = false}) {
    return const SizedBox.shrink();
  }

  Widget _buildTagsRow({bool isWhiteText = false}) {
    List<Widget> tagWidgets = [];
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];

    final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
    final String moodLabel = parsed.customMood ?? mood.label;
    final String iconPath = parsed.customMood != null
        ? (entry.moodIndex >= 0 && entry.moodIndex <= 23
            ? 'assets/icons/custom${entry.moodIndex + 1}.png'
            : 'assets/images/icons/custom.png')
        : (mood.iconPath ?? 'assets/icons/happy.png');

    tagWidgets.add(_buildTagPill(
      moodLabel,
      isWhiteText: isWhiteText,
      iconPath: iconPath,
      customMoodIconPath: parsed.customMoodIconPath,
    ));

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: tagWidgets,
    );
  }

  Widget _buildTagPill(String text, {required bool isWhiteText, IconData? icon, String? iconPath, String? customMoodIconPath}) {
    final bool forceWhite = isWhiteText || isNight;

    final Color bgColor = forceWhite 
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF2F2F2).withValues(alpha: 0.2);

    final Color borderColor = forceWhite
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFD8D8D8).withValues(alpha: 0.8);

    final Color textColor = forceWhite
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF5C5C5C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customMoodIconPath != null && customMoodIconPath.isNotEmpty) ...[
            Image.file(
              File(customMoodIconPath),
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 5),
          ] else if (iconPath != null) ...[
            Image.asset(
              iconPath,
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
              fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }
}
