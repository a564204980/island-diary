import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/profile_header.dart';
import 'package:island_diary/features/profile/presentation/widgets/premium_bento_card.dart';
import 'package:island_diary/features/profile/presentation/widgets/bento_menu_grid.dart';
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ProfileHeader(isNight: isNight, isVip: isVip),
                      const SizedBox(height: 24),
                      PremiumBentoCard(isVip: isVip, isNight: isNight),
                      const SizedBox(height: 24),
                      BentoMenuGrid(isNight: isNight),
                      const SizedBox(height: 80),
                    ],
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
}
