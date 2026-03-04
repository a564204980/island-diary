import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:island_diary/shared/widgets/typewriter_text.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  // 当前处于哪一幕：0 表示第一幕，1 表示第二幕
  int _currentSceneIndex = 0;

  // 第一幕的剧本状态
  bool _scene0ShowSecondLine = false;

  // 第二幕的剧本状态
  bool _scene1ShowSecondLine = false;
  bool _scene1ShowThirdLine = false;

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    // 回调正常水平音量，以防之前1.0太大声，暂设 0.4
    await _audioPlayer.setVolume(0.4);

    try {
      await _audioPlayer.play(AssetSource('audio/home-bg.mp3'));
    } catch (e) {
      debugPrint("Waiting for audio file: assets/audio/home-bg.mp3");
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // 触发全局交互：单次点击屏幕翻幕
  void _onTapScreen() {
    // 只有在第一幕的时候响应点击跳转到第二幕，第二幕结束后你也许会需要跳转首页（目前保留不跳）
    if (_currentSceneIndex == 0) {
      // 伴随一次深沉的震动确认交互
      HapticFeedback.mediumImpact();
      setState(() {
        _currentSceneIndex = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02050A), // 极夜底色
      // 捕获全屏的点击事件
      body: GestureDetector(
        onTap: _onTapScreen,
        behavior: HitTestBehavior.opaque, // 空白处也能感应点击
        // 这里的组件是所有视效平滑转换的魔法石
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1500), // 1.5秒极其轻柔的画面溶解替换
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          // 它会根据内部控件的 key 值的不同，自动识别进行新旧界面的溶入淡出切换
          child: _currentSceneIndex == 0 ? _buildScene0() : _buildScene1(),
        ),
      ),
    );
  }

  /// 构建第一幕：引子
  Widget _buildScene0() {
    return Stack(
      key: const ValueKey('scene0'), // 必须指定不同的 key，AnimatedSwitcher才知道它们变了
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _breathingAnimation,
            child: Image.asset(
              'assets/images/login_bg_1.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TypewriterText(
                  text: '外面很喧嚣吧？',
                  delay: const Duration(seconds: 1),
                  onFinished: () {
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _scene0ShowSecondLine = true);
                    });
                  },
                ),
                const SizedBox(height: 30),
                if (_scene0ShowSecondLine)
                  TypewriterText(
                    text: '停下来，在这个只属于你的岛屿上，\n\n喘口气。',
                    typingDuration: const Duration(milliseconds: 120),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建第二幕：拉勾约定
  Widget _buildScene1() {
    return Stack(
      key: const ValueKey('scene1'),
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _breathingAnimation,
            // 确保你已经把 login_bg_2.png 拉进资源目录了
            child: Image.asset(
              'assets/images/login_bg_2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // 加一层极淡的全局黑色遮罩(20%不透明度)，专门压平第二张粉色星空的刺眼高光，确保文字绝对清晰
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.2))),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
            ), // 第二幕字多，两侧预留大点边距防截断
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TypewriterText(
                  text: '在登岛之前，我们想和你拉个勾：',
                  delay: const Duration(milliseconds: 600), // 转场过半的时候就开始暗影打出第一句
                  onFinished: () {
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (mounted) setState(() => _scene1ShowSecondLine = true);
                    });
                  },
                ),
                const SizedBox(height: 25),
                if (_scene1ShowSecondLine)
                  TypewriterText(
                    text: '这里没有评价，没有建议，也不需要你时刻保持开心。',
                    typingDuration: const Duration(
                      milliseconds: 130,
                    ), // 这段念得略微沉稳
                    onFinished: () {
                      Future.delayed(const Duration(milliseconds: 1800), () {
                        if (mounted)
                          setState(() => _scene1ShowThirdLine = true);
                      });
                    },
                  ),
                const SizedBox(height: 25),
                if (_scene1ShowThirdLine)
                  TypewriterText(
                    text: '你所有的悲伤和快乐，都会化作岛上的植物，并被永远锁在你的手机里，连风都无法偷听。',
                    typingDuration: const Duration(milliseconds: 100), // 这段略快流淌
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
