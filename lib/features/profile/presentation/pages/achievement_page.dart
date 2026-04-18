import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement_detail_sheet.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement/achievement_header_card.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement/achievement_category_strip.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement/achievement_medal_cell.dart';
import 'package:island_diary/features/profile/presentation/pages/mascot_decoration_page.dart';

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

    // 将全局监听逻辑上移，确保进入 CustomScrollView 的元素全是标准的 Sliver 组件
    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.unlockedAchievements,
        userState.achievementPoints,
        userState.themeMode,
      ]),
      builder: (context, _) {
        final unlockedMap = userState.unlockedAchievements.value;
        final stats = userState.getAchievementStats();

        // 预过滤列表
        final filteredList = MascotAchievement.allAchievements
            .where((a) => _belongsToCategory(a, _activeCategoryIndex))
            .toList()
          ..sort((a, b) {
            final aUnlocked = unlockedMap.containsKey(a.id);
            final bUnlocked = unlockedMap.containsKey(b.id);
            if (aUnlocked != bUnlocked) return aUnlocked ? -1 : 1;
            // 难度低的（分值小的）排在前面
            return a.rewardPoints.compareTo(b.rewardPoints);
          });

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // 移除这一行，避免背景冲顶导致重叠
          extendBodyBehindAppBar: false, 
          appBar: _buildStandardAppBar(context, isNight),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // 1. 统计概览
                      SliverToBoxAdapter(
                        child: AchievementHeaderCard(
                          unlockedCount: unlockedMap.length,
                          totalPoints: userState.achievementPoints.value,
                          isNight: isNight,
                        ),
                      ),

                      // 2. 分类选择器 (吸顶)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverHeaderDelegate(
                          height: 64,
                          child: Container(
                            // 渐变或背景色，确保吸顶时下方内容不透出
                            color: Theme.of(context).scaffoldBackgroundColor,
                            alignment: Alignment.center,
                            child: AchievementCategoryStrip(
                              categories: _categories,
                              activeIndex: _activeCategoryIndex,
                              isNight: isNight,
                              onCategoryChanged: (index) => setState(() => _activeCategoryIndex = index),
                            ),
                          ),
                        ),
                      ),

                      // 3. 成就网格
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                        sliver: filteredList.isEmpty
                            ? const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text('尚未发现此类奇迹', style: TextStyle(color: Colors.white24)),
                                ),
                              )
                            : SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 4 : 3,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: isWide ? 0.8 : 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final achievement = filteredList[index];
                                    final isUnlocked = unlockedMap.containsKey(achievement.id);
                                    return AchievementMedalCell(
                                      achievement: achievement,
                                      isUnlocked: isUnlocked,
                                      isNight: isNight,
                                      onTap: () => _showAchievementDetail(context, achievement, isUnlocked, stats, isNight, unlockedMap),
                                    ).animate(key: ValueKey('${achievement.id}_$_activeCategoryIndex'))
                                     .fadeIn(delay: (index * 20).ms, duration: 300.ms)
                                     .scale(begin: const Offset(0.9, 0.9));
                                  },
                                  childCount: filteredList.length,
                                ),
                              ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildStandardAppBar(BuildContext context, bool isNight) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: isNight ? Colors.white70 : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '岛屿成就墙',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontFamily: 'LXGWWenKai',
          color: isNight ? Colors.white : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, MascotAchievement a, bool isUnlocked, Map<String, int> stats, bool isNight, Map<String, String> unlockedMap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AchievementDetailSheet(
        achievement: a,
        isUnlocked: isUnlocked,
        stats: stats,
        unlockedAt: unlockedMap[a.id],
        isNight: isNight,
        onGoWear: (id) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MascotDecorationPage(initialDecorationId: id),
            ),
          );
        },
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _SliverHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) => true;
}

class SweepLightEffect extends StatefulWidget {
  const SweepLightEffect({super.key});
  @override
  State<SweepLightEffect> createState() => _SweepLightEffectState();
}

class _SweepLightEffectState extends State<SweepLightEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: SweepPainter(_controller.value),
      ),
    );
  }
}

class SweepPainter extends CustomPainter {
  final double progress;
  SweepPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [progress - 0.2, progress, progress + 0.2],
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0)
        ],
      ).createShader(rect);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }
  @override
  bool shouldRepaint(SweepPainter old) => true;
}
