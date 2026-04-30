import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

class DiaryFeaturedCard extends StatelessWidget {
  final DiaryEntry entry;
  final bool isNight;

  const DiaryFeaturedCard({
    super.key,
    required this.entry,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    final imagePath = images.isNotEmpty ? images.first['path'] : null;
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isNight ? 0.4 : 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22), // 内圆角稍微小一点，适配边框
        child: Stack(
          children: [
            // Background Image
            if (imagePath != null)
              Positioned.fill(
                child: DiaryUtils.buildImage(imagePath, fit: BoxFit.cover),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isNight
                          ? [const Color(0xFF2C2E35), const Color(0xFF212329)]
                          : [const Color(0xFFF9F7F3), const Color(0xFFF4EFE6)],
                    ),
                  ),
                ),
              ),

            // Left to Right Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Text(
                      DiaryUtils.getFilteredContent(
                        entry.content,
                      ).split('\n').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ArphicKaiti',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Excerpt
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DiaryUtils.getFilteredContent(entry.content),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.6,
                          fontFamily: 'ArphicKaiti',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Tags
                  Row(
                    children: [
                      _buildTag(mood.label, iconPath: mood.iconPath),
                      if (entry.tag != null && entry.tag!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildTag(
                          entry.tag!,
                          icon: Icons.local_florist_rounded,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom: Time + Weather + Location
                  Row(
                    children: [
                      Text(
                        "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArphicKaiti',
                        ),
                      ),
                      if (entry.weather != null &&
                          entry.weather!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.amber.withValues(alpha: 0.9),
                          size: 14,
                        ),
                      ],
                      if (entry.location != null &&
                          entry.location!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.location!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'ArphicKaiti',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Top Right Bookmark (Swallowtail Ribbon)
            Positioned(
              top: 0,
              right: 20,
              child: ClipPath(
                clipper: _BookmarkClipper(),
                child: Container(
                  width: 32,
                  height: 44,
                  color: const Color(0xFFD4A373),
                  padding: const EdgeInsets.only(top: 8),
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Right Circular Image (if multiple images)
            if (images.length > 1)
              Positioned(
                bottom: 20,
                right: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 阴影层
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        // 图片层：增加黑色底色并强制铺满
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black, // 防止加载瞬间或边缘出现白缝
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Transform.scale(
                            scale: 1.05, // 稍微放大一点点，确保完全覆盖边缘
                            child: DiaryUtils.buildImage(
                              images.last['path'],
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        // 边框层：最上层白边
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ],
                    ),
                    // 数量标识 (当图片数量 > 3 时显示)
                    if (images.length > 3)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              '${images.length}',
                              style: const TextStyle(
                                color: Color(0xFFD4A373),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {String? iconPath, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            Image.asset(
              iconPath,
              width: 18,
              height: 18,
            )
          else if (icon != null)
            Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'ArphicKaiti',
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double radius = 3.0; // 圆角半径

    path.moveTo(0, 0);
    // 左边缘向下
    path.lineTo(0, size.height - radius);
    // 左下角圆角
    path.quadraticBezierTo(0, size.height, radius, size.height - 2);
    // 连线到中间切口起点
    path.lineTo(size.width / 2 - radius, size.height * 0.8 + 2);
    // 中间切口圆角
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.8,
      size.width / 2 + radius,
      size.height * 0.8 + 2,
    );
    // 连线到右下角起点
    path.lineTo(size.width - radius, size.height - 2);
    // 右下角圆角
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - radius,
    );
    // 右边缘向上
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
