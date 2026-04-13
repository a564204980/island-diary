import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/statistics/presentation/widgets/seasonal_atmosphere_painter.dart';

class VipBenefitsPage extends StatefulWidget {
  const VipBenefitsPage({super.key});

  @override
  State<VipBenefitsPage> createState() => _VipBenefitsPageState();
}

class _VipBenefitsPageState extends State<VipBenefitsPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;
    
    // 锁定“星光计划”专属品牌色：极光紫与幻梦蓝
    const starlightMain = Color(0xFFCE93D8);
    final themeColor = starlightMain;
    final season = SoulSeasonLogic.getSeason(userState.savedDiaries.value);

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, 
            color: isNight ? Colors.white70 : const Color(0xFF7E57C2).withValues(alpha: 0.5), 
            size: 18
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. 视差星辰背景系统
          Positioned.fill(
            child: _ParallaxCelestialBackground(
              isNight: isNight, 
              season: season, 
              scrollOffset: _scrollOffset
            ),
          ),

          // 2. 主滚动区域
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      _buildGrandHero(isNight, themeColor),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // 浮岛权益网格
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: _buildFloatingIslandGrid(context, isNight, themeColor),
              ),

              // 底部行动
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
                  child: _buildGrandAction(userState, isNight, themeColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrandHero(bool isNight, Color themeColor) {
    final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
    
    return Column(
      children: [
        // 具象化星芒中心 (Energy Field - 星钻核心)
        Stack(
          alignment: Alignment.center,
          children: [
            // 背景深度光晕
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [themeColor.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),

            // 星辰运行轨道 (Interstellar Orbits)
            ...List.generate(3, (index) => _buildCelestialOrbit(themeColor, index)),
            
            // 中层呼吸感扩散
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [themeColor.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 4.seconds, begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), curve: Curves.easeInOutExpo),

            // 核心勋章 - 星钻切面
            Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _StarlightInsigniaPainter(themeColor: themeColor, isGrand: true),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(1, 1), end: const Offset(1.06, 1.06), curve: Curves.easeInOutSine),
          ],
        ),

        const SizedBox(height: 60),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isNight 
              ? [Colors.white, themeColor.withValues(alpha: 0.5), Colors.white, const Color(0xFFFFD4AF), Colors.white]
              : [const Color(0xFF3E2723), themeColor, const Color(0xFF3E2723), const Color(0xFFB8860B), const Color(0xFF3E2723)],
            stops: const [0, 0.25, 0.5, 0.75, 1],
          ).createShader(bounds),
          child: Text(
            '星光计划 · 拾光伴侣',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
              color: Colors.white,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border_rounded, size: 14, color: themeColor.withValues(alpha: 0.4)),
            const SizedBox(width: 14),
            Container(
              height: 0.8,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, themeColor.withValues(alpha: 0.3), Colors.transparent]),
              ),
            ),
            const SizedBox(width: 14),
            Icon(Icons.star_border_rounded, size: 14, color: themeColor.withValues(alpha: 0.4)),
          ],
        ).animate().scaleX(begin: 0, end: 1, delay: 400.ms),
        const SizedBox(height: 24),
        
        Text(
          '✧  万象更新，在此间寻得永恒之光  ✧',
          style: TextStyle(
            fontSize: 15,
            color: textColor.withValues(alpha: 0.3),
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
            fontFamily: 'LXGWWenKai',
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildCelestialOrbit(Color themeColor, int index) {
    // 创建交错的旋转轨道
    final angles = [0.0, 60 * math.pi / 180, -60 * math.pi / 180];
    final durations = [30, 45, 60];
    
    return Transform.rotate(
      angle: angles[index],
      child: Container(
        width: 280,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(280, 100)),
          border: Border.all(color: themeColor.withValues(alpha: 0.08), width: 0.8),
        ),
        child: Stack(
          children: [
            // 轨道亮点 (Pearl)
            _OrbitingPearl(duration: durations[index], themeColor: themeColor),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat())
       .rotate(duration: durations[index].seconds, begin: 0, end: index % 2 == 0 ? 1 : -1),
    );
  }


  Widget _buildFloatingIslandGrid(BuildContext context, bool isNight, Color themeColor) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildFloatingCard(
          title: '审美特权',
          subtitle: '感官重塑',
          description: '解锁晨雾氤氲的季节本色主题，每一笔记录都伴随着呼吸感的动态粒子与人文气息的霞鹜字体，重构你的数字避风港。',
          orbColor: themeColor,
          isNight: isNight,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 24),

        _buildFloatingCard(
          title: '无限灵感',
          subtitle: '创作零束缚',
          description: '解除每日笔记数量限制，单篇日记支持无限张高清图片载入。你的心灵海域，理应承载每一寸想象力。',
          orbColor: const Color(0xFFF48FB1),
          isNight: isNight,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 24),
        
        _buildFloatingCard(
          title: '深度洞察',
          subtitle: '灵感迁徙图谱',
          description: '以前瞻性的 365 天视角，跨维度剖析情绪与万物荣枯的因果。年度热力图不仅是数据，更是你一年来灵魂生长的痕迹。',
          orbColor: const Color(0xFF64B5F6),
          isNight: isNight,
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildFloatingCard(
                title: '时空进化',
                subtitle: '永恒印记',
                orbColor: const Color(0xFF9575CD),
                isNight: isNight,
                isSmall: true,
              ).animate().fadeIn(delay: 800.ms),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFloatingCard(
                title: '仪式导出',
                subtitle: '纸上栖息',
                orbColor: const Color(0xFF4DB6AC),
                isNight: isNight,
                isSmall: true,
              ).animate().fadeIn(delay: 1000.ms),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildFloatingCard({
    required String title,
    required String subtitle,
    String? description,
    required Color orbColor,
    required bool isNight,
    bool isSmall = false,
  }) {
    final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
    
    return Container(
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.06) : orbColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          width: 0.5, // 极细边
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isNight ? 0.3 : 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Stack(
            children: [
              // 0.5px 金属扫光边框 (Premium Border)
              CustomPaint(
                painter: _NobleBorderPainter(color: orbColor),
                child: Container(),
              ),
              
              // 大卡片的侧边彩色装饰 (改为磨砂质感)
              if (!isSmall)
                Positioned(
                  left: 0,
                  top: 32,
                  bottom: 32,
                  width: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [orbColor.withValues(alpha: 0), orbColor, orbColor.withValues(alpha: 0)],
                      ),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .shimmer(duration: 4.seconds, color: Colors.white.withValues(alpha: 0.5)),
                ),
              
              Container(
                padding: EdgeInsets.all(isSmall ? 28 : 36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      orbColor.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.white.withValues(alpha: isNight ? 0.02 : 0.05),
                    ],
                  ),
                ),
                child: isSmall 
                  ? _buildSmallCardContent(title, subtitle, orbColor, textColor)
                  : _buildLargeCardContent(title, subtitle, description, orbColor, textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCardContent(String title, String subtitle, String? description, Color orbColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SoulOrb(color: orbColor, size: 36),
            _buildCardBadge(subtitle, orbColor),
          ],
        ),
        const SizedBox(height: 36),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: textColor,
            fontFamily: 'LXGWWenKai',
            letterSpacing: 1.5,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 18),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.8,
              color: textColor.withValues(alpha: 0.5),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallCardContent(String title, String subtitle, Color orbColor, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SoulOrb(color: orbColor, size: 42),
        const SizedBox(height: 24),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textColor,
            fontFamily: 'LXGWWenKai',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withValues(alpha: 0.4),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildGrandAction(UserState userState, bool isNight, Color themeColor) {
    return ListenableBuilder(
      listenable: userState.isVip,
      builder: (context, _) {
        final bool isVip = userState.isVip.value;
        final textColor = isNight ? Colors.white : const Color(0xFF3E2723);

        return Column(
          children: [
            Text(
              isVip ? '—— 星河拾光之契已经激活 ——' : '开启这扇门，通往更广阔的心灵原野',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.3),
                fontFamily: 'LXGWWenKai',
                letterSpacing: 2,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: 3.seconds),
            const SizedBox(height: 32),
            if (!isVip)
              GestureDetector(
                onTap: () {
                  userState.setIsVip(true);
                  ScaffoldMessenger.of(context).showMaterialBanner(
                    MaterialBanner(
                      backgroundColor: themeColor,
                      content: const Text('星辰契约已达成，从此拾光而行', style: TextStyle(color: Colors.white, fontFamily: 'LXGWWenKai')),
                      actions: [
                        TextButton(onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(), child: const Text('好的', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [themeColor, themeColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 顶部高光 (Glass Polish)
                      Positioned(
                        top: 4,
                        left: 40,
                        right: 40,
                        height: 1.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                      
                      const Text(
                        '申领星光计划拾光契约',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.03, 1.03), curve: Curves.easeInOutSine),
          ],
        );
      },
    );
  }
}

class SoulOrb extends StatelessWidget {
  final Color color;
  final double size;
  const SoulOrb({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(painter: _SoulOrbPainter(color: color)),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(duration: 2.seconds, begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15), curve: Curves.easeInOutSine);
  }
}

class _SoulOrbPainter extends CustomPainter {
  final Color color;
  _SoulOrbPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, color, color.withValues(alpha: 0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarlightInsigniaPainter extends CustomPainter {
  final Color themeColor;
  final bool isGrand;
  _StarlightInsigniaPainter({required this.themeColor, this.isGrand = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. 底层幻影光晕
    canvas.drawCircle(center, radius, Paint()
      ..shader = RadialGradient(
        colors: [themeColor.withValues(alpha: 0.6), themeColor.withValues(alpha: 0.1), Colors.transparent],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius)));

    // 2. 钻石切面绘制 (Faceted Diamond Effect)
    const points = 8;
    for (int i = 0; i < points; i++) {
        final angleTip = (i * 45 - 90) * math.pi / 180;
        final angleValleyNext = ((i * 45 + 22.5) - 90) * math.pi / 180;
        final angleValleyPrev = ((i * 45 - 22.5) - 90) * math.pi / 180;

        final pTip = center + Offset(radius * 0.8 * math.cos(angleTip), radius * 0.8 * math.sin(angleTip));
        final pValleyNext = center + Offset(radius * 0.3 * math.cos(angleValleyNext), radius * 0.3 * math.sin(angleValleyNext));
        final pValleyPrev = center + Offset(radius * 0.3 * math.cos(angleValleyPrev), radius * 0.3 * math.sin(angleValleyPrev));

        // 右半切面
        final pathRight = Path()..moveTo(center.dx, center.dy)..lineTo(pTip.dx, pTip.dy)..lineTo(pValleyNext.dx, pValleyNext.dy)..close();
        final paintRight = Paint()..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.9), themeColor.withValues(alpha: 0.3)],
        ).createShader(pathRight.getBounds());
        canvas.drawPath(pathRight, paintRight);

        // 左半切面
        final pathLeft = Path()..moveTo(center.dx, center.dy)..lineTo(pTip.dx, pTip.dy)..lineTo(pValleyPrev.dx, pValleyPrev.dy)..close();
        final paintLeft = Paint()..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Colors.white.withValues(alpha: 0.7), themeColor.withValues(alpha: 0.1)],
        ).createShader(pathLeft.getBounds());
        canvas.drawPath(pathLeft, paintLeft);
    }

    // 3. 核心星芒射线 (Flares)
    final flaresPaint = Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * math.pi / 180;
      final start = center + Offset(radius * 0.2 * math.cos(angle), radius * 0.2 * math.sin(angle));
      final end = center + Offset(radius * 1.5 * math.cos(angle), radius * 1.5 * math.sin(angle));
      canvas.drawLine(start, end, flaresPaint);
    }
    
    // 4. 晶体高光
    canvas.drawCircle(center, 4, Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(center, 1.5, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ParallaxCelestialBackground extends StatelessWidget {
  final bool isNight;
  final SoulSeasonResult season;
  final double scrollOffset;
  const _ParallaxCelestialBackground({required this.isNight, required this.season, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 底层：深邃宇宙渐变
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isNight 
                ? [const Color(0xFF0F172A), const Color(0xFF020617), Colors.black] 
                : [const Color(0xFFEDE7F6), const Color(0xFFF3E5F5), const Color(0xFFE8EAF6)],
            ),
          ),
        ),

        // 2. 星图点缀层 (Starfield)
        Positioned.fill(
          child: CustomPaint(
            painter: _StarfieldPainter(isNight: isNight, scrollOffset: scrollOffset),
          ),
        ),
        
        // 3. 极光光斑 (Mist Blobs)
        Positioned(
          top: -150 - scrollOffset * 0.1,
          left: -200,
          child: _AnimatedMistBlob(color: const Color(0xFF7E57C2).withValues(alpha: isNight ? 0.25 : 0.15), size: 900),
        ),
        Positioned(
          top: 400 - scrollOffset * 0.3,
          right: -250,
          child: _AnimatedMistBlob(color: const Color(0xFF42A5F5).withValues(alpha: isNight ? 0.2 : 0.1), size: 800),
        ),

        // 4. 环境粒子层
        SeasonalAtmosphere(particleType: season.particleType, isNight: isNight),
      ],
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final bool isNight;
  final double scrollOffset;
  _StarfieldPainter({required this.isNight, required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final starPaint = Paint()..color = Colors.white;
    
    for (int i = 0; i < 150; i++) {
        final x = random.nextDouble() * size.width;
        final y = (random.nextDouble() * size.height * 2) - scrollOffset * 0.2;
        final radius = random.nextDouble() * 1.2;
        final opacity = random.nextDouble() * (isNight ? 0.6 : 0.2);
        
        starPaint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawCircle(Offset(x, y), radius, starPaint);
        
        // 闪烁星星 (Twinkling)
        if (random.nextDouble() > 0.95) {
            canvas.drawCircle(Offset(x, y), radius * 2, starPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
        }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _OrbitingPearl extends StatefulWidget {
  final int duration;
  final Color themeColor;
  const _OrbitingPearl({required this.duration, required this.themeColor});

  @override
  State<_OrbitingPearl> createState() => _OrbitingPearlState();
}

class _OrbitingPearlState extends State<_OrbitingPearl> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration.seconds)..repeat();
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
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        const width = 280.0;
        const height = 100.0;
        final x = width / 2 + (width / 2) * math.cos(angle);
        final y = height / 2 + (height / 2) * math.sin(angle);
        
        return Positioned(
          left: x - 4,
          top: y - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: widget.themeColor.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NobleBorderPainter extends CustomPainter {
  final Color color;
  _NobleBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(36));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          const Color(0xFFFFD4AF).withValues(alpha: 0.5), // 香槟金边缘
          Colors.white.withValues(alpha: 0.8),
          color.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedMistBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _AnimatedMistBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .move(duration: 15.seconds, begin: const Offset(-40, -40), end: const Offset(40, 40), curve: Curves.easeInOutSine);
  }
}
