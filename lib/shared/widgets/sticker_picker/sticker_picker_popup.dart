import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:island_diary/core/services/sticker_service.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

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
      builder: (context) => _ImageSourceSheet(isNight: widget.isNight),
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
    final bytes = await File(image.path).readAsBytes();
    await StickerService().saveAsSticker(bytes);

    await _loadCustomStickers();
  }

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, widget.isNight);
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(widget.paperStyle, widget.isNight);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部指示条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: inkColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
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

class _ImageSourceSheet extends StatelessWidget {
  final bool isNight;
  const _ImageSourceSheet({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text("从相册选择"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text("拍照"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
