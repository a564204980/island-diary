import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';


class TitleSelectionSheet extends StatelessWidget {
  final bool isNight;
  const TitleSelectionSheet({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    final List<MascotAchievement> titleAchievements =
        MascotAchievement.allAchievements
            .where((a) => a.rewardTitle != null)
            .toList();

    return DiaryBottomSheet(
      height: MediaQuery.of(context).size.height * 0.82,
      paperStyle: 'default',
      isDiary: false,
      showDragHandle: true,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('荣誉称号',
                          style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: isNight ? Colors.white : const Color(0xFF0F172A),
                            fontFamily: _getFontFamily(),
                          )),
                      const SizedBox(height: 3),
                      Text('点亮成就，佩戴属于你的荣耀',
                          style: TextStyle(
                            fontSize: 12,
                            color: isNight ? Colors.white38 : const Color(0xFF64748B),
                            fontFamily: _getFontFamily(),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),



          // 网格
          Expanded(
            child: ValueListenableBuilder<Map<String, String>>(
              valueListenable: userState.unlockedAchievements,
              builder: (context, unlocked, _) {
                // 已解锁的排前面，未解锁的排后面
                final sorted = [...titleAchievements]
                  ..sort((a, b) {
                    final aUnlocked = unlocked.containsKey(a.id) ? 0 : 1;
                    final bUnlocked = unlocked.containsKey(b.id) ? 0 : 1;
                    return aUnlocked.compareTo(bUnlocked);
                  });
                return ValueListenableBuilder<List<String>>(
                  valueListenable: userState.selectedTitles,
                  builder: (context, currentTitles, _) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final a = sorted[index];
                        final isUnlocked = unlocked.containsKey(a.id);
                        final isSelected = currentTitles.contains(a.rewardTitle);

                        return _buildCard(context, userState, a, isUnlocked, isSelected)
                            .animate(key: ValueKey(a.id))
                            .fadeIn(delay: (index * 20).ms, duration: 260.ms);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    UserState userState,
    MascotAchievement a,
    bool isUnlocked,
    bool isSelected,
  ) {
    final tier = a.titleTier;

    // ── 未解锁：极简幽灵卡 ──────────────────────────────────────
    if (!isUnlocked) {
      return Container(
        decoration: BoxDecoration(
          color: isNight
              ? Colors.white.withValues(alpha: 0.03) // 极简暗背景
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNight
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 灰置的标签占位
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: isNight ? Colors.white30 : Colors.black38),
                  const SizedBox(width: 4),
                  Text(a.rewardTitle!,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white30 : Colors.black38,
                        fontFamily: _getFontFamily(),
                      )),
                ],
              ),
            ),
            const Spacer(),
            Text(a.description,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.35),
                  fontFamily: _getFontFamily(),
                )),
          ],
        ),
      );
    }

    // ── 已解锁：玻璃态暗色背景 + 内部高亮称号标签 ─────────────────────────────────
    return GestureDetector(
      onTap: () => userState.toggleTitle(a.rewardTitle!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isNight 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tier.color.withValues(alpha: isSelected ? 0.8 : 0.25),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tier.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : (isNight ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 微弱的径向光晕底色
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.5,
                      colors: [
                        tier.color.withValues(alpha: isNight ? 0.2 : 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 背景水印（大图标，极淡）
              Positioned(
                right: -15, bottom: -15,
                child: Icon(tier.badge, size: 75,
                    color: tier.color.withValues(alpha: 0.08)),
              ),

              // 主内容
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. 直观呈现佩戴后的标签效果（内外完全一致）
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: tier.cardGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: tier.color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tier.badge, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(a.rewardTitle!,
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold,
                                color: Colors.white, fontFamily: _getFontFamily(),
                                shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                              )),
                        ],
                      ),
                    ),
                    
                    const Spacer(),

                    // 2. 描述与状态
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            a.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: isNight ? Colors.white60 : Colors.black54,
                              fontFamily: _getFontFamily(),
                            ),
                          ),
                        ),
                        if (isSelected) 
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.check_circle_rounded, size: 14, color: tier.color),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0)
     .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 180.ms);
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}
