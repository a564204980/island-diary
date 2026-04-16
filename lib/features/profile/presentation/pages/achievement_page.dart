import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 背景装饰
          if (!isNight)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF176).withValues(alpha: 0.2),
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                // 自定义 App Bar
                _buildAppBar(context, isNight),
                
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      userState.unlockedAchievements,
                      userState.achievementPoints,
                    ]),
                    builder: (context, _) {
                      final stats = userState.getAchievementStats();
                      final unlockedMap = userState.unlockedAchievements.value;
                      
                      // 对成就列表进行排序：已解锁在前，未解锁的按难度（奖励点数）升序排列
                      final achievements = List<MascotAchievement>.from(MascotAchievement.allAchievements)
                        ..sort((a, b) {
                          final aUnlocked = unlockedMap.containsKey(a.id);
                          final bUnlocked = unlockedMap.containsKey(b.id);
                          
                          // 1. 解锁状态优先：已解锁的在前
                          if (aUnlocked != bUnlocked) {
                            return aUnlocked ? -1 : 1;
                          }
                          
                          // 2. 难度判定（以奖励点数为核心指标）：点数越低越容易，排在前边
                          if (a.rewardPoints != b.rewardPoints) {
                            return a.rewardPoints.compareTo(b.rewardPoints);
                          }
                          
                          // 3. 兜底判定（以条件目标值为指标）：目标值越低排在前边
                          return a.targetValue.compareTo(b.targetValue);
                        });

                      final unlockedCount = unlockedMap.length;
                      final totalPoints = userState.achievementPoints.value;

                      return Column(
                        children: [
                          _buildProgressOverview(unlockedCount, MascotAchievement.allAchievements.length, totalPoints, isNight),
                          Expanded(
                            child: CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // 成就列表
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final achievement = achievements[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _buildAchievementCard(
                                            achievement, 
                                            unlockedMap.containsKey(achievement.id), 
                                            stats, 
                                            isNight,
                                            unlockDate: unlockedMap[achievement.id],
                                          )
                                            .animate(delay: (index * 50).ms)
                                            .fadeIn(duration: 400.ms)
                                            .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                                        );
                                      },
                                      childCount: achievements.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isNight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isNight ? Colors.white70 : const Color(0xFF3E2723),
              size: 20,
            ),
          ),
          Text(
            '岛屿成就',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              color: isNight ? Colors.white : const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(int unlocked, int total, int totalPoints, bool isNight) {
    final double progress = total > 0 ? unlocked / total.toDouble() : 0.0;
    final primaryColor = isNight ? const Color(0xFFFFF176) : const Color(0xFF7B5C2E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isNight 
            ? Colors.white.withValues(alpha: 0.04) 
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNight ? Colors.white10 : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isNight ? Colors.black : primaryColor).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '探索与成就',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                        color: isNight ? Colors.white : const Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      '已点亮 $unlocked 个岛屿奇迹 • 累计 $totalPoints 点数',
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Douyin',
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度条
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        isNight ? const Color(0xFFFFCC80) : const Color(0xFFD4E157),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ).animate().shimmer(duration: 3.seconds, color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    MascotAchievement achievement,
    bool isUnlocked,
    Map<String, int> stats,
    bool isNight, {
    String? unlockDate,
  }) {
    // 查找饰品预览
    final decoration = achievement.rewardDecorationId != null 
        ? MascotDecoration.allDecorations.firstWhere(
            (d) => d.id == achievement.rewardDecorationId,
            orElse: () => MascotDecoration.allDecorations.first,
          )
        : null;

    final rarityColor = decoration?.rarity.color ?? (isNight ? const Color(0xFFFFF176) : const Color(0xFF7B5C2E));
    final int currentProgressValue = stats[achievement.condition.name] ?? 0;
    final double progressPercent = (currentProgressValue / achievement.targetValue.toDouble()).clamp(0.0, 1.0);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isUnlocked
                ? (isNight 
                    ? rarityColor.withValues(alpha: 0.05) 
                    : Colors.white)
                : (isNight 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isNight 
                    ? rarityColor.withValues(alpha: 0.08) 
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 左侧：勋章预览区
                SizedBox(
                  width: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (decoration != null)
                        ColorFiltered(
                          colorFilter: isUnlocked
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0.0, 0.0,
                                  0.2126, 0.7152, 0.0722, 0.0, 0.0,
                                  0.2126, 0.7152, 0.0722, 0.0, 0.0,
                                  0.0,    0.0,    0.0,    1.0, 0.0,
                                ]),
                          child: Opacity(
                            opacity: isUnlocked ? 1.0 : 0.5,
                            child: Image.asset(
                              decoration.path,
                              width: 44,
                              height: 44,
                            ),
                          ),
                        )
                      else
                        // 无饰品时的点数勋章图标
                        Icon(
                          Icons.military_tech_rounded,
                          size: 38,
                          color: isUnlocked ? rarityColor : (isNight ? Colors.white24 : Colors.black12),
                        ),
                      
                      if (!isUnlocked)
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: isNight ? Colors.white30 : Colors.black26,
                        ),
                    ],
                  ),
                ),
                
                // 右侧：详细内容区
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                achievement.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Douyin',
                                  color: isUnlocked
                                      ? (isNight ? Colors.white : const Color(0xFF3E2723))
                                      : (isNight ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ),
                            // 稀有度标签或点数标签
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUnlocked ? rarityColor.withValues(alpha: 0.1) : Colors.black12,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isUnlocked ? rarityColor.withValues(alpha: 0.2) : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                decoration?.rarity.label ?? '点数',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? rarityColor : Colors.black26,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // 条件与奖励
                        _buildInfoRow(
                          Icons.auto_fix_high_rounded,
                          achievement.description,
                          isUnlocked ? (isNight ? Colors.white54 : Colors.black54) : (isNight ? Colors.white38 : Colors.black38),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.card_giftcard_rounded,
                          '奖励：${achievement.rewardPoints} 点数${decoration != null ? ' + ${decoration.name}' : ''}',
                          isUnlocked ? rarityColor.withValues(alpha: 0.8) : (isNight ? Colors.white38 : Colors.black38),
                          isBold: isUnlocked,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // 状态展示
                        if (isUnlocked)
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: rarityColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '成就已达成',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: rarityColor,
                                ),
                              ),
                              if (unlockDate != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '解锁于: ${_formatDate(unlockDate)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isNight ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '解锁进度',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isNight ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                  Text(
                                    '${(progressPercent * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isNight ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progressPercent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isUnlocked)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Text(
                '尚未解锁',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isNight ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'LXGWWenKai',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '未知时间';
    }
  }
}
