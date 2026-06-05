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
  final bool ignoreDecorations;

  const StaticSprite({
    super.key,
    required this.assetPath,
    this.size = 48.0,
    this.frameCount = 1,
    this.frameIndex = 0,
    this.ignoreDecorations = false,
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

                  // 检查是否戴了帽子（selectedMascotDecoration不为空）
                  String targetPath = assetPath;
                  final userState = UserState();
                  final selectedDecoPath = userState.selectedMascotDecoration.value;
                  final hasDeco = !ignoreDecorations && selectedDecoPath != null && selectedDecoPath.isNotEmpty;
                  if (hasDeco && targetPath.contains('marshmallow')) {
                    final deco = MascotDecoration.getByPath(selectedDecoPath);
                    final isHat = deco?.category == MascotDecorationCategory.hat;
                    final keepEars = deco?.keepEars ?? false;
                    if (isHat && !keepEars) {
                      targetPath = targetPath.replaceAll('.png', '_noEars.png');
                    }
                  }

                  return FittedBox(
                    fit: BoxFit.none,
                    alignment: Alignment(xOffset, 0.0),
                    child: SizedBox(
                      width: size * frameCount,
                      height: size,
                      child: Image.asset(
                        targetPath,
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
          if (!ignoreDecorations)
            Positioned.fill(
              child: ListenableBuilder(
              listenable: Listenable.merge([
                userState.selectedMascotDecoration,
                userState.selectedGlassesDecoration,
                userState.selectedEarringDecoration,
                userState.isGlassesAboveHat,
              ]),
              builder: (context, _) {
                final String? decoPath = userState.selectedMascotDecoration.value;
                final String? glsPath = userState.selectedGlassesDecoration.value;
                final String? earPath = userState.selectedEarringDecoration.value;
                final bool isGlassesAbove = userState.isGlassesAboveHat.value;

                final earDeco = MascotDecoration.getByPath(earPath);
                final earringLayer = earDeco != null
                    ? _buildEarringLayer(earDeco, assetPath, size)
                    : const SizedBox.shrink();

                final deco = MascotDecoration.getByPath(decoPath);
                final isEarring = deco?.category == MascotDecorationCategory.face;
                final isOther = deco?.category == MascotDecorationCategory.other;
                final earringLegacyLayer = (isEarring && deco != null)
                    ? _buildEarringLayer(deco, assetPath, size)
                    : const SizedBox.shrink();

                final hatLayer = (!isEarring && !isOther && decoPath != null)
                    ? _buildDecorationLayer(decoPath, assetPath, size)
                    : const SizedBox.shrink();
                final glassesLayer = glsPath != null
                    ? _buildDecorationLayer(glsPath, assetPath, size)
                    : const SizedBox.shrink();

                return Stack(
                  children: isGlassesAbove 
                    ? [earringLayer, earringLegacyLayer, hatLayer, glassesLayer] // 耳饰 -> 帽子 -> 眼镜
                    : [earringLayer, earringLegacyLayer, glassesLayer, hatLayer], // 耳饰 -> 眼镜 -> 帽子
                );
              },
            ),
          ),
      ],
    ),
  );
}

  Widget _buildEarringLayer(MascotDecoration deco, String mascotPath, double size) {
    return Builder(
      builder: (context) {
        final decoConfig = deco.getConfigForCharacter(mascotPath);
        
        final leftPath = deco.leftPath ?? deco.path;
        final leftOffset = decoConfig.leftOffset ?? decoConfig.offset;
        final leftScale = decoConfig.leftScale ?? decoConfig.scale;

        final rightPath = deco.rightPath ?? deco.path;
        final rightOffset = decoConfig.rightOffset ?? decoConfig.offset;
        final rightScale = decoConfig.rightScale ?? decoConfig.scale;

        return Stack(
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: leftOffset * (size / 200.0),
                child: Transform.scale(
                  scale: leftScale,
                  child: Image.asset(
                    leftPath,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: rightOffset * (size / 200.0),
                child: Transform.scale(
                  scale: rightScale,
                  child: Image.asset(
                    rightPath,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
