import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:island_diary/core/services/sticker_service.dart';
import 'package:island_diary/core/services/sticker_segmentation_service.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_image_source_sheet.dart';

class StickerPickerPopup extends StatefulWidget {
  final String paperStyle;
  final bool isNight;
  final Function(String) onStickerSelected;

  const StickerPickerPopup({
    super.key,
    required this.paperStyle,
    required this.isNight,
    required this.onStickerSelected,
  });

  @override
  State<StickerPickerPopup> createState() => _StickerPickerPopupState();
}

class _StickerPickerPopupState extends State<StickerPickerPopup> {
  List<String> _customStickers = [];
  bool _isLoading = true;
  String _currentCategory = "我的";

  final List<String> _categories = ["我的", "黑紫甜酷兔"];
  
  final Map<String, List<String>> _predefinedStickers = {
    "黑紫甜酷兔": [
      "assets/images/sticker/bp_sweet_bunny1.png",
      "assets/images/sticker/bp_sweet_bunny2.png",
      "assets/images/sticker/bp_sweet_bunny3.png",
      "assets/images/sticker/bp_sweet_bunny4.png",
      "assets/images/sticker/bp_sweet_bunny5.png",
      "assets/images/sticker/bp_sweet_bunny6.png",
      "assets/images/sticker/bp_sweet_bunny7.png",
      "assets/images/sticker/bp_sweet_bunny8.png",
      "assets/images/sticker/bp_sweet_bunny9.png",
      "assets/images/sticker/bp_sweet_bunny10.png",
      "assets/images/sticker/bp_sweet_bunny11.png",
      "assets/images/sticker/bp_sweet_bunny12.png",
      "assets/images/sticker/bp_sweet_bunny13.png",
      "assets/images/sticker/bp_sweet_bunny14.png",
      "assets/images/sticker/bp_sweet_bunny15.png",
      "assets/images/sticker/bp_sweet_bunny16.png",
      "assets/images/sticker/bp_sweet_bunny17.png",
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadCustomStickers();
  }

  Future<void> _loadCustomStickers() async {
    setState(() => _isLoading = true);
    final stickers = await StickerService().getCustomStickers();
    if (mounted) {
      setState(() {
        _customStickers = stickers;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpload() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryImageSourceSheet(paperStyle: widget.paperStyle),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isLoading = true);
    
    // 自动调用谷歌端侧自拍分割服务抠图并烘焙白色卡通描边
    final croppedBytes = await StickerSegmentationService().segmentAndCropSubject(image.path);
    final finalBytes = croppedBytes ?? await File(image.path).readAsBytes();
    
    await StickerService().saveAsSticker(finalBytes);

    await _loadCustomStickers();
  }

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, widget.isNight);
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(widget.paperStyle, widget.isNight).withValues(alpha: 1.0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: DiaryUtils.getPopupDecoration(
        widget.paperStyle,
        widget.isNight,
        customBgColor: bgColor,
      ),
      child: Column(
        children: [
          // 顶部指示条
          const SizedBox(height: 12),
          DiaryUtils.buildPopupDragHandle(
            widget.paperStyle,
            widget.isNight,
            inkColor,
          ),

          // 分类选择
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final bool isSelected = _currentCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _currentCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? inkColor.withValues(alpha: 0.1) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? inkColor.withValues(alpha: 0.2) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? inkColor : inkColor.withValues(alpha: 0.5),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 贴纸内容区
          Expanded(
            child: _isLoading && _currentCategory == "我的"
                ? Center(child: CircularProgressIndicator(color: inkColor.withValues(alpha: 0.5)))
                : _buildStickerGrid(inkColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerGrid(Color inkColor) {
    if (_currentCategory == "我的") {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: _customStickers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _handleUpload,
              child: Container(
                decoration: BoxDecoration(
                  color: inkColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: inkColor.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: inkColor.withValues(alpha: 0.4),
                ),
              ),
            );
          }
          final stickerIndex = index - 1;
          return _buildStickerItem(_customStickers[stickerIndex], isFile: true);
        },
      );
    } else {
      final stickers = _predefinedStickers[_currentCategory] ?? [];
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: stickers.length,
        itemBuilder: (context, index) {
          return _buildStickerItem(stickers[index], isFile: false);
        },
      );
    }
  }

  Widget _buildStickerItem(String path, {required bool isFile}) {
    return GestureDetector(
      onTap: () => widget.onStickerSelected(path),
      child: Container(
        padding: const EdgeInsets.all(4), // 留一点间距，防止贴边
        decoration: BoxDecoration(
          color: Colors.transparent, // 改为透明
          borderRadius: BorderRadius.circular(16),
        ),
        child: isFile 
            ? Image.file(File(path), fit: BoxFit.contain)
            : Image.asset(path, fit: BoxFit.contain),
      ),
    );
  }
}

// 移除了重复硬编码的 _ImageSourceSheet 声明，完全由通用的 DiaryImageSourceSheet 统一代劳。
