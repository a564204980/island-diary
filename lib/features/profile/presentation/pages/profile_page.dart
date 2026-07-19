import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/profile_header.dart';
import 'package:island_diary/features/profile/presentation/widgets/premium_bento_card.dart';
import 'package:island_diary/features/profile/presentation/widgets/bento_menu_grid.dart';
import 'package:island_diary/features/profile/presentation/pages/plugin_store_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _checkBirthday();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkBirthday() async {
    final userState = UserState();
    final hasGift = await userState.checkAndClaimBirthdayGift();
    if (hasGift && mounted) {
      _showBirthdayCelebration(context);
    }
  }

  void _showBirthdayCelebration(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cake_rounded, size: 80, color: Color(0xFF7B5C2E)),
              const SizedBox(height: 24),
              Text(
                '生日快乐！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: _getFontFamily(),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '您的岛屿专属礼物已自动为您发放',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: _getFontFamily(),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B5C2E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '收下礼物',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: _getFontFamily(),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.themeMode,
        userState.isVip,
        userState.selectedTitles,
        userState.selectedIslandThemeId,
      ]),
      builder: (context, child) {
        final bool isNight = userState.isNight;
        final bool isVip = userState.isVip.value;
        final String themeId = userState.selectedIslandThemeId.value;

        return Stack(
          children: [
            // 节日与主题特定背景
            if (themeId == 'cotton_candy' || themeId == 'lego')
              Positioned.fill(
                child: Image.asset(
                  themeId == 'lego'
                      ? 'assets/images/theme/legao/legao_my_bg.png'
                      : (isNight
                          ? 'assets/images/theme/miamhuadao/mianhuadao_home_night_bg.png'
                          : 'assets/images/theme/miamhuadao/mianhaudao_home_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),

            // 背景模糊（特定主题下保持清晰）
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (themeId == 'cotton_candy' || themeId == 'lego') ? 0 : 10,
                  sigmaY: (themeId == 'cotton_candy' || themeId == 'lego') ? 0 : 10,
                ),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.0,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 84), // 避开底部悬浮导航栏高度，防止滚动时卡片穿透泄漏
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ProfileHeader(isNight: isNight, isVip: isVip),
                        const SizedBox(height: 24),
                        PremiumBentoCard(isVip: isVip, isNight: isNight),
                        const SizedBox(height: 24),


                        _buildPluginStorePromoBento(context, isNight),
                        const SizedBox(height: 24),
                        BentoMenuGrid(isNight: isNight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }

  Widget _buildPluginStorePromoBento(BuildContext context, bool isNight) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: true,
            barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
            pageBuilder: (context, animation, secondaryAnimation) => const PluginStorePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        height: 104,
        margin: const EdgeInsets.symmetric(horizontal: 2), // 稍微往里缩一点，制造独立卡片的悬浮感
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // 浅色模式下使用温暖柔和的橘粉色渐变，深色模式下使用深邃灰黑
          gradient: LinearGradient(
            colors: isNight
                ? [const Color(0xFF2C2C30), const Color(0xFF1E1E22)]
                : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isNight ? Colors.black26 : const Color(0xFFFFB74D).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 背景里的光晕点缀
            Positioned(
              right: -20,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF9800).withValues(alpha: isNight ? 0.15 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 左侧超大质感圆角图标 (类似 iOS App 图标)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7043).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.extension_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 中间文案
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '插件商店',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isNight ? Colors.white : const Color(0xFF3E2723),
                            letterSpacing: 0.5,
                            fontFamily: _getFontFamily(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '扩展小岛的无限可能',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isNight ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF795548),
                            fontFamily: _getFontFamily(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // 右侧行动按钮 (App Store 'GET' 按钮风格)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isNight ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isNight ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '去探索',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isNight ? Colors.white : const Color(0xFFFF7043),
                        fontFamily: _getFontFamily(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideX(),
    );
  }
}
