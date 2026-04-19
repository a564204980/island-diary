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
            child: ListenableBuilder(
              listenable: Listenable.merge([
                userState.selectedMascotDecoration,
                userState.selectedGlassesDecoration,
              ]),
              builder: (context, _) {
                return StaticSprite(
                  assetPath: mascotType,
                  size: 200,
                );
              },
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
                  color: userState.selectedMascotDecoration.value != null &&
                          MascotDecoration.getByPath(userState.selectedMascotDecoration.value!)?.rarity ==
                              MascotRarity.legendary
                      ? const Color(0xFFFFD97D).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
          ),
          _buildPreviewBadge(context),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(BuildContext context) {
    return Positioned(
      bottom: 16,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          userState.selectedMascotDecoration,
          userState.selectedGlassesDecoration,
        ]),
        builder: (context, _) {
          final isDressed = userState.selectedMascotDecoration.value != null || 
                              userState.selectedGlassesDecoration.value != null;
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
        },
      ),
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
