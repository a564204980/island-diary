import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 交互式贴纸控件：支持关闭、旋转、缩放、平移
class InteractiveSticker extends StatefulWidget {
  final StickerBlock block;
  final bool isSelected; // 是否处于选中编辑状态
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onTap; // 点击贴纸选中
  final double scrollOffset; // 当前的滚动偏移，用于辅助计算显示位置

  const InteractiveSticker({
    super.key,
    required this.block,
    required this.isSelected,
    required this.onRemove,
    required this.onChanged,
    required this.onTap,
    this.scrollOffset = 0,
  });

  @override
  State<InteractiveSticker> createState() => _InteractiveStickerState();
}

class _InteractiveStickerState extends State<InteractiveSticker> {
  // 基础显示大小
  final double _baseSize = 150.0;

  // 计算角度算法
  double _calculateAngle(Offset position, Offset center) {
    return math.atan2(position.dy - center.dy, position.dx - center.dx);
  }

  // 计算距离算法
  double _calculateDistance(Offset position, Offset center) {
    return (position - center).distance;
  }

  @override
  Widget build(BuildContext context) {
    // 使用固定的容器大小，避免缩放时由于容器尺寸变化导致的中心点抖动
    const double totalSize = 600.0; 
    
    // 增加一定的边界补偿，处理被包裹在 Positioned 容器中的偏移
    final double topOffset = 80.0; // 与主页面裁剪区域对齐
    
    // 算法修正：确保 widget.block.dx/dy 对应的是贴纸原始尺寸的左上角位置
    final double stickerCenterX = widget.block.dx + (_baseSize / 2);
    final double stickerCenterY = widget.block.dy + (_baseSize / 2);
    
    final double displayX = stickerCenterX - (totalSize / 2);
    // 减去 topOffset，因为 Positioned.fill(top: topOffset) 会让子组件的 0 点下移
    final double displayY = (stickerCenterY - (totalSize / 2)) - widget.scrollOffset - topOffset;
    
    return Positioned(
      left: displayX,
      top: displayY,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = const Offset(totalSize / 2, totalSize / 2);

          return Container(
            width: totalSize,
            height: totalSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. 贴纸主体：支持拖拽移动与点击选中
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // 确保透明区域也能响应点击
                  onTap: widget.onTap,
                  onPanUpdate: widget.isSelected
                      ? (details) {
                        setState(() {
                          widget.block.dx += details.delta.dx;
                          widget.block.dy += details.delta.dy;
                        });
                        widget.onChanged();
                      }
                      : null,
                  child: Transform.rotate(
                    angle: widget.block.rotation,
                    child: Transform.scale(
                      scale: widget.block.scale,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // 虚线框（仅选中时显示）
                          if (widget.isSelected)
                            CustomPaint(
                              size: Size(_baseSize, _baseSize),
                              painter: DashedRectPainter(
                                color: const Color(0xFF8B5E3C).withValues(alpha: 0.4),
                              ),
                            ),
                          // 透明贴纸图片：固定 Widget 尺寸，靠 Transform.scale 缩放，彻底解决闪烁问题
                          DiaryUtils.buildImage(
                            widget.block.path,
                            width: _baseSize,
                            height: _baseSize,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. 控制按钮组（仅选中时显示）
                if (widget.isSelected) ...[
                  // 关闭按钮 (左上)
                  _buildControlBtn(
                    angle: widget.block.rotation + math.pi * 1.25,
                    distance: (_baseSize * widget.block.scale / 2) * math.sqrt(2),
                    totalSize: totalSize,
                    icon: Icons.close_rounded,
                    onTap: widget.onRemove,
                  ),

                  // 旋转按钮 (右上)
                  _buildControlBtn(
                    angle: widget.block.rotation + math.pi * 1.75,
                    distance: (_baseSize * widget.block.scale / 2) * math.sqrt(2),
                    totalSize: totalSize,
                    icon: Icons.refresh_rounded,
                    onPanUpdate: (details) {
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final localPos = renderBox.globalToLocal(details.globalPosition);
                      final angle = _calculateAngle(localPos, center);
                      setState(() {
                        widget.block.rotation = angle - (math.pi * 1.75);
                      });
                      widget.onChanged();
                    },
                  ),

                  // 缩放按钮 (右下)
                  _buildControlBtn(
                    angle: widget.block.rotation + math.pi * 0.25,
                    distance: (_baseSize * widget.block.scale / 2) * math.sqrt(2),
                    totalSize: totalSize,
                    icon: Icons.open_in_full_rounded,
                    onPanUpdate: (details) {
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final localPos = renderBox.globalToLocal(details.globalPosition);
                      final distance = _calculateDistance(localPos, center);
                      setState(() {
                        final double newScale = (distance / (_baseSize / 2 * math.sqrt(2))).clamp(0.4, 3.0);
                        widget.block.scale = newScale;
                      });
                      widget.onChanged();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建控制按钮
  Widget _buildControlBtn({
    required double angle,
    required double distance,
    required double totalSize,
    required IconData icon,
    VoidCallback? onTap,
    GestureDragUpdateCallback? onPanUpdate,
  }) {
    const double btnSize = 28.0; // 稍微调大一点按钮，方便点击
    return Positioned(
      left: (distance * math.cos(angle)) + (totalSize / 2) - (btnSize / 2),
      top: (distance * math.sin(angle)) + (totalSize / 2) - (btnSize / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanUpdate: onPanUpdate,
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B5E3C).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Transform.flip(
            flipX: icon == Icons.open_in_full_rounded,
            child: Icon(icon, size: 16, color: const Color(0xFF8B5E3C)),
          ),
        ),
      ),
    );
  }
}

/// 绘制虚线框
class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 3.5;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
