import 'package:flutter/material.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 极简的静态精灵展示组件
/// 支持展示单张图片，或序列帧图片中的指定某一帧（默认第一帧）
class StaticSprite extends StatelessWidget {
  final String assetPath;
  final double size;
  final int frameCount;
  final int frameIndex;

  const StaticSprite({
    super.key,
    required this.assetPath,
    this.size = 48.0,
    this.frameCount = 1,
    this.frameIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
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

          // 2. 动态装扮图层 (响应全局状态)
          Positioned.fill(
            child: ListenableBuilder(
            listenable: Listenable.merge([
              userState.selectedMascotDecoration,
              userState.selectedGlassesDecoration,
              userState.isGlassesAboveHat,
            ]),
            builder: (context, _) {
              final String? decoPath = userState.selectedMascotDecoration.value;
              final String? glsPath = userState.selectedGlassesDecoration.value;
              final bool isGlassesAbove = userState.isGlassesAboveHat.value;

              final hatLayer = decoPath != null
                  ? _buildDecorationLayer(decoPath, assetPath, size)
                  : const SizedBox.shrink();
              final glassesLayer = glsPath != null
                  ? _buildDecorationLayer(glsPath, assetPath, size)
                  : const SizedBox.shrink();

              return Stack(
                children: isGlassesAbove 
                  ? [hatLayer, glassesLayer] // 眼镜盖住帽子
                  : [glassesLayer, hatLayer], // 帽子盖住眼镜
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDecorationLayer(String path, String mascotPath, double size) {
    return Builder(
      builder: (context) {
        final config = MascotDecoration.getByPath(path);
        final decoConfig = config?.getConfigForCharacter(mascotPath) ?? const MascotDecorationConfig();
        final offset = decoConfig.offset;
        final scale = decoConfig.scale;

        return Positioned.fill(
          child: Transform.translate(
            offset: offset * (size / 200.0),
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
