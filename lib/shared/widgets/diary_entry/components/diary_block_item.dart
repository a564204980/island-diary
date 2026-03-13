import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../models/diary_block.dart';

/// 渲染单个日记块（文本或图片）
class DiaryBlockItem extends StatelessWidget {
  final DiaryBlock block;
  final int index;
  final VoidCallback onRemoveImage;
  final Function(ImageBlock) onShowPreview;

  const DiaryBlockItem({
    super.key,
    required this.block,
    required this.index,
    required this.onRemoveImage,
    required this.onShowPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (block is TextBlock) {
      final textBlock = block as TextBlock;
      return _buildTextBlock(textBlock);
    } else if (block is ImageBlock) {
      final imageBlock = block as ImageBlock;
      return _buildImageBlock(context, imageBlock);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextBlock(TextBlock block) {
    return TextField(
      controller: block.controller,
      focusNode: block.focusNode,
      maxLines: null,
      cursorColor: const Color(0xFF8B5E3C),
      style: const TextStyle(fontFamily: 'FZKai', fontSize: 20, height: 1.6),
      decoration: InputDecoration(
        hintText: index == 0 ? '记录下这一刻的想法吧...' : '',
        hintStyle: const TextStyle(
          fontFamily: 'FZKai',
          color: Color(0xFFA68A78),
        ),
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
}
