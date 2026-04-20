import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class LaborDayEventPage extends StatelessWidget {
  const LaborDayEventPage({super.key});

  String _getEventStatus() {
    final now = DateTime.now();
    final start = DateTime(now.year, 5, 1);
    final end = DateTime(now.year, 5, 5);
    final displayEnd = DateTime(now.year, 5, 6);

    if (now.isBefore(start)) return '即将开始';
    if (now.isBefore(end.add(const Duration(days: 1)))) return '进行中';
    if (now.isBefore(displayEnd.add(const Duration(days: 1)))) return '已结束';
    return '活动结束';
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String status = _getEventStatus();
    final bool isOngoing = status == '进行中';

    return Scaffold(
      backgroundColor: isNight 
          ? const Color(0xFF1A1A2E) 
          : const Color(0xFFFFF8E1),
      body: Stack(
        children: [
          // 劳动节专属：日出背景层
          Positioned.fill(child: _LaborDayBackground(isNight: isNight)),

          // 内容区
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部返回按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isNight ? Colors.orange[200] : Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // 节日 Slogan：劳动节专题
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '五一劳动节 · 致敬热爱',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ).animate().scale(delay: 200.ms),
                                const SizedBox(height: 16),
                                Text(
                                  '生活因热爱而闪光\n梦想因勤恳而启航',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: isNight ? Colors.white : Colors.orange[950],
                                    height: 1.2,
                                  ),
                                ).animate().slideX(begin: -0.2, duration: 600.ms).fade(),
                                const SizedBox(height: 8),
                                Text(
                                  '活动时间：5月1日 - 5月5日',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isNight ? Colors.white70 : Colors.orange[950]?.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bento 布局
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildBentoRow([
                                  Expanded(
                                    flex: 3,
                                    child: _buildEventCard(
                                      isNight: isNight,
                                      title: '热爱值',
                                      content: '持续积攒',
                                      subtitle: '☀️',
                                      icon: Icons.wb_sunny_rounded,
                                      color: Colors.orange[400]!,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildEventCard(
                                      isNight: isNight,
                                      title: '状态',
                                      content: status,
                                      subtitle: isOngoing ? '火热进行' : '敬请期待',
                                      icon: Icons.celebration_rounded,
                                      color: status == '已结束' ? Colors.grey : Colors.amber[600]!,
                                    ),
                                  ),
                                ]),

                                const SizedBox(height: 16),

                                _buildProgressionCard(
                                  isNight: isNight,
                                  steps: [
                                    {'likes': '15', 'reward': '星光月卡体验券 (3天)'},
                                    {'likes': '35', 'reward': '劳动节限定装扮 · 劳作者 (永久)'},
                                    {'likes': '66', 'reward': '星光月卡 (30天) + 专属成就'},
                                  ],
                                ),

                                const SizedBox(height: 16),

                                _buildLongTaskCard(
                                  isNight: isNight,
                                  title: '去小红书发帖安利',
                                  description: '带话题 #岛屿日记 #我的岛屿生活，集赞后截图联系客服小姐姐领奖哦~',
                                  onTap: isOngoing ? () {} : null,
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    ).animate().slideY(begin: 0.1, duration: 600.ms).fade();
  }

  Widget _buildEventCard({
    required bool isNight,
    required String title,
    required String content,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withOpacity(0.08) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        boxShadow: isNight ? [] : [
          BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 11, color: isNight ? Colors.white38 : Colors.orange[900]?.withOpacity(0.4), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  content, 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: isNight ? Colors.white : Colors.orange[900],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subtitle, 
                  style: TextStyle(
                    fontSize: 10, 
                    color: isNight ? Colors.white38 : Colors.orange[900]?.withOpacity(0.6),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionCard({required bool isNight, required List<Map<String, dynamic>> steps}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Text('致敬进阶计划', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.orange[900])),
            ],
          ),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: isNight ? Colors.white10 : Colors.orange[50],
                        ),
                        child: Center(
                          child: Text(
                            step['likes'], 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.orange[200],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast) Expanded(child: Container(width: 2, color: isNight ? Colors.white10 : Colors.orange[50])),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('累计获得 ${step['likes']} 次点赞', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isNight ? Colors.white70 : Colors.orange[950])),
                        Text('奖励：${step['reward']}', style: TextStyle(fontSize: 11, color: isNight ? Colors.white38 : Colors.orange[800])),
                        if (!isLast) const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // 移除状态图标
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().slideX(begin: 0.1, duration: 800.ms).fade();
  }

  Widget _buildLongTaskCard({required bool isNight, required String title, required String description, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFFF57C00), const Color(0xFFFFB300)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24);
  }
}

class _LaborDayBackground extends StatelessWidget {
  final bool isNight;
  const _LaborDayBackground({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isNight 
                    ? [const Color(0xFF1B1B3A), const Color(0xFF0F0F2D)] 
                    : [const Color(0xFFFFD54F), const Color(0xFFFFECB3)],
              ),
            ),
          ),
        ),
        // 动态光晕 (日出效果)
        Positioned(
          top: -100,
          left: -100,
          child: _buildSunriseGlow(context),
        ),
        // 背景插画点缀 (低透明度)
        Positioned(
          right: -20,
          top: 120,
          child: Opacity(
            opacity: isNight ? 0.05 : 0.12,
            child: Image.asset(
              'assets/images/event/laborer_harvest.png',
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            ),
          ),
        ).animate().fadeIn(duration: 2.seconds),
        Positioned(
          left: -30,
          bottom: 180,
          child: Opacity(
            opacity: isNight ? 0.05 : 0.1,
            child: Image.asset(
              'assets/images/event/laborer_craftsman.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ).animate().fadeIn(duration: 2.seconds),
        // 底部剪影：金色海岸
        Positioned(left: 0, right: 0, bottom: 0, height: 250, child: _CoastSilhouette(isNight: isNight)),
        // 麦浪：底部点缀
        Positioned(left: 0, right: 0, bottom: 0, height: 140, child: _WheatField(isNight: isNight)),
        // 漂浮粒子：热爱之光
        Positioned.fill(child: _DiligenceParticles(isNight: isNight)),
      ],
    );
  }

  Widget _buildSunriseGlow(BuildContext context) {
    return Container(
      width: 600, height: 600,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.orange.withOpacity(isNight ? 0.15 : 0.4),
            Colors.transparent,
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 10.seconds);
  }
}

class _WheatField extends StatelessWidget {
  final bool isNight;
  const _WheatField({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(15, (index) {
          final random = math.Random(index);
          // 错开分布
          final double leftPos = (MediaQuery.of(context).size.width / 12) * index - 20;
          
          return Positioned(
            left: leftPos + (random.nextDouble() * 30),
            bottom: -20 + (random.nextDouble() * 30),
            child: Opacity(
              opacity: isNight ? 0.3 : 0.8,
              child: Transform.rotate(
                angle: (random.nextDouble() - 0.5) * 0.2,
                child: Icon(
                  Icons.grass_rounded,
                  size: 40 + random.nextDouble() * 40,
                  color: isNight ? Colors.orange[900]!.withOpacity(0.5) : Colors.orange[300],
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .rotate(
             begin: -0.05, 
             end: 0.05, 
             duration: (3 + random.nextDouble() * 2).seconds, 
             curve: Curves.easeInOutSine,
           );
        }),
      ),
    );
  }
}

class _CoastSilhouette extends StatelessWidget {
  final bool isNight;
  const _CoastSilhouette({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _WavePainter(color: isNight ? Colors.orange[900]!.withOpacity(0.1) : Colors.orange[100]!, baseline: 0.7, frequency: 0.01))),
        Positioned.fill(child: CustomPaint(painter: _WavePainter(color: isNight ? Colors.orange[800]!.withOpacity(0.2) : Colors.orange[200]!, baseline: 0.8, frequency: 0.015))),
        Positioned.fill(child: CustomPaint(painter: _WavePainter(color: isNight ? Colors.orange[700]!.withOpacity(0.3) : Colors.orange[300]!, baseline: 0.9, frequency: 0.02))),
      ],
    ).animate().slideY(begin: 0.2, duration: 1.seconds);
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double baseline;
  final double frequency;
  _WavePainter({required this.color, required this.baseline, required this.frequency});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * baseline);
    for (double x = 0; x <= size.width; x++) {
      double y = size.height * baseline + math.sin(x * frequency) * 15;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _DiligenceParticles extends StatelessWidget {
  final bool isNight;
  const _DiligenceParticles({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(20, (index) {
        final random = math.Random(index);
        final startX = random.nextDouble() * 1.2 - 0.1;
        return Positioned(
          left: MediaQuery.of(context).size.width * startX,
          top: -50,
          child: Icon(Icons.wb_sunny_rounded, size: 4 + random.nextDouble() * 8, color: Colors.orange[200]!.withOpacity(0.2))
              .animate(onPlay: (c) => c.repeat())
              .moveY(begin: 0, end: 1000, duration: (8 + random.nextInt(8)).seconds, delay: (random.nextDouble() * 5).seconds)
              .rotate(duration: 10.seconds),
        );
      }),
    );
  }
}
