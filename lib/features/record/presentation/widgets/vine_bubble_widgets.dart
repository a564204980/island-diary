import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/models/mood_item.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
// import 'package:island_diary/core/state/user_state.dart'; // 已通过 isNight 参数传递，无需直接导入

/// 藤蔓对话项：包含中心 Pod 和 侧向气泡
class VineBubbleItem extends StatelessWidget {
  final DiaryEntry diary;
  final bool isLeft;
  final double podXOffset;
  final double yOffset;
  final Duration delay;
  final bool isNight;

  const VineBubbleItem({
    super.key,
    required this.diary,
    required this.isLeft,
    required this.isNight,
    this.podXOffset = 0,
    this.yOffset = 0,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 中心发光点 Pod (应用水平偏移)
            Transform.translate(
              offset: Offset(podXOffset, 0),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(painter: _VinePodPainter()),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: delay, curve: Curves.easeInOutCubic),

            // 2. 有机连接线 (Tendril) (传递偏移量供绘图器使用)
            Positioned.fill(
              child: CustomPaint(
                painter: _TendrilPainter(
                  isLeft: isLeft,
                  podXOffset: podXOffset,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 1000.ms, delay: delay + 200.ms, curve: Curves.easeInOutCubic),

            // 3. 左右气泡实现 (紧凑型布局，使气泡紧贴藤蔓)
            Row(
              children: [
                // 左侧槽位
                Expanded(
                  child: isLeft
                      ? Align(
                          alignment: Alignment.centerRight, // 磁吸至中心藤蔓
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 35,
                                left: 16, // 增加左边缘安全距离
                              ), // 给 Pod 和卷须留出空间
                              child: DialogueBubble(
                                diary: diary,
                                isLeft: isLeft,
                                isNight: isNight,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // 中心避让区 (供藤蔓和 Pod 展示)
                const SizedBox(width: 50),

                // 右侧槽位
                Expanded(
                  child: !isLeft
                      ? Align(
                          alignment: Alignment.centerLeft, // 磁吸至中心藤蔓
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 35,
                                right: 16, // 增加右边缘安全距离
                              ), // 给 Pod 和卷须留出空间
                              child: DialogueBubble(
                                diary: diary,
                                isLeft: isLeft,
                                isNight: isNight,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            )
                .animate()
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  delay: delay,
                  curve: Curves.easeOutQuint,
                )
                .fadeIn(duration: 400.ms, delay: delay)
                .moveX(
                  begin: isLeft ? 10 : -10,
                  end: 0,
                  duration: 400.ms,
                  delay: delay,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}

/// 绘制连接 Pod 与气泡的有机卷须
class _TendrilPainter extends CustomPainter {
  final bool isLeft;
  final double podXOffset;
  _TendrilPainter({required this.isLeft, this.podXOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 起点同步发光点的偏移
    final center = Offset(size.width / 2 + podXOffset, size.height / 2);
    // 精确计算气泡边缘位置：基于中轴线的固定偏移 (25px 避让区 + 35px 呼吸间距 = 60px)
    final targetX = isLeft ? (size.width / 2 - 60) : (size.width / 2 + 60);
    final target = Offset(targetX, size.height / 2);

    final path = Path();
    path.moveTo(center.dx, center.dy);

    // 使用贝塞尔曲线模拟“卷须”感
    final controlPoint = Offset(
      (center.dx + target.dx) / 2,
      center.dy + (isLeft ? -20 : 20),
    );

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      target.dx,
      target.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 藤蔓发光点绘制器 (Pod)
class _VinePodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 终极方案：彻底放弃几何形状绘图
    // 仅使用一个具有超大幅度模糊阴影的不可见点来模拟氛围漫反射
    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. 基础极淡氛围
    final atmosPaint = Paint()
      ..color = const Color(0xFFFFF176).withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(center, 12, atmosPaint);

    // 2. 模拟微弱辉光
    final glowPaint = Paint()
      ..color = const Color(0xFFF8E8A0).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 4, glowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 气泡样式的对话框 (自带装饰尾巴)
class DialogueBubble extends StatelessWidget {
  final DiaryEntry diary;
  final bool isLeft;
  final bool isNight;

  const DialogueBubble({
    super.key,
    required this.diary,
    required this.isLeft,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final mood = kMoods[diary.moodIndex.clamp(0, kMoods.length - 1)];
    final dateStr = DateFormat('MM.dd HH:mm').format(diary.dateTime);

    final Color textColor =
        isNight ? Colors.white.withOpacity(0.95) : const Color(0xFF3E2723);
    final Color dateColor = textColor.withOpacity(0.65);

    // 核心优化：星空灯笼风格
    // 底色：#1A2A5E (深空蓝) 75% 不透明度
    final Color colorBase = isNight ? const Color(0xFF1A2A5E) : Colors.white;
    final Color vineGold = const Color(0xFFF8E8A0); // 藤蔓同款金

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? vineGold.withOpacity(0.5) : Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isNight ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        color: Colors.transparent, // 强制外层透明，消除颜色突跳
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isNight ? colorBase.withOpacity(0.6) : Colors.white.withOpacity(0.6),
              child: _buildBubbleContent(mood, dateStr, dateColor, textColor, vineGold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(
    MoodItem mood, 
    String dateStr, 
    Color dateColor, 
    Color textColor,
    Color glowColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft) ...[
                Image.asset(mood.iconPath!, width: 20, height: 20),
                const SizedBox(width: 8),
              ],
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: dateColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (!isLeft) ...[
                const SizedBox(width: 8),
                Image.asset(mood.iconPath!, width: 20, height: 20),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            diary.content,
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: textColor,
              fontWeight: isNight ? FontWeight.normal : FontWeight.w500,
              shadows: [
                if (isNight)
                  Shadow(
                    color: glowColor.withOpacity(0.3), // 轻微金色高光
                    offset: const Offset(0, 0),
                    blurRadius: 4,
                  ),
                Shadow(
                  color: Colors.black.withOpacity(isNight ? 0.3 : 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
