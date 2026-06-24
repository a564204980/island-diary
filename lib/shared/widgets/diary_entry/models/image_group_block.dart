import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';

/// 临时的渲染容器块，用于在编辑器或浏览页中，把连续的 ImageBlock 合并为一个拼图渲染。
/// 该块为纯内存块，保存时会还原为独立的 ImageBlock，不参与序列化/反序列化。
class ImageGroupBlock extends DiaryBlock {
  final List<ImageBlock> images;

  ImageGroupBlock(this.images, {String? id}) : super(id: id ?? images.map((img) => img.id).join('_'));

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'image_group',
    'images': images.map((img) => img.toMap()).toList(),
  };

  /// 预处理块列表：在混排模式且开启智能排版时，将连续的 ImageBlock 归并为一个 ImageGroupBlock。
  /// 自动忽略夹在图片中间的空文本块，防止它们打断连续图片的合并排版。
  static List<DiaryBlock> preprocess(List<DiaryBlock> originalBlocks, {required bool isMixedLayout, required bool isImageGrid}) {
    if (!isMixedLayout || !isImageGrid) {
      return originalBlocks;
    }

    final List<DiaryBlock> result = [];
    List<ImageBlock> tempImages = [];
    List<DiaryBlock> pendingEmptyTextBlocks = [];

    for (final block in originalBlocks) {
      if (block is ImageBlock) {
        // 遇到图片，直接忽略图片前面的空文本块，让图片保持连续合并
        pendingEmptyTextBlocks.clear();
        tempImages.add(block);
      } else if (block is TextBlock && block.controller.text.trim().isEmpty) {
        // 暂存空文本块，不立刻打断图片连续性
        pendingEmptyTextBlocks.add(block);
      } else {
        // 遇到有实义内容的块，打断连续性，恢复图片组和积压的空文本块
        if (tempImages.isNotEmpty) {
          if (tempImages.length == 1) {
            result.add(tempImages.first);
          } else {
            result.add(ImageGroupBlock(List.from(tempImages)));
          }
          tempImages.clear();
        }
        result.addAll(pendingEmptyTextBlocks);
        pendingEmptyTextBlocks.clear();
        result.add(block);
      }
    }

    if (tempImages.isNotEmpty) {
      if (tempImages.length == 1) {
        result.add(tempImages.first);
      } else {
        result.add(ImageGroupBlock(List.from(tempImages)));
      }
    }
    result.addAll(pendingEmptyTextBlocks);

    return result;
  }
}
