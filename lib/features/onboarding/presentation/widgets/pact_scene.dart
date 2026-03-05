import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/typewriter_text.dart';

class PactScene extends StatefulWidget {
  const PactScene({super.key});

  @override
  State<PactScene> createState() => _PactSceneState();
}

class _PactSceneState extends State<PactScene> {
  bool _showSecondLine = false;
  bool _showThirdLine = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TypewriterText(
              text: '在登岛之前，我们想和你拉个勾',
              delay: const Duration(milliseconds: 600),
              onFinished: () {
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted) setState(() => _showSecondLine = true);
                });
              },
            ),
            const SizedBox(height: 25),
            if (_showSecondLine)
              TypewriterText(
                text: '这里没有评价，没有建议，也不需要你时刻保持开心。',
                typingDuration: const Duration(milliseconds: 130),
                onFinished: () {
                  Future.delayed(const Duration(milliseconds: 1800), () {
                    if (mounted) {
                      setState(() => _showThirdLine = true);
                    }
                  });
                },
              ),
            const SizedBox(height: 25),
            if (_showThirdLine)
              TypewriterText(
                text: '你所有的悲伤和快乐，都会化作岛上的植物，并被永远锁在你的手机里，连风都无法偷听。',
                typingDuration: const Duration(milliseconds: 100),
              ),
          ],
        ),
      ),
    );
  }
}
