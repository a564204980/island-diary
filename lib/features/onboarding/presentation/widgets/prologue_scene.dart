import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/typewriter_text.dart';

class PrologueScene extends StatefulWidget {
  const PrologueScene({super.key});

  @override
  State<PrologueScene> createState() => _PrologueSceneState();
}

class _PrologueSceneState extends State<PrologueScene> {
  bool _showSecondLine = false;

  @override
  Widget build(BuildContext context) {
    return Center(
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
                  if (mounted) setState(() => _showSecondLine = true);
                });
              },
            ),
            const SizedBox(height: 30),
            if (_showSecondLine)
              TypewriterText(
                text: '停下来，在这个只属于你的岛屿上，\n\n喘口气。',
                typingDuration: const Duration(milliseconds: 120),
              ),
          ],
        ),
      ),
    );
  }
}
