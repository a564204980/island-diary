import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_parallax_background.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_hero_section.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_benefit_list.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_pricing_section.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_purchase_button.dart';

class VipBenefitsPage extends StatefulWidget {
  const VipBenefitsPage({super.key});

  @override
  State<VipBenefitsPage> createState() => _VipBenefitsPageState();
}

class _VipBenefitsPageState extends State<VipBenefitsPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  int _selectedTierIndex = 1;

  static const List<PricingTier> _tiers = [
    PricingTier(title: '月度拾光', price: '3.0', numericPrice: 3.0, period: '/月', note: '一杯水的支持'),
    PricingTier(title: '年度星河', price: '25.0', numericPrice: 25.0, period: '/年', note: '年度最受欢迎', isPop: true),
    PricingTier(title: '永恒印记', price: '68.0', numericPrice: 68.0, period: '终身', note: '一份永恒的契约'),
  ];

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
    const themeColor = Color(0xFFCE93D8);
    final season = SoulSeasonLogic.getSeason(userState.savedDiaries.value);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, 
            color: Colors.white70, 
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
          // 1. 视彩背景系统
          Positioned.fill(
            child: VipParallaxBackground(
              isNight: true, 
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
                      const VipHeroSection(isNight: true, themeColor: themeColor),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // 权益列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: VipBenefitList(isNight: true, themeColor: themeColor),
              ),

              // 方案选择
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: VipPricingSection(
                    isNight: true,
                    themeColor: themeColor,
                    selectedIndex: _selectedTierIndex,
                    onTierSelected: (index) => setState(() => _selectedTierIndex = index),
                    tiers: _tiers,
                  ),
                ),
              ),

              // 底部按钮
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
                  child: VipPurchaseButton(
                    isNight: true,
                    themeColor: themeColor,
                    selectedIndex: _selectedTierIndex,
                    tiers: _tiers,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
