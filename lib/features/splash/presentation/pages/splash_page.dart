import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/pages/home_page.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 开启全屏沉浸，使背景图在底部与顶部能完全铺满
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initAndNavigate();
  }

  @override
  void dispose() {
    // 离开页面时恢复正常状态栏与导航栏显示
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    final startTime = DateTime.now();

    // 异步加载本地配置
    await UserState().loadFromStorage();
    final hasSavedName = UserState().userName.value.isNotEmpty;

    // 保证启动页最少展示 1.8 秒，让动画完整且优雅地呈现
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 1800);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;

    // 恢复正常的状态栏与导航栏显示
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 直接使用 500ms 进行平滑的 Fade 路由替换跳转 (交叉淡入淡出，融合度最佳)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSavedName ? const HomePage() : const OnboardingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图铺满
          Positioned.fill(
            child: Image.asset(
              'assets/launch_screen_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 主标题和副标题
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 主标题图片加动画
                    Image.asset('assets/launch_screen_title.png', width: 260)
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 200.ms)
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        )
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.0, 1.0),
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 16),
                    // 副标题图片加动画
                    Image.asset('assets/launch_screen_tip.png', width: 180)
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 700.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
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
}
