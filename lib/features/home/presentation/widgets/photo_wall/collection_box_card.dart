import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/treemap_splitter.dart';
import 'package:island_diary/features/home/presentation/pages/photo_wall_detail_page.dart';

/// 记忆展板缩影相册卡片组件 (对齐 PhotoWallDetailPage 高斯模糊与双重边框样式)
class CollectionBoxCard extends StatelessWidget {
  final PhotoWallCollection collection;
  final bool isDark;
  final Color textColor;
  final List<String> presetPhotos;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const CollectionBoxCard({
    super.key,
    required this.collection,
    required this.isDark,
    required this.textColor,
    required this.presetPhotos,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
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
            padding: const EdgeInsets.all(7.0), // 图1保留：7px 立体双重外框
            decoration: BoxDecoration(
              // 图2高斯模糊透光外框：透光晶莹玻璃与柔光磨砂边框
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.60),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              // 图1保留：内层画布边框与柔和透光底色
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.40),
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // 1. 微缩展板内容渲染区 (100% 采用图2二叉树切分算法，贯穿全高 100%)
                    Positioned.fill(
                      child: MiniPhotoBoardContent(
                        collection: collection,
                        presetPhotos: presetPhotos,
                        isDark: isDark,
                      ),
                    ),

                    // 2. 悬浮在照片与软木展板顶层的半透明标题栏 (Floating Overlay Title Bar)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: isDark ? 0.85 : 0.65),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                collection.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onSelected: (val) {
                                if (val == 'rename') {
                                  onRename();
                                } else if (val == 'delete') {
                                  onDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  height: 36,
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF1E293B)),
                                      const SizedBox(width: 6),
                                      Text("重命名", style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                    ],
                                  ),
                                ),
                                if (!collection.isDefault)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    height: 36,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                        SizedBox(width: 6),
                                        Text("删除集合", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
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
    final List<String> effectivePhotos =
        collection.photoPaths.isNotEmpty ? collection.photoPaths : presetPhotos;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardW = constraints.maxWidth;
        final boardH = constraints.maxHeight;

        if (effectivePhotos.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = effectivePhotos.length;

        // 检查集合是否设置为散落手帐模式 (Scatter Mode)
        final isScatter = collection.layoutMode == 'scatter';

        if (isScatter) {
          const int cols = 3;
          const int maxRows = 3;

          final maxAvailableW = (boardW - 12.0) / cols;
          final cardW = (maxAvailableW * 0.90).clamp(24.0, 72.0);
          final cardH = (cardW * 1.15).clamp(28.0, 85.0);

          final rowStep = (boardH - cardH - 12.0) / math.max(1, maxRows - 1);
          final colStep = (boardW - cardW - 12.0) / math.max(1, cols - 1);

          const double refW = 330.0;
          const double refH = 568.0;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: List.generate(count, (index) {
              final path = effectivePhotos[index];
              final id = 'photo_$index';

              double left;
              double top;
              double angle;

              if (collection.customPositions != null && collection.customPositions!.containsKey(id)) {
                final posList = collection.customPositions![id]!;
                left = (posList[0] / refW) * (boardW - 12.0) + 6.0;
                top = (posList[1] / refH) * (boardH - 32.0) + 8.0;
              } else {
                final rand = math.Random(42 + id.hashCode);
                final col = id.hashCode.abs() % cols;
                final row = (id.hashCode.abs() ~/ cols) % maxRows;
                final offsetX = (rand.nextDouble() - 0.5) * 12.0;
                final offsetY = (rand.nextDouble() - 0.5) * 12.0;
                left = (6.0 + col * colStep + offsetX * (boardW / refW)).clamp(6.0, boardW - cardW - 6.0);
                top = (8.0 + row * rowStep + offsetY * (boardH / refH)).clamp(8.0, boardH - cardH - 24.0);
              }

              angle = collection.customAngles?[id] ??
                  ((math.Random(42 + id.hashCode).nextDouble() - 0.5) * 0.32);

              return Positioned(
                left: left.clamp(6.0, math.max(6.0, boardW - cardW - 6.0)),
                top: top.clamp(8.0, math.max(8.0, boardH - cardH - 24.0)),
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
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: _buildImageWidget(path, index),
                          ),
                        ),
                      ),
                      _buildMiniWashiTape(index),
                      Positioned(
                        top: -4,
                        child: _buildMiniPushPin(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        }

        // 100% 采用与图2 (PhotoWallDetailPage) 完全相同的二叉树切分算法 (TreemapSplitter)
        final bounds = Rect.fromLTWH(6.0, 8.0, math.max(10.0, boardW - 12.0), math.max(10.0, boardH - 32.0));
        final indices = List.generate(count, (i) => i);
        // 使用 42 作为固定 seed，与图2二叉树切分默认 seed 保持 1:1 对齐
        final leaves = TreemapSplitter.computeLeaves(bounds, indices, 42);

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
                  // 相片拍立得白框主体 (使用 Positioned.fill 强制撑满 100% 矩形空间，与图2 1:1)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: _buildImageWidget(path, leaf.index),
                      ),
                    ),
                  ),

                  // 复古手撕和纸胶带 (斜贴于照片顶部角角，与图2 1:1)
                  _buildMiniWashiTape(leaf.index),

                  // 3D 水晶图钉 (与图2 1:1)
                  Positioned(
                    top: -4,
                    child: _buildMiniPushPin(leaf.index),
                  ),
                ],
              ),
            );
          }).toList(),
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

  /// 微缩手撕和纸胶带
  Widget _buildMiniWashiTape(int index) {
    const tapeConfigs = [
      _MiniTapeConfig(Color(0xFFE6C594), -0.28, true),
      _MiniTapeConfig(Color(0xFFA3C9A8), 0.30, false),
      _MiniTapeConfig(Color(0xFFF2B5D4), -0.24, true),
      _MiniTapeConfig(Color(0xFFC4B2E6), 0.26, false),
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

  Widget _buildImageWidget(String path, int index) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          presetPhotos[index % presetPhotos.length],
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          presetPhotos[index % presetPhotos.length],
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      presetPhotos[index % presetPhotos.length],
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _MiniTapeConfig {
  final Color color;
  final double angle;
  final bool isLeft;

  const _MiniTapeConfig(this.color, this.angle, this.isLeft);
}
