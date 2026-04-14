import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/slime_button.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';

class SlimeOnboarding extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSlimeAction; // 新增：最后一步点击精灵时的特殊触发逻辑
  final bool isNight;

  const SlimeOnboarding({
    super.key,
    required this.onComplete,
    this.onSlimeAction,
    this.isNight = false,
  });

  @override
  State<SlimeOnboarding> createState() => _SlimeOnboardingState();
}

class _SlimeOnboardingState extends State<SlimeOnboarding> {
  int _step = 0;
  bool _showDialogue = true; // 新增：控制对话框显隐，用于平滑淡出
  double _maskOpacity = 0.0; // 光幕透明度，用 AnimatedOpacity 控制平滑消失
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
        // 进入第三步时，光幕渐入
        if (_step == 2) _maskOpacity = 0.5;
      });
    } else {
      // 最后一步：对话框与光幕平滑消隐，然后完成引导
      setState(() {
        _showDialogue = false;
        _maskOpacity = 0.0;
      });
      Future.delayed(const Duration(milliseconds: 700), widget.onComplete);
    }
  }

  void _handleGlobalTap() {
    if (_step == 2) {
      // 最后一步：点背景不仅仅隐藏气泡和光幕，还要触发引导完成（释放拦截层）
      // 调用 _nextStep 会触发延时后的 widget.onComplete
      _nextStep();
      return;
    }
    // 其他步骤：推进打字机或进入下一句
    _dialogueKeys[_step].currentState?.handleTap();
  }

  void _handleSlimeTap() {
    if (_step == 2) {
      // 如果是最后一步，且传入了特殊触发逻辑，则执行它
      if (widget.onSlimeAction != null) {
        widget.onSlimeAction!();
        return;
      }
    }
    _handleGlobalTap();
  }

  @override
  Widget build(BuildContext context) {
    // 【布局对齐】统一使用扩容后的高度，确保上方气泡在 hit-test 范围内
    return SizedBox(
      height: SlimeButton.containerHeight,
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
              // 【光幕层】使用 AnimatedOpacity 实现平滑淡出和淡入，避免切断感
              child: AnimatedOpacity(
                opacity: _maskOpacity,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),
          ),

          // 对话气泡，位置与正常状态一致
          Positioned(
            bottom: 124, // 进一步增加底部间距，避免遮挡
            child: AnimatedOpacity(
              opacity: _showDialogue ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: SpriteDialogue(
                key: _dialogueKeys[_step],
                text: _dialogues[_step],
                isNight: widget.isNight,
                useTypewriter: true,
                onNext: _nextStep,
              ),
            ),
          ),

          // 中心精灵按钮，位置与正常状态一致
          Positioned(
            bottom: SlimeButton.bottomOffset,
            child: _buildSlimeButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimeButton() {
    bool isGlowing = false;

    if (_step == 2) {
      // 进入第三步：精灵发光
      isGlowing = true;
    }

    return SlimeButton(
      key: const ValueKey(
        'slime_btn_stable',
      ), // 【核心修复】改为固定 Key，防止步骤切换时销毁重建导致动画断档
      isNight: widget.isNight,
      isGlowing: isGlowing,
      onTap: _handleSlimeTap,
    );
  }
}
