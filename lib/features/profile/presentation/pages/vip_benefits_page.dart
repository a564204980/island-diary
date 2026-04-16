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
  int _selectedTierIndex = 1; // 默认选中全场最实惠的年度

  static const List<_PricingTier> _tiers = [
    _PricingTier(title: '月度拾光', price: '3.0', numericPrice: 3.0, period: '/月', note: '一杯水的支持'),
    _PricingTier(title: '年度星河', price: '25.0', numericPrice: 25.0, period: '/年', note: '年度最受欢迎', isPop: true),
    _PricingTier(title: '永恒印记', price: '68.0', numericPrice: 68.0, period: '终身', note: '一份永恒的契约'),
  ];

  double _getEffectivePrice(int targetIndex, int currentLevel) {
    final targetPrice = _tiers[targetIndex].numericPrice;
    
    // 如果用户当前没有会员，返回原价
    if (currentLevel == 0) return targetPrice;
    
    // 如果当前档位 <= 当前等级，视为已持有（理论上不应发生购买，仅显示用）
    if ((targetIndex + 1) <= currentLevel) return 0.0;
    
    // 计算已付金额
    double paidAmount = 0.0;
    if (currentLevel == 1) {
      paidAmount = 3.0;
    } else if (currentLevel == 2) {
      paidAmount = 25.0;
    }
    
    return math.max(0.0, targetPrice - paidAmount);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    UserState().vipLevel.addListener(_updateState);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    UserState().vipLevel.removeListener(_updateState);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
            tooltip: '调试：重置会员状态',
            onPressed: () async {
              await userState.setIsVipLevel(0);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('调试：会员状态已重置为非会员'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
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

              // 2. 档位选择区
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _buildPricingSection(isNight, themeColor),
                ),
              ),

              // 3. 底部行动
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
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
        _buildHorizontalBenefitCard(
          title: '专属装扮',
          description: '激活不同档位，即赠顶级稀有饰品并永久留存',
          orbColor: const Color(0xFFFFD54F), // 金金色
          isNight: isNight,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),

        _buildHorizontalBenefitCard(
          title: '审美特权',
          description: '开启独家季节主题与霞鹜人文字体',
          orbColor: themeColor,
          isNight: isNight,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
        
        _buildHorizontalBenefitCard(
          title: '无限灵感',
          description: '解锁笔记数量限制，支持无限高清图片',
          orbColor: const Color(0xFFF48FB1),
          isNight: isNight,
        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
        
        _buildHorizontalBenefitCard(
          title: '深度洞察',
          description: '365天情绪热力图与灵魂演化分析',
          orbColor: const Color(0xFF64B5F6),
          isNight: isNight,
        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

        _buildHorizontalBenefitCard(
          title: '仪式导出',
          description: '支持高精 PDF 打印与精美卡片分享',
          orbColor: const Color(0xFF4DB6AC),
          isNight: isNight,
        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

        _buildHorizontalBenefitCard(
          title: '同步无界',
          description: '多端实时云同步，数据端到端加密',
          orbColor: const Color(0xFF9575CD),
          isNight: isNight,
        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
      ]),
    );
  }

  Widget _buildHorizontalBenefitCard({
    required String title,
    required String description,
    required Color orbColor,
    required bool isNight,
  }) {
    final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.05) : orbColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                SoulOrb(color: orbColor, size: 36),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildPricingSection(bool isNight, Color themeColor) {
    final userState = UserState();
    final currentLevel = userState.vipLevel.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 20),
          child: Text(
            '选择你的拾光方案',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: (isNight ? Colors.white : const Color(0xFF3E2723)).withValues(alpha: 0.8),
              fontFamily: 'LXGWWenKai',
              letterSpacing: 2,
            ),
          ),
        ),
        ...List.generate(_tiers.length, (index) {
          final tier = _tiers[index];
          final isSelected = _selectedTierIndex == index;
          final effectivePrice = _getEffectivePrice(index, currentLevel);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTierIndex = index),
              child: AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutQuint,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isNight ? themeColor.withValues(alpha: 0.15) : themeColor.withValues(alpha: 0.1))
                      : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? themeColor : (isNight ? Colors.white12 : Colors.black12),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))
                  ] : [],
                ),
                child: Row(
                  children: [
                    // 1. 选中指示器
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? themeColor : (isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.1)),
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        duration: 300.ms,
                        scale: isSelected ? 1.0 : 0.0,
                        curve: Curves.easeOutBack,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 2. 方案信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tier.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                              if (tier.isPop) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('推荐', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tier.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: (isNight ? Colors.white : const Color(0xFF3E2723)).withValues(alpha: 0.4),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 3. 价格展示
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (effectivePrice < tier.numericPrice && effectivePrice > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '补差价升级',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '¥',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                                ),
                              ),
                              TextSpan(
                                text: effectivePrice <= 0 ? (currentLevel >= (index + 1) ? '已激活' : '0.0') : effectivePrice.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: effectivePrice <= 0 && currentLevel >= (index + 1) ? 18 : 24,
                                  fontWeight: FontWeight.w900,
                                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                                ),
                              ),
                              TextSpan(
                                text: tier.period,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (isNight ? Colors.white : const Color(0xFF3E2723)).withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGrandAction(UserState userState, bool isNight, Color themeColor) {
    return ListenableBuilder(
      listenable: userState.vipLevel,
      builder: (context, _) {
        final bool isVip = userState.isVip.value;
        final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
        final selectedTier = _tiers[_selectedTierIndex];

        return Column(
          children: [
            Text(
              isVip && userState.vipLevel.value == 3 
                ? '—— 星河拾光之契已经激活 ——' 
                : (isVip 
                    ? '—— 有效期至：${userState.vipExpireTime.value?.toIso8601String().split('T')[0] ?? ''} ——' 
                    : '开启这扇门，通往更广阔的心灵原野'),
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.3),
                fontFamily: 'LXGWWenKai',
                letterSpacing: 2,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: 3.seconds),
            const SizedBox(height: 32),
            if (userState.vipLevel.value < (_selectedTierIndex + 1))
              GestureDetector(
                onTap: () async {
                  await userState.setIsVipLevel(_selectedTierIndex + 1);
                  // 立即触发成就同步（发放专属饰品）
                  await userState.checkAchievements();
                  
                  if (!context.mounted) return;
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
                      
                      Text(
                        '以 ¥${_getEffectivePrice(_selectedTierIndex, userState.vipLevel.value).toStringAsFixed(1)} ${selectedTier.period == '终身' ? '永久' : '激活'}${userState.vipLevel.value > 0 ? '升级' : ''}${selectedTier.title}',
                        style: const TextStyle(
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
            const SizedBox(height: 16),
            if (!isVip)
              Text(
                '一次支持，全岛建设加速中',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.2),
                  fontFamily: 'LXGWWenKai',
                  letterSpacing: 1,
                ),
              ),
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

class _PricingTier {
  final String title;
  final String price;
  final double numericPrice;
  final String period;
  final String note;
  final bool isPop;

  const _PricingTier({
    required this.title,
    required this.price,
    required this.numericPrice,
    required this.period,
    required this.note,
    this.isPop = false,
  });
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
