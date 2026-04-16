import 'package:flutter/material.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/features/profile/presentation/pages/achievement_page.dart';

class AchievementMedalCell extends StatelessWidget {
  final MascotAchievement achievement;
  final bool isUnlocked;
  final bool isNight;
  final VoidCallback onTap;

  const AchievementMedalCell({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    required this.isNight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: _buildMedalArt()),
            const SizedBox(height: 10),
            _buildMedalTitle(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedalArt() {
    final decoration = achievement.rewardDecorationId != null
        ? MascotDecoration.allDecorations
            .where((d) => d.id == achievement.rewardDecorationId)
            .firstOrNull
        : null;

    final isHonor = achievement.condition == AchievementCondition.vipLevel;
    // 使用共享扩展获取主题色，而非 decoration 稀有度色
    final primaryColor = isHonor
        ? AchievementCondition.vipLevel.themeColor
        : (decoration != null
            ? decoration.rarity.color  // 有实物奖励时，用稀有度色
            : achievement.condition.themeColor);  // 无实物时用类别主题色

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildBase(primaryColor),
          if (isUnlocked && isHonor)
            const Positioned.fill(child: SweepLightEffect()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildMedalIcon(decoration, primaryColor),
          ),
          if (!isUnlocked) _buildLockIcon(),
        ],
      ),
    );
  }

  Widget _buildBase(Color color) {
    if (!isUnlocked) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isNight
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          border: Border.all(
            color: isNight
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            width: 1.2,
          ),
        ),
      );
    }

    // 已解锁：多层圆环增加层次感
    return Stack(
      children: [
        // 外环（淡色大圆）
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isNight ? 0.12 : 0.07),
          ),
        ),
        // 内环（稍浓）
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.82,
            heightFactor: 0.82,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isNight ? 0.18 : 0.11),
                border: Border.all(
                  color: color.withValues(alpha: isNight ? 0.5 : 0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isNight ? 0.25 : 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedalIcon(MascotDecoration? decoration, Color color) {
    if (isUnlocked) {
      if (decoration != null) {
        return Image.asset(decoration.path, fit: BoxFit.contain);
      }
      // 无实物奖励：用渐变图标 + 柔和发光
      final gradient = achievement.condition.gradient;
      return Stack(
        alignment: Alignment.center,
        children: [
          // 发光底晕
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // 渐变图标
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Icon(achievement.condition.icon, size: 30),
          ),
        ],
      );
    } else {
      return Opacity(
        opacity: 0.22,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: decoration != null
              ? Image.asset(decoration.path, fit: BoxFit.contain)
              : Icon(achievement.condition.icon, size: 30, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildLockIcon() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: (isNight ? Colors.black : Colors.white).withValues(alpha: 0.72),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 13,
          color: isNight ? Colors.white70 : Colors.black38,
        ),
      ),
    );
  }

  Widget _buildMedalTitle() {
    return Text(
      achievement.title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
        color: isUnlocked
            ? (isNight ? Colors.white : const Color(0xFF1A1A1A))
            : (isNight ? Colors.white24 : Colors.black26),
        fontFamily: 'LXGWWenKai',
      ),
    );
  }
}
