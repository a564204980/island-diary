import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';

class FormGridItem extends StatelessWidget {
  final Map<String, String> form;
  final bool isSelected;
  final bool isNight;
  final bool isLocked;
  final String? lockHint;
  final int index;
  final bool shouldAnimate;

  const FormGridItem({
    super.key,
    required this.form,
    required this.isSelected,
    required this.isNight,
    required this.isLocked,
    this.lockHint,
    required this.index,
    this.shouldAnimate = true,
  });

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final path = form['path']!;
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          String msg = '该形象尚未解锁';
          if (path.contains('marshmallow4.png')) {
            msg = '开通会员即可解锁此形象';
          } else {
            try {
              final achievement = MascotAchievement.allAchievements
                  .where((a) => a.rewardMascotPath == path)
                  .firstOrNull;
              if (achievement != null) {
                msg = '达成成就【${achievement.title}】即可解锁';
              } else {
                msg = '达成特定成就即可解锁该形象';
              }
            } catch (_) {
              msg = '达成特定成就即可解锁该形象';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg,
                style: const TextStyle(
                  fontFamily: 'LXGWWenKai',
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              duration: 2.seconds,
              backgroundColor: isNight
                  ? const Color(0xFF4B5563)
                  : const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            ),
          );
          return;
        }
        HapticFeedback.lightImpact();
        userState.setMascotType(path);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _buildItemDecoration(
          isNight,
          form['rarity'] ?? '普通',
        ),
        child: Stack(
          children: [
            if (isSelected) _buildCheckBadge(form['rarity'] ?? '普通'),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: isLocked ? 0.3 : 1.0,
                      child: StaticSprite(
                        assetPath: path,
                        size: 80,
                        frameCount: path.contains('weixiao.png') ? 9 : 1,
                      )
                          .animate(target: isSelected ? 1 : 0)
                          .scale(
                            duration: 300.ms,
                            begin: const Offset(1, 1),
                            end: const Offset(1.15, 1.15),
                            curve: Curves.easeOutBack,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRarityTag(form['rarity'] ?? '普通'),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        form['name']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF818CF8)
                              : (isNight ? Colors.white : const Color(0xFF3E2723)),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isLocked ? (lockHint ?? '已锁定') : form['desc']!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isLocked
                          ? (isNight ? Colors.orangeAccent : Colors.deepOrange)
                          : (isNight ? Colors.white38 : Colors.black26),
                      fontFamily: 'LXGWWenKai',
                      fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
            if (isLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isNight
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    path.contains('marshmallow4.png')
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                    size: 14,
                    color: isNight ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      )
          .animate(
            delay: shouldAnimate ? (index % 10 * 50).ms : Duration.zero,
            autoPlay: shouldAnimate,
          )
          .fadeIn(duration: 400.ms)
          .moveY(
            begin: shouldAnimate ? 15 : 0,
            end: 0,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _buildRarityTag(String rarity) {
    final color = _getRarityColor(rarity);
    final isPremium = rarity == '传说' || rarity == '卓越';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[
            Icon(
              rarity == '传说' ? Icons.workspace_premium : Icons.stars_rounded,
              size: 11,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            rarity,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildItemDecoration(bool isNight, String rarity) {
    final color = _getRarityColor(rarity);
    return BoxDecoration(
      color: isSelected
          ? (isNight ? color.withValues(alpha: 0.1) : const Color(0xFFF9F8FF))
          : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isSelected
            ? color
            : (isNight ? Colors.white12 : const Color(0xffEEEEEE)),
        width: isSelected ? 2.5 : 1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: color.withValues(alpha: isNight ? 0.2 : 0.25),
                blurRadius: rarity == '传说' ? 30 : 20,
                offset: const Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.05 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  Widget _buildCheckBadge(String rarity) {
    final color = _getRarityColor(rarity);
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Color _getRarityColor(String rarity) {
    if (rarity == '传说') return const Color(0xFFF59E0B);
    if (rarity == '卓越') return const Color(0xFFA855F7);
    return const Color(0xFF94A3B8);
  }
}
