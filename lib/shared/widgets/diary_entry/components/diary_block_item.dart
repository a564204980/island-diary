import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../models/diary_block.dart';
import 'audio_player.dart';

/// 渲染单个日记块（文本或图片）
class DiaryBlockItem extends StatelessWidget {
  final DiaryBlock block;
  final int index;
  final bool isEmojiOpen;
  final VoidCallback onRemoveImage;
  final Function(ImageBlock) onShowPreview;
  final GlobalKey? blockKey;

  const DiaryBlockItem({
    super.key,
    required this.block,
    required this.index,
    required this.isEmojiOpen,
    required this.onRemoveImage,
    required this.onShowPreview,
    this.blockKey,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (block is TextBlock) {
      final textBlock = block as TextBlock;
      child = _buildTextBlock(textBlock);
    } else if (block is ImageBlock) {
      final imageBlock = block as ImageBlock;
      child = _buildImageBlock(context, imageBlock);
    } else if (block is AudioBlock) {
      final audioBlock = block as AudioBlock;
      child = _buildAudioBlock(audioBlock);
    } else {
      child = const SizedBox.shrink();
    }

    return Container(key: blockKey, child: child);
  }

  Widget _buildTextBlock(TextBlock block) {
    return TextField(
      controller: block.controller,
      focusNode: block.focusNode,
      maxLines: null,
      readOnly: isEmojiOpen,
      showCursor: true,
      cursorColor: const Color(0xFF8B5E3C),
      style: const TextStyle(fontSize: 20, height: 1.6),
      decoration: InputDecoration(
        hintText: index == 0 ? '记录下这一刻的想法吧...' : '',
        hintStyle: const TextStyle(color: Color(0xFFA68A78)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  Widget _buildImageBlock(BuildContext context, ImageBlock block) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxImgH = screenWidth < 600 ? 200 : 300;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      constraints: BoxConstraints(maxHeight: maxImgH),
      width: double.infinity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => onShowPreview(block),
            child: Hero(
              tag: block.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(
                        block.file.path,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.file(
                        File(block.file.path),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemoveImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 200.ms);
  }

  Widget _buildAudioBlock(AudioBlock block) {
    return HandDrawnAudioPlayer(path: block.path, name: block.name);
  }
}
