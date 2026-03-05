import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:island_diary/features/home/presentation/pages/home_page.dart';
import 'package:island_diary/features/onboarding/presentation/widgets/sand_blow_effect.dart';
import 'package:island_diary/features/onboarding/presentation/widgets/starfield_background.dart';
import 'package:island_diary/features/onboarding/presentation/widgets/prologue_scene.dart';
import 'package:island_diary/features/onboarding/presentation/widgets/pact_scene.dart';
import 'package:island_diary/features/onboarding/presentation/widgets/arrival_scene.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentSceneIndex = 0;
  bool _isDissolving = false;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.4);

    try {
      await _audioPlayer.play(AssetSource('audio/home-bg.mp3'));
    } catch (e) {
      debugPrint("Waiting for audio file: assets/audio/home-bg.mp3");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onTapScreen() {
    if (_currentSceneIndex < 2 && !_isDissolving) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentSceneIndex++;
      });
    }
  }

  void _triggerDissolve() {
    setState(() {
      _isDissolving = true;
    });
  }

  // 构建渐隐转场到主页面的自定义路由
  void _navigateToHomePage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000), // 长达1秒的柔和渐入
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  String _getBackgroundImagePath(int index) {
    switch (index) {
      case 0:
        return 'assets/images/login_bg_1.png';
      case 1:
        return 'assets/images/login_bg_2.png';
      case 2:
      default:
        return 'assets/images/login_bg_3.png';
    }
  }

  Widget _getCurrentSceneWidget(int index) {
    switch (index) {
      case 0:
        return const PrologueScene(key: ValueKey('scene0'));
      case 1:
        return const PactScene(key: ValueKey('scene1'));
      case 2:
      default:
        return ArrivalScene(
          key: const ValueKey('scene2'),
          onSubmitComplete: _triggerDissolve,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用自定义的粒子沙化特效包裹整个页面
    return SandBlowEffect(
      isDissolving: _isDissolving,
      onAnimationComplete: () {
        // 沙化动效结束（2.5秒）后，触发跳转主界面的逻辑
        if (mounted) {
          _navigateToHomePage();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A), // 极夜底色兜底
        body: GestureDetector(
          onTap: _onTapScreen,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // 底层：用户原有的静态背景图（取消整图放大呼吸，仅在两幕切换时提供1.5秒的淡入淡出）
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1500),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: Image.asset(
                    _getBackgroundImagePath(_currentSceneIndex),
                    key: ValueKey('bg_$_currentSceneIndex'),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              // 第二层遮罩层：原设计中专门用于压平第二张粉色星空高光（仅第二幕显示时淡入）
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeIn,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    color: _currentSceneIndex == 1
                        ? Colors.black.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
              ),
              // 中层特效：纯粹的呼吸星空层（此时背景已透明，叠在原图之上，只负责错落画纯白星星）
              // 在第三幕（登岛后视角：白天/非星空）使其平滑淡出隐藏
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeIn,
                    opacity: _currentSceneIndex == 2 ? 0.0 : 1.0,
                    child: const StarfieldBackground(),
                  ),
                ),
              ),
              // 前景：文字场景层（保持极柔的溶解切换）
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1500),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _getCurrentSceneWidget(_currentSceneIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
