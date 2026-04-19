import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/daily_task.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/pages/labor_day_event_page.dart';

class DailyTaskCard extends StatelessWidget {
  final bool isNight;

  const DailyTaskCard({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return ValueListenableBuilder<DailyTask?>(
      valueListenable: userState.dailyTask,
      builder: (context, task, _) {
        if (task == null) return const SizedBox.shrink();

        final bool isClaimed = task.isClaimed;
        final bool isHoliday = task.isHoliday;
        final bool isMembership = task.id == 'starlight_membership'; // 识别星光计划

        // 【自动显隐逻辑】如果是节日任务，且当前时间超过了 3月15日公示期，则不显示入口
        if (isHoliday) {
          final now = DateTime.now();
          final displayEnd = DateTime(now.year, 3, 15, 23, 59, 59);
          if (now.isAfter(displayEnd)) {
            return const SizedBox.shrink();
          }
        }

        // 【视觉策略】根据任务属性分配配色
        List<Color> bgColors;
        
        if (isMembership) {
          // 深度还原：星光计划专属“幻彩星空紫”
          bgColors = [
            const Color(0xFF312E81), // 浓郁靛蓝
            const Color(0xFF4C1D95), // 幻彩深紫
            const Color(0xFF1E1B4B), // 暗夜蓝
          ];
        } else if (isHoliday) {
          // 植树节专属“森林绿”
          bgColors = [
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9),
            const Color(0xFF81C784),
          ];
        } else {
          // 普通任务：极简白/磨砂白
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
          clipBehavior: Clip.none,
          children: [
            // 节日装饰：右上角浮动图标
            if (isHoliday && !isClaimed)
              Positioned(
                top: -12,
                right: -6,
                child:
                    Image.asset(
                          task.icon ?? 'assets/images/icons/leaf.png',
                          width: 32,
                          height: 32,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(begin: -0.1, end: 0.1, duration: 2.seconds)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                        ),
              ),

            // 主卡片
            AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: bgColors,
                    ),
                    border: Border.all(
                      width: isHoliday && !isClaimed ? 2.5 : 1,
                      color: isClaimed
                          ? Colors.transparent
                          : (isHoliday
                                ? Colors.green.withValues(alpha: 0.5)
                                : (isNight
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.5))),
                    ),
                    boxShadow: (isClaimed || !isHoliday)
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      // 任务内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isHoliday && !isClaimed)
                                  Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          '节日限定',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                      .animate(onPlay: (c) => c.repeat())
                                      .shimmer(duration: 2.seconds),
                                Text(
                                  isClaimed
                                      ? '好梦伴你'
                                      : (isHoliday ? '岛屿节日 · 惊喜' : '此时此刻 · 灵感'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (isHoliday && !isClaimed)
                                        ? Colors.green[800]
                                        : (isNight
                                              ? Colors.white38
                                              : Colors.black38),
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
                                    ? Colors.black87
                                    : (isNight ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 操作按钮
                      _buildInteractionButton(context, task, isNight),
                    ],
                  ),
                )
                .animate(target: (isHoliday && !isClaimed) ? 1 : 0)
                .custom(
                  duration: 3.seconds,
                  builder: (context, value, child) {
                    if (!isHoliday || isClaimed) return child;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.2 * value),
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
      },
    );
  }

  Widget _buildInteractionButton(
    BuildContext context,
    DailyTask task,
    bool isNight,
  ) {
    final bool isHoliday = task.isHoliday;

    if (task.isClaimed) {
      return Icon(
        Icons.check_circle,
        color: Colors.green.withValues(alpha: 0.5),
        size: 28,
      );
    }

    if (task.isCompleted) {
      return ElevatedButton(
            onPressed: () => UserState().claimTaskReward(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isHoliday
                  ? Colors.green[700]
                  : Colors.orangeAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '收下星光',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1.5.seconds,
            color: Colors.white.withValues(alpha: 0.38),
          );
    }

    return TextButton(
      onPressed: () {
        if (isHoliday) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LaborDayEventPage()),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: (isHoliday && !task.isClaimed)
            ? Colors.green[900]
            : (isNight ? Colors.blueAccent : Colors.blue),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '去看看',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 12),
        ],
      ),
    );
  }
}
