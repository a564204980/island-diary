import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/image_group_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_image_collage.dart';
import 'package:intl/intl.dart';

class DiaryBookReaderPage extends StatefulWidget {
  final List<DiaryEntry> entries;
  final int initialIndex;

  const DiaryBookReaderPage({
    super.key,
    required this.entries,
    this.initialIndex = 0,
  });

  @override
  State<DiaryBookReaderPage> createState() => _DiaryBookReaderPageState();
}

class _DiaryBookReaderPageState extends State<DiaryBookReaderPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getWeatherIcon(String? weather) {
    if (weather == null) return Icons.wb_sunny_outlined;
    if (weather.contains("晴")) return Icons.wb_sunny_outlined;
    if (weather.contains("多云")) return Icons.wb_cloudy_outlined;
    if (weather.contains("阴")) return Icons.cloud_outlined;
    if (weather.contains("雨")) return Icons.umbrella_outlined;
    if (weather.contains("雪")) return Icons.ac_unit_outlined;
    if (weather.contains("风")) return Icons.air_outlined;
    if (weather.contains("雾")) return Icons.grain_outlined;
    if (weather.contains("雷")) return Icons.thunderstorm_outlined;
    return Icons.wb_sunny_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    // 象牙白或高级黑灰
    final bgColor = isNight ? const Color(0xFF121214) : const Color(0xFFFDFBF7);
    final paperColor = isNight ? const Color(0xFF1C1C22) : const Color(0xFFFAF8F3);
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';
    final inkColor = isNight ? Colors.white70 : const Color(0xFF332A22);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. 全屏铺满的书页翻页容器
          PageView.builder(
            controller: _pageController,
            itemCount: widget.entries.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final entry = widget.entries[index];
              return _buildBookPage(entry, paperColor, inkColor, fontFamily, isNight);
            },
          ),

          // 2. 顶部极简控制层 (使用 AppBar 覆盖以实现完美的返回按钮对齐)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isNight ? Colors.white70 : Colors.black87,
                ),
              ),
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.entries.length}',
                      style: TextStyle(
                        color: isNight ? Colors.white38 : Colors.black38,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单页的实体全屏纸张和书籍正文内容
  Widget _buildBookPage(
    DiaryEntry entry,
    Color paperColor,
    Color inkColor,
    String fontFamily,
    bool isNight,
  ) {
    // 心情数据获取
    final mood = kMoods[entry.moodIndex.clamp(0, kMoods.length - 1)];

    // 精微化整合元数据小字串
    final dateStr = DateFormat('yyyy年M月d日').format(entry.dateTime);
    final timeStr = DateFormat('HH:mm').format(entry.dateTime);
    final List<String> metaList = [
      dateStr,
      timeStr,
      '${mood.label}',
      if (entry.weather != null) entry.weather!,
      if (entry.location != null) entry.location!,
    ];
    final metaInfo = metaList.join('  ·  ');

    return Container(
      color: paperColor,
      child: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // 1. 优雅的正文大标题
                Text(
                  entry.title ?? '未命名章节',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                    color: inkColor,
                    fontFamily: fontFamily,
                    height: 1.4,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),

                // 2. 精微化元数据小字
                Text(
                  metaInfo,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: inkColor.withValues(alpha: 0.35),
                    fontFamily: fontFamily,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // 3. 正文内容
                ..._buildReaderBlocks(entry, inkColor, fontFamily)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建段落文本块，支持将文本按换行符拆分成独立的段落，应用段落留白
  List<Widget> _buildParagraphWidgets(String text, TextStyle style) {
    final lines = text.split('\n');
    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(
          line,
          style: style,
        ),
      );
    }).toList();
  }

  List<Widget> _buildReaderBlocks(DiaryEntry entry, Color inkColor, String fontFamily) {
    final textStyle = TextStyle(
      fontSize: 16.5,
      height: 1.9,
      letterSpacing: 0.6,
      color: inkColor.withValues(alpha: 0.85),
      fontFamily: fontFamily,
    );

    if (entry.blocks.isEmpty) {
      final filteredContent = DiaryUtils.getFilteredContent(entry.content);
      return [
        if (filteredContent.trim().isNotEmpty)
          ..._buildParagraphWidgets(filteredContent, textStyle),
        _buildReaderImages(entry),
      ];
    }

    if (entry.isImageGrid && !entry.isMixedLayout) {
      final filteredContent = DiaryUtils.getFilteredContent(entry.content);
      return [
        if (filteredContent.trim().isNotEmpty)
          ..._buildParagraphWidgets(filteredContent, textStyle),
        _buildReaderImages(entry),
      ];
    }

    final List<DiaryBlock> originalBlocks = entry.blocks.map((b) => DiaryBlock.fromMap(Map<String, dynamic>.from(b as Map))).toList();
    final processedBlocks = ImageGroupBlock.preprocess(
      originalBlocks,
      isMixedLayout: entry.isMixedLayout,
      isImageGrid: entry.isImageGrid,
    );

    final List<Widget> list = [];
    for (var block in processedBlocks) {
      if (block is TextBlock) {
        final content = block.controller?.text ?? '';
        final filtered = DiaryUtils.getFilteredContent(content);
        if (filtered.trim().isNotEmpty) {
          list.addAll(_buildParagraphWidgets(filtered, textStyle));
        }
      } else if (block is ImageBlock) {
        final path = block.file.path;
        list.add(
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 6, bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DiaryUtils.buildImage(path, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      } else if (block is ImageGroupBlock) {
        final List<String> paths = block.images.map((img) => img.file.path).toList();
        list.add(
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 20),
            child: DiaryImageCollage(
              imagePaths: paths,
              spacing: 6.0,
              borderRadius: 8.0,
            ),
          ),
        );
      }
    }

    return list;
  }

  /// 构建正文图片展示 (九宫格或大图)
  Widget _buildReaderImages(DiaryEntry entry) {
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    if (images.isEmpty) return const SizedBox.shrink();

    if (entry.isImageGrid) {
      if (images.length <= 5) {
        final paths = images.map((img) => img['path'] as String).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: DiaryImageCollage(
            imagePaths: paths,
            spacing: 6.0,
            borderRadius: 8.0,
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 6;
          final double itemSize = (constraints.maxWidth - spacing * 2) / 3;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: images.map((image) {
                final path = image['path'];
                return Container(
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
    }

    return Column(
      children: images.map((image) {
        final path = image['path'];
        return Center(
          child: Container(
            margin: const EdgeInsets.only(top: 6, bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DiaryUtils.buildImage(path, fit: BoxFit.contain),
            ),
          ),
        );
      }).toList(),
    );
  }
}
