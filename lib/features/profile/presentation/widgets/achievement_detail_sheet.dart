import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/features/profile/presentation/pages/mascot_decoration_page.dart';

class AchievementDetailSheet extends StatelessWidget {
  final MascotAchievement achievement;
  final bool isUnlocked;
  final Map<String, int> stats;
  final String? unlockedAt;
  final bool isNight;

  const AchievementDetailSheet({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    required this.stats,
    this.unlockedAt,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = achievement.rewardDecorationId != null 
        ? MascotDecoration.allDecorations.firstWhere((d) => d.id == achievement.rewardDecorationId)
        : null;
    
    final bg = isNight ? const Color(0xFF1A1A2E) : Colors.white;
    final accent = isUnlocked
        ? (decoration?.rarity.color ?? achievement.condition.themeColor)
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, 
            height: 4, 
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2), 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          const SizedBox(height: 24),
          
          // 图标预览
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                ),
              ),
              Hero(
                tag: 'medal_${achievement.id}',
                child: ColorFiltered(
                  colorFilter: isUnlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([0.2,0.2,0.2,0,0, 0.2,0.2,0.2,0,0, 0.2,0.2,0.2,0,0, 0,0,0,1,0]),
                  child: decoration != null
                      ? Image.asset(decoration.path, width: 80)
                      : Icon(achievement.condition.icon, size: 60, color: accent),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900, 
              color: isNight ? Colors.white : Colors.black, 
              fontFamily: 'Douyin'
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, 
              color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.5), 
              height: 1.6, 
              fontFamily: 'LXGWWenKai'
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 奖励展示
          if (achievement.rewardTitle != null || achievement.rewardDecorationId != null) ...[
             _buildRewardSection(decoration, accent),
             if (isUnlocked && unlockedAt != null) ...[
               const SizedBox(height: 12),
               _buildUnlockDateNote(unlockedAt!, accent),
             ],
          ],

          const SizedBox(height: 16),
          
          if (!isUnlocked)
            _buildProgressBox(stats[achievement.condition.name] ?? 0, achievement.targetValue, accent),
            
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // 只有当有装扮奖励且已解锁时，才会引导跳转
                if (isUnlocked && achievement.rewardDecorationId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MascotDecorationPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnlocked ? accent : Colors.grey.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                !isUnlocked 
                    ? '继续努力' 
                    : (achievement.rewardDecorationId != null ? '这就去穿戴奖励' : '我知道了'), 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSection(MascotDecoration? decoration, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '成就奖励',
            style: TextStyle(
              fontSize: 12, 
              color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai'
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (achievement.rewardTitle != null)
                _buildRewardBadge(Icons.workspace_premium_rounded, '称号：${achievement.rewardTitle}', color),
              if (achievement.rewardTitle != null && achievement.rewardDecorationId != null)
                const SizedBox(width: 8),
              if (decoration != null)
                _buildRewardBadge(Icons.style_rounded, '装扮：${decoration.name}', color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockDateNote(String dateStr, Color color) {
    String dateText = '';
    try {
      final date = DateTime.parse(dateStr);
      dateText = '于 ${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} 达成此殊荣';
    } catch (_) {
      return const SizedBox.shrink();
    }
    
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_rounded, size: 12, color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.3)),
          const SizedBox(width: 6),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 11, 
              color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'LXGWWenKai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String? unlockedAtStr, IconData icon, Color color) {
    String dateText = '已达成此奇迹';
    if (unlockedAtStr != null) {
      try {
        final date = DateTime.parse(unlockedAtStr);
        dateText = '于 ${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} 达成';
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            dateText, 
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'LXGWWenKai')
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBox(int current, int target, Color color) {
    final progress = (current / target.toDouble()).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '解锁进度', 
              style: TextStyle(
                fontSize: 12, 
                color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.3)
              )
            ),
            Text(
              '$current / $target', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.6)
              )
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.05),
          valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
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
    _controller = AnimationController(vsync: this, duration: 3.seconds)..repeat();
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
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2, paint);
  }
  @override
  bool shouldRepaint(SweepPainter old) => true;
}
