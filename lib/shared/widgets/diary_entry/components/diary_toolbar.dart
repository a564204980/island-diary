import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_painters.dart';

/// 随键盘起伏的动态吸附工具栏（双行版）
class DiaryToolbar extends StatelessWidget {
  final bool isEmojiOpen;
  final VoidCallback onEmojiToggle;
  final VoidCallback onImagePick;
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
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final Color? accentColor;
  final bool? isNightOverride;
  final bool isNoteBackground;

  const DiaryToolbar({
    super.key,
    required this.isEmojiOpen,
    required this.onEmojiToggle,
    required this.onImagePick,
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
    this.onClose,
    this.onSave,
    this.accentColor,
    this.isNightOverride,
    this.isNoteBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = isNightOverride ?? UserState().isNight;
    final Color primaryColor = isNight
        ? const Color(0xFFE0C097)
        : (accentColor ?? const Color(0xFF8B5E3C));
        
        
    final Color toolbarBg = isNight 
        ? const Color(0xFF1E1E2C).withValues(alpha: isNoteBackground ? 0.8 : 0.9) 
        : (isNoteBackground 
            ? Colors.white.withValues(alpha: 0.12)
            : primaryColor.withValues(alpha: 0.08));
            
    final Color toolbarBorder = isNoteBackground 
        ? (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.08))
        : primaryColor.withValues(alpha: 0.3);


    return LayoutBuilder(
      builder: (context, constraints) {
        final double rowWidth = constraints.maxWidth - 16;

        return Container(
          height: 110,
          width: double.infinity,
          child: Stack(
            children: [
              // 背景 - 阴影层 (不在 ClipRect 内，允许向外溢出)
              Positioned.fill(
                child: CustomPaint(
                  painter: HandDrawnToolbarPainter(
                    color: toolbarBg,
                    borderColor: toolbarBorder,
                    shadowOnly: true,
                  ),
                ),
              ),
              // 背景 - 磨砂玻璃 + 手绘线条 (受 ClipRect 限制以保证模糊范围)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isNoteBackground ? 12 : 6, 
                      sigmaY: isNoteBackground ? 12 : 6,
                    ),
                    child: CustomPaint(
                      painter: HandDrawnToolbarPainter(
                        color: toolbarBg,
                        borderColor: toolbarBorder,
                        shadowOnly: false,
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
                  children: _buildDualRowToolbarIcons(rowWidth, isNight, primaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建双行工具栏图标组
  List<Widget> _buildDualRowToolbarIcons(double rowWidth, bool isNight, Color primaryColor) {
    final List<Map<String, dynamic>> icons = [
      // 第一行
      {
        'path': isEmojiOpen
            ? 'assets/images/icons/keyword.png'
            : 'assets/images/icons/emoji_icon.png',
        'onTap': onEmojiToggle,
      },
      {'path': 'assets/images/icons/photo_icon.png', 'onTap': onImagePick},
      {'path': 'assets/images/icons/watcher.png', 'onTap': onWeatherClick},
      {'path': 'assets/images/icons/calendar.png', 'onTap': onDateClick},
      {'path': 'assets/images/icons/time.png', 'onTap': onTimeClick},
      {'path': 'assets/images/icons/address_icon.png', 'onTap': onLocationClick},
      {'path': 'assets/images/icons/tag.png', 'onTap': onTagClick},
      
      // 第二行
      {'path': 'assets/images/icons/fontSize_icon.png', 'onTap': onFontSizeClick},
      {'path': 'assets/images/icons/finally_icon.png', 'onTap': onFontClick},
      {'path': 'assets/images/icons/pencil_icon.png', 'onTap': onColorClick},
      {'path': 'assets/images/icons/calligraphy_icon.png', 'onTap': onBgColorClick},
      {'path': 'assets/images/icons/more.png', 'onTap': onMoreClick},
      {
        'icon': Icons.close_rounded,
        'onTap': onClose,
        'color': isNight ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F),
      },
      {
        'icon': Icons.check_rounded,
        'onTap': onSave,
        'color': isNight ? const Color(0xFFA5D6A7) : primaryColor,
      },
    ];

    final double itemWidth = rowWidth / 7;
    final row1Icons = icons.sublist(0, 7);
    final row2Icons = icons.sublist(7);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row1Icons.map((icon) {
          return _buildToolbarItem(
            itemWidth,
            assetPath: icon['path'],
            icon: icon['icon'],
            iconColor: icon['color'],
            bgColor: icon['bgColor'],
            onTap: icon['onTap'],
            isNight: isNight,
            primaryColor: primaryColor,
          );
        }).toList(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row2Icons.map((icon) {
          return _buildToolbarItem(
            itemWidth,
            assetPath: icon['path'],
            icon: icon['icon'],
            iconColor: icon['color'],
            bgColor: icon['bgColor'],
            onTap: icon['onTap'],
            isNight: isNight,
            primaryColor: primaryColor,
          );
        }).toList(),
      ),
    ];
  }

  Widget _buildToolbarItem(
    double width, {
    String? assetPath,
    IconData? icon,
    Color? iconColor,
    Color? bgColor,
    VoidCallback? onTap,
    bool isSelected = false,
    required bool isNight,
    required Color primaryColor,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: InkWell(
          onTap: onTap ?? () {},
          child: assetPath != null
              ? Image.asset(
                  assetPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                )
              : Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 200.ms,
        ),
      ),
    );
  }
}
