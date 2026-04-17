import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement_detail_sheet.dart';

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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 延迟 50ms 启动复杂组件渲染，确保 Scaffold 背景色先渲染，消除白屏闪烁
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isInitialized = true);

        // 如果有初始 ID，则尝试滚动
        if (widget.initialDecorationId != null) {
          _scrollToTarget();
        }
      }
    });
  }

  void _scrollToTarget() async {
    // 等待一帧确保列表已构建
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final userState = UserState();
    final ownedIds = userState.ownedDecorationIds.value;

    // 找到在列表中的索引
    final displayedDecorations = MascotDecoration.allDecorations.where((deco) {
      return ownedIds.contains(deco.id);
    }).toList();

    final index = displayedDecorations.indexWhere(
      (d) => d.id == widget.initialDecorationId,
    );
    if (index == -1) return;

    // 计算滚动的偏移量
    // 头部高度：8 (spacer) + ~60 (title row) + 16 (padding)
    const headerHeight = 68.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final gridWidth = screenWidth - 48; // 左右 padding 24
    final itemWidth = (gridWidth - 16) / 2; // 中间 spacing 16
    final itemHeight = itemWidth / 0.8; // childAspectRatio 0.8

    final rowIndex = (index / 2).floor();
    final scrollOffset = headerHeight + (rowIndex * (itemHeight + 16));

    _scrollController.animateTo(
      scrollOffset,
      duration: 600.ms,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
                // 背景装饰
                if (!isNight) _buildLightBackground(),

                SafeArea(
                  child: Column(
                    children: [
                      // --- 固定区域：AppBar ---
                      _buildAppBar(context, isNight),

                      // --- 固定区域：预览区域 (监听所选装扮) ---
                      ListenableBuilder(
                        listenable: userState.selectedMascotDecoration,
                        builder: (context, _) => _buildPreviewHero(
                          userState.selectedMascotDecoration.value,
                          isNight,
                          userState,
                        ),
                      ),

                      // --- 滚动区域：装饰列表 ---
                      Expanded(
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 12),
                            ),

                            // 1. 搜索栏
                            _buildSearchBar(isNight),

                            // 2. 标题行
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
                                        color: isNight
                                            ? Colors.white
                                            : const Color(0xFF3E2723),
                                        fontFamily: 'LXGWWenKai',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${userState.ownedDecorationIds.value.length} 个已解锁',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isNight
                                            ? Colors.white38
                                            : Colors.black26,
                                        fontFamily: 'LXGWWenKai',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. 装扮网格 (监听拥有状态与所选状态)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                              sliver: ListenableBuilder(
                                listenable: Listenable.merge([
                                  userState.selectedMascotDecoration,
                                  userState.ownedDecorationIds,
                                ]),
                                builder: (context, _) {
                                  final currentDecoration =
                                      userState.selectedMascotDecoration.value;
                                  final ownedIds =
                                      userState.ownedDecorationIds.value;

                                  // 1. 过滤：已获得 + 搜索关键词
                                  final displayedDecorations = MascotDecoration
                                      .allDecorations
                                      .where((deco) {
                                        final isOwned = ownedIds.contains(
                                          deco.id,
                                        );
                                        if (!isOwned) return false;

                                        if (_searchQuery.isEmpty) return true;
                                        final query = _searchQuery
                                            .toLowerCase();
                                        return deco.name.toLowerCase().contains(
                                              query,
                                            ) ||
                                            deco.description
                                                .toLowerCase()
                                                .contains(query);
                                      })
                                      .toList();

                                  if (displayedDecorations.isEmpty) {
                                    return SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 60),
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 64,
                                            color: isNight
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '没有找到相关装扮',
                                            style: TextStyle(
                                              color: isNight
                                                  ? Colors.white38
                                                  : Colors.black26,
                                              fontFamily: 'LXGWWenKai',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          childAspectRatio: 0.8,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final deco = displayedDecorations[index];
                                      return _DecorationGridItem(
                                        deco: deco,
                                        isSelected:
                                            currentDecoration == deco.path,
                                        isNight: isNight,
                                        isOwned: true, // 能出现在列表里的肯定都是已拥有的
                                        index: index,
                                        shouldHighlight:
                                            deco.id ==
                                            widget.initialDecorationId,
                                      );
                                    }, childCount: displayedDecorations.length),
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
              ],
            ),
    );
  }

  Widget _buildSearchBar(bool isNight) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isNight
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: isNight
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
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
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: isNight ? Colors.white24 : Colors.black26,
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
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
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
    bool isNight,
    UserState userState,
  ) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.8),
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
            child:
                StaticSprite(
                      key: ValueKey(decorationPath),
                      assetPath: 'assets/images/emoji/marshmallow.png',
                      decorationPath: decorationPath,
                      size: 200,
                    )
                    .animate()
                    .scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.9, 0.9),
                    )
                    .fadeIn(duration: 400.ms)
                    .then(delay: 500.ms)
                    .shimmer(
                      duration: 2500.ms,
                      color:
                          decorationPath != null &&
                              MascotDecoration.getByPath(
                                    decorationPath,
                                  )?.rarity ==
                                  MascotRarity.legendary
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
              // 1. 状态标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFF3E2723).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNight
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 14,
                      color: isNight
                          ? Colors.white38
                          : const Color(0xFF3E2723).withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "当前外观预览",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isNight
                            ? Colors.white38
                            : const Color(0xFF3E2723).withValues(alpha: 0.4),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 卸下按钮（仅在穿着时显示）
              if (isDressed) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => userState.setMascotDecoration(null),
                  child:
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isNight
                                  ? const Color(
                                      0xFFE57373,
                                    ).withValues(alpha: 0.15)
                                  : const Color(
                                      0xFFD32F2F,
                                    ).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isNight
                                    ? const Color(
                                        0xFFE57373,
                                      ).withValues(alpha: 0.2)
                                    : const Color(
                                        0xFFD32F2F,
                                      ).withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: isNight
                                      ? const Color(0xFFEF9A9A)
                                      : const Color(0xFFC62828),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "卸下",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isNight
                                        ? const Color(0xFFEF9A9A)
                                        : const Color(0xFFC62828),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 独立的装扮网格项组件，提升渲染性能
class _DecorationGridItem extends StatelessWidget {
  final MascotDecoration? deco;
  final bool isSelected;
  final bool isNight;
  final bool isOwned;
  final int index;
  final bool shouldHighlight;

  const _DecorationGridItem({
    required this.deco,
    required this.isSelected,
    required this.isNight,
    required this.isOwned,
    required this.index,
    this.shouldHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child:
          AnimatedOpacity(
                duration: 300.ms,
                opacity: isOwned ? 1.0 : 0.7,
                child: AnimatedContainer(
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(12),
                  decoration: _buildItemDecoration(),
                  child: Stack(
                    children: [
                      if (deco != null) _buildWatermark(),
                      _buildContent(),
                      if (isSelected) _buildCheckBadge(),
                    ],
                  ),
                ),
              )
              .animate(delay: (index % 10 * 50).ms)
              .fadeIn(duration: 400.ms)
              .moveY(begin: 15, end: 0, curve: Curves.easeOutCubic)
              .then(delay: 600.ms) // 等待滚动准备到位
              .shake(
                hz: shouldHighlight ? 4 : 0,
                rotation: 0.05,
                duration: 400.ms,
              ), // 仅高亮项抖动
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
        color: isSelected
            ? rarityColor
            : (isNight ? Colors.white10 : const Color(0xFFEFEBE9)),
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
    Widget image = Image.asset(deco!.path, fit: BoxFit.contain);
    if (!isOwned) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        (image)
            .animate(target: isSelected ? 1 : 0)
            .scale(
              duration: 300.ms,
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
            ),
        if (!isOwned)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Colors.white70,
            ),
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
            colors: [
              deco!.rarity.color.withValues(alpha: 0.85),
              deco!.rarity.color,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deco!.rarity == MascotRarity.legendary) ...[
              const Icon(
                Icons.workspace_premium,
                size: 11,
                color: Colors.white,
              ),
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
            ? (isOwned
                  ? Colors.white38
                  : const Color(0xFFFFD97D).withValues(alpha: 0.4))
            : (isOwned
                  ? const Color(0xFF8D6E63)
                  : const Color(0xFFD32F2F).withValues(alpha: 0.6)),
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
          color: deco?.rarity == MascotRarity.legendary
              ? const Color(0xFF3E2723)
              : Colors.white,
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}
