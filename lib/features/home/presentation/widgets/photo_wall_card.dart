import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/features/home/presentation/widgets/random_memory_overlay.dart';
import 'package:island_diary/features/home/presentation/pages/photo_wall_page.dart';
import 'package:island_diary/core/services/wind_service.dart';

class PhotoWallItemData {
  final String imagePath;
  final DateTime date;
  final String? tag;
  final DiaryEntry? entry;

  PhotoWallItemData({
    required this.imagePath,
    required this.date,
    this.tag,
    this.entry,
  });
}

/// 手帐情绪板 (Scrapbook Moodboard) 创意照片墙组件
class PhotoWallCard extends StatefulWidget {
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;
  final bool isTall;

  const PhotoWallCard({
    super.key,
    required this.groupedEntries,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
    this.isTall = false,
  });

  @override
  State<PhotoWallCard> createState() => _PhotoWallCardState();
}

class _PhotoWallCardState extends State<PhotoWallCard> {
  final List<PhotoWallItemData> _photoItems = [];

  // 纸胶带色板 (马卡龙半透明色)
  final List<Color> _washiTapeColors = const [
    Color(0xCCFFB7B2), // 柔粉
    Color(0xCCB5EAD7), // 薄荷绿
    Color(0xCCE2F0CB), // 奶油绿
    Color(0xCCAA96DA), // 薰衣草紫
    Color(0xCCFFDAC1), // 暖杏橘
  ];

  @override
  void initState() {
    super.initState();
    _extractPhotoItems();
  }

  @override
  void didUpdateWidget(covariant PhotoWallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupedEntries.length != oldWidget.groupedEntries.length) {
      _extractPhotoItems();
    }
  }

  void _extractPhotoItems() {
    _photoItems.clear();
    for (var group in widget.groupedEntries) {
      for (var entryList in group.values) {
        for (var entry in entryList) {
          final contentBlocks = entry.blocks;
          for (var block in contentBlocks) {
            if (block['type'] == 'image' && block['path'] != null) {
              final path = block['path'].toString();
              if (File(path).existsSync()) {
                _photoItems.add(
                  PhotoWallItemData(
                    imagePath: path,
                    date: entry.dateTime,
                    tag: entry.tag,
                    entry: entry,
                  ),
                );
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhotos = _photoItems.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasPhotos) {
          RandomMemoryOverlay.show(context, isNight: widget.isNight);
        } else {
          showTopToast(context, '📸 记录带照片的日记，即可制作专属手帐照片墙', icon: Icons.photo_library_rounded);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: widget.isTall ? 296 : 140,
            clipBehavior: Clip.antiAlias,
            padding: EdgeInsets.symmetric(horizontal: widget.isTall ? 6 : 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isNight
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isNight
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
        child: hasPhotos
            ? _buildScrapbookBoard()
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  // 顶部标题栏（仅在空状态时显示）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.collections_bookmark_rounded,
                            size: 16,
                            color: widget.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "记忆手帐板",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: widget.fontFamily,
                              color: widget.textColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "手帐板",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontFamily: widget.fontFamily,
                          color: widget.subtitleColor,
                        ),
                      ),
                    ],
                  ),

                      // 手帐空状态展示区
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildEmptyScrapbookBoard(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// 真实感手帐情绪板（风速物理联动版：根据海岛风速驱动拍立得晃荡频率与顺风偏角）
  Widget _buildScrapbookBoard() {
    // 长条形态下最多可显示 30 张照片，矮形态下显示 5 张
    final int maxCount = widget.isTall ? 30 : 5;
    final displayItems = _photoItems.take(maxCount).toList();
    final int count = displayItems.length;

    // 针对 30 张高密度照片准备的自然多姿态偏角矩阵
    final baseAngles = [-0.18, 0.16, -0.08, 0.22, -0.14, 0.12, -0.16, 0.18, -0.10, 0.20, -0.15, 0.10, -0.12, 0.16, -0.08, -0.20, 0.15, -0.09, 0.18, -0.14, 0.10, -0.16, 0.14, -0.08, 0.19, -0.12, 0.15, -0.10, 0.16, -0.08];

    final shortTopOffsets = [6.0, 22.0, 8.0, 24.0, 10.0];

    return ValueListenableBuilder<WindMode>(
      valueListenable: WindService.currentWind,
      builder: (context, wind, _) {
        // 根据风速等级计算摆动振幅、周期与顺风倾角
        double swingRange;
        int baseDurationMs;
        double windTilt;

        switch (wind) {
          case WindMode.none:
            swingRange = 0.008;
            baseDurationMs = 3600;
            windTilt = 0.0;
            break;
          case WindMode.breeze:
            swingRange = 0.04;
            baseDurationMs = 2400;
            windTilt = -0.01;
            break;
          case WindMode.moderate:
            swingRange = 0.08;
            baseDurationMs = 1300;
            windTilt = -0.035;
            break;
          case WindMode.gale:
            swingRange = 0.15;
            baseDurationMs = 650;
            windTilt = -0.08; // 狂风从右往左吹，顺风向左摇曳
            break;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            // 设定为 42x56，使相框与相邻相框产生 20%~30% 的自然边角叠压
            final double cardWidth = widget.isTall ? (count > 8 ? 42.0 : 48.0) : 56.0;
            final double cardHeight = widget.isTall ? (count > 8 ? 56.0 : 64.0) : 74.0;
            
            final step = count > 1 ? (availableWidth - cardWidth) / (count - 1) : 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. 高密度层叠拍立得照片层 (后一张适度覆盖在前一张之上)
                ...List.generate(count, (index) {
                  final item = displayItems[index];
                  final staticAngle = baseAngles[index % baseAngles.length];
                  final double finalAngle;
                  if (wind == WindMode.gale) {
                    // 狂风大作（自右向左强风）：所有相框偏角在视觉上 100% 真正向左侧歪倒 (0.02 ~ 0.35 弧度)
                    final double indexPhase = (index % 5) * 0.032;
                    finalAngle = (staticAngle * 0.65 + 0.12 + indexPhase).clamp(0.02, 0.35);
                  } else {
                    finalAngle = staticAngle + windTilt; // 静态角 + 顺风偏移
                  }

                  final double top;
                  final double left;

                  if (widget.isTall) {
                    if (count <= 1) {
                      top = 10.0;
                      left = (availableWidth - cardWidth) / 2;
                    } else if (count <= 8) {
                      // 少量照片时：双列大拍立得全幅交错
                      const double minTop = 8.0;
                      const double maxTop = 195.0;
                      final double topStep = (maxTop - minTop) / (count - 1);
                      top = (minTop + index * topStep + math.sin(index * 1.5) * 3.0);
                      
                      const double minLeft = -2.0;
                      final double maxLeft = availableWidth - cardWidth + 2.0;
                      final double ratio = (index % 2 == 0) ? 0.05 : 0.95;
                      left = minLeft + ratio * (maxLeft - minLeft);
                    } else {
                      // 1:1 参考示范图：4 列高密度交错重叠拼贴 (双向无缝错位，且严格保护底部标语)
                      const int cols = 4;
                      final int row = index ~/ cols;
                      final int col = index % cols;

                      const double minTop = 6.0;
                      const double maxTop = 182.0;
                      final int totalRows = ((count + cols - 1) ~/ cols);
                      final double rowStep = totalRows > 1 ? (maxTop - minTop) / (totalRows - 1) : 0.0;
                      
                      // 奇偶行与奇偶列的双向无缝错位，创造 20%~30% 的自然边角叠压
                      final double rowOffset = ((col % 2 == 1) ? 8.0 : -3.0) + math.sin(index * 2.1) * 2.5;
                      top = (minTop + row * rowStep + rowOffset).clamp(minTop, maxTop);

                      const double minLeft = 4.0;
                      final double maxLeft = availableWidth - cardWidth - 4.0;
                      final double colStep = (maxLeft - minLeft) / (cols - 1);
                      final double colOffset = ((row % 2 == 1) ? 4.0 : -4.0) + math.cos(index * 1.8) * 2.5;
                      left = (minLeft + col * colStep + colOffset).clamp(2.0, availableWidth - cardWidth - 2.0);
                    }
                  } else {
                    // 矮形态：单行横向交错
                    top = shortTopOffsets[index % shortTopOffsets.length];
                    left = count > 1 
                        ? index * step 
                        : (availableWidth - cardWidth) / 2;
                  }

                  return Positioned(
                    left: left,
                    top: top,
                    child: Transform.rotate(
                      angle: finalAngle,
                      child: BouncingButton(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 320),
                              reverseTransitionDuration: const Duration(milliseconds: 260),
                              pageBuilder: (context, animation, secondaryAnimation) {
                                return PhotoWallPage(
                                  isNight: widget.isNight,
                                  themeId: 'default',
                                );
                              },
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                );
                                final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                );
                                return FadeTransition(
                                  opacity: fadeAnimation,
                                  child: ScaleTransition(
                                    scale: scaleAnimation,
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        scaleFactor: 1.06,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            // 拍立得主卡片
                            Container(
                              width: cardWidth,
                              height: cardHeight,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: widget.isNight ? 0.38 : 0.16),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.5),
                                child: Image.file(
                                  File(item.imagePath),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(
                      key: ValueKey(wind),
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .rotate(
                      begin: -swingRange / 2,
                      end: swingRange / 2,
                      duration: Duration(milliseconds: baseDurationMs + index * 120),
                      curve: Curves.easeInOutSine,
                    )
                    .moveY(
                      begin: 0,
                      end: (index % 2 == 0) ? -3.0 : 3.0,
                      duration: Duration(milliseconds: (baseDurationMs * 1.1).toInt()),
                      curve: Curves.easeInOutSine,
                    ),
                  );
                }),

                // 底部手帐诗意标语栏
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 11,
                          color: widget.accentColor.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "收集时光里的温柔碎片",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: widget.fontFamily,
                            color: widget.subtitleColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 无数据时的手帐情绪板空状态 (长条形态高密度交错)
  Widget _buildEmptyScrapbookBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final double cardWidth = widget.isTall ? 50.0 : 56.0;

        final List<Map<String, dynamic>> configs;
        if (widget.isTall) {
          final double minLeft = 2.0;
          final double maxLeft = math.max(minLeft, availableWidth - cardWidth - 2.0);
          configs = [
            {'left': minLeft + 0.05 * (maxLeft - minLeft), 'top': 4.0, 'angle': -0.12, 'tapeColor': _washiTapeColors[0]},
            {'left': minLeft + 0.75 * (maxLeft - minLeft), 'top': 26.0, 'angle': 0.10, 'tapeColor': _washiTapeColors[1]},
            {'left': minLeft + 0.28 * (maxLeft - minLeft), 'top': 48.0, 'angle': -0.06, 'tapeColor': _washiTapeColors[2]},
            {'left': minLeft + 0.88 * (maxLeft - minLeft), 'top': 70.0, 'angle': 0.14, 'tapeColor': _washiTapeColors[0]},
            {'left': minLeft + 0.10 * (maxLeft - minLeft), 'top': 92.0, 'angle': -0.08, 'tapeColor': _washiTapeColors[1]},
            {'left': minLeft + 0.60 * (maxLeft - minLeft), 'top': 114.0, 'angle': 0.09, 'tapeColor': _washiTapeColors[2]},
            {'left': minLeft + 0.38 * (maxLeft - minLeft), 'top': 136.0, 'angle': -0.05, 'tapeColor': _washiTapeColors[0]},
            {'left': minLeft + 0.82 * (maxLeft - minLeft), 'top': 158.0, 'angle': 0.11, 'tapeColor': _washiTapeColors[1]},
            {'left': minLeft + 0.18 * (maxLeft - minLeft), 'top': 178.0, 'angle': -0.07, 'tapeColor': _washiTapeColors[2]},
          ];
        } else {
          configs = [
            {'left': 12.0, 'top': 12.0, 'angle': -0.09, 'tapeColor': _washiTapeColors[0]},
            {'left': 56.0, 'top': 6.0, 'angle': 0.07, 'tapeColor': _washiTapeColors[1]},
            {'left': 98.0, 'top': 14.0, 'angle': -0.04, 'tapeColor': _washiTapeColors[2]},
          ];
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ...List.generate(configs.length, (index) {
              final cfg = configs[index];
              final angle = cfg['angle'] as double;
              final left = cfg['left'] as double;
              final top = cfg['top'] as double;

              return Positioned(
                left: left,
                top: top,
                child: Transform.rotate(
                  angle: angle,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: cardWidth,
                        height: 68,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.isNight
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: widget.isNight ? 0.2 : 0.8),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: widget.isNight ? 0.15 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              index % 2 == 1 ? Icons.add_a_photo_outlined : Icons.filter_vintage_outlined,
                              size: 18,
                              color: widget.accentColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              index % 2 == 1 ? "留存回忆" : "•••",
                              style: TextStyle(
                                fontSize: 7.5,
                                fontFamily: widget.fontFamily,
                                color: widget.subtitleColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: (index % 2 == 0) ? -3.0 : 3.0,
                duration: Duration(milliseconds: 2200 + index * 450),
                curve: Curves.easeInOutSine,
              );
            }),

            // 底部手帐诗意标语栏
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 11,
                      color: widget.accentColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "收集时光里的温柔碎片",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: widget.fontFamily,
                        color: widget.subtitleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
