import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/pages/photo_wall_page.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/treemap_splitter.dart';
import 'package:island_diary/shared/animations/shared_axis_page_route.dart';
import 'package:island_diary/core/state/user_state.dart';

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

  static PhotoWallCollection? _staticActiveCollection;

  /// 更新照片墙卡片组件引用的静态激活集合缓存
  static void updateStaticCache(PhotoWallCollection collection) {
    _staticActiveCollection = collection;
  }

  @override
  State<PhotoWallCard> createState() => _PhotoWallCardState();
}

class _PhotoWallCardState extends State<PhotoWallCard> {
  final List<PhotoWallItemData> _photoItems = [];
  PhotoWallCollection? _activeCollection;

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

  Future<void> _extractPhotoItems() async {
    // 1. 第一阶段：同步从内存静态缓存或日记数据提取 (首帧渲染 0 延迟生效，解决长按编辑模式弹出空占位符问题)
    _populateFromSyncSources();

    // 2. 第二阶段：异步从持久化数据 SharedPreferences 读取并校验最新激活集合
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('photo_wall_collections_v2');
      if (rawJson != null && rawJson.isNotEmpty) {
        final List list = json.decode(rawJson);
        PhotoWallCollection? activeCol;
        PhotoWallCollection? fallbackCol;

        for (var item in list) {
          Map<String, dynamic>? map;
          if (item is Map) {
            map = Map<String, dynamic>.from(item);
          } else if (item is String) {
            try {
              final decoded = json.decode(item);
              if (decoded is Map) map = Map<String, dynamic>.from(decoded);
            } catch (_) {}
          }
          if (map != null) {
            final col = PhotoWallCollection.fromMap(map);
            if (col.photoPaths.isNotEmpty) {
              fallbackCol ??= col;
              if (col.isActive) {
                activeCol = col;
                break;
              }
            }
          }
        }

        final targetCol = activeCol ?? fallbackCol;
        if (targetCol != null) {
          _activeCollection = targetCol;
          PhotoWallCard._staticActiveCollection = targetCol;
          _populatePhotoItems(targetCol.photoPaths);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  /// 同步提取内存静态缓存或日记中的图片
  void _populateFromSyncSources() {
    List<String> photoPaths = [];

    if (PhotoWallCard._staticActiveCollection != null &&
        PhotoWallCard._staticActiveCollection!.photoPaths.isNotEmpty) {
      _activeCollection = PhotoWallCard._staticActiveCollection;
      photoPaths = List.from(_activeCollection!.photoPaths);
    }

    if (photoPaths.isEmpty) {
      final savedDiaries = UserState().savedDiaries.value;
      for (var entry in savedDiaries) {
        final contentBlocks = entry.blocks;
        for (var block in contentBlocks) {
          if (block['type'] == 'image' && block['path'] != null) {
            final path = block['path'].toString();
            if (path.startsWith('assets/') || File(path).existsSync()) {
              photoPaths.add(path);
            }
          }
        }
      }
    }

    _populatePhotoItems(photoPaths);
  }

  /// 转换照片路径列表为视图数据
  void _populatePhotoItems(List<String> photoPaths) {
    _photoItems.clear();
    for (var path in photoPaths) {
      if (path.startsWith('assets/') || File(path).existsSync()) {
        _photoItems.add(
          PhotoWallItemData(
            imagePath: path,
            date: DateTime.now(),
            tag: null,
            entry: null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhotos = _photoItems.isNotEmpty;

    return BouncingButton(
      scaleFactor: 0.96,
      onTap: () async {
        HapticFeedback.mediumImpact();
        if (hasPhotos) {
          await Navigator.of(context).push(
            SharedAxisPageRoute(
              page: PhotoWallPage(
                isNight: widget.isNight,
                themeId: 'default',
              ),
            ),
          );
          _extractPhotoItems();
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

  /// 真实感手帐情绪板 (100% 响应 layoutMode: scatter 或 treemap)
  Widget _buildScrapbookBoard() {
    final int maxCount = widget.isTall ? 30 : 5;
    final displayItems = _photoItems.take(maxCount).toList();
    final int count = displayItems.length;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    final bool isScatter = _activeCollection?.layoutMode == 'scatter';

    if (isScatter) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double boardW = constraints.maxWidth;
          final double boardH = constraints.maxHeight;

          const double refW = 330.0;
          const double refH = 568.0;

          if (widget.isTall) {
            // 长方形大卡片模式：沿用编辑页 (PhotoWallDetailPage) 的完整自定义排版/坐标映射
            const int cols = 3;
            const int maxRows = 3;

            final maxAvailableW = (boardW - 12.0) / cols;
            final cardW = (maxAvailableW * 0.90).clamp(24.0, 72.0);
            final cardH = (cardW * 1.15).clamp(28.0, 85.0);

            final rowStep = (boardH - cardH - 12.0) / math.max(1, maxRows - 1);
            final colStep = (boardW - cardW - 12.0) / math.max(1, cols - 1);

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: List.generate(count, (index) {
                final item = displayItems[index];
                final id = 'photo_$index';

                double left;
                double top;
                double angle;

                if (_activeCollection?.customPositions != null &&
                    _activeCollection!.customPositions!.containsKey(id)) {
                  final posList = _activeCollection!.customPositions![id]!;
                  left = (posList[0] / refW) * boardW;
                  top = (posList[1] / refH) * boardH;
                  angle = _activeCollection?.customAngles?[id] ?? 0.0;
                } else {
                  final rand = math.Random(42 + id.hashCode);
                  final col = id.hashCode.abs() % cols;
                  final row = (id.hashCode.abs() ~/ cols) % maxRows;
                  final offsetX = (rand.nextDouble() - 0.5) * 12.0;
                  final offsetY = (rand.nextDouble() - 0.5) * 12.0;
                  left = (6.0 + col * colStep + offsetX * (boardW / refW)).clamp(2.0, boardW - cardW - 2.0);
                  top = (6.0 + row * rowStep + offsetY * (boardH / refH)).clamp(2.0, boardH - cardH - 2.0);
                  angle = _activeCollection?.customAngles?[id] ??
                      ((rand.nextDouble() - 0.5) * 0.32);
                }

                return Positioned(
                  left: left.clamp(0.0, math.max(0.0, boardW - cardW)).toDouble(),
                  top: top.clamp(0.0, math.max(0.0, boardH - cardH)).toDouble(),
                  width: cardW,
                  height: cardH,
                  child: Transform.rotate(
                    angle: angle,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: widget.isNight ? 0.38 : 0.16),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: item.imagePath.startsWith('assets/')
                                  ? Image.asset(item.imagePath, fit: BoxFit.cover)
                                  : Image.file(
                                      File(item.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(color: Colors.grey.shade200),
                                    ),
                            ),
                          ),
                        ),
                        _buildWashiTapeWidget(index),
                        Positioned(
                          top: -4,
                          child: _buildMiniPushPinWidget(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          } else {
            // 小卡片模式：不沿用大卡片的竖向排版，采用小卡片专属自适应高低落差微缩散落布局
            final double cardW = (boardW * 0.42).clamp(40.0, 64.0);
            final double cardH = (cardW * 1.15).clamp(46.0, 74.0);

            final double maxLeft = math.max(4.0, boardW - cardW - 6.0);
            final double maxTop = math.max(4.0, boardH - cardH - 6.0);
            final double stepX = count > 1 ? (maxLeft - 6.0) / (count - 1) : 0.0;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: List.generate(count, (index) {
                final item = displayItems[index];
                final id = 'photo_$index';
                final seed = (_activeCollection?.id.hashCode.abs() ?? 42) + id.hashCode;
                final rand = math.Random(seed);

                final offsetX = (rand.nextDouble() - 0.5) * 4.0;
                final offsetY = (rand.nextDouble() - 0.5) * 4.0;

                final left = (6.0 + index * stepX + offsetX).clamp(2.0, maxLeft).toDouble();

                // 奇偶错开形成高低落差：偶数靠上，奇数拉下填满下方空间
                final double isEven = (index % 2 == 0) ? 0.0 : 1.0;
                final double targetTop = (isEven * (maxTop * 0.75)) + 4.0 + offsetY;
                final top = targetTop.clamp(2.0, maxTop).toDouble();

                final angle = (index % 2 == 0 ? -0.10 : 0.09) + (rand.nextDouble() - 0.5) * 0.06;

                return Positioned(
                  left: left,
                  top: top,
                  width: cardW,
                  height: cardH,
                  child: Transform.rotate(
                    angle: angle,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: widget.isNight ? 0.38 : 0.16),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: item.imagePath.startsWith('assets/')
                                  ? Image.asset(item.imagePath, fit: BoxFit.cover)
                                  : Image.file(
                                      File(item.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(color: Colors.grey.shade200),
                                    ),
                            ),
                          ),
                        ),
                        _buildWashiTapeWidget(index),
                        Positioned(
                          top: -4,
                          child: _buildMiniPushPinWidget(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardW = constraints.maxWidth;
        final double boardH = constraints.maxHeight;

        const double refW = 330.0;
        const double refH = 568.0;
        final double scaleX = boardW / refW;
        final double scaleY = boardH / refH;

        final refBounds = Rect.fromLTWH(10, 10, refW - 20, refH - 20);
        final indices = List.generate(count, (i) => i);
        final seed = _activeCollection?.id.hashCode.abs() ?? 42;
        final leaves = TreemapSplitter.computeLeaves(refBounds, indices, seed);

        final double scaleFactor = (boardW / refW).clamp(0.4, 1.0);
        final double outerRadius = (16.0 * scaleFactor).clamp(8.0, 16.0);
        final double innerRadius = (14.0 * scaleFactor).clamp(6.0, 14.0);
        final double gap = (3.0 * scaleFactor).clamp(1.5, 3.5);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ...leaves.map((leaf) {
              final item = displayItems[leaf.index % displayItems.length];
              final cardRect = Rect.fromLTRB(
                leaf.rect.left * scaleX,
                leaf.rect.top * scaleY,
                leaf.rect.right * scaleX,
                leaf.rect.bottom * scaleY,
              ).deflate(gap);

              return Positioned(
                left: cardRect.left,
                top: cardRect.top,
                width: cardRect.width,
                height: cardRect.height,
                child: BouncingButton(
                  onTap: () async {
                    await Navigator.of(context).push(
                      SharedAxisPageRoute(
                        page: PhotoWallPage(
                          isNight: widget.isNight,
                          themeId: 'default',
                        ),
                      ),
                    );
                    _extractPhotoItems();
                  },
                  scaleFactor: 1.05,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // 拍立得主卡片
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(outerRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: widget.isNight ? 0.38 : 0.16),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(innerRadius),
                            child: item.imagePath.startsWith('assets/')
                                ? Image.asset(item.imagePath, fit: BoxFit.cover)
                                : Image.file(
                                    File(item.imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(color: Colors.grey.shade200),
                                  ),
                          ),
                        ),
                      ),

                      // 和纸胶带
                      _buildWashiTapeWidget(leaf.index),

                      // 3D 水晶图钉
                      Positioned(
                        top: -4,
                        child: _buildMiniPushPinWidget(leaf.index),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// 微缩 3D 水晶图钉
  Widget _buildMiniPushPinWidget(int index) {
    const pinColors = [
      Color(0xFFFF8B8B),
      Color(0xFF6BD2B0),
      Color(0xFFFFC04D),
      Color(0xFFB89FE1),
      Color(0xFF88A3EC),
    ];
    final color = pinColors[index % pinColors.length];
    final highlightColor = Color.lerp(color, Colors.white, 0.70)!;
    final shadowColor = Color.lerp(color, const Color(0xFF2C1A1D), 0.50)!;

    const double pinSize = 10.0;

    return SizedBox(
      width: pinSize,
      height: pinSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 1.8,
            left: 1.0,
            child: Container(
              width: pinSize - 2,
              height: pinSize - 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
          Container(
            width: pinSize,
            height: pinSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB0B0B0),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(0.8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 0.78,
                colors: [highlightColor, color, shadowColor],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 2.0,
            left: 2.4,
            child: Container(
              width: 2.8,
              height: 1.8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.all(Radius.elliptical(1.4, 0.9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 微缩手撕和纸胶带
  Widget _buildWashiTapeWidget(int index) {
    const tapeConfigs = [
      _TapeConfig(Color(0xFFE6C594), -0.28, true),
      _TapeConfig(Color(0xFFA3C9A8), 0.30, false),
      _TapeConfig(Color(0xFFF2B5D4), -0.24, true),
      _TapeConfig(Color(0xFFC4B2E6), 0.26, false),
    ];
    final config = tapeConfigs[index % tapeConfigs.length];

    return Positioned(
      top: 2,
      left: config.isLeft ? -2 : null,
      right: !config.isLeft ? -2 : null,
      child: Transform.rotate(
        angle: config.angle,
        child: SizedBox(
          width: 22.0,
          height: 7.5,
          child: CustomPaint(
            painter: WashiTapePainter(color: config.color),
          ),
        ),
      ),
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
          ],
        );
      },
    );
  }
}

class _TapeConfig {
  final Color color;
  final double angle;
  final bool isLeft;

  const _TapeConfig(this.color, this.angle, this.isLeft);
}

/// 手撕撕裂和纸胶带 CustomPainter
class WashiTapePainter extends CustomPainter {
  final Color color;

  WashiTapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    final path = Path();
    const int numTeeth = 4;
    final toothH = size.height / numTeeth;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    for (int i = 0; i < numTeeth; i++) {
      final yMid = (i + 0.5) * toothH;
      final yEnd = (i + 1) * toothH;
      final dx = (i % 2 == 0) ? -2.5 : 0.0;
      path.lineTo(size.width + dx, yMid);
      path.lineTo(size.width, yEnd);
    }

    path.lineTo(0, size.height);

    for (int i = numTeeth - 1; i >= 0; i--) {
      final yMid = (i + 0.5) * toothH;
      final yStart = i * toothH;
      final dx = (i % 2 == 0) ? 2.5 : 0.0;
      path.lineTo(dx, yMid);
      path.lineTo(0, yStart);
    }

    path.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(path.shift(const Offset(0.8, 1.2)), shadowPaint);

    canvas.drawPath(path, paint);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(2, 1), Offset(size.width - 2, 1), shinePaint);

    final fiberPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.3, 2), Offset(size.width * 0.3 + 3, size.height - 2), fiberPaint);
    canvas.drawLine(Offset(size.width * 0.7, 2), Offset(size.width * 0.7 - 3, size.height - 2), fiberPaint);
  }

  @override
  bool shouldRepaint(covariant WashiTapePainter oldDelegate) =>
      color != oldDelegate.color;
}
