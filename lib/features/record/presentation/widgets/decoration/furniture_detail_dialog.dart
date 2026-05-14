import 'package:flutter/material.dart';
import '../../../domain/models/furniture_item.dart';
import '../furniture_sprite.dart';

class FurnitureDetailDialog extends StatelessWidget {
  final FurnitureItem item;
  final VoidCallback onPlace;

  const FurnitureDetailDialog({
    super.key,
    required this.item,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 主体容器
          Container(
            width: 260, // 缩小总宽度
            decoration: BoxDecoration(
              color: const Color(0xFFFEF4D1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8D4B4), width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 图片展示框
                  Container(
                    width: 180, // 缩小展示框
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE8C4A0).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        _buildCornerDecor(top: 6, left: 6, rotation: 0),
                        _buildCornerDecor(top: 6, right: 6, rotation: 1.57),
                        _buildCornerDecor(bottom: 6, left: 6, rotation: 4.71),
                        _buildCornerDecor(bottom: 6, right: 6, rotation: 3.14),
                        
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: AspectRatio(
                              aspectRatio: item.intrinsicWidth / item.intrinsicHeight,
                              child: FurnitureSprite(item: item),
                            ),
                          ),
                        ),
                        
                        // 数量角标
                        Positioned(
                          bottom: -8,
                          right: -8,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF4D1),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4A373), width: 2.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: Color(0xFF8B4513),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 2. 名称
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 18, // 缩小字号
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 3. 标签 (风格)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF87CEEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.style.isEmpty ? '常规' : item.style,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 4. 描述
                  Text(
                    item.description.isEmpty ? '常规的${item.name}' : item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8D6E63),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 5. 摆放按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onPlace();
                    },
                    child: Container(
                      width: 130,
                      height: 44, // 缩小按钮
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF9C7A1), Color(0xFFE7AD84)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF8B4513), width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B4513).withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '摆放',
                        style: TextStyle(
                          color: Color(0xFF5D4037),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 关闭按钮 (右上角 X)
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
          
          // 收藏按钮 (左下角书签)
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                color: Color(0xFF8B4513),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDecor({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double rotation,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotation,
        child: const Icon(
          Icons.auto_awesome_mosaic_rounded, // 临时使用这个图标作为装饰角
          size: 14,
          color: Color(0xFFD4A373),
        ),
      ),
    );
  }
}
