import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../models/diary_block.dart';
import '../utils/diary_utils.dart';
import 'audio_player.dart';

class DiaryBlockItem extends StatelessWidget {
  final DiaryBlock block;
  final int index;
  final bool isEmojiOpen;
  final GlobalKey? blockKey;
  final VoidCallback? onRemoveImage;
  final Function(ImageBlock)? onShowPreview;
  final bool? isNightOverride;
  final bool isNoteBackground;
  final Color? accentColor;
  final String? paperStyle;

  const DiaryBlockItem({
    super.key,
    required this.block,
    required this.index,
    this.isEmojiOpen = false,
    this.blockKey,
    this.onRemoveImage,
    this.onShowPreview,
    this.isNightOverride,
    this.isNoteBackground = false,
    this.accentColor,
    this.paperStyle,
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
      return _buildTextBlock(block as TextBlock, context);
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
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4B483).withValues(alpha: 0.3)),
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

  Widget _buildTextBlock(TextBlock block, BuildContext context) {
    final isNight = isNightOverride ?? UserState().isNight;
    
    final inkColor = paperStyle != null 
        ? DiaryUtils.getInkColor(paperStyle!, isNight)
        : (isNight ? const Color(0xFFE0C097) : const Color(0xFF5D4037));

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: inkColor,
          selectionColor: inkColor.withValues(alpha: 0.2),
          selectionHandleColor: inkColor,
        ),
      ),
      child: TextField(
        controller: block.controller,
        focusNode: block.focusNode,
        maxLines: null,
        readOnly: false,
        showCursor: true,
        cursorColor: inkColor,
        style: TextStyle(
          fontSize: 20, 
          height: 1.6,
          color: inkColor,
          fontFamilyFallback: const ['LXGWWenKai'],
        ),
      decoration: InputDecoration(
        hintText: index == 0 ? '记录下这一刻的想法吧...' : '',
        hintStyle: TextStyle(
          color: isNoteBackground 
              ? (accentColor?.withValues(alpha: 0.5) ?? (isNight ? Colors.white38 : Colors.black38))
              : (isNight 
                  ? const Color(0xFFBDB2A7).withValues(alpha: 0.6) 
                  : const Color(0xFF8B5E3C).withValues(alpha: 0.6)),
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    ),);
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
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: block.videoPath != null
                  ? _LiveImagePlayer(
                      videoPath: block.videoPath!,
                      fallbackPath: block.file.path,
                    )
                  : DiaryUtils.buildImage(
                      block.file.path,
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

/// 专用于模拟实况图微动效果的本地视频播放器
class _LiveImagePlayer extends StatefulWidget {
  final String videoPath;
  final String fallbackPath;

  const _LiveImagePlayer({
    required this.videoPath,
    required this.fallbackPath,
  });

  @override
  State<_LiveImagePlayer> createState() => _LiveImagePlayerState();
}

class _LiveImagePlayerState extends State<_LiveImagePlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || widget.videoPath.startsWith('http') || widget.videoPath.startsWith('blob:')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }
    
    _controller.initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.setLooping(true);
          _controller.setVolume(0); // 实况图静音播放
          _controller.play();
        }
      }).catchError((e) {
        debugPrint('Live Photo Video Error: $e');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return DiaryUtils.buildImage(
        widget.fallbackPath,
        fit: BoxFit.cover,
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
