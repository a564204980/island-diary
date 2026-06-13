import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/pages/security_center_page.dart';
import 'package:island_diary/features/profile/presentation/pages/mascot_decoration_page.dart';
import 'package:island_diary/features/profile/presentation/pages/about_island_page.dart';
import 'package:island_diary/features/profile/presentation/pages/cloud_sync_page.dart';
import 'package:island_diary/features/profile/presentation/widgets/bento_box.dart';
import 'package:island_diary/features/profile/presentation/pages/diary_books_page.dart';
import 'package:island_diary/features/profile/presentation/widgets/life_line_switcher_sheet.dart';
import 'package:island_diary/core/models/life_line_profile.dart';
import 'package:island_diary/features/record/presentation/pages/diary_drafts_page.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';

class BentoMenuGrid extends StatelessWidget {
  final bool isNight;
  const BentoMenuGrid({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildThemeBento(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '\u5c9b\u5c7f\u5b89\u5168',
                      icon: Icons.lock_outline,
                      color: const Color(0xFF81C784),
                      targetPage: const SecurityCenterPage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '岁月成书',
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFF64B5F6),
                      targetPage: const DiaryBooksPage(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '\u5c0f\u8f6f\u7684\u8863\u5e3d\u95f4',
                      icon: Icons.auto_fix_high_rounded,
                      color: const Color(0xFFFFB74D),
                      targetPage: const MascotDecorationPage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '备份与恢复',
                      icon: Icons.settings_backup_restore_rounded,
                      color: const Color(0xFF00ACC1),
                      targetPage: const CloudSyncPage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDraftsBentoAction(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '\u5173\u4e8e\u5c0f\u5c9b',
                      icon: Icons.info_outline,
                      color: const Color(0xFFBA68C8),
                      targetPage: const AboutIslandPage(),
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
        }
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 1, child: _buildThemeBento(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildMenuActionBento(
                            context,
                            title: '\u5c9b\u5c7f\u5b89\u5168',
                            icon: Icons.lock_outline,
                            color: const Color(0xFF81C784),
                            targetPage: const SecurityCenterPage(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildMenuActionBento(
                            context,
                            title: '岁月成书',
                            icon: Icons.auto_stories_rounded,
                            color: const Color(0xFF64B5F6),
                            targetPage: const DiaryBooksPage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '\u5c0f\u8f6f\u7684\u8863\u5e3d\u95f4',
                      icon: Icons.auto_fix_high_rounded,
                      color: const Color(0xFFFFB74D),
                      targetPage: const MascotDecorationPage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuActionBento(
                      context,
                      title: '备份与恢复',
                      icon: Icons.settings_backup_restore_rounded,
                      color: const Color(0xFF00ACC1),
                      targetPage: const CloudSyncPage(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildLifeLineBento(context),
            const SizedBox(height: 12),
            _buildDraftsBentoAction(context),
            const SizedBox(height: 12),
            _buildMenuActionBento(
              context,
              title: '\u5173\u4e8e\u5c0f\u5c9b',
              icon: Icons.info_outline,
              color: const Color(0xFFBA68C8),
              targetPage: const AboutIslandPage(),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildThemeBento(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isUnsupported = themeId == 'lego' || themeId == 'cotton_candy';
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, currentMode, _) {
        return _ThemeOptionsWidget(
          isNight: isNight,
          currentMode: currentMode,
          isUnsupported: isUnsupported,
        );
      },
    );
  }

  Widget _buildMenuActionBento(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget targetPage,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: true,
            barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
            pageBuilder: (context, animation, secondaryAnimation) => targetPage,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
      child: _buildQuickActionBento(title: title, icon: icon, color: color),
    );
  }


  Widget _buildQuickActionBento({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return BentoBox(
      isNight: isNight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white70 : Colors.black87,
                fontFamily: _getFontFamily(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeLineBento(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const LifeLineSwitcherSheet(),
        );
      },
      child: BentoBox(
        isNight: isNight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u4eba\u751f\u7ebf',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white70 : Colors.black87,
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: UserState().currentLifeLineId,
                    builder: (context, id, _) {
                      final profiles = UserState().lifeLines.value;
                      final current = profiles.firstWhere(
                        (p) => p.id == id,
                        orElse: () => LifeLineProfile(
                          id: 'default',
                          name: '\u6d77\u5c9b\u65b0\u5c45\u6c11',
                          createdAt: 0,
                        ),
                      );
                      return Text(
                        '\u5f53\u524d: ${current.name}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isNight ? Colors.white38 : Colors.black38,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsBentoAction(BuildContext context) {
    return ValueListenableBuilder<List<DiaryDraft>>(
      valueListenable: UserState().savedDrafts,
      builder: (context, drafts, _) {
        final count = drafts.length;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: true,
                barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
                pageBuilder: (context, animation, secondaryAnimation) => const DiaryDraftsPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: BentoBox(
            isNight: isNight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC407A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFEC407A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "草稿箱",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white70 : Colors.black87,
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD35D5D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$count",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}

class _ThemeOptionsWidget extends StatelessWidget {
  final bool isNight;
  final String currentMode;
  final bool isUnsupported;

  const _ThemeOptionsWidget({
    required this.isNight,
    required this.currentMode,
    required this.isUnsupported,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> modes = ['light', 'dark', 'auto'];
    final int selectedIndex = modes.indexOf(currentMode).clamp(0, 2);

    const List<IconData> icons = [
      Icons.wb_sunny_outlined,
      Icons.nightlight_outlined,
      Icons.auto_awesome_outlined,
    ];

    return BentoBox(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  size: 18,
                  color: Color(0xFF4DB6AC),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\u4e3b\u9898\u6a21\u5f0f',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontFamily: _getFontFamily(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: isUnsupported ? 0.70 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isNight
                    ? const Color(0xFF1E1C16)
                    : const Color(0xFFFFFDF6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF4EFE6),
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: 36,
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      alignment: selectedIndex == 0
                          ? Alignment.centerLeft
                          : (selectedIndex == 1
                                ? Alignment.center
                                : Alignment.centerRight),
                      child: FractionallySizedBox(
                        widthFactor: 0.33,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isNight
                                ? const Color(0xFF2C281F)
                                : const Color(0xFFFEF5DC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isNight
                                  ? const Color(
                                      0xFFFFF176,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFFFBE4A8),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: List.generate(modes.length, (i) {
                          final bool isSelected = i == selectedIndex;

                          // 🌸 乐高/自动等环境下极富美感的高清晰色彩增强体系 (拒绝低辨识度的偏淡细线)
                          final List<Color> activeIconColors = [
                            isNight
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFE65100), // 白天模式：亮太阳橙
                            isNight
                                ? const Color(0xFFB39DDB)
                                : const Color(0xFF5E35B1), // 夜晚模式：深紫罗兰
                            isNight
                                ? const Color(0xFF80DEEA)
                                : const Color(0xFF00ACC1), // 自动模式：极光深青
                          ];

                          final Color inactiveColor = isNight
                              ? Colors.white.withValues(alpha: 0.4)
                              : const Color(
                                  0xFF8D7A66,
                                ).withValues(alpha: 0.45); // 中度质感泥褐色，完美清晰

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (isUnsupported) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '当前岛屿主题拥有专属明暗，不支持手动切换明暗，保持白天哦~',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                UserState().setThemeMode(modes[i]);
                              },
                              child: Center(
                                child: Icon(
                                  icons[i],
                                  size: 20,
                                  color: isSelected
                                      ? activeIconColors[i]
                                      : inactiveColor,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}
