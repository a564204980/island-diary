import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'dart:typed_data';

class MascotDecorationPage extends StatefulWidget {
  const MascotDecorationPage({super.key});

  @override
  State<MascotDecorationPage> createState() => _MascotDecorationPageState();
}

class _MascotDecorationPageState extends State<MascotDecorationPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 延迟 50ms 启动复杂组件渲染，确保 Scaffold 背景色先渲染，消除白屏闪烁
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Scaffold(
      backgroundColor: isNight
          ? const Color(0xFF13131F)
          : const Color(0xFFFDFCF7),
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
                  ),
                ),

                // --- 滚动区域：装饰列表 ---
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // 1. 标题行
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              _buildSectionIndicator(),
                              const SizedBox(width: 12),
                              Text(
                                '挑选装扮',
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
                                '${MascotDecoration.allDecorations.length + 1} 个选项',
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

                      // 2. 装扮网格 (监听拥有状态与所选状态)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        sliver: ListenableBuilder(
                          listenable: Listenable.merge([
                            userState.selectedMascotDecoration,
                            userState.ownedDecorationIds,
                          ]),
                          builder: (context, _) {
                            final currentDecoration = userState.selectedMascotDecoration.value;
                            final ownedIds = userState.ownedDecorationIds.value;

                            return SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == 0) {
                                    return _DecorationGridItem(
                                      deco: null,
                                      isSelected: currentDecoration == null,
                                      isNight: isNight,
                                      isOwned: true,
                                      index: index,
                                    );
                                  }

                                  final deco = MascotDecoration.allDecorations[index - 1];
                                  return _DecorationGridItem(
                                    deco: deco,
                                    isSelected: currentDecoration == deco.path,
                                    isNight: isNight,
                                    isOwned: ownedIds.contains(deco.id),
                                    index: index,
                                  );
                                },
                                childCount: MascotDecoration.allDecorations.length + 1,
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
                  const Color(0xFFFFD97D).withValues(alpha: 0.1),
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
                  const Color(0xFFEFEBE9).withValues(alpha: 0.3),
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
            '小软装扮中心',
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

  Widget _buildPreviewHero(String? decorationPath, bool isNight) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFDFCF7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: StaticSprite(
              key: ValueKey(decorationPath), 
              assetPath: 'assets/images/emoji/marshmallow.png',
              decorationPath: decorationPath,
              size: 200,
            ).animate()
             .scale(duration: 400.ms, curve: Curves.easeOutBack, begin: const Offset(0.9, 0.9))
             .fadeIn(duration: 400.ms)
             .then(delay: 500.ms)
             .shimmer(
                duration: 2500.ms,
                color: decorationPath != null && MascotDecoration.getByPath(decorationPath)?.rarity == MascotRarity.legendary
                    ? const Color(0xFFFFD97D).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
             ),
          ),
          _buildPreviewBadge(isNight),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(bool isNight) {
    return Positioned(
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF3E2723).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_red_eye_outlined, size: 14, color: isNight ? Colors.white38 : const Color(0xFF3E2723).withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              "当前外观预览",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isNight ? Colors.white38 : const Color(0xFF3E2723).withValues(alpha: 0.4),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
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

  const _DecorationGridItem({
    required this.deco,
    required this.isSelected,
    required this.isNight,
    required this.isOwned,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedOpacity(
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
      ).animate(delay: (index % 10 * 50).ms) 
       .fadeIn(duration: 400.ms)
       .moveY(begin: 15, end: 0, curve: Curves.easeOutCubic),
    );
  }

  void _handleTap(BuildContext context) {
    if (!isOwned) {
      final achievement = MascotAchievement.getByRewardId(deco?.id ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成就锁定：${achievement?.description ?? "尚未达成解锁条件"}', style: const TextStyle(fontFamily: 'LXGWWenKai')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
          ? (isNight ? const Color(0xFFFFD97D).withValues(alpha: 0.1) : const Color(0xFFFFFDE7))
          : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
      borderRadius: BorderRadius.circular(28),
      gradient: (isSelected && deco?.rarity == MascotRarity.legendary)
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNight ? [const Color(0xFF2A2E50), const Color(0xFF13131F)] : [const Color(0xFFFFFDE7), Colors.white],
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
              ? Center(child: Icon(Icons.block_rounded, size: 40, color: isNight ? Colors.white24 : Colors.black12))
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
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: image,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        (image).animate(target: isSelected ? 1 : 0)
               .scale(duration: 300.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
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
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final desc = deco == null 
        ? '回归最初的纯净模样' 
        : (isOwned ? deco!.description : '解锁成就：${MascotAchievement.getByRewardId(deco!.id)?.description ?? "未知要求"}');
    
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
