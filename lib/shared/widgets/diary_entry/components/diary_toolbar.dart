import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'diary_painters.dart';

/// 随键盘起伏的动态吸附工具栏（双行版）
class DiaryToolbar extends StatelessWidget {
  final bool isEmojiOpen;
  final bool isRecording;
  final VoidCallback onEmojiToggle;
  final VoidCallback onRecordToggle;
  final VoidCallback onImagePick;
  final VoidCallback? onTopicClick;
  final VoidCallback? onColorClick;
  final VoidCallback? onBgColorClick;

  const DiaryToolbar({
    super.key,
    required this.isEmojiOpen,
    required this.isRecording,
    required this.onEmojiToggle,
    required this.onRecordToggle,
    required this.onImagePick,
    this.onTopicClick,
    this.onColorClick,
    this.onBgColorClick,
  });

  @override
  Widget build(BuildContext context) {
    final double rowWidth = MediaQuery.of(context).size.width - 16;

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
  }

  /// 构建双行工具栏图标组
  List<Widget> _buildDualRowToolbarIcons(double rowWidth) {
    final List<String> iconPaths = [
      isEmojiOpen
          ? 'assets/images/icons/keyword.png'
          : 'assets/images/icons/emoji_icon.png',
      'assets/images/icons/record_icon.png',
      'assets/images/icons/photo_icon.png',
      'assets/images/icons/topic_icon.png',
      'assets/images/icons/pencil_icon.png',
      'assets/images/icons/calligraphy_icon.png',
      'assets/images/icons/time_icon.png',
      'assets/images/icons/address_icon.png',
      'assets/images/icons/music_icon.png',
      'assets/images/icons/link_icon.png',
      'assets/images/icons/fontSize_icon.png',
      'assets/images/icons/utils_icons.png',
    ];

    final double itemWidth = rowWidth / 6;
    final row1 = iconPaths.sublist(0, 6);
    final row2 = iconPaths.sublist(6, 12);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row1.asMap().entries.map((entry) {
          final int index = entry.key;
          final String path = entry.value;

          VoidCallback? activeOnTap;
          if (index == 0) activeOnTap = onEmojiToggle;
          if (index == 1) activeOnTap = onRecordToggle;
          if (index == 2) activeOnTap = onImagePick;
          if (index == 3) activeOnTap = onTopicClick;
          if (index == 4) activeOnTap = onColorClick;
          if (index == 5) activeOnTap = onBgColorClick;

          return _buildToolbarItem(
            path,
            itemWidth,
            onTap: activeOnTap,
            isSelected: index == 1 && isRecording,
          );
        }).toList(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row2
            .map((path) => _buildToolbarItem(path, itemWidth))
            .toList(),
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
