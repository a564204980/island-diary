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

    // 颜色优先级逻辑调整：
    // 1. 实物奖励：使用装饰品稀有度色 (维持原样)
    // 2. 称号奖励（无实物）：使用统一的称号品牌色 (Slate Blue)，不再随类别变色
    // 3. 纯荣誉/名望：使用类别主题色
    final primaryColor = (decoration != null)
        ? decoration.rarity.color
        : (achievement.rewardTitle != null
            ? const Color(0xFF14B8A6) // 换成用户最喜欢的“审美绿”作为称号统一导向色
            : achievement.condition.themeColor);

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
          // 右上角添加奖励类型角标
          Positioned(
            top: 14,
            right: 14,
            child: _buildRewardBadge(primaryColor),
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
      
      // 无饰品，但有称号：显示称号本身的盾牌图标勋章
      final bool hasTitle = achievement.rewardTitle != null;
      final icon = hasTitle ? achievement.titleTier.badge : achievement.condition.icon;
      final gradient = hasTitle ? achievement.titleTier.cardGradient : achievement.condition.gradient;

      // 无实物奖励：用渐变图标 + 柔和发光
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
          // 渐变图标/明亮图标
          if (hasTitle)
            Icon(
              icon,
              size: 32,
              color: Colors.white.withValues(alpha: 0.95),
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            )
          else
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Icon(icon, size: 30),
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
              : Icon(
                  achievement.rewardTitle != null 
                    ? achievement.titleTier.badge 
                    : achievement.condition.icon, 
                  size: 30, 
                  color: Colors.grey
                ),
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

  Widget _buildRewardBadge(Color themeColor) {
    IconData icon;
    if (achievement.rewardDecorationId != null) {
      icon = Icons.redeem_rounded;
    } else if (achievement.rewardTitle != null) {
      icon = Icons.workspace_premium_rounded;
    } else {
      icon = Icons.stars_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (isNight ? Colors.black87 : Colors.white).withValues(alpha: isUnlocked ? 0.9 : 0.4),
        shape: BoxShape.circle,
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ] : null,
      ),
      child: Icon(
        icon,
        size: 10,
        color: isUnlocked ? themeColor : (isNight ? Colors.white12 : Colors.black12),
      ),
    );
  }
}
