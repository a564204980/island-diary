import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/slime_button.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';

class SlimeOnboarding extends StatefulWidget {
  final VoidCallback onComplete;
  final bool isNight;

  const SlimeOnboarding({
    super.key,
    required this.onComplete,
    this.isNight = false,
  });

  @override
  State<SlimeOnboarding> createState() => _SlimeOnboardingState();
}

class _SlimeOnboardingState extends State<SlimeOnboarding> {
  int _step = 0;
  final UserState _userState = UserState();
  final List<GlobalKey<SpriteDialogueState>> _dialogueKeys = [
    GlobalKey<SpriteDialogueState>(),
    GlobalKey<SpriteDialogueState>(),
    GlobalKey<SpriteDialogueState>(),
  ];

  late final List<String> _dialogues;

  @override
  void initState() {
    super.initState();
    final name = _userState.userName.value.isNotEmpty
        ? _userState.userName.value
        : '旅人';
    _dialogues = [
      '呼……你终于靠岸啦！我在这里等你好久了，$name。',
      '这里是你的专属岛屿。你看，它现在还有些空荡荡的，但它会吸收你的情绪，慢慢长出奇妙的植物哦。',
      '以后无论是开心还是难过，都可以随时来找我。现在……要不要试着摸摸我，把今天的心情种进岛里？',
    ];
  }

  void _nextStep() {
    if (_step < _dialogues.length - 1) {
      setState(() {
        _step++;
      });
    } else {
      widget.onComplete();
    }
  }

  void _handleGlobalTap() {
    _dialogueKeys[_step].currentState?.handleTap();
  }

  @override
  Widget build(BuildContext context) {
    // 【布局对齐】强制设定高度刚好等于 BottomNavBar 外层 Stack 的固定高度 144
    // (计算公式: 32*2 + 12[Button] + 24[TopOffset] + 52[SafetyMargin] = 144)
    // 这样确保内部 Positioned(top: 24) 的绝对参考系与 BottomNavBar 完全同步。
    return SizedBox(
      height: 144,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 背景遮罩/点击区域 (在最后一步时变暗，其他步骤透明但能接收点击)
          Positioned.fill(
            top: -1000,
            bottom: -1000,
            left: -1000,
            right: -1000,
            child: GestureDetector(
              onTap: _handleGlobalTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                color: _step == 2
                    ? Colors.black.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
          ),

          // 对话气泡，位置与正常状态一致
          Positioned(
            bottom: 124, // 进一步增加底部间距，避免遮挡
            child: SpriteDialogue(
              key: _dialogueKeys[_step],
              text: _dialogues[_step],
              isNight: widget.isNight,
              useTypewriter: true,
              onNext: _nextStep,
            ),
          ),

          // 中心精灵按钮，位置与正常状态一致
          Positioned(top: 40, child: _buildSlimeButton()),
        ],
      ),
    );
  }

  Widget _buildSlimeButton() {
    int start = 0;
    int end = 8;
    int? repeatCount;
    bool isGlowing = false;

    if (_step == 0) {
      // 欢快跳动 (序列帧 1-3)，跳两次静止
      start = 0;
      end = 2;
      repeatCount = 2;
    } else if (_step == 1) {
      // 呼吸状态
      start = 0;
      end = 8;
    } else if (_step == 2) {
      // 呼吸状态 + 发光
      start = 0;
      end = 8;
      isGlowing = true;
    }

    return SlimeButton(
      key: ValueKey('slime_btn_$_step'), // 利用 Key 强制在步骤切换时重置动画
      isNight: widget.isNight,
      isGlowing: isGlowing,
      onTap: _handleGlobalTap,
      startFrame: start,
      endFrame: end,
      repeatCount: repeatCount,
      duration: _step == 0 ? 400.ms : 800.ms,
    );
  }
}
