import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/form_selection_sheet.dart';

class MascotPreviewHero extends StatelessWidget {
  final String mascotType;
  final bool isNight;
  final UserState userState;

  const MascotPreviewHero({
    super.key,
    required this.mascotType,
    required this.isNight,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.selectedMascotDecoration,
        userState.selectedGlassesDecoration,
      ]),
      builder: (context, _) {
        final mascotDec = MascotDecoration.getByPath(
          userState.selectedMascotDecoration.value,
        );
        final glassesDec = MascotDecoration.getByPath(
          userState.selectedGlassesDecoration.value,
        );
        final activeDec = mascotDec ?? glassesDec;
        final hasDec = activeDec != null;

        final currentForm = MascotFormSelectionSheet.mascotForms.firstWhere(
          (form) => form['path'] == mascotType,
          orElse: () => MascotFormSelectionSheet.mascotForms.first,
        );
        final String formName = currentForm['name']!;
        final String formDesc = currentForm['desc']!;
        final String formRarityStr = currentForm['rarity']!;
        
        MascotRarity formRarity = MascotRarity.common;
        if (formRarityStr == '传说') formRarity = MascotRarity.legendary;
        if (formRarityStr == '卓越') formRarity = MascotRarity.epic;
        if (formRarityStr == '稀有') formRarity = MascotRarity.rare;

        final String displayName = hasDec ? activeDec.name : formName;
        final String displayDesc = hasDec ? activeDec.description : formDesc;
        final MascotRarity displayRarity = hasDec
            ? activeDec.rarity
            : formRarity;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: isNight
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNight
                  ? Colors.white10
                  : Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 高达专属背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.id == 'mask' && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/emoji/modules_bg/gaoda_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 如意凤冠专属背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.id == 'phoenix_crown' && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/emoji/modules_bg/ruyifengguan_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 可爱粉色发夹怪专属背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.id == 'yellow_duck_hat' && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/emoji/modules_bg/3.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 糖心醒狮专属背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.id == 'candy_heart_lion' && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/emoji/modules_bg/4.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 专属传说背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.rarity == MascotRarity.legendary && activeDec.category != MascotDecorationCategory.hat && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/review/chuanshuo_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 专属卓越背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.rarity == MascotRarity.epic && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/review/zhuoyue_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 专属稀有背景图片层（带淡入淡出动效，夜间不使用）
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (hasDec && activeDec.rarity == MascotRarity.rare && !isNight)
                      ? 1.0
                      : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/review/xiyou_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 头像正后方的柔和品质光晕 (Glow)
              _buildGlowBg(activeDec?.rarity),
              // 内容主体
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    StaticSprite(
                      assetPath: mascotType,
                      size: 130, // 头像尺寸由 200 精简为 130，比例更和谐
                    )
                    .animate(
                      key: ValueKey(activeDec?.id),
                    ) // 绑定 key，在换装时触发过渡动画
                    .scale(
                      duration: 400.ms,
                      curve: Curves.elasticOut, // Q弹软萌的弹性过渡，极其顺滑
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                    )
                    .shimmer(
                      duration: 600.ms,
                      color: (activeDec?.rarity.color ?? Colors.white)
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 6),
                    // 固定高度的装扮信息区域，保证有无装扮时卡片高度完全一致
                    SizedBox(
                      height: 56,
                      child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: 1.0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 左侧国风渐变线与小菱形
                                      Container(
                                        width: 20,
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              displayRarity.color.withValues(alpha: 0.0),
                                              displayRarity.color.withValues(alpha: 0.6),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Transform.rotate(
                                        angle: 45 * 3.1415926535 / 180,
                                        child: Container(
                                          width: 4,
                                          height: 4,
                                          color: displayRarity.color.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 椭圆胶囊品质标签
                                      _buildRarityTag(displayRarity),
                                      const SizedBox(width: 8),
                                      // 装备名称
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isNight
                                              ? Colors.white.withValues(alpha: 0.9)
                                              : Colors.black87,
                                          fontFamily: 'SweiFistLeg',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 右侧小菱形与国风渐变线
                                      Transform.rotate(
                                        angle: 45 * 3.1415926535 / 180,
                                        child: Container(
                                          width: 4,
                                          height: 4,
                                          color: displayRarity.color.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 20,
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              displayRarity.color.withValues(alpha: 0.6),
                                              displayRarity.color.withValues(alpha: 0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: SizedBox(
                                      height: 30, // 限制描述文字高度，最多支持 2 行折行，防止溢出
                                      child: Text(
                                        displayDesc,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isNight
                                              ? Colors.white60
                                              : Colors.black54,
                                          fontFamily: 'SweiFistLeg',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    _buildButtons(context, hasDec),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowBg(MascotRarity? rarity) {
    if (rarity == null || rarity == MascotRarity.common)
      return const SizedBox.shrink();

    final Color glowColor = rarity.color.withValues(
      alpha: isNight ? 0.15 : 0.22,
    );

    return Positioned(
      top: 35, // 大概在头像的正中心后方
      left: 0,
      right: 0,
      child: Center(
        child:
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 65, // 超大模糊半径使得光晕极柔和晕开
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  duration: 3000.ms,
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }

  Widget _buildRarityTag(MascotRarity rarity) {
    Color rarityColor = rarity.color;
    BoxDecoration decoration;
    TextStyle textStyle;

    if (rarity == MascotRarity.legendary) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rarityColor.withValues(alpha: 0.25),
            rarityColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.5),
          width: 1,
        ),
      );
      textStyle = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: rarityColor,
        fontFamily: 'SweiFistLeg',
      );
    } else if (rarity == MascotRarity.epic) {
      decoration = BoxDecoration(
        color: rarityColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      );
      textStyle = const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'SweiFistLeg',
      );
    } else if (rarity == MascotRarity.rare) {
      decoration = BoxDecoration(
        color: rarityColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      );
      textStyle = const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'SweiFistLeg',
      );
    } else {
      decoration = BoxDecoration(
        color: rarityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      );
      textStyle = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: rarityColor.withValues(alpha: 0.8),
        fontFamily: 'SweiFistLeg',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: decoration,
      child: Text(
        rarity.label,
        style: textStyle,
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isDressed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showFormSelectionSheet(context),
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
                const Icon(
                  Icons.auto_fix_high_rounded,
                  size: 14,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 6),
                Text(
                  "变身",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isNight
                        ? const Color(0xFFC4B5FD)
                        : const Color(0xFF7C3AED),
                    fontFamily: 'SweiFistLeg',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDressed) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await userState.setMascotDecoration(null);
              await userState.setSelectedGlassesDecoration(null);
            },
            child:
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                              fontFamily: 'SweiFistLeg',
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
  }

  void _showFormSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          MascotFormSelectionSheet(isNight: isNight, userState: userState),
    );
  }
}
