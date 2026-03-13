import 'package:flutter/material.dart';

/// 表情选择面板
class EmojiPanel extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPanel({super.key, required this.onEmojiSelected});

  // 基础表情列表
  static const List<String> _emojis = [
    '😊',
    '🥰',
    '🥳',
    '😎',
    '🤩',
    '😇',
    '😭',
    '😱',
    '😡',
    '😴',
    '🙄',
    '🤔',
    '❤️',
    '✨',
    '🔥',
    '☁️',
    '🌙',
    '🌟',
    '🍃',
    '🌸',
    '🌊',
    '🐱',
    '🐶',
    '🍕',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9EED8).withOpacity(0.95),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => onEmojiSelected(_emojis[index]),
            child: Center(
              child: Text(_emojis[index], style: const TextStyle(fontSize: 28)),
            ),
          );
        },
      ),
    );
  }
}
