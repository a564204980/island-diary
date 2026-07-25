import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';

/// 统一的海岛页面透光渐变背景组件 (IslandPageBackground)
/// 内置背景图片交叉淡入淡出 (Cross-Fade)、云朵漂浮动效与渐变遮罩平滑色彩过渡动画，支持高斯模糊 (blurSigma)
class IslandPageBackground extends StatelessWidget {
  final Widget? child;
  final Alignment backgroundAlignment;
  final double? blurSigma;
  final bool showClouds;
  final bool shouldAnimateClouds;

  const IslandPageBackground({
    super.key,
    this.child,
    this.backgroundAlignment = Alignment.topCenter,
    this.blurSigma,
    this.showClouds = true,
    this.shouldAnimateClouds = true,
  });

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        UserState().themeMode,
        UserState().selectedIslandThemeId,
        UserState().currentBackgroundPath,
      ],
      builder: (context, values, _) {
        final bool isNight = UserState().isNight;
        final String themeId = values[1] as String;
        final String currentBgPath = values[2] as String;

        final bool isSpecialTheme =
            themeId == 'cotton_candy' || themeId == 'lego';
        final String activeBgPath = isSpecialTheme
            ? (themeId == 'lego'
                  ? 'assets/images/theme/legao/legao_page_bg.png'
                  : (isNight
                        ? 'assets/images/theme/miamhuadao/mianhuadao_page_night_bg.png'
                        : 'assets/images/theme/miamhuadao/mianhuadao_page_bg.png'))
            : currentBgPath;

        Widget bgImage = Image.asset(
          activeBgPath,
          key: ValueKey<String>(activeBgPath),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: backgroundAlignment,
        );

        if (blurSigma != null && blurSigma! > 0) {
          bgImage = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma!, sigmaY: blurSigma!),
            child: bgImage,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // 0. 全屏背景底层 (带 AnimatedSwitcher 柔和淡入淡出过渡动画)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [...previousChildren, ?currentChild],
                  );
                },
                child: bgImage,
              ),
            ),

            // 1. 全屏云朵漂浮层
            if (showClouds && themeId != 'lego')
              Positioned.fill(
                child: FloatingClouds(
                  isNight: isNight,
                  themeId: themeId,
                  shouldAnimate: shouldAnimateClouds,
                ),
              ),

            // 2. 全屏透光渐变遮罩层 (带 AnimatedContainer 柔和渐变过渡)
            if (!isSpecialTheme)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 0.75, 1.0],
                      colors: isNight
                          ? [
                              Colors.transparent,
                              const Color(0xFF0D1B2A).withValues(alpha: 0.20),
                              const Color(0xFF0D1B2A).withValues(alpha: 0.65),
                              const Color(0xFF0D1B2A).withValues(alpha: 0.82),
                            ]
                          : [
                              Colors.transparent,
                              const Color(0xFFE6F3F5).withValues(alpha: 0.20),
                              const Color(0xFFE6F3F5).withValues(alpha: 0.65),
                              const Color(0xFFE6F3F5).withValues(alpha: 0.85),
                            ],
                    ),
                  ),
                ),
              ),

            ?child,
          ],
        );
      },
    );
  }
}

