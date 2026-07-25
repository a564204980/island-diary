import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/treemap_splitter.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/photo_board_decorations.dart';
import 'package:island_diary/features/home/presentation/services/photo_wall_image_cache.dart';

/// 记忆展板缩影相册卡片组件 (对齐 PhotoWallDetailPage 高斯模糊与双重边框样式)
class CollectionBoxCard extends StatelessWidget {
  final PhotoWallCollection collection;
  final bool isDark;
  final Color textColor;
  final List<String> presetPhotos;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onSetActive;

  const CollectionBoxCard({
    super.key,
    required this.collection,
    required this.isDark,
    required this.textColor,
    required this.presetPhotos,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      scaleFactor: 1.04,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // 1. 微缩展板内容渲染区
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: MiniPhotoBoardContent(
                          collection: collection,
                          presetPhotos: presetPhotos,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // 1.5 首页激活状态徽章 Badge (极简通透手帐风)
                    if (collection.isActive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 10,
                                color: Color(0xFF38BDF8),
                              ),
                              SizedBox(width: 3),
                              Text(
                                '首页展示',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 2. 悬浮微型独立气泡 - 左下角标题标签 (Glass Micro Tag)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      right: 44,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.45)
                                    : Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.20)
                                      : Colors.white.withValues(alpha: 0.75),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                collection.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. 悬浮微型独立气泡 - 右下角操作按钮 (Glass Circular Button with RenderBox Anchor)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Builder(
                            builder: (btnContext) {
                              return GestureDetector(
                                onTap: () => _showCardMenu(btnContext),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.45)
                                        : Colors.white.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.20)
                                          : Colors.white.withValues(alpha: 0.75),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.more_horiz_rounded,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      size: 15,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 测量 ... 按钮在屏幕上的物理坐标，使弹窗左边缘与 ... 按钮左边缘 100% 压线对齐，并从按钮内部放缩吐出/吸回
  void _showCardMenu(BuildContext btnContext) {
    HapticFeedback.selectionClick();
    final RenderBox renderBox = btnContext.findRenderObject() as RenderBox;
    final Offset buttonOffset = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;
    final Size screenSize = MediaQuery.of(btnContext).size;

    // 弹窗左边缘 100% 与 ... 按钮左边缘 (buttonOffset.dx) 垂直压线对齐
    final double left = buttonOffset.dx.clamp(12.0, screenSize.width - 175.0);
    final double top = buttonOffset.dy + buttonSize.height + 4;
    const double menuWidth = 165.0;

    showGeneralDialog<String>(
      context: btnContext,
      barrierDismissible: true,
      barrierLabel: 'CardMenu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final CurvedAnimation curve = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.15, end: 1.0).animate(curve),
                alignment: Alignment.topLeft, // 100% 物理锚定在 ... 按钮左上物理圆心
                child: FadeTransition(
                  opacity: anim1,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onSetActive != null)
                            _buildMenuItem(
                              context: context,
                              icon: collection.isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.home_max_rounded,
                              iconColor: collection.isActive
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              label: collection.isActive ? "已设为首页展示" : "设为首页展示",
                              textColor: isDark ? Colors.white : const Color(0xFF1E293B),
                              onTap: () {
                                Navigator.pop(context);
                                if (!collection.isActive) {
                                  onSetActive!();
                                }
                              },
                            ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.edit_rounded,
                            iconColor: isDark ? Colors.white70 : const Color(0xFF1E293B),
                            label: "重命名集合",
                            onTap: () {
                              Navigator.pop(context);
                              onRename();
                            },
                          ),
                          if (!collection.isDefault)
                            _buildMenuItem(
                              context: context,
                              icon: Icons.delete_outline_rounded,
                              iconColor: Colors.redAccent,
                              label: "删除相册集合",
                              textColor: Colors.redAccent,
                              onTap: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 展板微缩 1:1 缩影渲染组件 (100% 使用图2二叉树切分算法 TreemapSplitter)
class MiniPhotoBoardContent extends StatelessWidget {
  final PhotoWallCollection collection;
  final List<String> presetPhotos;
  final bool isDark;

  const MiniPhotoBoardContent({
    super.key,
    required this.collection,
    required this.presetPhotos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 始终渲染实时多图矢量布局（实时感知位置与角度改动，不存磁盘快照）
    return _buildMultiPhotoLayout();
  }


  Widget _buildMultiPhotoLayout() {
    if (collection.photoPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 28,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : const Color(0xFF475569),
            ),
            const SizedBox(height: 6),
            Text(
              "暂无照片",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'LXGWWenKai',
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF334155),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }

    // 在渲染前同步过滤路径，无效路径用预设写真补位（消除白框根源）
    final List<String> effectivePhotos = collection.photoPaths.asMap().entries.map((e) {
      final path = e.value;
      if (path.startsWith('assets/')) return path;
      if (File(path).existsSync()) return path;
      return _defaultFallbackBgs[e.key.abs() % _defaultFallbackBgs.length];
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardW = constraints.maxWidth;
        final boardH = constraints.maxHeight;

        if (effectivePhotos.isEmpty) return const SizedBox.shrink();

        final count = effectivePhotos.length;
        final bool isTreemap = collection.layoutMode == 'treemap';

        if (isTreemap) {
          // 100% 对应编辑页二叉切分/手帐切块模式 (Treemap)，使用相同的 randomSeed (collection.id.hashCode.abs())
          final seed = collection.id.hashCode.abs();
          final bounds = Rect.fromLTWH(6.0, 8.0, math.max(10.0, boardW - 12.0), math.max(10.0, boardH - 32.0));
          final indices = List.generate(count, (i) => i);
          final leaves = TreemapSplitter.computeLeaves(bounds, indices, seed);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: leaves.map((leaf) {
              final path = effectivePhotos[leaf.index % effectivePhotos.length];
              const gap = 1.5;
              final cardRect = leaf.rect.deflate(gap);

              return Positioned(
                left: cardRect.left,
                top: cardRect.top,
                width: cardRect.width,
                height: cardRect.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1.5))],
                        ),
                        padding: const EdgeInsets.all(2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildImageWidget(path, leaf.index),
                        ),
                      ),
                    ),
                    _buildMiniWashiTape(leaf.index),
                    Positioned(top: -4, child: _buildMiniPushPin(leaf.index)),
                  ],
                ),
              );
            }).toList(),
          );
        }

        // 散落/自由拖拽模式：与编辑页 PhotoBoardCanvas (图1) 100% 精确按比例对齐
        const double refW = 330.0;
        const double refH = 568.0;

        const int cols = 3;
        const int maxRows = 3;

        final double scaleFactor = boardW / refW;

        final maxAvailableW = (refW - 24.0) / cols;
        final baseCardW = (maxAvailableW * 0.90).clamp(48.0, 96.0);
        final baseCardH = (baseCardW * 1.15).clamp(55.0, 110.0);

        final colStep = (refW - baseCardW - 24.0) / math.max(1, cols - 1);
        final rowStep = (refH - baseCardH - 24.0) / math.max(1, maxRows - 1);

        final bool hasCustomPos = collection.customPositions != null && collection.customPositions!.isNotEmpty;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: List.generate(count, (index) {
            final path = effectivePhotos[index];
            final id = 'photo_$index';

            final double userScale = collection.customScales?[id] ?? 1.0;
            final double cardW = baseCardW * userScale * scaleFactor;
            final double cardH = baseCardH * userScale * scaleFactor;

            double left;
            double top;
            double angle;

            if (hasCustomPos && collection.customPositions!.containsKey(id)) {
              final posList = collection.customPositions![id]!;
              left = (posList[0] / refW) * boardW;
              top = (posList[1] / refH) * boardH;
              angle = collection.customAngles?[id] ?? 0.0;
            } else {
              final seed = collection.id.hashCode.abs() + id.hashCode;
              final rand = math.Random(seed);
              final col = id.hashCode.abs() % cols;
              final row = (id.hashCode.abs() ~/ cols) % maxRows;
              final offsetX = (rand.nextDouble() - 0.5) * 12.0;
              final offsetY = (rand.nextDouble() - 0.5) * 12.0;

              final defaultLeft = (16.0 + col * colStep + offsetX)
                  .clamp(16.0, refW - baseCardW - 16.0);
              final defaultTop = (16.0 + row * rowStep + offsetY)
                  .clamp(16.0, refH - baseCardH - 16.0);

              left = (defaultLeft / refW) * boardW;
              top = (defaultTop / refH) * boardH;

              angle = collection.customAngles?[id] ??
                  ((rand.nextDouble() - 0.5) * 0.32);
            }

            return Positioned(
              left: left.clamp(0.0, math.max(0.0, boardW - cardW)),
              top: top.clamp(0.0, math.max(0.0, boardH - cardH)),
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
                          borderRadius: BorderRadius.circular(16 * scaleFactor * userScale),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1.5))],
                        ),
                        padding: const EdgeInsets.all(2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14 * scaleFactor * userScale),
                          child: _buildImageWidget(path, index),
                        ),
                      ),
                    ),
                    _buildMiniWashiTape(index),
                    Positioned(top: -4 * scaleFactor, child: _buildMiniPushPin(index)),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// 微缩 3D 水晶图钉 (直径 10px，与图2 1:1)
  Widget _buildMiniPushPin(int index) {
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
          // 斜向软阴影
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

          // 金属座圈
          Container(
            width: pinSize,
            height: pinSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB0B0B0),
            ),
          ),

          // 水晶半球主体
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

          // 顶部小高光点
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

  /// 微缩手撕和纸胶带 (1:1 响应编辑页 photoId 取余，保持左右贴角位置绝对一致)
  Widget _buildMiniWashiTape(int index) {
    const tapeConfigs = [
      _MiniTapeConfig(Color(0xFFE6C594), -0.28, true),
      _MiniTapeConfig(Color(0xFFA3C9A8), 0.30, false),
      _MiniTapeConfig(Color(0xFFF2B5D4), -0.24, true),
      _MiniTapeConfig(Color(0xFFC4B2E6), 0.26, false),
    ];
    final String photoId = 'photo_$index';
    final config = tapeConfigs[photoId.hashCode.abs() % tapeConfigs.length];

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

  static const List<String> _defaultFallbackBgs = [
    'assets/images/home_card/me_day.jpg',
    'assets/images/home_card/me_night.jpg',
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

  Widget _buildImageWidget(String path, int index) {
    /// 统一淡入包裹，让图片从透明浮现而不是突然出现（与首页卡片保持一致）
    Widget withFadeIn(Widget child) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: child,
      );
    }

    Widget buildErrorFallback() {
      final String fallbackPath = _defaultFallbackBgs[index.abs() % _defaultFallbackBgs.length];
      return withFadeIn(Image.asset(
        fallbackPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ));
    }

    // 1. 优先尝试从全局内存字节高速缓存获取 (0 帧解码等待)
    var cachedBytes = PhotoWallImageCache.get(path);
    if (cachedBytes == null && !path.startsWith('assets/')) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          cachedBytes = file.readAsBytesSync();
          PhotoWallImageCache.put(path, cachedBytes);
        }
      } catch (_) {}
    }

    if (cachedBytes != null) {
      return withFadeIn(Image.memory(
        cachedBytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => buildErrorFallback(),
      ));
    }

    if (path.startsWith('assets/')) {
      return withFadeIn(Image.asset(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => buildErrorFallback(),
      ));
    }

    return buildErrorFallback();
  }
}

class _MiniTapeConfig {
  final Color color;
  final double angle;
  final bool isLeft;

  const _MiniTapeConfig(this.color, this.angle, this.isLeft);
}
