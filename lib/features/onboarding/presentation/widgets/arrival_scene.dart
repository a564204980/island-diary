import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/typewriter_text.dart';

class ArrivalScene extends StatefulWidget {
  final VoidCallback onSubmitComplete;
  const ArrivalScene({super.key, required this.onSubmitComplete});

  @override
  State<ArrivalScene> createState() => _ArrivalSceneState();
}

class _ArrivalSceneState extends State<ArrivalScene> {
  bool _showSecondLine = false;
  bool _showInput = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit(String value) async {
    if (value.trim().isNotEmpty) {
      // 1. 保存到全局状态 + 持久化到本地 (async)
      await UserState().setUserName(value);

      // 2. 触发顶层全屏消散动画
      widget.onSubmitComplete();

      // 隐藏光标停止输入
      if (mounted) {
        setState(() {
          _showInput = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TypewriterText(
              text: '海浪把你送来了。',
              delay: const Duration(seconds: 1),
              onFinished: () {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) setState(() => _showSecondLine = true);
                });
              },
            ),
            const SizedBox(height: 30),
            if (_showSecondLine)
              TypewriterText(
                text: '远道而来的旅人，风该怎么称呼你？',
                typingDuration: const Duration(milliseconds: 120),
                onFinished: () {
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) setState(() => _showInput = true);
                  });
                },
              ),

            const SizedBox(height: 40),
            // 用户输入框
            AnimatedOpacity(
              opacity: _showInput ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !_showInput,
                child: SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _nameController,
                    maxLength: 10, // 限制最大长度10
                    textAlign: TextAlign.center,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) => null, // 隐藏底部的 0/10 计数器
                    onSubmitted: _onSubmit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: '姓名',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white70,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
