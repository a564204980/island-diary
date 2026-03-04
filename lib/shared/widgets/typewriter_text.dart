import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 岛屿日记全局公用基础UI组件
/// 一个优雅的打字机特效组件，伴随轻微的触觉震动
class TypewriterText extends StatefulWidget {
  final String text;
  final Duration typingDuration;
  final Duration delay;
  final VoidCallback? onFinished;

  const TypewriterText({
    super.key,
    required this.text,
    this.typingDuration = const Duration(milliseconds: 180),
    this.delay = Duration.zero,
    this.onFinished,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, _startTyping);
  }

  void _startTyping() async {
    for (int i = 0; i < widget.text.length; i++) {
      if (!mounted) return;

      setState(() {
        _displayedText += widget.text[i];
      });

      // 伴随震动
      HapticFeedback.lightImpact();

      final char = widget.text[i];
      if (char == '\n') {
        await Future.delayed(const Duration(milliseconds: 800));
      } else if (['，', '？', '。'].contains(char)) {
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await Future.delayed(widget.typingDuration);
      }
    }

    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        _displayedText,
        key: ValueKey(_displayedText),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 3.0,
          height: 1.8,
          // 增加文字阴影，让白字在亮色背景下依然能“浮”出来清晰可见
          shadows: [
            Shadow(
              color: Colors.black54, // 半透明深黑
              offset: Offset(0, 1.5),
              blurRadius: 4.0, // 柔和的弥散半径
            ),
          ],
        ),
      ),
    );
  }
}
