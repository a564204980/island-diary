import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/pages/vip_benefits_page.dart';
import 'package:island_diary/features/profile/presentation/pages/security_center_page.dart';
import 'package:island_diary/core/state/user_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.themeMode,
        userState.isVip,
        userState.userName,
      ]),
      builder: (context, child) {
        final bool isNight = userState.isNight;
        final bool isVip = userState.isVip.value;
        final String name = userState.userName.value;

        return Stack(
          children: [
            // 背景模糊
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),

            SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 20),
                  // 1. 头部区域
                  _buildProfileHeader(name, isVip, isNight),
                  const SizedBox(height: 32),

                  // 2. VIP 会员特权卡片
                  _buildVipMembershipCard(context, isVip, isNight),
                  const SizedBox(height: 24),

                  // 3. 功能矩阵 (Bento Style)
                  _buildBentoMenu(context, isNight),

                  const SizedBox(height: 32),
                  // 4. 底部信息
                  Center(
                    child: Text(
                      '小岛日记 · 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.white24 : Colors.black26,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(String name, bool isVip, bool isNight) {
    return Column(
      children: [
        // 头像容器
        Stack(
          alignment: Alignment.center,
          children: [
            // 底部光环
            if (isVip)
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF176).withValues(alpha: 0.5),
                      const Color(0xFFCE93D8).withValues(alpha: 0.5),
                      const Color(0xFFFFF176).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds),

            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isVip
                      ? const Color(0xFFFFF176)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isVip
                        ? const Color(0xFFFFF176).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/emoji/weixiao.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // VIP 挂件
            if (isVip)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF176),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 14,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ),
          ],
        ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),

        const SizedBox(height: 16),

        // 姓名与称号
        Column(
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isNight ? Colors.white : const Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isVip
                    ? const Color(0xFFFFF176).withValues(alpha: 0.2)
                    : (isNight
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isVip ? '岛屿永久居民' : '普通居民',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isVip
                      ? (isNight
                            ? const Color(0xFFFFCC80)
                            : const Color(0xFF7B5C2E))
                      : (isNight ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildVipMembershipCard(
    BuildContext context,
    bool isVip,
    bool isNight,
  ) {
    return Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isVip
                    ? const Color(0xFFAB47BC).withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 极光渐变背景
                Positioned.fill(
                  child: AnimatedGradient(isVip: isVip, isNight: isNight),
                ),

                // 内容
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVip ? '星光计划 · 已激活' : '星光计划 · 永久居民',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isVip
                                      ? Colors.white
                                      : (isNight
                                            ? Colors.white
                                            : const Color(0xFF3E2723)),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                isVip ? '您的岛屿正沐浴在永恒星光中' : '让每一份心情都拥有流光溢彩的家',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isVip
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : (isNight
                                            ? Colors.white38
                                            : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            isVip ? Icons.workspace_premium : Icons.stars,
                            color: isVip
                                ? const Color(0xFFFFF176)
                                : (isNight ? Colors.white24 : Colors.black12),
                            size: 32,
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VipBenefitsPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isVip
                                ? Colors.white.withValues(alpha: 0.2)
                                : (isNight
                                      ? Colors.white
                                      : const Color(0xFF3E2723)),
                            borderRadius: BorderRadius.circular(16),
                            border: isVip
                                ? Border.all(color: Colors.white30)
                                : null,
                          ),
                          child: Text(
                            isVip ? '查看专属权益' : '立即入驻',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isVip
                                  ? Colors.white
                                  : (isNight
                                        ? const Color(0xFF3E2723)
                                        : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic, delay: 300.ms)
        .fadeIn(delay: 300.ms);
  }

  Widget _buildBentoMenu(BuildContext context, bool isNight) {
    return Column(
      children: [
        // 第一排 Bento
        Row(
          children: [
            Expanded(flex: 3, child: _buildThemeBento(isNight)),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  final isNight = UserState().isNight;
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: true, // 保持不透明以覆盖底层
                      barrierColor: isNight
                          ? Colors.black
                          : const Color(0xFFFDFCF7),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SecurityCenterPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: _buildQuickActionBento(
                  title: '岛屿安全',
                  icon: Icons.lock_outline,
                  color: const Color(0xFF81C784),
                  isNight: isNight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 第二排 Bento
        Row(
          children: [
            Expanded(
              child: _buildQuickActionBento(
                title: '回忆导出',
                icon: Icons.ios_share,
                color: const Color(0xFF64B5F6),
                isNight: isNight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionBento(
                title: '关于小岛',
                icon: Icons.info_outline,
                color: const Color(0xFFBA68C8),
                isNight: isNight,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildThemeBento(bool isNight) {
    final mode = UserState().themeMode.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _bentoDecoration(isNight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 16,
                color: isNight ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 6),
              Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildThemeOptions(mode, isNight),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(String currentMode, bool isNight) {
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
                  ? (isNight
                        ? const Color(0xFFFFF176)
                        : const Color(0xFF7B5C2E))
                  : (isNight ? Colors.white24 : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionBento({
    required String title,
    required IconData icon,
    required Color color,
    required bool isNight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _bentoDecoration(isNight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _bentoDecoration(bool isNight) {
    return BoxDecoration(
      color: isNight
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isNight
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}

/// 动感渐变背景
class AnimatedGradient extends StatefulWidget {
  final bool isVip;
  final bool isNight;
  const AnimatedGradient({
    super.key,
    required this.isVip,
    required this.isNight,
  });

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isVip
                  ? [
                      const Color(0xFFCE93D8),
                      const Color(0xFF7E57C2),
                      const Color(0xFF42A5F5),
                    ]
                  : (widget.isNight
                        ? [const Color(0xFF37474F), const Color(0xFF263238)]
                        : [const Color(0xFFEEEEEE), const Color(0xFFF5F5F5)]),
              stops: widget.isVip
                  ? [
                      0.0,
                      0.5 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                      1.0,
                    ]
                  : null, // 非 VIP 状态下不使用动态 stop
            ),
          ),
        );
      },
    );
  }
}
