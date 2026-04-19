import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class LaborDayEventPage extends StatelessWidget {
  const LaborDayEventPage({super.key});

  String _getEventStatus() {
    final now = DateTime.now();
    final start = DateTime(now.year, 3, 12);
    final end = DateTime(now.year, 3, 14);
    final displayEnd = DateTime(now.year, 3, 15);

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
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFF1F8E9),
      body: Stack(
        children: [
          // 增强版背景层：组合渐变、浮动光斑与粒子
          Positioned.fill(child: _ArborDayBackground(isNight: isNight)),

          // 内容区
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部返回按钮：在最左侧（不受 700 宽度限制布局的影响，或者说作为导航层）
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isNight
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
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
                          // 节日 Slogan：植树节专题
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '植树节 · 小红书应援',
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
                                  '在云端种下一棵树\n为岛屿开出一片森林',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: isNight
                                        ? Colors.white
                                        : const Color(0xFF1B5E20),
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                )
                                    .animate()
                                    .slideX(begin: -0.2, duration: 600.ms)
                                    .fade(),
                                const SizedBox(height: 8),
                                Text(
                                  '活动时间：3月12日 - 3月14日',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isNight
                                        ? Colors.white54
                                        : const Color(0xFF2E7D32).withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bento 磁贴布局
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                // 磁贴1：品牌愿景与状态
                                _buildBentoRow([
                                  Expanded(
                                    flex: 3,
                                    child: _buildEventCard(
                                      isNight: isNight,
                                      title: '森林守护',
                                      content: '正在发芽',
                                      subtitle: '🌱',
                                      icon: Icons.eco_rounded,
                                      color: Colors.green[400]!,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildEventCard(
                                      isNight: isNight,
                                      title: '当前状态',
                                      content: status,
                                      subtitle: status == '预热中' ? '即将开幕' : (isOngoing ? '限定活动' : '感谢参与'),
                                      icon: Icons.auto_awesome_rounded,
                                      color: status == '已结束' ? Colors.grey : Colors.orange[400]!,
                                    ),
                                  ),
                                ]),

                                const SizedBox(height: 16),

                                // 核心模块：点赞阶梯计划
                                _buildProgressionCard(
                                  isNight: isNight,
                                  steps: [
                                    {
                                      'likes': '5',
                                      'reward': '植树节限定头像框',
                                      'isUnlocked': isOngoing, // 仅在进行中显示某种程度的模拟，或作为展示
                                    },
                                    {
                                      'likes': '20',
                                      'reward': '园艺工背带裙装扮',
                                      'isUnlocked': false,
                                    },
                                    {
                                      'likes': '50',
                                      'reward': '森林秘境壁纸套装',
                                      'isUnlocked': false,
                                    },
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // 底部引导卡片
                                _buildLongTaskCard(
                                  isNight: isNight,
                                  title: status == '已结束'
                                      ? '活动已圆满落幕'
                                      : '去小红书发帖安利',
                                  description: status == '已结束'
                                      ? '感谢每一位森林守护者的付出，明年植树节我们再见！'
                                      : '带话题 #岛屿日记 #我的岛屿生活，集赞后截图联系客服小姐姐领奖哦~',
                                  onTap: isOngoing
                                      ? () {
                                          // TODO: 调起分享逻辑
                                        }
                                      : null,
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
      padding: const EdgeInsets.all(16), // Reduced from 20 to avoid overflow
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isNight
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24), // Slightly smaller
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isNight ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 22, // Slightly smaller
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: isNight ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionCard({
    required bool isNight,
    required List<Map<String, dynamic>> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isNight
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '成就阶梯计划',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white : Colors.black87,
                ),
              ),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step['isUnlocked']
                              ? Colors.green
                              : (isNight ? Colors.white10 : Colors.grey[200]),
                        ),
                        child: Center(
                          child: Text(
                            step['likes'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: step['isUnlocked']
                                  ? Colors.white
                                  : (isNight
                                        ? Colors.white38
                                        : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isNight ? Colors.white10 : Colors.grey[200],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          '累计集赞 ${step['likes']} 个',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isNight ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '奖励：${step['reward']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isNight ? Colors.white38 : Colors.grey[600],
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 24),
                        if (isLast) const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (step['isUnlocked'])
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().slideX(begin: 0.1, duration: 800.ms).fade();
  }

  Widget _buildLongTaskCard({
    required bool isNight,
    required String title,
    required String description,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: 2.seconds, color: Colors.white24);
  }
}

class _ArborDayBackground extends StatelessWidget {
  final bool isNight;
  const _ArborDayBackground({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 基础渐变
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isNight
                    ? [const Color(0xFF1B263B), const Color(0xFF0D1B2A)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
              ),
            ),
          ),
        ),

        // 2. 只有在夜间显示的星空装饰
        if (isNight) ...[
          Positioned.fill(child: _NightSkyDecoration()),
        ],

        // 3. 现代几何装饰树 (仅在大屏模式显示)
        _buildModernDecor(context),

        // 3. 动态光斑 (Aurora Glow)
        Positioned.fill(
          child: Stack(
            children: [
              _buildGlowSpot(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                alignment: Alignment.topLeft,
                size: 600,
                duration: 12.seconds,
              ),
              _buildGlowSpot(
                color: const Color(0xFF43A047).withValues(alpha: 0.08),
                alignment: Alignment.bottomRight,
                size: 700,
                duration: 18.seconds,
              ),
            ],
          ).animate().fadeIn(duration: 2.seconds),
        ),

        // 4. 底部森林剪影层
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 300,
          child: _ForestSilhouette(isNight: isNight),
        ),

        // 5. 漂浮的微小绿叶粒子
        Positioned.fill(child: _FloatingLeaves(isNight: isNight)),

        // 6. 定向纹理
        Positioned.fill(
          child: CustomPaint(
            painter: _SoftGrainPainter(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.green.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDecor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return const SizedBox.shrink();

    return Stack(
      children: [
        // 左侧弧形装饰
        Positioned(
          left: -100,
          top: 100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (isNight ? Colors.white : Colors.green).withValues(
                  alpha: 0.05,
                ),
                width: 40,
              ),
            ),
          ),
        ),
        // 右侧抽象树形
        Positioned(
          right: -50,
          bottom: 200,
          child: Opacity(
            opacity: 0.05,
            child: Icon(
              Icons.park_rounded,
              size: 400,
              color: isNight ? Colors.white : Colors.green,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 1.seconds).slide();
  }

  Widget _buildGlowSpot({
    required Color color,
    required Alignment alignment,
    required double size,
    required Duration duration,
  }) {
    return Positioned(
      child:
          Align(
                alignment: alignment,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color, Colors.transparent],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: const Offset(-30, -30),
                end: const Offset(30, 30),
                duration: duration,
                curve: Curves.easeInOut,
              ),
    );
  }
}

class _ForestSilhouette extends StatelessWidget {
  final bool isNight;
  const _ForestSilhouette({required this.isNight});

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ForestSilhouettePainter(
                  color:
                      (isNight
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC8E6C9))
                          .withValues(alpha: 0.2),
                  baseline: 0.6,
                  seed: 123,
                  isWideScreen: isWideScreen,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ForestSilhouettePainter(
                  color:
                      (isNight
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFA5D6A7))
                          .withValues(alpha: 0.3),
                  baseline: 0.75,
                  seed: 456,
                  isWideScreen: isWideScreen,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ForestSilhouettePainter(
                  color:
                      (isNight
                              ? const Color(0xFF0D3214)
                              : const Color(0xFF81C784))
                          .withValues(alpha: 0.4),
                  baseline: 0.9,
                  seed: 789,
                  isWideScreen: isWideScreen,
                ),
              ),
            ),
          ],
        )
        .animate()
        .slideY(begin: 0.2, duration: 1200.ms, curve: Curves.easeOutCubic)
        .fade();
  }
}

class _ForestSilhouettePainter extends CustomPainter {
  final Color color;
  final double baseline;
  final int seed;
  final bool isWideScreen;

  _ForestSilhouettePainter({
    required this.color,
    required this.baseline,
    required this.seed,
    required this.isWideScreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final h = size.height;
    final w = size.width;
    final random = math.Random(seed);

    path.moveTo(0, h);
    path.lineTo(0, h * baseline);

    // 1. 绘制错落的山坡地形（根据屏幕宽度调整密度）
    double lastY = h * baseline;
    List<Offset> mountainPoints = [];
    mountainPoints.add(Offset(0, lastY));

    // 根据屏幕宽度调整步进尺度：手机端步长稍微缩短一点点
    double minStep = isWideScreen ? 40 : 100;
    double randomStep = isWideScreen ? 60 : 120;

    for (
      double x = minStep;
      x <= w;
      x += minStep + random.nextInt(randomStep.toInt()).toDouble()
    ) {
      double y = h * baseline + (random.nextDouble() - 0.5) * 40;
      path.lineTo(x, y);
      mountainPoints.add(Offset(x, y));
      lastY = y;
    }
    path.lineTo(w, lastY);
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, paint);

    // 2. 在山坡上“种”树（根据屏幕宽度调整密度）
    for (int i = 0; i < mountainPoints.length - 1; i++) {
      final p1 = mountainPoints[i];
      final p2 = mountainPoints[i + 1];

      // 宽屏模式保持密集感，手机端概率从 0.5 提高到 0.8
      int treeCount;
      if (isWideScreen) {
        treeCount = 1 + (random.nextDouble() > 0.7 ? 1 : 0);
      } else {
        treeCount = random.nextDouble() > 0.2 ? 1 : 0;
      }

      for (int j = 0; j < treeCount; j++) {
        double t = random.nextDouble();
        double tx = p1.dx + (p2.dx - p1.dx) * t;
        double ty = p1.dy + (p2.dy - p1.dy) * t;

        // 随机选择树木类型
        int treeType = random.nextInt(3);
        double treeHeight = 50 + random.nextDouble() * 70; // 显著增大树木规格

        if (treeType == 0) {
          _drawPine(canvas, Offset(tx, ty), treeHeight, paint);
        } else if (treeType == 1) {
          _drawRoundTree(canvas, Offset(tx, ty), treeHeight * 0.8, paint);
        } else {
          _drawBush(canvas, Offset(tx, ty), treeHeight * 0.4, paint);
        }
      }
    }
  }

  void _drawPine(Canvas canvas, Offset bottom, double height, Paint paint) {
    // 树干
    canvas.drawRect(
      Rect.fromLTWH(bottom.dx - 2, bottom.dy - height * 0.2, 4, height * 0.2),
      paint,
    );

    final path = Path();
    // 第一层 (底部)
    path.moveTo(bottom.dx - height * 0.4, bottom.dy - height * 0.15);
    path.lineTo(bottom.dx, bottom.dy - height * 0.6);
    path.lineTo(bottom.dx + height * 0.4, bottom.dy - height * 0.15);
    path.close();

    // 第二层 (中部)
    path.moveTo(bottom.dx - height * 0.3, bottom.dy - height * 0.45);
    path.lineTo(bottom.dx, bottom.dy - height * 0.85);
    path.lineTo(bottom.dx + height * 0.3, bottom.dy - height * 0.45);
    path.close();

    // 第三层 (顶部)
    path.moveTo(bottom.dx - height * 0.2, bottom.dy - height * 0.75);
    path.lineTo(bottom.dx, bottom.dy - height * 1.15);
    path.lineTo(bottom.dx + height * 0.2, bottom.dy - height * 0.75);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawRoundTree(
    Canvas canvas,
    Offset bottom,
    double height,
    Paint paint,
  ) {
    // 树干
    canvas.drawRect(
      Rect.fromLTWH(bottom.dx - 2, bottom.dy - height * 0.3, 4, height * 0.3),
      paint,
    );

    // 簇状树冠 (类似云朵，避免单一圆圈)
    double centerY = bottom.dy - height * 0.75;
    double radius = height * 0.35;

    canvas.drawCircle(Offset(bottom.dx, centerY), radius, paint);
    canvas.drawCircle(
      Offset(bottom.dx - radius * 0.6, centerY + radius * 0.2),
      radius * 0.7,
      paint,
    );
    canvas.drawCircle(
      Offset(bottom.dx + radius * 0.6, centerY + radius * 0.2),
      radius * 0.7,
      paint,
    );
    canvas.drawCircle(
      Offset(bottom.dx, centerY - radius * 0.4),
      radius * 0.8,
      paint,
    );
  }

  void _drawBush(Canvas canvas, Offset bottom, double height, Paint paint) {
    // 灌木也用多簇结构
    double rx = height * 1.25;
    double ry = height;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bottom.dx, bottom.dy - ry),
        width: rx * 2,
        height: ry * 2,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bottom.dx - rx * 0.5, bottom.dy - ry * 0.7),
        width: rx,
        height: ry,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bottom.dx + rx * 0.5, bottom.dy - ry * 0.7),
        width: rx,
        height: ry,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _FloatingLeaves extends StatelessWidget {
  final bool isNight;
  const _FloatingLeaves({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(15, (index) {
        final random = math.Random(index);
        final startX = random.nextDouble() * 1.4 - 0.2;
        final duration = (10 + random.nextInt(10)).seconds;
        final delay = (random.nextDouble() * 8).seconds;

        return Positioned(
          left: MediaQuery.of(context).size.width * startX,
          top: -100,
          child:
              Icon(
                    Icons.eco_rounded,
                    size: 6 + random.nextDouble() * 10,
                    color: (isNight ? Colors.green[300] : Colors.green[900])!
                        .withValues(alpha: 0.12),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                    begin: 0,
                    end: MediaQuery.of(context).size.height + 200,
                    duration: duration,
                    delay: delay,
                    curve: Curves.linear,
                  )
                  .rotate(begin: 0, end: 4, duration: duration)
                  .slideX(
                    begin: 0,
                    end: (random.nextDouble() - 0.5) * 2,
                    duration: duration,
                    curve: Curves.easeInOutSine,
                  ),
        );
      }),
    );
  }
}

class _SoftGrainPainter extends CustomPainter {
  final Color color;
  _SoftGrainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = math.Random(42);
    for (int i = 0; i < 2000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _NightSkyDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 月亮 (右上角)
        Positioned(
          top: 80,
          right: 40,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 底圆
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE082),
                    shape: BoxShape.circle,
                  ),
                ),
                // 遮罩圆（形成弯月）
                Positioned(
                  left: 20,
                  top: -5,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B263B), // 近似背景渐变色
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: -10, duration: 4.seconds, curve: Curves.easeInOut),
        ),

        // 星星
        ...List.generate(20, (index) {
          final random = math.Random(index + 999);
          final top = random.nextDouble() * 350;
          final left = random.nextDouble() * 1000;
          final size = 1.5 + random.nextDouble() * 1.5;

          return Positioned(
            top: top,
            left: left % (MediaQuery.of(context).size.width + 100),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(
               begin: const Offset(0.4, 0.4), 
               end: const Offset(1.2, 1.2), 
               duration: (1.5 + random.nextDouble() * 2.5).seconds, 
               delay: (random.nextDouble() * 2).seconds
             )
             .blur(begin: const Offset(0, 0), end: const Offset(0.5, 0.5)),
          );
        }),
      ],
    );
  }
}
