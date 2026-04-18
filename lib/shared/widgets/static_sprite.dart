import 'package:flutter/material.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';

/// 极简的静态精灵展示组件
/// 支持展示单张图片，或序列帧图片中的指定某一帧（默认第一帧）
class StaticSprite extends StatelessWidget {
  final String assetPath;
  final String? decorationPath; // 新增：装扮路径
  final double size;
  final int frameCount;
  final int frameIndex;

  const StaticSprite({
    super.key,
    required this.assetPath,
    this.decorationPath,
    this.size = 48.0,
    this.frameCount = 1,
    this.frameIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 1. 基础角色层
          Positioned.fill(
            child: ClipRect(
              child: Builder(
                builder: (context) {
                  final int index = frameIndex.clamp(0, frameCount - 1);
                  final double xOffset = frameCount <= 1
                      ? 0.0
                      : -1.0 + 2.0 * index / (frameCount - 1);

                  return FittedBox(
                    fit: BoxFit.none,
                    alignment: Alignment(xOffset, 0.0),
                    child: SizedBox(
                      width: size * frameCount,
                      height: size,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. 装扮叠加层
          if (decorationPath != null)
            Builder(
              builder: (context) {
                final config = MascotDecoration.getByPath(decorationPath);
                final decoConfig = config?.getConfigForCharacter(assetPath) ?? const MascotDecorationConfig();
                final offset = decoConfig.offset;
                final scale = decoConfig.scale;

                return Positioned.fill(
                  child: Transform.translate(
                    // 将 Offset 与当前 size 挂钩，实现等比例位移
                    // 基准值设为 200 (即预览页的 size)，确保用户在预览页调好的位置在全站同步
                    offset: offset * (size / 200.0),
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        decorationPath!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
