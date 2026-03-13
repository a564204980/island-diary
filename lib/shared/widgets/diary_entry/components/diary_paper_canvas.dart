import 'package:flutter/material.dart';

/// 日记信纸容器组件，封装底图与边框效果
class DiaryPaperCanvas extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? shadowColor;

  const DiaryPaperCanvas({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(32, 40, 32, 32),
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? Colors.black).withOpacity(0.15),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 信纸底图
          Positioned.fill(
            child: Image.asset(
              'assets/images/paper.png',
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
          // 内容层
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
