import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../models/diary_block.dart';
import '../diary_entry_sheet.dart';
import './diary_editor_core_mixin.dart';

mixin DiaryEditorMediaMixin<T extends MoodDiaryEntrySheet> on State<T>, DiaryEditorCoreMixin<T> {
  void onImageButtonPressed() async {
    FocusScope.of(context).unfocus();
    setState(() => isImagePickerOpen = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFC4B69E)),
              title: const Text('从相册选择', style: TextStyle(fontFamily: 'LXGWWenKai')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFC4B69E)),
              title: const Text('拍照', style: TextStyle(fontFamily: 'LXGWWenKai')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) {
      setState(() => isImagePickerOpen = false);
      return;
    }

    String? pickedPath;
    String? pickedVideoPath;

    if (source == ImageSource.gallery) {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.common,
        ),
      );
      if (result == null || result.isEmpty) {
        setState(() => isImagePickerOpen = false);
        return;
      }
      final entity = result.first;
      final file = await entity.originFile;
      if (file == null) {
        setState(() => isImagePickerOpen = false);
        return;
      }
      pickedPath = file.path;
      if (entity.isLivePhoto) {
        final videoFile = await entity.fileWithSubtype;
        if (videoFile != null) pickedVideoPath = videoFile.path;
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        setState(() => isImagePickerOpen = false);
        return;
      }
      pickedPath = image.path;
    }

    setState(() => isImagePickerOpen = false);

    final int insertIndex;
    TextBlock? newBottomBlock;

    if (activeBlock != null) {
      final controller = activeBlock.controller;
      final selection = savedSelection ?? controller.selection;
      final text = controller.text;
      final int splitOffset = selection.isValid
          ? selection.extentOffset.clamp(0, text.length)
          : text.length;
      final beforeText = text.substring(0, splitOffset);
      final afterText = text.substring(splitOffset);
      final originalIndex = blocks.indexOf(activeBlock);
      controller.text = beforeText;
      insertIndex = originalIndex + 1;
      newBottomBlock = TextBlock(afterText, baseColor: currentTextColor);
    } else {
      insertIndex = blocks.length;
      newBottomBlock = TextBlock('', baseColor: currentTextColor);
    }

    final imageBlock = ImageBlock(XFile(pickedPath), videoPath: pickedVideoPath);

    setState(() {
      blocks.insert(insertIndex, imageBlock);
      blocks.insert(insertIndex + 1, newBottomBlock!);
      blockKeys[imageBlock.id] = GlobalKey();
      blockKeys[newBottomBlock.id] = GlobalKey();
      lastFocusedBlockId = newBottomBlock.id;
      addFocusListener(newBottomBlock);
    });

    onBlocksChanged();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && newBottomBlock != null) {
        newBottomBlock.controller.selection = const TextSelection.collapsed(offset: 0);
        newBottomBlock.focusNode.requestFocus();
        scrollToActiveBlock();
      }
    });
  }

  void onMusicButtonPressed() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final int insertIndex;
      TextBlock? newBottomBlock;

      if (activeBlock != null) {
        final controller = activeBlock.controller;
        final selection = savedSelection ?? controller.selection;
        final text = controller.text;
        final int splitOffset = selection.isValid ? selection.extentOffset : text.length;
        final beforeText = text.substring(0, splitOffset);
        final afterText = text.substring(splitOffset);
        final originalIndex = blocks.indexOf(activeBlock);
        controller.text = beforeText;
        insertIndex = originalIndex + 1;
        newBottomBlock = TextBlock(afterText, baseColor: currentTextColor);
      } else {
        insertIndex = blocks.length;
        newBottomBlock = TextBlock('', baseColor: currentTextColor);
      }

      final audioBlock = AudioBlock(file.path!, file.name);

      setState(() {
        blocks.insert(insertIndex, audioBlock);
        blocks.insert(insertIndex + 1, newBottomBlock!);
        blockKeys[audioBlock.id] = GlobalKey();
        blockKeys[newBottomBlock.id] = GlobalKey();
        lastFocusedBlockId = newBottomBlock.id;
        addFocusListener(newBottomBlock);
      });

      onBlocksChanged();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && newBottomBlock != null) {
          newBottomBlock.controller.selection = const TextSelection.collapsed(offset: 0);
          newBottomBlock.focusNode.requestFocus();
          scrollToActiveBlock();
        }
      });
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= blocks.length) return;
    final block = blocks[index];
    setState(() {
      blocks.removeAt(index);
      blockKeys.remove(block.id);
    });
    onBlocksChanged();
  }

  void showImagePreview(ImageBlock block) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Hero(
                tag: block.id,
                child: kIsWeb
                    ? Image.network(block.file.path, fit: BoxFit.contain)
                    : Image.file(io.File(block.file.path), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleCustomEmojiSelected(String imagePath) {
    if (!mounted) return;
    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final int insertIndex;
    TextBlock? newBottomBlock;

    if (activeBlock != null) {
      final controller = activeBlock.controller;
      final selection = savedSelection ?? controller.selection;
      final text = controller.text;
      final int splitOffset = selection.isValid
          ? selection.extentOffset.clamp(0, text.length)
          : text.length;
      final beforeText = text.substring(0, splitOffset);
      final afterText = text.substring(splitOffset);
      final originalIndex = blocks.indexOf(activeBlock);
      controller.text = beforeText;
      insertIndex = originalIndex + 1;
      newBottomBlock = TextBlock(afterText, baseColor: currentTextColor);
    } else {
      insertIndex = blocks.length;
      newBottomBlock = TextBlock('', baseColor: currentTextColor);
    }

    final parts = imagePath.split('|');
    final actualImagePath = parts[0];
    final String? videoPath = parts.length > 1 ? parts[1] : null;

    final imageBlock = ImageBlock(XFile(actualImagePath), videoPath: videoPath);

    setState(() {
      blocks.insert(insertIndex, imageBlock);
      blocks.insert(insertIndex + 1, newBottomBlock!);
      blockKeys[imageBlock.id] = GlobalKey();
      blockKeys[newBottomBlock.id] = GlobalKey();
      lastFocusedBlockId = newBottomBlock.id;
      addFocusListener(newBottomBlock);
    });

    onBlocksChanged();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && newBottomBlock != null) {
        newBottomBlock.controller.selection = const TextSelection.collapsed(offset: 0);
        newBottomBlock.focusNode.requestFocus();
        scrollToActiveBlock();
      }
    });
  }
}
