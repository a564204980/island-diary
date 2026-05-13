import 'package:flutter/material.dart';

class WallPatternThumbnail extends StatelessWidget {
  final String itemId;
  final double width;
  final double height;
  final String? imagePath; // 新增 imagePath 参数

  const WallPatternThumbnail({
    super.key,
    required this.itemId,
    this.width = 100,
    this.height = 100,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // 按照用户的明确要求：直接使用配置中的真实图片作为缩略图
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

    // 回退方案（如果不提供路径，显示一个占位符）
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.wallpaper, color: Colors.grey),
    );
  }
}
