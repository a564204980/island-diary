import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
              const Text(
                '生日快乐！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'LXGWWenKai',
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '您的岛屿专属礼物已存入成就系统',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'LXGWWenKai',
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
                  child: const Text(
                    '收下礼物',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'LXGWWenKai',
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
      ]),
      builder: (context, child) {
        final bool isNight = userState.isNight;
        final bool isVip = userState.isVip.value;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 20),
                      ProfileHeader(isNight: isNight, isVip: isVip),
                      const SizedBox(height: 32),
                      PremiumBentoCard(isVip: isVip, isNight: isNight),
                      const SizedBox(height: 24),
                      BentoMenuGrid(isNight: isNight),
                      const SizedBox(height: 32),
                      _buildFooter(isNight),
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

  Widget _buildFooter(bool isNight) {
    return Center(
      child: Text(
        '岛屿日记 · 1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: isNight ? Colors.white24 : Colors.black26,
          fontFamily: 'LXGWWenKai',
        ),
      ),
    );
  }
}
