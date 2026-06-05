import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/decoration_grid_item.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/mascot_preview_hero.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/form_selection_sheet.dart';

class MascotDecorationPage extends StatefulWidget {
  final String? initialDecorationId;
  const MascotDecorationPage({super.key, this.initialDecorationId});

  @override
  State<MascotDecorationPage> createState() => _MascotDecorationPageState();
}

class _MascotDecorationPageState extends State<MascotDecorationPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MascotDecorationCategory? _selectedCategory;
  bool _isInitialized = false;



  bool _isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预热形象图片
    for (var form in MascotFormSelectionSheet.mascotForms) {
      precacheImage(AssetImage(form['path']!), context);
    }
  }

  @override
  void initState() {
    super.initState();

    // 如果指定了初始 ID，则尝试自动匹配其分类
    if (widget.initialDecorationId != null) {
      final targetDeco = MascotDecoration.allDecorations.where(
        (d) => d.id == widget.initialDecorationId
      ).firstOrNull;
      if (targetDeco != null) {
        _selectedCategory = targetDeco.category;
      }
    }

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.initialDecorationId != null) {
          _scrollToTarget();
        }
      }
    });
  }

  List<MascotDecoration> _getFilteredDecorations(List<String> ownedIds) {
    return MascotDecoration.allDecorations.where((deco) {
      // 默认解锁所有饰品，不再在此过滤未拥有的饰品
      if (deco.category == MascotDecorationCategory.other) {
        return false;
      }

      // 分类过滤
      if (_selectedCategory != null && deco.category != _selectedCategory) {
        return false;
      }

      // 搜索过滤
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
    final crossAxisCount = screenWidthForGrid > 600 ? 4 : 3; // 精准对齐 3 列微格
    final gridWidth = screenWidthForGrid - 48;
    final itemWidth = (gridWidth - (crossAxisCount - 1) * 10) / crossAxisCount;
    final itemAspectRatio = screenWidthForGrid > 600 ? 0.8 : 0.82;
    final itemHeight = itemWidth / itemAspectRatio;

    final rowIndex = (index / crossAxisCount).floor();
    final scrollOffset = headerHeight + (rowIndex * (itemHeight + 10)); // 间距 10

    _scrollController.animateTo(
      scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: 800.ms,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    UserState().refreshNavbarBgTrigger.value++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          userState.flushMascotEvent();
        }
      },
      child: Scaffold(
        backgroundColor: isNight
            ? const Color(0xFF0D1B2A)
            : const Color(0xFFE6F3F5),
        extendBodyBehindAppBar: true,
        appBar: _buildStandardAppBar(context, isNight),
        body: !_isInitialized
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  // 1. 背景装饰
                  if (!isNight) _buildLightBackground(),
  
                  // 2. 核心交互区域 (应用 800px 宽度限制)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: SafeArea(
                            child: Column(
                              children: [
                              // --- 固定区域：预览英雄区域 ---
                              ListenableBuilder(
                                listenable: Listenable.merge([
                                  userState.selectedMascotDecoration,
                                  userState.selectedGlassesDecoration,
                                  userState.selectedEarringDecoration,
                                  userState.selectedBackgroundDecoration,
                                  userState.selectedMascotType,
                                ]),
                                builder: (context, _) => MascotPreviewHero(
                                  mascotType: userState.selectedMascotType.value,
                                  isNight: isNight,
                                  userState: userState,
                                ),
                              ),
  
                              // --- 动态可折叠搜索栏 ---
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _isSearchActive
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 6,
                                        ),
                                        child: _buildSearchBar(isNight),
                                      )
                                    : const SizedBox.shrink(),
                              ),
  
                              // --- 滚动过滤区域 ---
                              Expanded(
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  slivers: [
                                    // --- 标题区域 ---
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
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
  
                                    // --- 吸顶分类过滤区域 ---
                                    SliverPersistentHeader(
                                      pinned: true,
                                      delegate: _StickyCategoryHeaderDelegate(
                                        height: 54.0,
                                        backgroundColor: isNight
                                            ? const Color(0xFF0D1B2A)
                                            : const Color(0xFFE6F3F5),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: _buildCategoryFilters(isNight),
                                        ),
                                      ),
                                    ),
  
                                    // --- 网格列表 ---
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
                                      sliver: ListenableBuilder(
                                        listenable: Listenable.merge([
                                          userState.selectedMascotDecoration,
                                          userState.selectedGlassesDecoration,
                                          userState.selectedEarringDecoration,
                                          userState.selectedBackgroundDecoration,
                                          userState.isGlassesOverlayEnabled,
                                          userState.selectedMascotType,
                                          userState.ownedDecorationIds,
                                        ]),
                                        builder: (context, _) {
                                          final currentDecoration = userState.selectedMascotDecoration.value;
                                          final currentGlasses = userState.selectedGlassesDecoration.value;
                                          final currentEarring = userState.selectedEarringDecoration.value;
                                          final currentBackground = userState.selectedBackgroundDecoration.value;
                                          final isOverlay = userState.isGlassesOverlayEnabled.value;
                                          final ownedIds = userState.ownedDecorationIds.value;
                                          final displayedDecorations = _getFilteredDecorations(ownedIds);
  
                                          if (displayedDecorations.isEmpty) {
                                            return _buildEmptyState(isNight);
                                          }
  
                                          return SliverGrid(
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: constraints.maxWidth > 600 ? 4 : 3, // 手机端3列，更轻巧精致
                                              mainAxisSpacing: 10,
                                              crossAxisSpacing: 10,
                                              childAspectRatio: constraints.maxWidth > 600 ? 0.8 : 0.82,
                                            ),
                                            delegate: SliverChildBuilderDelegate(
                                              (context, index) {
                                                final deco = displayedDecorations[index];
                                                final bool isGlasses = deco.category == MascotDecorationCategory.glasses;
                                                final bool isEarring = deco.category == MascotDecorationCategory.face;
                                                final bool isBackground = deco.category == MascotDecorationCategory.other;
                                                
                                                final bool isSelected = isEarring
                                                    ? currentEarring == deco.path
                                                    : isBackground
                                                        ? currentBackground == deco.path
                                                        : (isOverlay && isGlasses) 
                                                            ? currentGlasses == deco.path
                                                            : currentDecoration == deco.path;
  
                                                return DecorationGridItem(
                                                  deco: deco,
                                                  isSelected: isSelected,
                                                  isNight: isNight,
                                                  isOwned: true,
                                                  index: index,
                                                  shouldHighlight: deco.id == widget.initialDecorationId,
                                                  shouldAnimate: false,
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
                      ),
                    );
                  },
                ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(bool isNight) {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
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
          Positioned.fill(
            left: 44,
            child: TextField(
              focusNode: _searchFocusNode,
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
              decoration: const InputDecoration(
                hintText: '寻找你心仪的装扮...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
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
      ],
    );
  }

  Widget _buildCategoryFilters(bool isNight) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip(null, '全部', isNight),
                for (var category in MascotDecorationCategory.values.where((c) => c != MascotDecorationCategory.other)) ...[
                  const SizedBox(width: 8),
                  _buildCategoryChip(category, category.label, isNight),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildExtraSettingsButton(isNight),
        ),
      ],
    );
  }

  Widget _buildExtraSettingsButton(bool isNight) {
    return GestureDetector(
      onTap: () => _showGlassesSettings(context, isNight),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(
            color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          size: 18,
          color: isNight ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  void _showGlassesSettings(BuildContext context, bool isNight) {
    final userState = UserState();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSectionIndicator(),
                const SizedBox(width: 12),
                Text(
                  "搭配偏好",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : Colors.black87,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: userState.isGlassesOverlayEnabled,
              builder: (context, _) {
                final enabled = userState.isGlassesOverlayEnabled.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: enabled 
                        ? (isNight ? const Color(0xFFFBBC05).withValues(alpha: 0.3) : const Color(0xFFFBBC05).withValues(alpha: 0.2))
                        : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "眼镜叠戴模式",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white : Colors.black87,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "开启后，眼镜可以与帽子、耳饰同时穿戴",
                              style: TextStyle(
                                fontSize: 12,
                                color: isNight ? Colors.white38 : Colors.black45,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: enabled,
                        activeColor: const Color(0xFFFBBC05),
                        onChanged: (val) => userState.setGlassesOverlayEnabled(val),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: userState.isGlassesAboveHat,
              builder: (context, _) {
                final isAbove = userState.isGlassesAboveHat.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAbove 
                        ? (isNight ? const Color(0xFFFBBC05).withValues(alpha: 0.3) : const Color(0xFFFBBC05).withValues(alpha: 0.2))
                        : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "图层叠放优先级",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white : Colors.black87,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "开启后眼镜覆盖帽子，关闭后帽子覆盖眼镜",
                              style: TextStyle(
                                fontSize: 12,
                                color: isNight ? Colors.white38 : Colors.black45,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAbove,
                        activeColor: const Color(0xFFFBBC05),
                        onChanged: (val) => userState.setGlassesAboveHat(val),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(MascotDecorationCategory? category, String label, bool isNight) {
    final isSelected = _selectedCategory == category;
    final primaryColor = isNight ? const Color(0xFFFBBC05) : const Color(0xFFFBBC05);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isNight ? 0.15 : 0.1)
              : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.5)
                : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? primaryColor
                : (isNight ? Colors.white70 : Colors.black54),
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
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

  PreferredSizeWidget _buildStandardAppBar(BuildContext context, bool isNight) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isNight ? Brightness.light : Brightness.dark,
        statusBarBrightness: isNight ? Brightness.dark : Brightness.light,
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: isNight ? Colors.white70 : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '小软装扮中心',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontFamily: 'LXGWWenKai',
          color: isNight ? Colors.white : const Color(0xFF1A1A1A),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
            size: 22,
            color: isNight ? Colors.white70 : Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (_isSearchActive) {
                _searchFocusNode.requestFocus();
              } else {
                _searchFocusNode.unfocus();
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  _StickyCategoryHeaderDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
