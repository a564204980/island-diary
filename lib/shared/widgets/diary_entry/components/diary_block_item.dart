import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:island_diary/core/state/user_state.dart';
import '../models/diary_block.dart';
import 'audio_player.dart';

class DiaryBlockItem extends StatelessWidget {
  final DiaryBlock block;
  final int index;
  final bool isEmojiOpen;
  final GlobalKey? blockKey;
  final VoidCallback? onRemoveImage;
  final Function(ImageBlock)? onShowPreview;

  const DiaryBlockItem({
    super.key,
    required this.block,
    required this.index,
    this.isEmojiOpen = false,
    this.blockKey,
    this.onRemoveImage,
    this.onShowPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: blockKey,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (block is TextBlock) {
      return _buildTextBlock(block as TextBlock);
    } else if (block is ImageBlock) {
      return _buildImageBlock(block as ImageBlock);
    } else if (block is AudioBlock) {
      return _buildAudioBlock(block as AudioBlock);
    } else if (block is RewardBlock) {
      return _buildRewardBlock(block as RewardBlock);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRewardBlock(RewardBlock block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4B483).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Image.asset(block.imagePath, width: 40, height: 40),
          const SizedBox(width: 12),
          Text(
            block.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5E3C),
            ),
          ),
          const Spacer(),
          if (onRemoveImage != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemoveImage,
            ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(TextBlock block) {
    final isNight = UserState().isNight;
    return TextField(
      controller: block.controller,
      focusNode: block.focusNode,
      maxLines: null,
      readOnly: isEmojiOpen,
      showCursor: true,
      cursorColor: isNight 
          ? const Color(0xFFE0C097) 
          : const Color(0xFF8B5E3C),
      style: TextStyle(
        fontSize: 20, 
        height: 1.6,
        color: isNight ? const Color(0xFFE0C097) : Colors.black,
        fontFamilyFallback: const ['LXGWWenKai'],
      ),
      decoration: InputDecoration(
        hintText: index == 0 ? '记录下这一刻的想法吧...' : '',
        hintStyle: TextStyle(
          color: isNight 
              ? const Color(0xFFBDB2A7).withOpacity(0.6) 
              : const Color(0xFFA68A78)
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  Widget _buildImageBlock(ImageBlock block) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => onShowPreview?.call(block),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(block.file.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 8,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
            onPressed: onRemoveImage,
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildAudioBlock(AudioBlock block) {
    return Stack(
      children: [
        HandDrawnAudioPlayer(
          path: block.path,
          name: block.name,
        ),
        Positioned(
          top: 15,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF8B5E3C)),
            onPressed: onRemoveImage,
          ),
        ),
      ],
    );
  }
}
