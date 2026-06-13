import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';

class DiaryImageCollage extends StatelessWidget {
  final List<String> imagePaths;
  final double spacing;
  final double borderRadius;
  final Function(int)? onTapImage;
  final Function(int)? onDeleteImage;

  const DiaryImageCollage({
    super.key,
    required this.imagePaths,
    this.spacing = 8.0,
    this.borderRadius = 12.0,
    this.onTapImage,
    this.onDeleteImage,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    switch (imagePaths.length) {
      case 1:
        return _buildOneImage();
      case 2:
        return _buildTwoImages();
      case 3:
        return _buildThreeImages();
      case 4:
        return _buildFourImages();
      case 5:
        return _buildFiveImages();
      default:
        // 如果多于5张，默认展示5张的布局，或者交由外部降级处理
        return _buildFiveImages();
    }
  }

  Widget _buildImageItem(int index) {
    final path = imagePaths[index];
    return AnimatedDeleteWrapper(
      onDelete: () => onDeleteImage?.call(index),
      builder: (context, startDelete) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => onTapImage?.call(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
              ),
            ),
            if (onDeleteImage != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: startDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 1 张图片：大图展示 (比例 3:2)
  Widget _buildOneImage() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: _buildImageItem(0),
    );
  }

  // 2 张图片：左右等分 (比例 3:4)
  Widget _buildTwoImages() {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.75,
            child: _buildImageItem(0),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.75,
            child: _buildImageItem(1),
          ),
        ),
      ],
    );
  }

  // 3 张图片：左侧一大 (2/3宽)，右侧上下两小 (1/3宽)
  Widget _buildThreeImages() {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左大图
          Expanded(
            flex: 2,
            child: _buildImageItem(0),
          ),
          SizedBox(width: spacing),
          // 右侧两张堆叠小图
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildImageItem(1),
                ),
                SizedBox(height: spacing),
                Expanded(
                  child: _buildImageItem(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4 张图片：左侧一大 (2/3宽)，右侧上下三小 (1/3宽)
  Widget _buildFourImages() {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左大图
          Expanded(
            flex: 2,
            child: _buildImageItem(0),
          ),
          SizedBox(width: spacing),
          // 右侧三张堆叠小图
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildImageItem(1),
                ),
                SizedBox(height: spacing),
                Expanded(
                  child: _buildImageItem(2),
                ),
                SizedBox(height: spacing),
                Expanded(
                  child: _buildImageItem(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5 张图片：图 1 同款 (上部为左大右三小，下部为底部通栏长图)
  Widget _buildFiveImages() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 上部：左侧大图 + 右侧三张堆叠小图
        AspectRatio(
          aspectRatio: 1.1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左大图
              Expanded(
                flex: 2,
                child: _buildImageItem(0),
              ),
              SizedBox(width: spacing),
              // 右侧三张堆叠小图
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildImageItem(1),
                    ),
                    SizedBox(height: spacing),
                    Expanded(
                      child: _buildImageItem(2),
                    ),
                    SizedBox(height: spacing),
                    Expanded(
                      child: _buildImageItem(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing),
        // 下部：底部跨栏长图 (比例 3:1)
        AspectRatio(
          aspectRatio: 3.0,
          child: _buildImageItem(4),
        ),
      ],
    );
  }
}
