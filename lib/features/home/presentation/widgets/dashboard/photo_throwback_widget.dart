import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/features/home/presentation/widgets/random_memory_overlay.dart';

/// 左侧：大方块时光相框组件 (那年今日)
class PhotoThrowbackWidget extends StatefulWidget {
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;
  final bool isTall;

  const PhotoThrowbackWidget({
    super.key,
    required this.groupedEntries,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
    this.isTall = true,
  });

  @override
  State<PhotoThrowbackWidget> createState() => _PhotoThrowbackWidgetState();
}

class _PhotoThrowbackWidgetState extends State<PhotoThrowbackWidget> {
  static String? _cachedSessionImagePath;

  @override
  void initState() {
    super.initState();
    _ensureSessionImage();
  }

  @override
  void didUpdateWidget(covariant PhotoThrowbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSessionImage();
  }

  void _ensureSessionImage() {
    // 若已有有效缓存，直接保留不刷新
    if (_cachedSessionImagePath != null) {
      if (_cachedSessionImagePath!.startsWith('assets/')) return;
      if (File(_cachedSessionImagePath!).existsSync()) return;
    }

    final validPaths = <String>[];

    // 1. 与 PhotoWallCard 一致：优先从 groupedEntries 提取有真实文件的相片
    for (var group in widget.groupedEntries) {
      for (var entryList in group.values) {
        for (var entry in entryList) {
          for (var block in entry.blocks) {
            if (block['type'] == 'image' && block['path'] != null) {
              final p = block['path'].toString();
              if (File(p).existsSync()) {
                validPaths.add(p);
              }
            }
          }
        }
      }
    }

    // 2. 兜底全量检索 UserState().savedDiaries
    if (validPaths.isEmpty) {
      for (var entry in UserState().savedDiaries.value) {
        for (var block in entry.blocks) {
          if (block['type'] == 'image') {
            final p = (block['path'] ?? block['url'] ?? block['value'] ?? block['imagePath'])?.toString();
            if (p != null && File(p).existsSync()) {
              validPaths.add(p);
            }
          }
        }
      }
    }

    if (validPaths.isNotEmpty) {
      final random = math.Random();
      _cachedSessionImagePath = validPaths[random.nextInt(validPaths.length)];
    } else if (UserState().savedDiaries.value.isNotEmpty || widget.groupedEntries.isNotEmpty) {
      // 3. 只要岛上有日记数据，默认精选一张岛屿回忆插画背景图
      final presetBgs = [
        'assets/images/emoji/modules_bg/4.png',
        'assets/images/emoji/modules_bg/5.png',
        'assets/images/emoji/modules_bg/6.png',
        'assets/images/emoji/modules_bg/7.png',
        'assets/images/emoji/modules_bg/8.png',
        'assets/images/emoji/modules_bg/9.png',
        'assets/images/emoji/modules_bg/10.png',
        'assets/images/emoji/modules_bg/11.png',
        'assets/images/emoji/modules_bg/12.png',
      ];
      final random = math.Random();
      _cachedSessionImagePath = presetBgs[random.nextInt(presetBgs.length)];
    } else {
      _cachedSessionImagePath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _cachedSessionImagePath;
    final borderColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.45);

    return BouncingButton(
      scaleFactor: 0.96,
      onTap: () {
        HapticFeedback.mediumImpact();
        RandomMemoryOverlay.show(context, isNight: widget.isNight);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity, // 始终撑满父容器宽度，无论是长方块还是矮方块插槽
        height: widget.isTall ? 296 : 140, // 296 时为长方块，140 时自动变成矮方块！
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: imagePath != null
              ? Stack(
                  children: [
                    // 相片层
                    Positioned.fill(
                      child: imagePath.startsWith('assets/')
                          ? Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildFallbackContent(),
                            )
                          : Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildFallbackContent(),
                            ),
                    ),

                    // 渐变阴影层：在有用户照片时叠加黑色渐变遮罩以保证白色文字可读性
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 内容层（有照片时）
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "随机掉落的记忆碎片",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: widget.fontFamily,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : _buildFallbackContent(),
        ),
      ),
    );
  }

  Widget _buildFallbackContent() {
    final isDark = widget.isNight;
    final accent = widget.accentColor;
    final subCol = widget.subtitleColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(23),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.20),
                ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部艺术感拍立得空状态插图
          Expanded(
            child: Center(
              child: Container(
                width: 90,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.4),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 相框底衬
                    Icon(
                      Icons.filter_hdr_rounded,
                      size: 40,
                      color: accent.withValues(alpha: 0.65),
                    ),
                    // 右上角微光闪烁星芒
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 0, end: -6, duration: 2500.ms, curve: Curves.easeInOutSine),
            ),
          ),

          // 底部标题与精致副标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "随机掉落的记忆碎片",
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: widget.fontFamily,
                  color: subCol,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
