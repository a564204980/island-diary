import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 岛屿日记全局公用基础UI组件
/// 一个优雅的打字机特效组件，伴随轻微的触觉震动
class TypewriterText extends StatefulWidget {
  final String text;
  final Duration typingDuration;
  final Duration delay;
  final VoidCallback? onFinished;
  final TextStyle? style;

  const TypewriterText({
    super.key,
    required this.text,
    this.typingDuration = const Duration(milliseconds: 50), // 默认 0.05s/字
    this.delay = Duration.zero,
    this.onFinished,
    this.style,
  });

  @override
  State<TypewriterText> createState() => TypewriterTextState();
}

class TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  bool _isFinished = false;
  bool _skipRequested = false;

  bool get isFinished => _isFinished;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, _startTyping);
  }

  /// 此时暴露给外部，点击时若未完成则瞬间完成
  void skip() {
    if (!_isFinished) {
      setState(() {
        _skipRequested = true;
        _displayedText = widget.text;
        _isFinished = true;
      });
      widget.onFinished?.call();
    }
  }

  void _startTyping() async {
    for (int i = 0; i < widget.text.length; i++) {
      if (!mounted || _skipRequested) return;

      setState(() {
        _displayedText += widget.text[i];
      });

      // 伴随震动
      HapticFeedback.lightImpact();

      final char = widget.text[i];
      Duration wait = widget.typingDuration;
      if (char == '\n') {
        wait = const Duration(milliseconds: 400);
      } else if (['，', '？', '。', '！'].contains(char)) {
        wait = const Duration(milliseconds: 250);
      }

      await Future.delayed(wait);
    }

    if (mounted && !_skipRequested) {
      setState(() {
        _isFinished = true;
      });
      widget.onFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      textAlign: TextAlign.center,
      style:
          widget.style ??
          const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
    );
  }
}
