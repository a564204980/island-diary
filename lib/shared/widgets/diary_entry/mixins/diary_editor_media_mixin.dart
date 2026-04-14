import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../models/diary_block.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import '../../island_vip_guard_dialog.dart';
import './diary_editor_core_mixin.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:http/http.dart' as http;
import 'package:island_diary/core/constants/api_constants.dart';

mixin DiaryEditorMediaMixin<T extends DiaryEditorPage> on State<T>, DiaryEditorCoreMixin<T> {
  void onImageButtonPressed() async {
    FocusScope.of(context).unfocus();
    
    // VIP 校验：非会员限额 3 张
    final bool isVip = UserState().isVip.value;
    final int imageCount = blocks.whereType<ImageBlock>().length;
    if (!isVip && imageCount >= 3) {
      showDialog(
        context: context,
        builder: (context) => const IslandVipGuardDialog(
          title: '已达到免费图片上限',
          description: '普通用户单篇日记至多上传 3 张图片。启用“星光计划”即可开启无限灵感。',
        ),
      );
      return;
    }

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

    if (!mounted) return;
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
      if (!mounted) return;
      if (result == null || result.isEmpty) {
        setState(() => isImagePickerOpen = false);
        return;
      }
      final entity = result.first;
      final file = await entity.originFile;
      if (!mounted) return;
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
      if (!mounted) return;
      if (image == null) {
        setState(() => isImagePickerOpen = false);
        return;
      }
      pickedPath = image.path;
    }

    if (!mounted) return;
    setState(() => isImagePickerOpen = false);

    final int insertIndex;
    TextBlock? newBottomBlock;

    if (isImageGrid) {
      final imageBlock = ImageBlock(XFile(pickedPath), videoPath: pickedVideoPath);
      setState(() {
        blocks.add(imageBlock);
        blockKeys[imageBlock.id] = GlobalKey();
      });
      onBlocksChanged();
      _uploadImageInBackground(imageBlock, pickedPath);
      return;
    }

    // 布局校验：当用户不是 VIP 或 主动关闭了图文混排开关时，强制置底
    final bool canMix = isVip && isMixedLayout;
    bool needsNewBottomBlock = true;
    if (!canMix) {
      // 如果末尾已经是一个空的 TextBlock，则直接把图片插在它前面，避免产生连续空行
      if (blocks.isNotEmpty && blocks.last is TextBlock && (blocks.last as TextBlock).controller.text.isEmpty) {
        insertIndex = blocks.length - 1;
        newBottomBlock = blocks.last as TextBlock;
        needsNewBottomBlock = false;
      } else {
        insertIndex = blocks.length;
        newBottomBlock = TextBlock('', baseColor: currentTextColor);
      }
    } else if (activeBlock != null) {
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

    if (!mounted) return;
    setState(() {
      blocks.insert(insertIndex, imageBlock);
      if (needsNewBottomBlock) {
        blocks.insert(insertIndex + 1, newBottomBlock!);
        blockKeys[newBottomBlock.id] = GlobalKey();
      }
      blockKeys[imageBlock.id] = GlobalKey();
      lastFocusedBlockId = newBottomBlock!.id;
      addFocusListener(newBottomBlock);
    });

    onBlocksChanged();

    // 异步后台上传：将本地路径替换为服务器 URL，防止 404
    _uploadImageInBackground(imageBlock, pickedPath);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && newBottomBlock != null) {
        newBottomBlock.controller.selection = const TextSelection.collapsed(offset: 0);
        newBottomBlock.focusNode.requestFocus();
        scrollToActiveBlock();
      }
    });
  }

  /// 后台上传逻辑
  Future<void> _uploadImageInBackground(ImageBlock block, String localPath) async {
    try {
      final String? remoteUrl = await _uploadFile(localPath);
      if (remoteUrl != null && mounted) {
        setState(() {
          final index = blocks.indexOf(block);
          if (index != -1) {
            // 替换为远程 URL，ImageBlock 内部会自动识别
            blocks[index] = ImageBlock(XFile(remoteUrl), id: block.id, videoPath: block.videoPath);
          }
        });
        onBlocksChanged();
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
      // 上传失败保留本地路径，至少当前会话可见
    }
  }

  Future<String?> _uploadFile(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.uploadEndpoint));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 假设后端直接返回图片访问地址，或者是一个包含 url 字段的 JSON
        // 根据 404 的地址推断，后端返回的可能是类似于 "2026-04-13/xxx.jpg" 的相对路径
        final String responseBody = response.body;
        if (responseBody.startsWith('http')) {
          return responseBody;
        } else {
          // 如果返回的是相对路径，拼接到 BaseUrl
          return "${ApiConstants.baseUrl}/api/v1/files/upload/$responseBody";
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    return null;
  }

  void onMusicButtonPressed() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (!mounted) return;
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
    
    // VIP 校验
    final bool isVip = UserState().isVip.value;
    final int imageCount = blocks.whereType<ImageBlock>().length;
    if (!isVip && imageCount >= 3) {
      showDialog(
        context: context,
        builder: (context) => const IslandVipGuardDialog(
          title: '已达到免费内容上限',
          description: '普通用户单篇日记至多上传 3 张图片。入驻“星空岛”即可畅享灵感生活。',
        ),
      );
      return;
    }

    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final int insertIndex;
    TextBlock? newBottomBlock;

    if (isImageGrid) {
      final parts = imagePath.split('|');
      final actualImagePath = parts[0];
      final String? videoPath = parts.length > 1 ? parts[1] : null;
      final imageBlock = ImageBlock(XFile(actualImagePath), videoPath: videoPath);
      setState(() {
        blocks.add(imageBlock);
        blockKeys[imageBlock.id] = GlobalKey();
      });
      onBlocksChanged();
      _uploadImageInBackground(imageBlock, actualImagePath);
      return;
    }

    // 布局校验：当用户不是 VIP 或 主动关闭了图文混排开关时，强制置底
    final bool canMix = isVip && isMixedLayout;
    bool needsNewBottomBlock = true;
    if (!canMix) {
      // 如果末尾已经是一个空的 TextBlock，则直接把图片插在它前面，避免产生连续空行
      if (blocks.isNotEmpty && blocks.last is TextBlock && (blocks.last as TextBlock).controller.text.isEmpty) {
        insertIndex = blocks.length - 1;
        newBottomBlock = blocks.last as TextBlock;
        needsNewBottomBlock = false;
      } else {
        insertIndex = blocks.length;
        newBottomBlock = TextBlock('', baseColor: currentTextColor);
      }
    } else if (activeBlock != null) {
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
      if (needsNewBottomBlock) {
        blocks.insert(insertIndex + 1, newBottomBlock!);
        blockKeys[newBottomBlock.id] = GlobalKey();
      }
      blockKeys[imageBlock.id] = GlobalKey();
      lastFocusedBlockId = newBottomBlock!.id;
      addFocusListener(newBottomBlock);
    });

    onBlocksChanged();

    // 同时对自定义贴纸执行后台上传
    _uploadImageInBackground(imageBlock, actualImagePath);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && newBottomBlock != null) {
        newBottomBlock.controller.selection = const TextSelection.collapsed(offset: 0);
        newBottomBlock.focusNode.requestFocus();
        scrollToActiveBlock();
      }
    });
  }
}
