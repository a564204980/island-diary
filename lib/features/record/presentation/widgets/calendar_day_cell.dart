import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'lego_calendar_components.dart';

class _LunarCacheData {
  final String lunarStr;
  final bool isImportantFest;
  _LunarCacheData(this.lunarStr, this.isImportantFest);
}

class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<DiaryEntry>? entries;
  final bool isToday;
  final bool isSelected;
  final bool isNight;
  final VoidCallback onTap;

  static final Map<String, _LunarCacheData> _lunarCache = {};

  const CalendarDayCell({
    super.key,
    required this.date,
    this.entries,
    required this.isToday,
    required this.isSelected,
    required this.isNight,
    required this.onTap,
  });

  static const Set<String> _importantFests = {
    '元旦', '除夕', '春节', '元宵节', '清明', '劳动节', '端午节', '中秋节', '国庆节',
    '情人节', '妇女节', '儿童节', '教师节', '圣诞节', '冬至', '七夕', '重阳', '腊八',
  };

  _LunarCacheData _getLunarData(DateTime date) {
    final key = "${date.year}-${date.month}-${date.day}";
    if (_lunarCache.containsKey(key)) {
      return _lunarCache[key]!;
    }

    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    final solarFests = solar.getFestivals();
    final lunarFests = lunar.getFestivals();
    final jieQi = lunar.getJieQi();

    String? importantFest;
    for (final f in [
      ...solarFests,
      ...lunarFests,
      if (jieQi.isNotEmpty) jieQi,
    ]) {
      if (_importantFests.any((important) => f.contains(important))) {
        importantFest = _importantFests.firstWhere((important) => f.contains(important));
        break;
      }
    }

    String lunarStr;
    if (importantFest != null) {
      lunarStr = importantFest;
    } else {
      if (lunar.getDay() == 1) {
        lunarStr = '${lunar.getMonthInChinese()}月';
      } else {
        lunarStr = lunar.getDayInChinese();
      }
    }

    final data = _LunarCacheData(lunarStr, importantFest != null);
    _lunarCache[key] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEntry = entries?.isNotEmpty ?? false;
    
    // 收集当天所有日记里的所有图片
    final List<String> allImages = [];
    int? moodIdx;
    String? customMoodIconPath;
    String? customMoodIconAsset;
    
    if (hasEntry) {
      final lastEntry = entries!.last;
      moodIdx = lastEntry.moodIndex;
      final parsed = ParsedTags.parse(lastEntry.tag, lastEntry.moodIndex);
      if (parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty) {
        customMoodIconPath = parsed.customMoodIconPath;
      }
      if (lastEntry.moodIndex >= 0 && lastEntry.moodIndex <= 23) {
        customMoodIconAsset = 'assets/icons/custom${lastEntry.moodIndex + 1}.png';
      }
      for (var entry in entries!) {
        for (var block in entry.blocks) {
          if (block['type'] == 'image' && block['path'] != null) {
            allImages.add(block['path'] as String);
          }
        }
      }
    }

    final lunarData = _getLunarData(date);
    final lunarStr = lunarData.lunarStr;
    final bool isImportantFest = lunarData.isImportantFest;

    final bool hasPhotos = allImages.isNotEmpty;

    final TextStyle dayStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: 'LXGWWenKai',
      color: hasPhotos
          ? Colors.white
          : (isNight
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF3B2E25)),
      shadows: hasPhotos
          ? [
              const Shadow(
                blurRadius: 4,
                color: Colors.black87,
                offset: Offset(0, 1.5),
              ),
            ]
          : null,
    );

    final Color lunarColor = isImportantFest
        ? (hasPhotos ? Colors.white : const Color(0xFFE1AF78))
        : (isNight ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.55));

    final TextStyle lunarStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      fontFamily: 'LXGWWenKai',
      color: hasPhotos
          ? Colors.white70
          : (isNight
                ? Colors.white70
                : (hasEntry
                      ? const Color(0xFF7E7570)
                      : lunarColor)),
      shadows: hasPhotos
          ? [
              const Shadow(
                blurRadius: 3,
                color: Colors.black54,
                offset: Offset(0, 1),
              ),
            ]
          : null,
      height: 1.1,
    );

    final BorderSide borderSide = isSelected
        ? const BorderSide(color: Color(0xFFE1AF78), width: 2.2)
        : (isToday
            ? BorderSide(color: const Color(0xFFE1AF78).withValues(alpha: 0.6), width: 1.5)
            : (hasEntry
                ? BorderSide(color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.12), width: 1.0)
                : BorderSide(color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06), width: 0.8)));

    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    final Widget cellContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.35 : 0.2)
            : (isToday
                  ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.2 : 0.1)
                  : (hasEntry
                        ? _getMoodMacaronColor(moodIdx, isNight)
                        : (isNight
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white.withValues(alpha: 0.5)))),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: hasPhotos ? Clip.antiAlias : Clip.none,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 图片背景或拼图组件
          if (allImages.isNotEmpty)
            Positioned.fill(
              child: _buildGridImages(allImages),
            ),

          // 日期数字 + 心情图标（整合为同一列，避免图标被文字遮挡）
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${date.day}", style: dayStyle),
                  if (!hasEntry) ...[
                    const SizedBox(height: 1),
                    Text(lunarStr, style: lunarStyle),
                  ] else if (allImages.isEmpty && (moodIdx != null || customMoodIconPath != null)) ...[
                    const SizedBox(height: 1),
                    _buildMoodIcon(
                      moodIdx: moodIdx,
                      customMoodIconPath: customMoodIconPath,
                      customMoodIconAsset: customMoodIconAsset,
                      isNight: isNight,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 顶层覆盖的完美圆角/乐高凹陷边框，确保图片和凹陷边缘完全贴合
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: LegoBorderPainter(
                  hasSockets: false,
                  progress: 0.0,
                  borderColor: borderSide.color,
                  borderWidth: borderSide.width,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isLego) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
        builder: (context, progress, child) {
          final bool active = progress > 0.0;
          return GestureDetector(
            onTap: onTap,
            child: Transform.translate(
              offset: Offset(0, 1.5 * progress),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: LegoCellClipper(
                      hasSockets: active,
                      progress: progress,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.35 : 0.2)
                            : (isToday
                                  ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.2 : 0.1)
                                  : (hasEntry
                                        ? _getMoodMacaronColor(moodIdx, isNight)
                                        : (isNight
                                              ? Colors.white.withValues(alpha: 0.06)
                                              : Colors.white.withValues(alpha: 0.5)))),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: hasPhotos ? Clip.antiAlias : Clip.none,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (allImages.isNotEmpty)
                            Positioned.fill(
                              child: _buildGridImages(allImages),
                            ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("${date.day}", style: dayStyle),
                                  if (!hasEntry) ...[
                                    const SizedBox(height: 1),
                                    Text(lunarStr, style: lunarStyle),
                                  ] else if (allImages.isEmpty && (moodIdx != null || customMoodIconPath != null)) ...[
                                    const SizedBox(height: 1),
                                    _buildMoodIcon(
                                      moodIdx: moodIdx,
                                      customMoodIconPath: customMoodIconPath,
                                      customMoodIconAsset: customMoodIconAsset,
                                      isNight: isNight,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: LegoBorderPainter(
                                  hasSockets: active,
                                  progress: progress,
                                  borderColor: borderSide.color,
                                  borderWidth: borderSide.width,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (active)
                    Positioned(
                      top: -3,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegoStud(progress),
                            const SizedBox(width: 6),
                            _buildLegoStud(progress),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: cellContent,
    );
  }

  Widget _buildLegoStud(double progress) {
    return Container(
      width: 7,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFE1AF78),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(1.5),
          topRight: Radius.circular(1.5),
        ),
      ),
    );
  }

  Widget _buildMoodIcon({
    required int? moodIdx,
    required String? customMoodIconPath,
    required String? customMoodIconAsset,
    required bool isNight,
  }) {
    const double size = 18;
    final fallbackIcon = Icon(Icons.mood, size: size, color: isNight ? Colors.white54 : const Color(0xFF5C5C5C));

    Widget img;
    if (customMoodIconPath != null) {
      img = Image.file(
        File(customMoodIconPath),
        width: size, height: size,
        errorBuilder: (c, e, s) => customMoodIconAsset != null
            ? Image.asset(customMoodIconAsset, width: size, height: size,
                errorBuilder: (c2, e2, s2) => fallbackIcon)
            : fallbackIcon,
      );
    } else if (customMoodIconAsset != null) {
      img = Image.asset(
        customMoodIconAsset,
        width: size, height: size,
        errorBuilder: (c, e, s) => fallbackIcon,
      );
    } else if (moodIdx != null) {
      final iconPath = kMoods[moodIdx.clamp(0, kMoods.length - 1)].iconPath;
      if (iconPath != null) {
        img = Image.asset(iconPath, width: size, height: size);
      } else {
        return fallbackIcon;
      }
    } else {
      return fallbackIcon;
    }

    return Opacity(opacity: 0.9, child: img);
  }

  Widget _buildGridImages(List<String> images) {
    Widget tile(String path) => SizedBox.expand(
      child: ClipRect(
        child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
      ),
    );

    final int count = images.length;
    if (count == 1) {
      return tile(images[0]);
    } else if (count == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(images[0])),
          const SizedBox(width: 1),
          Expanded(child: tile(images[1])),
        ],
      );
    } else if (count == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(images[0])),
          const SizedBox(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[1])),
                const SizedBox(height: 1),
                Expanded(child: tile(images[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      final int remaining = count - 4;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[0])),
                const SizedBox(width: 1),
                Expanded(child: tile(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[2])),
                const SizedBox(width: 1),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      tile(images[3]),
                      if (remaining > 0)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.9,
                              colors: [
                                Colors.black.withValues(alpha: 0.72),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "+$remaining",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Color _getMoodMacaronColor(int? moodIdx, bool isNight) {
    if (moodIdx == null) return isNight ? const Color(0xFF3B3E42) : Colors.white;
    if (isNight) {
      switch (moodIdx % 5) {
        case 0: return const Color(0xFF3A382A);
        case 1: return const Color(0xFF283832);
        case 2: return const Color(0xFF2B333F);
        case 3: return const Color(0xFF3E2B2B);
        case 4: return const Color(0xFF3E2F35);
        default: return const Color(0xFF3B3E42);
      }
    } else {
      switch (moodIdx % 5) {
        case 0: return const Color(0xFFFFF1C5).withValues(alpha: 0.85); // Macaron Yellow
        case 1: return const Color(0xFFE2F5EE).withValues(alpha: 0.85); // Macaron Mint
        case 2: return const Color(0xFFE0ECFC).withValues(alpha: 0.85); // Macaron Blue
        case 3: return const Color(0xFFFFE0D6).withValues(alpha: 0.85); // Macaron Peach
        case 4: return const Color(0xFFFFDDE2).withValues(alpha: 0.85); // Macaron Pink
        default: return const Color(0xFFF3E7FC).withValues(alpha: 0.85); // Macaron Lavender
      }
    }
  }
}
