import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';

/// 小红书/iOS 记忆相册风照片墙集合卡片组件 (Apple Memories / RedBook Style Album Card)
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
    // 暖米白卡纸外壳配色 (日间模式温暖手帐米白，暗夜模式高端墨蓝)
    final Color cardBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFAFAFA);
    final Color cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);

    return BouncingButton(
      onTap: onTap,
      scaleFactor: 1.04, // 轻灵微弹触感
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardBorderColor,
            width: 1.0,
          ),
          boxShadow: [
            // 极简高级弥散软阴影 (Soft Ambient Elevation)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 照片墙满幅展示区 (核心美图，无任何按键遮挡)
            Expanded(
              child: Center(
                child: MiniPhotoStack(
                  photoPaths: collection.photoPaths,
                  presetPhotos: presetPhotos,
                  isDark: isDark,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 2. 底部标题与设置/更多菜单
            Row(
              children: [
                Expanded(
                  child: Text(
                    collection.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  onSelected: (val) {
                    if (val == 'rename') {
                      onRename();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('修改名称', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    if (!collection.isDefault)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('删除集合', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 拍立得大尺寸写真重叠组件 (小红书/iOS 风格，满幅震撼美感)
class MiniPhotoStack extends StatelessWidget {
  final List<String> photoPaths;
  final List<String> presetPhotos;
  final bool isDark;

  const MiniPhotoStack({
    super.key,
    required this.photoPaths,
    required this.presetPhotos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final int displayCount = math.min(photoPaths.length, 3);
    final List<double> angles = [-0.12, 0.10, -0.03];
    final List<Offset> offsets = [
      const Offset(-20, -4),
      const Offset(20, 6),
      const Offset(0, 0),
    ];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: List.generate(displayCount, (index) {
        final path = photoPaths[index % photoPaths.length];
        final angle = angles[index % angles.length];
        final offset = offsets[index % offsets.length];

        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 102,
              height: 130,
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildImageWidget(path, index),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildImageWidget(String path, int index) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          presetPhotos[index % presetPhotos.length],
          fit: BoxFit.cover,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          presetPhotos[index % presetPhotos.length],
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      presetPhotos[index % presetPhotos.length],
      fit: BoxFit.cover,
    );
  }
}
