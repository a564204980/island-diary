import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/daily_task.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/pages/labor_day_event_page.dart';
import 'package:island_diary/features/profile/presentation/pages/arbor_day_event_page.dart';

class DailyTaskCard extends StatelessWidget {
  final bool isNight;

  const DailyTaskCard({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.dailyTask,
        userState.isVip,
        userState.isEventDrawerUnlocked,
      ]),
      builder: (context, _) {
        final task = userState.dailyTask.value;
        final bool isVip = userState.isVip.value;
        final bool isDrawerUnlocked = userState.isEventDrawerUnlocked.value;
        
        // 如果是会员，或者手动开启了抽屉，则进入“全活动专题流”模式
        final bool isStreamMode = isVip || isDrawerUnlocked;

        if (task == null && !isStreamMode) return const SizedBox.shrink();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          child: isStreamMode 
              ? _buildEventVerticalStream(context, userState, task) 
              : (task == null ? const SizedBox.shrink() : _buildTaskContainer(context, task)),
        );
      },
    );
  }

  /// 构建标准的单任务卡片容器
  Widget _buildTaskContainer(BuildContext context, DailyTask task) {
    final bool isClaimed = task.isClaimed;
    final bool isHoliday = task.isHoliday;
    final bool isMembership = task.id == 'starlight_membership';

    List<Color> bgColors;
    if (isMembership) {
      bgColors = [const Color(0xFF312E81), const Color(0xFF4C1D95), const Color(0xFF1E1B4B)];
    } else if (isHoliday) {
      bgColors = task.id == 'holiday_labor_day'
          ? [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5), const Color(0xFFFED7AA)]
          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFF81C784)];
    } else {
      bgColors = [
        isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      ];
    }

    if (isClaimed && !isMembership) {
      bgColors = [
        isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
        isNight ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.3),
      ];
    }

    return Stack(
      key: ValueKey('single_${task.id}'),
      clipBehavior: Clip.none,
      children: [
        if (isHoliday && !isClaimed)
          Positioned(
            top: -12,
            right: -6,
            child: Image.asset(
                  task.icon ?? 'assets/images/icons/leaf.png',
                  width: 32,
                  height: 32,
                )
                .animate(onPlay: (c) => c.repeat())
                .rotate(begin: 0, end: 1, duration: 12.seconds)
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 3.seconds, curve: Curves.easeInOut)
                .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: bgColors),
            border: Border.all(
              width: isHoliday && !isClaimed ? 2.5 : 1,
              color: isClaimed
                  ? Colors.transparent
                  : (isHoliday
                      ? (task.id == 'holiday_labor_day' ? Colors.orange.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5))
                      : (isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5))),
            ),
            boxShadow: (isClaimed || !isHoliday) ? [] : [
              BoxShadow(
                color: (task.id == 'holiday_labor_day' ? Colors.orange : Colors.green).withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isHoliday && !isClaimed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: task.id == 'holiday_labor_day' ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('节日限定', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                        Text(
                          isClaimed ? '好梦伴你' : (isHoliday ? '岛屿节日 · 惊喜' : '此时此刻 · 灵感'),
                          style: TextStyle(
                            fontSize: 12,
                            color: (isHoliday && !isClaimed)
                                ? (task.id == 'holiday_labor_day' ? Colors.orange[900] : Colors.green[800])
                                : (isNight ? Colors.white38 : Colors.black38),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isClaimed ? '心中有光，便是好风景。' : task.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: (isHoliday && !isClaimed)
                            ? (task.id == 'holiday_labor_day' ? Colors.brown[900] : Colors.black87)
                            : (isNight ? Colors.white : Colors.black87),
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildInteractionButton(context, task, isNight),
            ],
          ),
        ).animate(target: (isHoliday && !isClaimed) ? 1 : 0).custom(
          duration: 3.seconds,
          builder: (context, value, child) {
            if (!isHoliday || isClaimed) return child;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (task.id == 'holiday_labor_day' ? Colors.orange : Colors.green).withValues(alpha: 0.2 * value),
                    blurRadius: 20 * value,
                    spreadRadius: 5 * value,
                  ),
                ],
              ),
              child: child,
            );
          },
        ),
      ],
    );
  }

  /// 构建“垂直专题流”模式下的 UI
  Widget _buildEventVerticalStream(BuildContext context, UserState userState, DailyTask? currentTask) {
    // 1. 直接构造展示列表，利用 Collection If 简化逻辑
    final List<DailyTask> displayList = [
      // 如果当前任务不是节日活动（如普通任务或会员任务），则排在首位展示
      if (currentTask?.id.startsWith('holiday_') == false) currentTask!,
      ...DailyTask.getAvailableEvents(),
    ];

    return Column(
      key: const ValueKey('stream_mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 垂直平铺所有活动模块
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final task = displayList[index];
            final bool isNormalTask = !task.id.startsWith('holiday_');
            
            return _buildStreamTaskCard(context, task, isNormalTask: isNormalTask)
              .animate()
              .fadeIn(delay: (index * 100).ms)
              .slideX(begin: 0.1, end: 0);
          },
        ),
      ],
    );
  }

  /// 专题流中的独立大模块卡片
  Widget _buildStreamTaskCard(BuildContext context, DailyTask task, {required bool isNormalTask}) {
    final bool isLabor = task.id == 'holiday_labor_day';
    final bool isArbor = task.id == 'holiday_arbor_day';
    
    List<Color> bgColors;
    if (isNormalTask) {
      bgColors = [
        isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      ];
    } else if (isLabor) {
      bgColors = isNight 
          ? [const Color(0xFF431407), const Color(0xFF2D0E05)] // 夜间劳动节：红土深褐
          : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)];
    } else if (isArbor) {
      bgColors = isNight 
          ? [const Color(0xFF064E3B), const Color(0xFF062D24)] // 夜间植树节：深邃林绿
          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)];
    } else {
      bgColors = [Colors.white, Colors.white];
    }

    return GestureDetector(
      onTap: () {
        if (!isNormalTask) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isLabor ? const LaborDayEventPage() : const ArborDayEventPage(),
            ),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 节日装饰图标：右上角旋转
          if (!isNormalTask)
            Positioned(
              top: -10,
              right: -5,
              child: Image.asset(
                    task.icon ?? 'assets/images/icons/leaf.png',
                    width: 28,
                    height: 28,
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(begin: 0, end: 1, duration: 12.seconds)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 3.seconds, curve: Curves.easeInOut)
                  .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
            ),
          
          AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: bgColors),
              border: Border.all(
                color: isNormalTask 
                    ? (isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.5)) 
                    : (isLabor ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
                width: isNormalTask ? 1 : 2,
              ),
              boxShadow: isNormalTask ? [] : [
                BoxShadow(
                  color: (isLabor ? Colors.orange : Colors.green).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 图标已移回右上角，此处仅保留标题
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isNormalTask 
                            ? (isNight ? Colors.white : Colors.black87) 
                            : (isNight 
                                ? (isLabor ? const Color(0xFFFDBA74) : const Color(0xFF6EE7B7))
                                : (isLabor ? Colors.orange[900] : Colors.green[900])),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black12),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isNight ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(BuildContext context, DailyTask task, bool isNight) {
    if (task.isClaimed) return Icon(Icons.check_circle, color: Colors.green.withValues(alpha: 0.5), size: 28);
    if (task.isCompleted) {
      return ElevatedButton(
        onPressed: () => UserState().claimTaskReward(),
        style: ElevatedButton.styleFrom(
          backgroundColor: task.isHoliday
              ? (task.id == 'holiday_labor_day' ? Colors.orange[800] : Colors.green[700])
              : Colors.orangeAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('收下星光', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1.5.seconds);
    }
    return TextButton(
      onPressed: () {
        if (task.isHoliday) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => task.id == 'holiday_labor_day' ? const LaborDayEventPage() : const ArborDayEventPage(),
          ));
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: (task.isHoliday && !task.isClaimed)
            ? (task.id == 'holiday_labor_day' ? Colors.orange[900] : Colors.green[900])
            : (isNight ? Colors.blueAccent : Colors.blue),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text('去看看', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 12)],
      ),
    );
  }
}
