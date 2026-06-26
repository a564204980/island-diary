import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
import '../components/diary_image_source_sheet.dart';
import '../components/redbook_asset_picker.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/features/record/presentation/pages/custom_camera_page.dart';

mixin DiaryEditorMediaMixin<T extends DiaryEditorPage> on State<T>, DiaryEditorCoreMixin<T> {
  void onImageButtonPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    
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
    if (!mounted) return;

    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => DiaryImageSourceSheet(
        paperStyle: currentPaperStyle,
        isMixedLayout: isMixedLayout,
        isImageGrid: isImageGrid,
        onMixedLayoutChanged: (val) {
          setState(() {
            isMixedLayout = val;
          });
          onBlocksChanged();
        },
        onImageGridChanged: (val) {
          setState(() {
            isImageGrid = val;
          });
          onBlocksChanged();
        },
      ),
    );

    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (source == null) {
      setState(() => isImagePickerOpen = false);
      return;
    }

    if (source == ImageSource.gallery) {
      // 动态计算剩余可选额度：非 VIP 最多 3 张，已选 imageCount 张；VIP 则宽限至 9 张
      final int remainingLimit = isVip ? 9 : (3 - imageCount).clamp(1, 3);

      final List<AssetEntity>? result = await RedBookAssetPicker.pick(
        context,
        maxAssets: remainingLimit,
        requestType: RequestType.common,
      );
      if (!mounted) return;
      if (result == null || result.isEmpty) {
        setState(() => isImagePickerOpen = false);
        return;
      }

      if (result.length == 1) {
        final file = await result.first.originFile;
        if (file != null && mounted) {
          setState(() => isImagePickerOpen = false);
          final dynamic routeResult = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => CustomCameraPage(initialImagePath: file.path),
            ),
          );
          if (routeResult != null && mounted) {
            String? editedPath;
            String? newMattedPath;
            if (routeResult is Map) {
              editedPath = routeResult['editedPath'] as String?;
              newMattedPath = routeResult['mattedPath'] as String?;
            } else if (routeResult is String) {
              editedPath = routeResult;
            }
            if (editedPath != null) {
              _insertSingleImageBlock(
                pickedPath: editedPath,
                mattedPath: newMattedPath,
                isVip: isVip,
                activeBlock: activeBlock,
                savedSelection: savedSelection,
              );
            }
          }
          return;
        }
      }

      TextBlock? currentActiveBlock = activeBlock;
      TextSelection? currentSelection = savedSelection;

      for (final entity in result) {
        final file = await entity.originFile;
        if (!mounted) continue;
        if (file == null) continue;

        String currentPickedPath = file.path;
        String? currentPickedVideoPath;

        if (entity.isLivePhoto) {
          final videoFile = await entity.fileWithSubtype;
          if (videoFile != null) {
            // 持久化保存视频：从临时目录拷贝到 App 文档目录，防止被清理
            try {
              final appDocDir = await getApplicationDocumentsDirectory();
              final String fileName = "${entity.id}_${p.basename(videoFile.path)}";
              final String savedPath = p.join(appDocDir.path, 'live_photos', fileName);
              
              final savedFile = io.File(savedPath);
              if (!await savedFile.parent.exists()) {
                await savedFile.parent.create(recursive: true);
              }
              
              await io.File(videoFile.path).copy(savedPath);
              currentPickedVideoPath = savedPath;
            } catch (e) {
              debugPrint("Failed to save live photo video: $e");
              currentPickedVideoPath = videoFile.path; // 失败则退回临时路径
            }
          }
        } else if (io.Platform.isAndroid) {
          final extractedPath = await _extractAndroidMotionPhotoVideo(file.path, entity.id);
          if (extractedPath != null) {
            currentPickedVideoPath = extractedPath;
          }
        }

        // 顺序插入图片块并推进焦点文本块
        final nextBlock = _insertSingleImageBlock(
          pickedPath: currentPickedPath,
          pickedVideoPath: currentPickedVideoPath,
          isVip: isVip,
          activeBlock: currentActiveBlock,
          savedSelection: currentSelection,
        );

        if (nextBlock != null) {
          currentActiveBlock = nextBlock;
          currentSelection = const TextSelection.collapsed(offset: 0);
        }
      }

      setState(() => isImagePickerOpen = false);
      return;
    } else {
      // 相机拍摄单张处理（使用自定义拍照界面）
      final String? imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CustomCameraPage()),
      );
      if (!mounted) {
        setState(() => isImagePickerOpen = false);
        return;
      }
      if (imagePath == null) {
        setState(() => isImagePickerOpen = false);
        return;
      }

      setState(() => isImagePickerOpen = false);
      _insertSingleImageBlock(
        pickedPath: imagePath,
        isVip: isVip,
        activeBlock: activeBlock,
        savedSelection: savedSelection,
      );
    }
  }

  /// 针对已插入日记中的图片进行再次编辑跳转
  Future<void> editImageBlock(ImageBlock block) async {
    final String initialPath = block.localPath ?? block.file.path;
    
    final dynamic result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCameraPage(
          initialImagePath: initialPath,
          initialMattedPath: block.mattedPath,
        ),
      ),
    );
    if (result == null) return;

    String? editedPath;
    String? newMattedPath;
    if (result is Map) {
      editedPath = result['editedPath'] as String?;
      newMattedPath = result['mattedPath'] as String?;
    } else if (result is String) {
      editedPath = result;
    }

    if (editedPath != null && mounted) {
      setState(() {
        final index = blocks.indexOf(block);
        if (index != -1) {
          blocks[index] = ImageBlock(
            XFile(editedPath!),
            videoPath: block.videoPath,
            localPath: block.localPath ?? block.file.path,
            mattedPath: newMattedPath,
            isUploading: false,
          );
        }
      });
      onBlocksChanged();
    }
  }

  TextBlock? _insertSingleImageBlock({
    required String pickedPath,
    String? pickedVideoPath,
    String? mattedPath,
    required bool isVip,
    TextBlock? activeBlock,
    TextSelection? savedSelection,
  }) {
    final int insertIndex;
    TextBlock? newBottomBlock;

    if (isImageGrid && !isMixedLayout) {
      final imageBlock = ImageBlock(
        XFile(pickedPath),
        videoPath: pickedVideoPath,
        localPath: pickedPath,
        mattedPath: mattedPath,
        isUploading: true,
      );
      setState(() {
        blocks.add(imageBlock);
        blockKeys[imageBlock.id] = GlobalKey();
      });
      onBlocksChanged();
      _uploadImageInBackground(imageBlock, pickedPath);
      return null;
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
      if (controller.text.isEmpty) {
        insertIndex = blocks.indexOf(activeBlock);
        newBottomBlock = activeBlock;
        needsNewBottomBlock = false;
      } else {
        final selection = savedSelection ?? controller.selection;
        final text = controller.text;
        final int splitOffset = selection.isValid
            ? selection.extentOffset.clamp(0, text.length)
            : text.length;
        final originalIndex = blocks.indexOf(activeBlock);
        
        // 如果光标在最前面，且前一个 block 是图片块，则直接插在图片后面，不进行拆分
        if (splitOffset == 0 && originalIndex > 0 && blocks[originalIndex - 1] is ImageBlock) {
          insertIndex = originalIndex;
          newBottomBlock = activeBlock;
          needsNewBottomBlock = false;
        } else {
          var beforeText = text.substring(0, splitOffset);
          var afterText = text.substring(splitOffset);
          
          // 去除多余换行符，防止图片上方出现空白行
          while (beforeText.endsWith('\n')) {
            beforeText = beforeText.substring(0, beforeText.length - 1);
          }
          // 去除多余换行符，防止图片下方出现空白行
          while (afterText.startsWith('\n')) {
            afterText = afterText.substring(1);
          }
          
          controller.text = beforeText;
          insertIndex = originalIndex + 1;
          newBottomBlock = TextBlock(afterText, baseColor: currentTextColor);
        }
      }
    } else {
      insertIndex = blocks.length;
      newBottomBlock = TextBlock('', baseColor: currentTextColor);
    }

    final imageBlock = ImageBlock(
      XFile(pickedPath),
      videoPath: pickedVideoPath,
      localPath: pickedPath,
      mattedPath: mattedPath,
      isUploading: true,
    );

    // 升级为空日记的判断（没有任何图片，且所有文本框文字皆为空）
    final bool isPureEmptyDiary = blocks.whereType<ImageBlock>().isEmpty &&
        blocks.whereType<TextBlock>().every((b) => b.controller.text.trim().isEmpty);

    setState(() {
      if (isPureEmptyDiary) {
        // 直接将第一张图片置顶在最前面，彻底抹去上方无用的空文字框和长Placeholder占位空间
        blocks.clear();
        blocks.add(imageBlock);
        
        newBottomBlock = TextBlock('', baseColor: currentTextColor);
        blocks.add(newBottomBlock!);
        
        blockKeys[newBottomBlock!.id] = GlobalKey();
        blockKeys[imageBlock.id] = GlobalKey();
        lastFocusedBlockId = newBottomBlock!.id;
        addFocusListener(newBottomBlock!);
        needsNewBottomBlock = false;
      } else {
        blocks.insert(insertIndex, imageBlock);
        if (needsNewBottomBlock) {
          blocks.insert(insertIndex + 1, newBottomBlock!);
          blockKeys[newBottomBlock!.id] = GlobalKey();
        }
        blockKeys[imageBlock.id] = GlobalKey();
        lastFocusedBlockId = newBottomBlock!.id;
        addFocusListener(newBottomBlock!);
      }
    });

    onBlocksChanged();

    // 异步后台上传：将本地路径替换为服务器 URL，防止 404
    _uploadImageInBackground(imageBlock, pickedPath);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && newBottomBlock != null) {
        newBottomBlock!.controller.selection = const TextSelection.collapsed(offset: 0);
        scrollToActiveBlock();
      }
    });

    return newBottomBlock;
  }

  /// 后台图片压缩处理逻辑（纯本地处理，不上传云端服务器）
  Future<void> _uploadImageInBackground(ImageBlock block, String localPath) async {
    try {
      // 进行本地背景图片缩放和质量压缩，增加 3 秒安全超时保护，超时则降级使用原图，防止无限转圈
      String compressedPath;
      try {
        compressedPath = await DiaryUtils.compressImage(localPath).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("本地图片压缩超时或失败，直接退回原图路径: $e");
        compressedPath = localPath;
      }
      
      if (mounted) {
        setState(() {
          final index = blocks.indexWhere((b) => b.id == block.id);
          if (index != -1) {
            // 压缩成功或超时降级：更新图片路径，并将 isUploading 置为 false
            blocks[index] = ImageBlock(
              XFile(compressedPath),
              id: block.id,
              videoPath: block.videoPath,
              localPath: compressedPath,
              isUploading: false,
            );
          }
        });
        onBlocksChanged();
      }
    } catch (e) {
      debugPrint("本地图片压缩处理异常: $e");
      if (mounted) {
        setState(() {
          final index = blocks.indexWhere((b) => b.id == block.id);
          if (index != -1) {
            // 失败时回退为原图，重置加载状态，保证日记可编辑和显示
            blocks[index] = ImageBlock(
              block.file,
              id: block.id,
              videoPath: block.videoPath,
              localPath: localPath,
              isUploading: false,
            );
          }
        });
      }
    }
  }

  void onMusicButtonPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
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
      if (block is ImageBlock && index > 0 && index < blocks.length - 1) {
        final prevBlock = blocks[index - 1];
        final nextBlock = blocks[index + 1];
        if (prevBlock is TextBlock && nextBlock is TextBlock) {
          final prevController = prevBlock.controller as DiaryTextEditingController;
          final nextController = nextBlock.controller as DiaryTextEditingController;

          final String originalPrevText = prevController.text;
          const String separator = "";
          final String newText = originalPrevText + separator + nextController.text;

          // 合并文字属性并做相应的偏移
          final List<TextAttribute> mergedAttrs = List.from(prevController.attributes);
          final int offset = originalPrevText.length;
          for (var attr in nextController.attributes) {
            mergedAttrs.add(TextAttribute(
              start: attr.start + offset,
              end: attr.end + offset,
              color: attr.color,
              backgroundColor: attr.backgroundColor,
              fontSize: attr.fontSize,
              underline: attr.underline,
              underlineStyle: attr.underlineStyle,
            ));
          }

          // 将合并后的数据更新到前一个文本块中
          prevController.text = newText;
          prevController.attributes.clear();
          prevController.attributes.addAll(mergedAttrs);

          // 移除图片和多余的后半截文本块
          blocks.removeAt(index); // 移除图片块
          blocks.removeAt(index); // 此时 index + 1 的位置变成了 index，再次移除即是移除后半截文本块

          blockKeys.remove(block.id);
          blockKeys.remove(nextBlock.id);
          onBlocksChanged();
          return;
        }
      }

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

    if (isImageGrid && !isMixedLayout) {
      final parts = imagePath.split('|');
      final actualImagePath = parts[0];
      final String? videoPath = parts.length > 1 ? parts[1] : null;
      final imageBlock = ImageBlock(
        XFile(actualImagePath),
        videoPath: videoPath,
        localPath: actualImagePath,
        isUploading: true,
      );
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
      final originalIndex = blocks.indexOf(activeBlock);
      
      // 如果光标在最前面，且前一个 block 是图片块，则直接插在图片后面，不进行拆分
      if (splitOffset == 0 && originalIndex > 0 && blocks[originalIndex - 1] is ImageBlock) {
        insertIndex = originalIndex;
        newBottomBlock = activeBlock;
        needsNewBottomBlock = false;
      } else {
        var beforeText = text.substring(0, splitOffset);
        var afterText = text.substring(splitOffset);
        
        // 去除多余换行符，防止图片上方出现空白行
        while (beforeText.endsWith('\n')) {
          beforeText = beforeText.substring(0, beforeText.length - 1);
        }
        // 去除多余换行符，防止图片下方出现空白行
        while (afterText.startsWith('\n')) {
          afterText = afterText.substring(1);
        }
        
        controller.text = beforeText;
        insertIndex = originalIndex + 1;
        newBottomBlock = TextBlock(afterText, baseColor: currentTextColor);
      }
    } else {
      insertIndex = blocks.length;
      newBottomBlock = TextBlock('', baseColor: currentTextColor);
    }

    final parts = imagePath.split('|');
    final actualImagePath = parts[0];
    final String? videoPath = parts.length > 1 ? parts[1] : null;

    final imageBlock = ImageBlock(
      XFile(actualImagePath),
      videoPath: videoPath,
      localPath: actualImagePath,
      isUploading: true,
    );

    setState(() {
      if (blocks.length == 1 && blocks.first is TextBlock && (blocks.first as TextBlock).controller.text.isEmpty) {
        // 同样在空白状态下直接插入收藏大贴纸时自动置顶
        blocks.clear();
        blocks.add(imageBlock);
        
        newBottomBlock = TextBlock('', baseColor: currentTextColor);
        blocks.add(newBottomBlock!);
        
        blockKeys[newBottomBlock!.id] = GlobalKey();
        blockKeys[imageBlock.id] = GlobalKey();
        lastFocusedBlockId = newBottomBlock!.id;
        addFocusListener(newBottomBlock!);
        needsNewBottomBlock = false;
      } else {
        blocks.insert(insertIndex, imageBlock);
        if (needsNewBottomBlock) {
          blocks.insert(insertIndex + 1, newBottomBlock!);
          blockKeys[newBottomBlock!.id] = GlobalKey();
        }
        blockKeys[imageBlock.id] = GlobalKey();
        lastFocusedBlockId = newBottomBlock!.id;
        addFocusListener(newBottomBlock!);
      }
    });

    onBlocksChanged();

    // 同时对自定义贴纸执行后台上传
    _uploadImageInBackground(imageBlock, actualImagePath);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && newBottomBlock != null) {
        newBottomBlock!.controller.selection = const TextSelection.collapsed(offset: 0);
        newBottomBlock!.focusNode.requestFocus();
        scrollToActiveBlock();
      }
    });
  }

  /// 专门用于贴纸创作的单图选择逻辑
  Future<String?> pickSingleImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryImageSourceSheet(paperStyle: currentPaperStyle),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (source == null) return null;

    if (source == ImageSource.gallery) {
      if (!mounted) return null;
      final List<AssetEntity>? result = await RedBookAssetPicker.pick(
        context,
        maxAssets: 1,
        requestType: RequestType.image,
      );
      if (result == null || result.isEmpty) return null;
      final file = await result.first.originFile;
      return file?.path;
    } else {
      if (!mounted) return null;
      final String? imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CustomCameraPage()),
      );
      return imagePath;
    }
  }

  /// 提取安卓端 Motion Photo（动态照片/Moving Picture）的视频轨道并保存到临时文件
  Future<String?> _extractAndroidMotionPhotoVideo(String imagePath, String assetId) async {
    try {
      final file = io.File(imagePath);
      final bytes = await file.readAsBytes();
      
      // 搜索 MP4 的 'ftyp' 标志: [0x66, 0x74, 0x79, 0x70] (从后往前搜索避开 JPEG 头部/元数据的假匹配)
      int ftypIndex = -1;
      for (int i = bytes.length - 4; i >= 0; i--) {
        if (bytes[i] == 0x66 &&
            bytes[i + 1] == 0x74 &&
            bytes[i + 2] == 0x79 &&
            bytes[i + 3] == 0x70) {
          ftypIndex = i;
          break;
        }
      }
      
      if (ftypIndex > 4) {
        // MP4 文件的起始位置在 'ftyp' 标志的前 4 个字节（即 ftyp box 的 size 长度）
        final int videoStart = ftypIndex - 4;
        final videoBytes = bytes.sublist(videoStart);
        
        final appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = "${assetId}_motion.mp4";
        final String savedPath = p.join(appDocDir.path, 'live_photos', fileName);
        
        final savedFile = io.File(savedPath);
        if (!await savedFile.parent.exists()) {
          await savedFile.parent.create(recursive: true);
        }
        await savedFile.writeAsBytes(videoBytes);
        return savedPath;
      }
    } catch (e) {
      debugPrint("Failed to extract Android motion photo video: $e");
    }
    return null;
  }


}
