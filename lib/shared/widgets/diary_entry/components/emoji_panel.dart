import 'package:flutter/material.dart';
import '../utils/emoji_mapping.dart';

/// 表情选择面板
class EmojiPanel extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPanel({super.key, required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    final emojis = EmojiMapping.commonEmojis;

    return Container(
      color: const Color(0xFFF9EED8).withOpacity(0.95),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          final emoji = emojis[index];
          final unicode = emoji['unicode'] ?? emoji['name']!;

          return InkWell(
            onTap: () => onEmojiSelected(unicode),
            child: Center(
              child: Image.asset(
                emoji['path']!,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
