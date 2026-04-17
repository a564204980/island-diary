import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/pages/security_center_page.dart';
import 'package:island_diary/features/profile/presentation/pages/mascot_decoration_page.dart';
import 'package:island_diary/features/profile/presentation/pages/achievement_page.dart';
import 'package:island_diary/features/profile/presentation/pages/about_island_page.dart';
import 'package:island_diary/features/profile/presentation/widgets/bento_box.dart';

class BentoMenuGrid extends StatelessWidget {
  final bool isNight;

  const BentoMenuGrid({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 第一部分：1(左大) : 2(右小叠放) 布局
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧：主题模式 (大)
              Expanded(flex: 1, child: _buildThemeBento(context)),
              const SizedBox(width: 12),
              // 右侧：岛屿安全 + 小软的衣帽间 (两个小)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildMenuActionBento(
                        context,
                        title: '岛屿安全',
                        icon: Icons.lock_outline,
                        color: const Color(0xFF81C784),
                        targetPage: const SecurityCenterPage(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildQuickActionBento(
                        title: '回忆导出',
                        icon: Icons.ios_share,
                        color: const Color(0xFF64B5F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 第二部分：平行排列
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMenuActionBento(
                  context,
                  title: '小软的衣帽间',
                  icon: Icons.auto_fix_high_rounded,
                  color: const Color(0xFFFFB74D),
                  targetPage: const MascotDecorationPage(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMenuActionBento(
                  context,
                  title: '岛屿成就',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFFF7043),
                  targetPage: const AchievementPage(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 第三部分：关于小岛 (整合后的新入口)
        _buildMenuActionBento(
          context,
          title: '关于小岛',
          icon: Icons.info_outline,
          color: const Color(0xFFBA68C8),
          targetPage: const AboutIslandPage(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildThemeBento(BuildContext context) {
    return BentoBox(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_rounded, size: 18, color: Color(0xFF4DB6AC)),
              ),
              const SizedBox(width: 12),
              Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : Colors.black87,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: UserState().themeMode,
            builder: (context, mode, _) {
              return _buildThemeOptions(mode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(String currentMode) {
    final List<Map<String, dynamic>> options = [
      {'label': '日间', 'mode': 'light', 'icon': Icons.wb_sunny_outlined},
      {'label': '夜间', 'mode': 'dark', 'icon': Icons.nightlight_outlined},
      {'label': '自动', 'mode': 'auto', 'icon': Icons.auto_awesome_outlined},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((opt) {
        final bool isSelected = currentMode == opt['mode'];
        return GestureDetector(
          onTap: () => UserState().setThemeMode(opt['mode']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isNight
                      ? const Color(0xFFFFF176).withValues(alpha: 0.15)
                      : const Color(0xFFFFF176).withValues(alpha: 0.3))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFF176).withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              opt['icon'] as IconData,
              size: 18,
              color: isSelected
                  ? (isNight ? const Color(0xFFFFF176) : const Color(0xFF7B5C2E))
                  : (isNight ? Colors.white24 : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuActionBento(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget targetPage,
  }) {
    return GestureDetector(
      onTap: () {
        final isNight = UserState().isNight;
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: true,
            barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
            pageBuilder: (context, animation, secondaryAnimation) => targetPage,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
