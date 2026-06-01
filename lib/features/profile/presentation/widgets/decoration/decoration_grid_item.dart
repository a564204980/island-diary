import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/profile/presentation/widgets/achievement_detail_sheet.dart';

class DecorationGridItem extends StatelessWidget {
  final MascotDecoration? deco;
  final bool isSelected;
  final bool isNight;
  final bool isOwned;
  final int index;
  final bool shouldHighlight;
  final bool shouldAnimate;

  const DecorationGridItem({
    super.key,
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
    final Widget content = Opacity(
      opacity: isOwned ? 1.0 : 0.7,
      child: _buildItemContent(userState),
    );

    if (!shouldAnimate) {
      return GestureDetector(
        onTap: () => _handleTap(context),
        child: content,
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: content
          .animate(
            delay: (index % 10 * 50).ms,
            autoPlay: true,
          )
          .fadeIn(duration: 400.ms)
          .moveY(
            begin: 15,
            end: 0,
            curve: Curves.easeOutCubic,
          )
          .then(delay: 600.ms)
          .shake(
            hz: shouldHighlight ? 4 : 0,
            rotation: 0.05,
            duration: 400.ms,
          ),
    );
  }

  Widget _buildItemContent(UserState userState) {
    return Container(
      decoration: _buildItemDecoration(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (deco != null) _buildWatermark(),
          _buildContent(),
          if (isSelected) _buildCheckBadge(),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) async {
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

    final userState = UserState();

    // 一键全量清空逻辑：如果点击的是“取消”占位符，一律同步卸载所有槽位
    if (deco == null) {
      await userState.setMascotDecoration(null);
      await userState.setSelectedGlassesDecoration(null);
      return;
    }

    final bool isGlasses = deco?.category == MascotDecorationCategory.glasses;
    final bool isOverlayEnabled = userState.isGlassesOverlayEnabled.value;

    if (isOverlayEnabled && isGlasses) {
      // 叠戴模式开启且是眼镜：操作独立眼镜槽位
      if (userState.selectedGlassesDecoration.value == deco?.path) {
        userState.setSelectedGlassesDecoration(null);
      } else {
        userState.setSelectedGlassesDecoration(deco?.path);
      }
    } else {
      // 叠戴模式关闭 或 非眼镜物品：操作基础槽位
      if (userState.selectedMascotDecoration.value == deco?.path) {
        userState.setMascotDecoration(null);
      } else {
        userState.setMascotDecoration(deco?.path);
      }
    }
  }

  BoxDecoration _buildItemDecoration() {
    final rarityColor = deco?.rarity.color ?? const Color(0xFFFFD97D);
    return BoxDecoration(
      color: isSelected
          ? (isNight
              ? const Color(0xFFFFD97D).withValues(alpha: 0.1)
              : const Color(0xFFFFFDE7))
          : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
      borderRadius: BorderRadius.circular(20), // 适应3列，圆角微缩到20
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
          : null,
    );
  }

  Widget _buildWatermark() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // 对齐20像素圆角
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // 底部优雅留白
      child: Column(
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
          const SizedBox(height: 6), // 间距收紧
          _buildTitleRow(),
          const SizedBox(height: 3),
          _buildDescription(),
        ],
      ),
    );
  }

  Widget _buildDecorationImage() {
    Widget image = Image.asset(
      deco!.path,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
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
    final Widget mainImage = isSelected
        ? Transform.scale(scale: 1.1, child: image)
        : image;

    if (!shouldAnimate) {
      if (!isOwned) {
        return Stack(
          alignment: Alignment.center,
          children: [
            mainImage,
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
      return mainImage;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), // 左右收紧 8 像素安全边距
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (deco != null) _buildRarityTag(),
          Flexible(
            child: Text(
              deco?.name ?? '取消',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12, // 标题字号由 14 优化到 12
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white : const Color(0xFF3E2723),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityTag() {
    return Opacity(
      opacity: isOwned ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // padding 缩紧
        margin: const EdgeInsets.only(right: 4), // 间距缩紧
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
                size: 9, // 图标缩小到 9
                color: Colors.white,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              deco!.rarity.label,
              style: const TextStyle(
                fontSize: 8, // 字号调小为 8
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
            : '解锁：${MascotAchievement.getByRewardId(deco!.id)?.description ?? "未知"}');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), // 左右收紧 8 像素安全边距，防贴边
      child: Text(
        desc,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8.5, // 描述文字缩小到 8.5，绝不溢出
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
      ),
    );
  }

  Widget _buildCheckBadge() {
    final rarityColor = deco?.rarity.color ?? const Color(0xFFFFD97D);
    return Positioned(
      top: -5,
      right: -5,
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
