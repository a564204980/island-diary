import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'diary_painters.dart';

/// 随键盘起伏的动态吸附工具栏（双行版）
class DiaryToolbar extends StatelessWidget {
  final bool isEmojiOpen;
  final VoidCallback onEmojiToggle;
  final VoidCallback onImagePick;
  final VoidCallback? onTopicClick;
  final VoidCallback? onColorClick;
  final VoidCallback? onBgColorClick;
  final VoidCallback? onLocationClick;
  final VoidCallback? onFontSizeClick;
  final VoidCallback? onFontClick;
  final VoidCallback? onDateClick;
  final VoidCallback? onTimeClick;
  final VoidCallback? onTagClick;
  final VoidCallback? onWeatherClick;
  final VoidCallback? onMoreClick;

  const DiaryToolbar({
    super.key,
    required this.isEmojiOpen,
    required this.onEmojiToggle,
    required this.onImagePick,
    this.onTopicClick,
    this.onColorClick,
    this.onBgColorClick,
    this.onLocationClick,
    this.onFontSizeClick,
    this.onFontClick,
    this.onDateClick,
    this.onTimeClick,
    this.onTagClick,
    this.onWeatherClick,
    this.onMoreClick,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double rowWidth = constraints.maxWidth - 16;

        return Container(
          height: 110,
          width: double.infinity,
          child: Stack(
            children: [
              // 背景 - 磨砂玻璃 + 手绘线条
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: CustomPaint(
                      painter: HandDrawnToolbarPainter(
                        color: const Color(0xFFF9EED8).withOpacity(0.85),
                        borderColor: const Color(0xFF8B5E3C),
                      ),
                    ),
                  ),
                ),
              ),
              // 双行图标列表
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildDualRowToolbarIcons(rowWidth),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建双行工具栏图标组
  List<Widget> _buildDualRowToolbarIcons(double rowWidth) {
    // 扩展为 7x2 布局 (目前总共 13 个图标)
    final List<Map<String, dynamic>> icons = [
      // 第一行 (7个)
      {
        'path': isEmojiOpen
            ? 'assets/images/icons/keyword.png'
            : 'assets/images/icons/emoji_icon.png',
        'onTap': onEmojiToggle,
      },
      {'path': 'assets/images/icons/photo_icon.png', 'onTap': onImagePick},
      {'path': 'assets/images/icons/topic_icon.png', 'onTap': onTopicClick},
      {'path': 'assets/images/icons/calendar.png', 'onTap': onDateClick},
      {'path': 'assets/images/icons/time.png', 'onTap': onTimeClick},
      {'path': 'assets/images/icons/address_icon.png', 'onTap': onLocationClick},
      {'path': 'assets/images/icons/tag.png', 'onTap': onTagClick},
      
      // 第二行 (6个已定，总 13 个)
      {'path': 'assets/images/icons/fontSize_icon.png', 'onTap': onFontSizeClick},
      {'path': 'assets/images/icons/finally_icon.png', 'onTap': onFontClick},
      {'path': 'assets/images/icons/pencil_icon.png', 'onTap': onColorClick},
      {'path': 'assets/images/icons/calligraphy_icon.png', 'onTap': onBgColorClick},
      {'path': 'assets/images/icons/watcher.png', 'onTap': onWeatherClick},
      {'path': 'assets/images/icons/more.png', 'onTap': onMoreClick},
    ];

    final double itemWidth = rowWidth / 7;
    final row1Icons = icons.sublist(0, 7);
    final row2Icons = icons.sublist(7);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row1Icons.map((icon) {
          return _buildToolbarItem(
            icon['path'],
            itemWidth,
            onTap: icon['onTap'],
          );
        }).toList(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row2Icons.map((icon) {
          return _buildToolbarItem(
            icon['path'],
            itemWidth,
            onTap: icon['onTap'],
          );
        }).toList(),
      ),
    ];
  }




  Widget _buildToolbarItem(
    String assetPath,
    double width, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: InkWell(
          onTap:
              onTap ??
              () {
                // TODO: 具体功能逻辑
              },
          child:
              Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5E3C).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      assetPath,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  )
                  .animate(target: isSelected ? 1 : 0)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 200.ms,
                  ),
        ),
      ),
    );
  }
}
