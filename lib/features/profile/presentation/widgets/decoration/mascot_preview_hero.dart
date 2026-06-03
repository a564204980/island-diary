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
        final mascotDec = MascotDecoration.getByPath(userState.selectedMascotDecoration.value);
        final glassesDec = MascotDecoration.getByPath(userState.selectedGlassesDecoration.value);
        final activeDec = mascotDec ?? glassesDec;
        final hasDec = activeDec != null;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          clipBehavior: Clip.none,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                StaticSprite(
                  assetPath: mascotType,
                  size: 130, // 头像尺寸由 200 精简为 130，比例更和谐
                )
                    .animate() // 移除 key 绑定，防止切换装备时头像重复播放缩放动画
                    .scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.9, 0.9),
                    )
                    .fadeIn(duration: 400.ms)
                    .then(delay: 500.ms)
                    .shimmer(
                      duration: 2500.ms,
                      color: activeDec?.rarity == MascotRarity.legendary
                          ? const Color(0xFFFFD97D).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: hasDec ? 1.0 : 0.0,
                  child: SizedBox(
                    height: hasDec ? 48 : 0,
                    child: hasDec
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeDec.rarity.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: activeDec.rarity.color,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      activeDec.rarity.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: activeDec.rarity.color,
                                        fontFamily: 'LXGWWenKai',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    activeDec.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isNight ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  activeDec.description,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isNight ? Colors.white60 : Colors.black54,
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildButtons(context, hasDec),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtons(BuildContext context, bool isDressed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showFormSelectionSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
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
            onTap: () async {
              await userState.setMascotDecoration(null);
              await userState.setSelectedGlassesDecoration(null);
            },
            child: Container(
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
  }

  void _showFormSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MascotFormSelectionSheet(
        isNight: isNight,
        userState: userState,
      ),
    );
  }
}
