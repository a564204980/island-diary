import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'dart:math' as Math;
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement_detail_sheet.dart';
import 'package:flutter/services.dart';

class MascotDecorationPage extends StatefulWidget {
  final String? initialDecorationId;
  const MascotDecorationPage({super.key, this.initialDecorationId});

  @override
  State<MascotDecorationPage> createState() => _MascotDecorationPageState();
}

class _MascotDecorationPageState extends State<MascotDecorationPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0.0);
  String _searchQuery = '';
  bool _isInitialized = false;
  bool _isFirstLoad = true;

  static const List<Map<String, String>> _mascotForms = [
    {
      'id': 'form_marshmallow',
      'name': '云织',
      'path': 'assets/images/emoji/marshmallow.png',
      'desc': '软绵绵的最初陪伴，编织每一天的温柔',
      'rarity': '传说',
    },
    {
      'id': 'form_weixiao',
      'name': '活力微笑',
      'path': 'assets/images/emoji/weixiao.png',
      'desc': '元气满满的每一天',
    },
    {
      'id': 'form_sikao',
      'name': '沉思学者',
      'path': 'assets/images/emoji/sikao.png',
      'desc': '深夜哲思的伙伴',
    },
    {
      'id': 'form_nanguo',
      'name': '忧郁小软',
      'path': 'assets/images/emoji/nanguo.png',
      'desc': '静静陪你难过一会儿',
    },
    {
      'id': 'form_pedding',
      'name': '甜品布丁',
      'path': 'assets/images/emoji/pedding.png',
      'desc': '看起来很好吃的样子',
    },
    {
      'id': 'form_marshmallow2',
      'name': '笃守',
      'path': 'assets/images/emoji/marshmallow2.png',
      'desc': '汪汪！不论何时，都是你最忠实的森林伙伴',
      'rarity': '普通',
    },
    {
      'id': 'form_marshmallow3',
      'name': '灵犀',
      'path': 'assets/images/emoji/marshmallow3.png',
      'desc': '敏捷聪慧的灵之化身，洞察林间的秘密',
      'rarity': '卓越',
    },
    {
      'id': 'form_marshmallow4',
      'name': '霜见',
      'path': 'assets/images/emoji/marshmallow4.png',
      'desc': '月光般轻盈恬静，静谧守望你的思绪',
      'rarity': '传说',
    },
  ];

  static const double _searchFlightThreshold = 120.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var form in _mascotForms) {
      precacheImage(AssetImage(form['path']!), context);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.initialDecorationId != null) {
          _scrollToTarget();
        }
        Future.delayed(1.seconds, () {
          if (mounted) setState(() => _isFirstLoad = false);
        });
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final double offset = _scrollController.offset;
    final double progress = (offset / _searchFlightThreshold).clamp(0.0, 1.0);
    if (_scrollProgress.value != progress) {
      _scrollProgress.value = progress;
    }
  }

  List<MascotDecoration> _getFilteredDecorations(List<String> ownedIds) {
    return MascotDecoration.allDecorations.where((deco) {
      const bool isOwned = true; 
      if (!isOwned) return false;
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return deco.name.toLowerCase().contains(query) ||
             deco.description.toLowerCase().contains(query);
    }).toList();
  }

  void _scrollToTarget() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final userState = UserState();
    final ownedIds = userState.ownedDecorationIds.value;
    final displayedList = _getFilteredDecorations(ownedIds);

    final index = displayedList.indexWhere(
      (d) => d.id == widget.initialDecorationId,
    );
    if (index == -1) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const headerHeight = 70.0 + 46.0;
    final screenWidthForGrid = (screenWidth > 800 ? 800 : screenWidth);
    final crossAxisCount = screenWidthForGrid > 600 ? 3 : 2;
    final gridWidth = screenWidthForGrid - 48;
    final itemWidth = (gridWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
    final itemAspectRatio = screenWidthForGrid > 600 ? 0.75 : 0.8;
    final itemHeight = itemWidth / itemAspectRatio;

    final rowIndex = (index / crossAxisCount).floor();
    final scrollOffset = headerHeight + (rowIndex * (itemHeight + 16));

    _scrollController.animateTo(
      scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: 800.ms,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: !_isInitialized
          ? const SizedBox.shrink()
          : Stack(
              children: [
                // 1. 背景装饰
                if (!isNight) _buildLightBackground(),

                // 2. 核心交互区域 (应用 800px 宽度限制并匹配搜索栏路径)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Stack(
                          children: [
                            // 主页面骨架
                            SafeArea(
                              child: Column(
                                children: [
                                  // --- 固定区域：AppBar ---
                                  _buildAppBar(context, isNight),

                                  // --- 固定区域：预览英雄区域 ---
                                  ListenableBuilder(
                                    listenable: Listenable.merge([
                                      userState.selectedMascotDecoration,
                                      userState.selectedMascotType,
                                    ]),
                                    builder: (context, _) => _buildPreviewHero(
                                      userState.selectedMascotDecoration.value,
                                      userState.selectedMascotType.value,
                                      isNight,
                                      userState,
                                    ),
                                  ),

                                  // --- 滚动过滤区域 ---
                                  Expanded(
                                    child: CustomScrollView(
                                      controller: _scrollController,
                                      physics: const BouncingScrollPhysics(),
                                      slivers: [
                                        // --- 搜索栏占位符 ---
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 70),
                                        ),

                                        // --- 标题行 (挑选装扮) ---
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              4,
                                              14,
                                              16,
                                            ),
                                            child: Row(
                                              children: [
                                                _buildSectionIndicator(),
                                                const SizedBox(width: 12),
                                                Text(
                                                  _searchQuery.isEmpty ? '挑选装扮' : '搜索结果',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: isNight ? Colors.white : const Color(0xFF3E2723),
                                                    fontFamily: 'LXGWWenKai',
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${userState.ownedDecorationIds.value.length} 个已解锁',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isNight ? Colors.white38 : Colors.black26,
                                                    fontFamily: 'LXGWWenKai',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // --- 网格列表 ---
                                        SliverPadding(
                                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                                          sliver: ListenableBuilder(
                                            listenable: Listenable.merge([
                                              userState.selectedMascotDecoration,
                                              userState.selectedMascotType,
                                              userState.ownedDecorationIds,
                                            ]),
                                            builder: (context, _) {
                                              final currentDecoration = userState.selectedMascotDecoration.value;
                                              final ownedIds = userState.ownedDecorationIds.value;
                                              final displayedDecorations = _getFilteredDecorations(ownedIds);

                                              if (displayedDecorations.isEmpty) return _buildEmptyState(isNight);

                                              return SliverGrid(
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                                                  mainAxisSpacing: 16,
                                                  crossAxisSpacing: 16,
                                                  childAspectRatio: constraints.maxWidth > 600 ? 0.75 : 0.8,
                                                ),
                                                delegate: SliverChildBuilderDelegate(
                                                  (context, index) {
                                                    final deco = displayedDecorations[index];
                                                    return _DecorationGridItem(
                                                      deco: deco,
                                                      isSelected: currentDecoration == deco.path,
                                                      isNight: isNight,
                                                      isOwned: true,
                                                      index: index,
                                                      shouldHighlight: deco.id == widget.initialDecorationId,
                                                      shouldAnimate: true,
                                                    );
                                                  },
                                                  childCount: displayedDecorations.length,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 3. 飞行搜索栏 (置于居中容器内部，坐标相对于 800px 区域)
                            _buildFlyingSearchBar(isNight, contentWidth),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildFlyingSearchBar(bool isNight, double contentWidth) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollProgress,
      builder: (context, progress, child) {
        final screenWidth = contentWidth;
        final safeAreaTop = MediaQuery.of(context).padding.top;

        final startY = safeAreaTop + 60.0 + 300.0 + 12.0 - _scrollController.offset;
        final endY = safeAreaTop + 10.0;

        final startX = 24.0;
        final endX = screenWidth - 24.0 - 46.0;

        final t = Curves.easeInOutCubic.transform(progress);
        final p0 = Offset(startX, startY);
        final p2 = Offset(endX, endY);
        final p1 = Offset(startX + (endX - startX) * 0.4, startY - 150.0);

        final currentPos = Offset(
          Math.pow(1 - t, 2) * p0.dx + 2 * (1 - t) * t * p1.dx + Math.pow(t, 2) * p2.dx,
          Math.pow(1 - t, 2) * p0.dy + 2 * (1 - t) * t * p1.dy + Math.pow(t, 2) * p2.dy,
        );

        final currentWidth = (screenWidth - 48.0) + (46.0 - (screenWidth - 48.0)) * t;

        return Positioned(
          left: currentPos.dx,
          top: currentPos.dy.clamp(-100.0, 1000.0),
          child: Opacity(
            opacity: startY < -50 ? 0 : 1.0,
            child: Container(
              width: currentWidth,
              height: 46,
              decoration: BoxDecoration(
                color: isNight
                    ? Colors.white.withValues(alpha: progress > 0.8 ? 0.1 : 0.05)
                    : Colors.black.withValues(alpha: progress > 0.8 ? 0.08 : 0.03),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: progress > 0.9
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 13,
                    child: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isNight ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  if (progress < 0.9)
                    Positioned.fill(
                      left: 44,
                      child: Opacity(
                        opacity: (1 - progress * 1.5).clamp(0.0, 1.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            color: isNight ? Colors.white70 : const Color(0xFF3E2723),
                            fontSize: 14,
                            fontFamily: 'LXGWWenKai',
                          ),
                          decoration: InputDecoration(
                            hintText: '寻找你心仪的装扮...',
                            hintStyle: TextStyle(
                              color: isNight ? Colors.white24 : Colors.black26,
                              fontSize: 14,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    color: isNight ? Colors.white24 : Colors.black26,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  if (progress >= 0.9)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(23),
                        onTap: () {
                          _scrollController.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLightBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB3E5FC).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFFFFF).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionIndicator() {
    return Container(
      width: 6,
      height: 22,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD97D).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isNight) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 16),
          Text(
            '没有找到相关结果',
            style: TextStyle(
              color: isNight ? Colors.white38 : Colors.black26,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isNight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isNight ? Colors.white70 : const Color(0xFF3E2723),
            ),
          ),
          const Spacer(),
          Text(
            '小软的衣帽间',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white : const Color(0xFF3E2723),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPreviewHero(
    String? decorationPath,
    String mascotType,
    bool isNight,
    UserState userState,
  ) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: StaticSprite(
              assetPath: mascotType,
              decorationPath: decorationPath,
              size: 200,
            ).animate().scale(
              duration: 400.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.9, 0.9),
            ).fadeIn(duration: 400.ms).then(delay: 500.ms).shimmer(
              duration: 2500.ms,
              color: decorationPath != null &&
                      MascotDecoration.getByPath(decorationPath)?.rarity == MascotRarity.legendary
                  ? const Color(0xFFFFD97D).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          _buildPreviewBadge(isNight, userState),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(bool isNight, UserState userState) {
    return Positioned(
      bottom: 16,
      child: ListenableBuilder(
        listenable: userState.selectedMascotDecoration,
        builder: (context, _) {
          final isDressed = userState.selectedMascotDecoration.value != null;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showFormSelectionSheet(context, isNight, userState),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isNight
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text(
                        "变身",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isNight ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDressed) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => userState.setMascotDecoration(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isNight
                          ? const Color(0xFFE57373).withValues(alpha: 0.15)
                          : const Color(0xFFD32F2F).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNight
                            ? const Color(0xFFE57373).withValues(alpha: 0.2)
                            : const Color(0xFFD32F2F).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: isNight ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "卸下",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isNight ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showFormSelectionSheet(BuildContext context, bool isNight, UserState userState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF1A1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNight ? 0.5 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF8B5CF6), size: 22),
                  const SizedBox(width: 12),
                  Text(
                    '变更形象',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white : const Color(0xFF1F2937),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: isNight ? Colors.white38 : Colors.black26),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  userState.selectedMascotType,
                  userState.unlockedMascotPaths,
                  userState.vipLevel,
                ]),
                builder: (context, _) {
                  final currentType = userState.selectedMascotType.value;
                  final unlockedPaths = userState.unlockedMascotPaths.value;
                  final isVip = userState.isVip.value;

                  final targetPaths = [
                    'assets/images/emoji/marshmallow.png',
                    'assets/images/emoji/marshmallow2.png',
                    'assets/images/emoji/marshmallow3.png',
                    'assets/images/emoji/marshmallow4.png',
                  ];
                  final filteredForms = _mascotForms
                      .where((f) => targetPaths.contains(f['path']))
                      .toList();
                  
                  filteredForms.sort((a, b) {
                    final aPath = a['path']!;
                    final bPath = b['path']!;
                    bool aLocked = (aPath == 'assets/images/emoji/marshmallow4.png') ? !isVip : !unlockedPaths.contains(aPath);
                    bool bLocked = (bPath == 'assets/images/emoji/marshmallow4.png') ? !isVip : !unlockedPaths.contains(bPath);
                    if (aLocked != bLocked) return aLocked ? 1 : -1;
                    return 0;
                  });

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filteredForms.length,
                    itemBuilder: (context, index) {
                      final form = filteredForms[index];
                      final path = form['path']!;
                      bool isLocked = !unlockedPaths.contains(path);
                      String? lockHint;
                      if (path == 'assets/images/emoji/marshmallow4.png') {
                        isLocked = !isVip;
                        lockHint = isLocked ? '星光计划专属' : null;
                      } else if (isLocked) {
                        lockHint = '待成就解锁';
                      }
                      return _FormGridItem(
                        form: form,
                        isSelected: currentType == path,
                        isNight: isNight,
                        isLocked: isLocked,
                        lockHint: lockHint,
                        index: index,
                        shouldAnimate: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorationGridItem extends StatelessWidget {
  final MascotDecoration? deco;
  final bool isSelected;
  final bool isNight;
  final bool isOwned;
  final int index;
  final bool shouldHighlight;
  final bool shouldAnimate;

  const _DecorationGridItem({
    required this.deco,
    required this.isSelected,
    required this.isNight,
    required this.isOwned,
    required this.index,
    this.shouldHighlight = false,
    this.shouldAnimate = true,
  });

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedOpacity(
        duration: 300.ms,
        opacity: isOwned ? 1.0 : 0.7,
        child: _buildItemContent(userState),
      ).animate(
        delay: shouldAnimate ? (index % 10 * 50).ms : Duration.zero,
        autoPlay: shouldAnimate,
      ).fadeIn(duration: shouldAnimate ? 400.ms : Duration.zero)
       .moveY(begin: shouldAnimate ? 15 : 0, end: 0, curve: Curves.easeOutCubic)
       .then(delay: shouldAnimate ? 600.ms : Duration.zero)
       .shake(hz: (shouldAnimate && shouldHighlight) ? 4 : 0, rotation: 0.05, duration: 400.ms),
    );
  }

  Widget _buildItemContent(UserState userState) {
    return Container(
      decoration: _buildItemDecoration(),
      child: Stack(
        children: [
          if (deco != null) _buildWatermark(),
          _buildContent(),
          if (isSelected) _buildCheckBadge(),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (!isOwned) {
      final achievement = MascotAchievement.getByRewardId(deco?.id ?? '');
      if (achievement == null) return;
      final userState = UserState();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => AchievementDetailSheet(
          achievement: achievement,
          isUnlocked: false,
          stats: userState.getAchievementStats(),
          isNight: isNight,
        ),
      );
      return;
    }
    UserState().setMascotDecoration(deco?.path);
  }

  BoxDecoration _buildItemDecoration() {
    final rarityColor = deco?.rarity.color ?? const Color(0xFFFFD97D);
    return BoxDecoration(
      color: isSelected
          ? (isNight
                ? const Color(0xFFFFD97D).withValues(alpha: 0.1)
                : const Color(0xFFFFFDE7))
          : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
      borderRadius: BorderRadius.circular(28),
      gradient: (isSelected && deco?.rarity == MascotRarity.legendary)
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNight
                  ? [const Color(0xFF2A2E50), const Color(0xFF13131F)]
                  : [const Color(0xFFFFFDE7), Colors.white],
            )
          : null,
      border: Border.all(
        color: isSelected ? rarityColor : (isNight ? Colors.white10 : const Color(0xFFEFEBE9)),
        width: isSelected ? 2.5 : 1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: rarityColor.withValues(alpha: isNight ? 0.2 : 0.3),
                blurRadius: deco?.rarity == MascotRarity.legendary ? 40 : 20,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.1 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  Widget _buildWatermark() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Opacity(
          opacity: isNight ? 0.05 : 0.08,
          child: Transform.scale(
            scale: 1.8,
            child: Image.asset(
              deco!.path,
              fit: BoxFit.contain,
              color: isOwned ? null : Colors.black.withValues(alpha: 0.1),
              colorBlendMode: isOwned ? null : BlendMode.srcATop,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: deco == null
              ? Center(
                  child: Icon(
                    Icons.block_rounded,
                    size: 40,
                    color: isNight ? Colors.white24 : Colors.black12,
                  ),
                )
              : _buildDecorationImage(),
        ),
        const SizedBox(height: 10),
        _buildTitleRow(),
        const SizedBox(height: 4),
        _buildDescription(),
      ],
    );
  }

  Widget _buildDecorationImage() {
    Widget image = Image.asset(deco!.path, fit: BoxFit.contain, gaplessPlayback: true);
    if (!isOwned) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        (image).animate(target: isSelected ? 1 : 0).scale(
          duration: 300.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
        ),
        if (!isOwned)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white70),
          ),
      ],
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (deco != null) _buildRarityTag(),
        Flexible(
          child: Text(
            deco?.name ?? '取消',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white : const Color(0xFF3E2723),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRarityTag() {
    return Opacity(
      opacity: isOwned ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [deco!.rarity.color.withValues(alpha: 0.85), deco!.rarity.color],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deco!.rarity == MascotRarity.legendary) ...[
              const Icon(Icons.workspace_premium, size: 11, color: Colors.white),
              const SizedBox(width: 3),
            ],
            Text(
              deco!.rarity.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final desc = deco == null
        ? '回归最初的纯净模样'
        : (isOwned
              ? deco!.description
              : '解锁成就：${MascotAchievement.getByRewardId(deco!.id)?.description ?? "未知要求"}');
    return Text(
      desc,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        color: isNight
            ? (isOwned ? Colors.white38 : const Color(0xFFFFD97D).withValues(alpha: 0.4))
            : (isOwned ? const Color(0xFF8D6E63) : const Color(0xFFD32F2F).withValues(alpha: 0.6)),
        fontFamily: 'LXGWWenKai',
        fontWeight: isOwned ? FontWeight.normal : FontWeight.w600,
      ),
    );
  }

  Widget _buildCheckBadge() {
    final rarityColor = deco?.rarity.color ?? const Color(0xFFFFD97D);
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: rarityColor, shape: BoxShape.circle),
        child: Icon(
          Icons.check,
          size: 14,
          color: deco?.rarity == MascotRarity.legendary ? const Color(0xFF3E2723) : Colors.white,
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

class _FormGridItem extends StatelessWidget {
  final Map<String, String> form;
  final bool isSelected;
  final bool isNight;
  final bool isLocked;
  final String? lockHint;
  final int index;
  final bool shouldAnimate;

  const _FormGridItem({
    required this.form,
    required this.isSelected,
    required this.isNight,
    required this.isLocked,
    this.lockHint,
    required this.index,
    this.shouldAnimate = true,
  });

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final path = form['path']!;
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          String msg = '该形象尚未解锁';
          if (path.contains('marshmallow4.png')) {
            msg = '开通会员即可解锁此形象';
          } else {
            try {
              final achievement = MascotAchievement.allAchievements.firstWhere((a) => a.rewardMascotPath == path);
              msg = '达成成就【${achievement.title}】即可解锁';
            } catch (_) {
              msg = '达成特定成就即可解锁该形象';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg, style: const TextStyle(fontFamily: 'LXGWWenKai', color: Colors.white, fontSize: 13)),
              behavior: SnackBarBehavior.floating,
              duration: 2.seconds,
              backgroundColor: isNight ? const Color(0xFF4B5563) : const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            ),
          );
          return;
        }
        HapticFeedback.lightImpact();
        userState.setMascotType(path);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _buildItemDecoration(isNight, form['rarity'] ?? '普通'),
        child: Stack(
          children: [
            if (isSelected) _buildCheckBadge(form['rarity'] ?? '普通'),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: isLocked ? 0.3 : 1.0,
                      child: StaticSprite(
                        assetPath: path,
                        decorationPath: null,
                        size: 80,
                        frameCount: path.contains('weixiao.png') ? 9 : 1,
                      ).animate(target: isSelected ? 1 : 0).scale(
                        duration: 300.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRarityTag(form['rarity'] ?? '普通'),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        form['name']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF818CF8) : (isNight ? Colors.white : const Color(0xFF3E2723)),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isLocked ? (lockHint ?? '已锁定') : form['desc']!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isLocked ? (isNight ? Colors.orangeAccent : Colors.deepOrange) : (isNight ? Colors.white38 : Colors.black26),
                      fontFamily: 'LXGWWenKai',
                      fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
            if (isLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: Icon(
                    path.contains('marshmallow4.png') ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                    size: 14,
                    color: isNight ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      ).animate(
        delay: shouldAnimate ? (index % 10 * 50).ms : Duration.zero,
        autoPlay: shouldAnimate,
      ).fadeIn(duration: 400.ms).moveY(begin: shouldAnimate ? 15 : 0, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildRarityTag(String rarity) {
    final color = _getRarityColor(rarity);
    final isPremium = rarity == '传说' || rarity == '卓越';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[Icon(rarity == '传说' ? Icons.workspace_premium : Icons.stars_rounded, size: 11, color: Colors.white), const SizedBox(width: 4)],
          Text(rarity, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'LXGWWenKai', letterSpacing: 0.5)),
        ],
      ),
    );
  }

  BoxDecoration _buildItemDecoration(bool isNight, String rarity) {
    final color = _getRarityColor(rarity);
    return BoxDecoration(
      color: isSelected ? (isNight ? color.withValues(alpha: 0.1) : const Color(0xFFF9F8FF)) : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isSelected ? color : (isNight ? Colors.white12 : const Color(0xffEEEEEE)), width: isSelected ? 2.5 : 1),
      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: isNight ? 0.2 : 0.25), blurRadius: rarity == '传说' ? 30 : 20, offset: const Offset(0, 6))] : [BoxShadow(color: Colors.black.withValues(alpha: isNight ? 0.05 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }

  Widget _buildCheckBadge(String rarity) {
    final color = _getRarityColor(rarity);
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Color _getRarityColor(String rarity) {
    if (rarity == '传说') return const Color(0xFFF59E0B);
    if (rarity == '卓越') return const Color(0xFFA855F7);
    return const Color(0xFF94A3B8);
  }
}
