import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement_detail_sheet.dart';
import 'dart:ui';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  int _activeCategoryIndex = 0;
  final List<String> _categories = ['全部', '岛屿轨迹', '笔耕不辍', '心境探索', '专属荣誉'];

  bool _belongsToCategory(MascotAchievement a, int index) {
    if (index == 0) return true;
    switch (index) {
      case 1: // 轨迹
        return [AchievementCondition.totalDiaries, AchievementCondition.activeDays].contains(a.condition);
      case 2: // 笔耕
        return [AchievementCondition.totalWords, AchievementCondition.maxStreak, AchievementCondition.maxSingleWords].contains(a.condition);
      case 3: // 心境
        return [
          AchievementCondition.uniqueMoods,
          AchievementCondition.totalMoods,
          AchievementCondition.photoDiaries,
          AchievementCondition.uniqueTags,
          AchievementCondition.morningDiaries,
          AchievementCondition.nightDiaries
        ].contains(a.condition);
      case 4: // 荣誉
        return a.condition == AchievementCondition.vipLevel;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // 背景艺术渐变
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isNight ? const Color(0xFF311B92) : const Color(0xFFE3F2FD)).withValues(alpha: 0.3),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isNight),
                
                // 顶部统计概览
                ListenableBuilder(
                  listenable: Listenable.merge([userState.unlockedAchievements, userState.achievementPoints]),
                  builder: (context, _) {
                    final unlockedCount = userState.unlockedAchievements.value.length;
                    final totalPoints = userState.achievementPoints.value;
                    return _buildHeaderOverview(unlockedCount, totalPoints, isNight);
                  },
                ),

                // 分类选择器
                _buildCategorySelector(isNight),

                // 成就网格
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([userState.unlockedAchievements]),
                    builder: (context, _) {
                      final stats = userState.getAchievementStats();
                      final unlockedMap = userState.unlockedAchievements.value;
                      
                      final filteredList = MascotAchievement.allAchievements
                          .where((a) => _belongsToCategory(a, _activeCategoryIndex))
                          .toList()
                        ..sort((a, b) {
                          final aUnlocked = unlockedMap.containsKey(a.id);
                          final bUnlocked = unlockedMap.containsKey(b.id);
                          if (aUnlocked != bUnlocked) return aUnlocked ? -1 : 1;
                          return b.rewardPoints.compareTo(a.rewardPoints);
                        });

                      if (filteredList.isEmpty) {
                        return Center(
                          child: Text(
                            '尚未发现此类奇迹',
                            style: TextStyle(color: isNight ? Colors.white30 : Colors.black26),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final achievement = filteredList[index];
                          final isUnlocked = unlockedMap.containsKey(achievement.id);
                          return _buildMedalView(achievement, isUnlocked, stats, isNight)
                            .animate(key: ValueKey('${achievement.id}_$_activeCategoryIndex'))
                            .fadeIn(delay: (index * 30).ms, duration: 400.ms)
                            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isNight ? Colors.white12 : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 20, color: isNight ? Colors.white : Colors.black87),
            ),
          ),
          Text(
            '岛屿勋章墙',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'LXGWWenKai',
              color: isNight ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 40), // 平衡
        ],
      ),
    );
  }

  Widget _buildHeaderOverview(int unlocked, int points, bool isNight) {
    final textColor = isNight ? Colors.white : const Color(0xFF1A1A1A);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('已点亮', unlocked.toString(), '勋章', textColor),
          Container(width: 1, height: 30, color: textColor.withValues(alpha: 0.1)),
          _buildStatItem('累计', points.toString(), '荣誉', textColor),
          Container(width: 1, height: 30, color: textColor.withValues(alpha: 0.1)),
          _buildStatItem('世界排名', 'TOP 1%', '位置', textColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, fontFamily: 'Douyin')),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6))),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector(bool isNight) {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _activeCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _activeCategoryIndex = index),
            child: AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isNight ? const Color(0xFFFFF176) : Colors.black) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? (isNight ? Colors.black : Colors.white) 
                      : (isNight ? Colors.white38 : Colors.black38),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedalView(MascotAchievement achievement, bool isUnlocked, Map<String, int> stats, bool isNight) {
    final decoration = achievement.rewardDecorationId != null 
        ? MascotDecoration.allDecorations.firstWhere((d) => d.id == achievement.rewardDecorationId)
        : null;

    final isHonor = achievement.condition == AchievementCondition.vipLevel;
    final primaryColor = isHonor 
        ? const Color(0xFFFFD54F) 
        : (decoration?.rarity.color ?? (isNight ? Colors.white24 : Colors.black12));

    return GestureDetector(
      onTap: () => _showAchievementDetail(achievement, isUnlocked, stats, isNight),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 勋章底盘
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isUnlocked && isHonor)
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked 
                              ? primaryColor.withValues(alpha: isNight ? 0.15 : 0.08)
                              : (isNight ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUnlocked ? primaryColor.withValues(alpha: 0.4) : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 扫光波纹 (Honor Only)
                if (isUnlocked && isHonor)
                  const Positioned.fill(
                    child: SweepLightEffect(),
                  ),

                // 图标
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Hero(
                    tag: 'medal_${achievement.id}',
                    child: ColorFiltered(
                      colorFilter: isUnlocked
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix([
                              0.2, 0.2, 0.2, 0, 0,
                              0.2, 0.2, 0.2, 0, 0,
                              0.2, 0.2, 0.2, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Opacity(
                        opacity: isUnlocked ? 1.0 : 0.3,
                        child: decoration != null 
                            ? Image.asset(decoration.path, fit: BoxFit.contain)
                            : Icon(Icons.stars_rounded, size: 36, color: primaryColor),
                      ),
                    ),
                  ),
                ),

                if (!isUnlocked)
                  Icon(Icons.lock_rounded, size: 16, color: isNight ? Colors.white12 : Colors.black12),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked 
                  ? (isNight ? Colors.white : Colors.black87) 
                  : (isNight ? Colors.white24 : Colors.black26),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail(MascotAchievement a, bool isUnlocked, Map<String, int> stats, bool isNight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AchievementDetailSheet(achievement: a, isUnlocked: isUnlocked, stats: stats, isNight: isNight),
    );
  }
}
