import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';
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
  final String paperStyle;

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
    this.paperStyle = 'standard',
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = isNightOverride ?? UserState().isNight;

    // 核心墨水/强调色
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final Color primaryColor = isNight ? const Color(0xFFE0C097) : inkColor;

    // 动态工具栏背景：基于信纸色调进行高亮处理
    final Color paperBase = DiaryUtils.getPaperBaseColor(paperStyle, isNight);

    final Color toolbarBg = isNight
        ? const Color(0xFF1E1E2C).withValues(alpha: 0.95)
        : paperBase.withValues(alpha: 0.95);

    final Color toolbarBorder = isNight
        ? Colors.white24
        : primaryColor.withValues(alpha: 0.25);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double rowWidth = constraints.maxWidth - 16;
        final bool isWide = rowWidth > 700; // 宽屏判断

        return SizedBox(
          height: isWide ? 64 : 110, // 宽屏下高度变窄
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
                    showSideBorders: isWide,
                  ),
                ),
              ),
              // 背景 - 磨砂玻璃 + 手绘线条 (受 ClipRect 限制以保证模糊范围)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isNoteBackground ? 1 : 4,
                      sigmaY: isNoteBackground ? 1 : 4,
                    ),
                    child: CustomPaint(
                      painter: HandDrawnToolbarPainter(
                        color: toolbarBg,
                        borderColor: toolbarBorder,
                        shadowOnly: false,
                        showSideBorders: isWide,
                      ),
                    ),
                  ),
                ),
              ),
              // 图标列表
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isWide ? 8 : 12,
                  horizontal: 8,
                ),
                child: isWide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildSingleRowIcons(
                          rowWidth,
                          isNight,
                          primaryColor,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildDualRowToolbarIcons(
                          rowWidth,
                          isNight,
                          primaryColor,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建单行工具栏图标组
  List<Widget> _buildSingleRowIcons(
    double rowWidth,
    bool isNight,
    Color primaryColor,
  ) {
    final List<Map<String, dynamic>> icons = _getIconData(
      isNight,
      primaryColor,
    );
    // 允许图标进一步缩小，并减小左右边距以防止溢出
    final double itemWidth = math.min(44.0, (rowWidth - 40) / icons.length);
    const double horizontalPadding = 2.0;

    return icons.map((icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: _buildToolbarItem(
          itemWidth,
          icon: icon['icon'],
          iconColor: icon['color'],
          bgColor: icon['bgColor'],
          onTap: icon['onTap'],
          primaryColor: primaryColor,
        ),
      );
    }).toList();
  }

  /// 提取图标数据逻辑
  List<Map<String, dynamic>> _getIconData(bool isNight, Color primaryColor) {
    return [
      {
        'icon': isEmojiOpen ? Icons.keyboard_alt_rounded : Icons.mood_rounded,
        'onTap': onEmojiToggle,
      },
      {'icon': Icons.photo_library_rounded, 'onTap': onImagePick},
      {'icon': Icons.wb_sunny_rounded, 'onTap': onWeatherClick},
      {'icon': Icons.calendar_month_rounded, 'onTap': onDateClick},
      {'icon': Icons.schedule_rounded, 'onTap': onTimeClick},
      {'icon': Icons.location_on_rounded, 'onTap': onLocationClick},
      {'icon': Icons.local_offer_rounded, 'onTap': onTagClick},
      {'icon': Icons.format_size_rounded, 'onTap': onFontSizeClick},
      {'icon': Icons.font_download_rounded, 'onTap': onFontClick},
      {'icon': Icons.palette_rounded, 'onTap': onColorClick},
      {'icon': Icons.style_rounded, 'onTap': onBgColorClick},
      {'icon': Icons.more_horiz_rounded, 'onTap': onMoreClick},
      {
        'icon': Icons.close_rounded,
        'onTap': onClose,
        'color': isNight ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F),
        'bgColor': (isNight ? Colors.redAccent : const Color(0xFFD32F2F))
            .withValues(alpha: 0.1),
      },
      {
        'icon': Icons.check_rounded,
        'onTap': onSave,
        'color': isNight ? const Color(0xFFA5D6A7) : primaryColor,
        'bgColor': (isNight ? Colors.greenAccent : primaryColor).withValues(
          alpha: 0.12,
        ),
      },
    ];
  }

  /// 构建双行工具栏图标组
  List<Widget> _buildDualRowToolbarIcons(
    double rowWidth,
    bool isNight,
    Color primaryColor,
  ) {
    final List<Map<String, dynamic>> icons = _getIconData(
      isNight,
      primaryColor,
    );

    // 在宽屏下即使是两行也保持一定的紧凑度
    final double itemWidth = rowWidth / 7;

    final row1Icons = icons.sublist(0, 7);
    final row2Icons = icons.sublist(7);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center, // 居中排列
        children: row1Icons.map((icon) {
          return _buildToolbarItem(
            itemWidth,
            icon: icon['icon'],
            iconColor: icon['color'],
            bgColor: icon['bgColor'],
            onTap: icon['onTap'],
            primaryColor: primaryColor,
          );
        }).toList(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center, // 居中排列
        children: row2Icons.map((icon) {
          return _buildToolbarItem(
            itemWidth,
            icon: icon['icon'],
            iconColor: icon['color'],
            bgColor: icon['bgColor'],
            onTap: icon['onTap'],
            primaryColor: primaryColor,
          );
        }).toList(),
      ),
    ];
  }

  Widget _buildToolbarItem(
    double width, {
    required IconData icon,
    Color? iconColor,
    Color? bgColor,
    VoidCallback? onTap,
    bool isSelected = false,
    required Color primaryColor,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child:
            InkWell(
                  onTap: onTap ?? () {},
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.2)
                          : (bgColor ?? primaryColor.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 22, // 略微缩小图标以适应背景圆角
                      color: iconColor ?? primaryColor,
                    ),
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
