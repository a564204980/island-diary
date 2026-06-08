import 'dart:async';
import 'package:flutter/material.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 极简的静态精灵展示组件
/// 支持展示单张图片，或序列帧图片中的指定某一帧（默认第一帧）
/// 升级为 StatefulWidget 以支持定时进行生动的眨眼帧动画播放
class StaticSprite extends StatefulWidget {
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
  State<StaticSprite> createState() => _StaticSpriteState();
}

class _StaticSpriteState extends State<StaticSprite> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _blinkController.addListener(() {
      setState(() {});
    });
    // 6秒重复一次播放眨眼动画
    _blinkTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted && (widget.assetPath.contains('marshmallow.png') || widget.assetPath.contains('marshmallow_noEars.png'))) {
        _blinkController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // 1. 基础角色层
          Positioned.fill(
            child: Builder(
              builder: (context) {
                // 检查是否戴了帽子（selectedMascotDecoration不为空）
                String targetPath = widget.assetPath;
                final userState = UserState();
                final selectedDecoPath = userState.selectedMascotDecoration.value;
                final hasDeco = !widget.ignoreDecorations && selectedDecoPath != null && selectedDecoPath.isNotEmpty;
                if (hasDeco && targetPath.contains('marshmallow')) {
                  final deco = MascotDecoration.getByPath(selectedDecoPath);
                  final isHat = deco?.category == MascotDecorationCategory.hat;
                  final keepEars = deco?.keepEars ?? false;
                  if (isHat && !keepEars) {
                    targetPath = targetPath.replaceAll('.png', '_noEars.png');
                  }
                }

                String currentAssetPath = targetPath;
                int currentFrameCount = widget.frameCount;
                int currentFrameIndex = widget.frameIndex;

                final bool isYunzhiWithEars = targetPath.contains('marshmallow.png') && !targetPath.contains('_noEars.png');
                final bool isYunzhiNoEars = targetPath.contains('marshmallow_noEars.png');
                if (_blinkController.isAnimating) {
                  if (isYunzhiWithEars) {
                    final int frame = (_blinkController.value * 5).floor().clamp(0, 4);
                    currentAssetPath = 'assets/images/emoji/animation/1/blink/1-${frame + 1}.png';
                    currentFrameCount = 1;
                    currentFrameIndex = 0;
                  } else if (isYunzhiNoEars) {
                    final int frame = (_blinkController.value * 5).floor().clamp(0, 4);
                    currentAssetPath = 'assets/images/emoji/animation/1/blink/2-${frame + 1}.png';
                    currentFrameCount = 1;
                    currentFrameIndex = 0;
                  }
                }

                // 核心重构：使用绝对像素平移定位（Positioned）和 ClipRect 替代 FittedBox
                // 彻底解决 FittedBox 在父级没有明确尺寸限制时引起的约束失效、错位和裁剪不全问题
                return ClipRect(
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: -currentFrameIndex * widget.size,
                          top: 0,
                          width: widget.size * currentFrameCount,
                          height: widget.size,
                          child: Image.asset(
                            currentAssetPath,
                            alignment: Alignment.topLeft,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. 动态装扮图层 (响应全局状态)
          if (!widget.ignoreDecorations)
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
                      ? _buildEarringLayer(earDeco, widget.assetPath, widget.size)
                      : const SizedBox.shrink();

                  final deco = MascotDecoration.getByPath(decoPath);
                  final isEarring = deco?.category == MascotDecorationCategory.face;
                  final isOther = deco?.category == MascotDecorationCategory.other;
                  final earringLegacyLayer = (isEarring && deco != null)
                      ? _buildEarringLayer(deco, widget.assetPath, widget.size)
                      : const SizedBox.shrink();

                  final hatLayer = (!isEarring && !isOther && decoPath != null)
                      ? _buildDecorationLayer(decoPath, widget.assetPath, widget.size)
                      : const SizedBox.shrink();
                  final glassesLayer = glsPath != null
                      ? _buildDecorationLayer(glsPath, widget.assetPath, widget.size)
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
