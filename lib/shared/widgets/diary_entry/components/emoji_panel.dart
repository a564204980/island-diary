import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/emoji_mapping.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 表情选择面板
class EmojiPanel extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final VoidCallback? onBackspace;
  final VoidCallback? onSend;
  final Function(String)? onCustomEmojiSelected;
  final String paperStyle;

  const EmojiPanel({
    super.key,
    required this.onEmojiSelected,
    this.onBackspace,
    this.onSend,
    this.onCustomEmojiSelected,
    this.paperStyle = 'standard',
  });

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  // 全局级别的最近使用记录 (存储 identifier)
  static List<String> _globalRecentEmojis = [];
  // 当前面板固定展示的记录
  late List<String> _displayRecentEmojis;

  List<String> _customEmojis = [];
  int _currentIndex = 0; // 0: 云织, 1: 霜见, 2: 笃守, 3: 灵犀, 4: 收藏

  @override
  void initState() {
    super.initState();
    _globalRecentEmojis.removeWhere((e) => e.isEmpty);
    _displayRecentEmojis = List.from(_globalRecentEmojis);
    _loadCustomEmojis();
  }

  Future<void> _loadCustomEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customEmojis = prefs.getStringList('island_diary_custom_emojis') ?? [];
    });
  }

  Future<void> _saveCustomEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('island_diary_custom_emojis', _customEmojis);
  }

  Future<void> _pickCustomEmoji() async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.common,
        filterOptions: FilterOptionGroup(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final AssetEntity asset = result.first;
      final File? file = await asset.originFile;
      if (file == null) return;

      String finalPath = file.path;
      if (asset.isLivePhoto) {
        final File? videoFile = await asset.fileWithSubtype;
        if (videoFile != null) {
          finalPath = '${file.path}|${videoFile.path}';
        }
      } else if (Platform.isAndroid) {
        final extractedPath = await _extractAndroidMotionPhotoVideo(file.path, asset.id);
        if (extractedPath != null) {
          finalPath = '${file.path}|$extractedPath';
        }
      }

      setState(() {
        _customEmojis.insert(0, finalPath);
      });
      _saveCustomEmojis();
    }
  }

  void _handleEmojiTap(String identifier) {
    widget.onEmojiSelected(identifier);
    
    // 仅记录在 EmojiMapping 中有定义的表情到最近使用
    if (!EmojiMapping.isEmojiChar(identifier)) return;

    _globalRecentEmojis.remove(identifier);
    _globalRecentEmojis.insert(0, identifier);
    if (_globalRecentEmojis.length > 8) {
      _globalRecentEmojis = _globalRecentEmojis.sublist(0, 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final Color inkColor;
    final Color accentColor;
    if (isNight) {
      inkColor = Colors.white;
      accentColor = themeId == 'cotton_candy' ? const Color(0xFFC0A6FF) : const Color(0xFFE0C097);
    } else {
      inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
      accentColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFFA68565);
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // 分类切换栏 (iOS Segmented Control 高级毛玻璃悬浮风格)
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            decoration: BoxDecoration(
              color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryTabText(
                    index: 0,
                    title: '云织',
                    isSelected: _currentIndex == 0,
                    inkColor: inkColor,
                    isNight: isNight,
                  ),
                ),
                Expanded(
                  child: _buildCategoryTabText(
                    index: 1,
                    title: '霜见',
                    isSelected: _currentIndex == 1,
                    inkColor: inkColor,
                    isNight: isNight,
                  ),
                ),
                Expanded(
                  child: _buildCategoryTabText(
                    index: 2,
                    title: '笃守',
                    isSelected: _currentIndex == 2,
                    inkColor: inkColor,
                    isNight: isNight,
                  ),
                ),
                Expanded(
                  child: _buildCategoryTabText(
                    index: 3,
                    title: '灵犀',
                    isSelected: _currentIndex == 3,
                    inkColor: inkColor,
                    isNight: isNight,
                  ),
                ),
                Expanded(
                  child: _buildCategoryTabIcon(
                    index: 4,
                    icon: Icons.favorite_rounded,
                    isSelected: _currentIndex == 4,
                    inkColor: inkColor,
                    isNight: isNight,
                  ),
                ),
              ],
            ),
          ),

          // 内容区
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildEmojiPage('云织', accentColor, inkColor),
                _buildEmojiPage('霜见', accentColor, inkColor),
                _buildEmojiPage('笃守', accentColor, inkColor),
                _buildEmojiPage('灵犀', accentColor, inkColor),
                _buildCustomEmojiPage(accentColor, inkColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabText({
    required int index,
    required String title,
    required bool isSelected,
    required Color inkColor,
    required bool isNight,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? inkColor : inkColor.withValues(alpha: 0.4),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabIcon({
    required int index,
    required IconData icon,
    required bool isSelected,
    required Color inkColor,
    required bool isNight,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? inkColor : inkColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPage(String categoryId, Color accentColor, Color inkColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = (screenWidth / 50).floor().clamp(8, 20);
    
    final category = EmojiMapping.categories.firstWhere((c) => c['id'] == categoryId);
    final List emojis = category['emojis'];

    return CustomScrollView(
      slivers: [
        if (_displayRecentEmojis.isNotEmpty) ...[
          _buildSectionTitle('最近使用', inkColor),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final identifier = _displayRecentEmojis[index];
                final path = EmojiMapping.getPathForEmoji(identifier);
                return InkWell(
                  onTap: () => _handleEmojiTap(identifier),
                  child: Center(
                    child: path != null
                        ? Image.asset(path, width: 32, height: 32, fit: BoxFit.contain)
                        : Text(identifier, style: const TextStyle(fontSize: 16)),
                  ),
                );
              }, childCount: _displayRecentEmojis.length),
            ),
          ),
        ],
        _buildSectionTitle('所有表情', inkColor),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 0).copyWith(bottom: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final e = emojis[index];
              // 使用 PUA 字符作为标识符
              final identifier = String.fromCharCode(e['pua'] as int);
              final path = '${category['prefix']}${e['file']}';
              return InkWell(
                onTap: () => _handleEmojiTap(identifier),
                child: Center(
                  child: Image.asset(path, width: 32, height: 32, fit: BoxFit.contain),
                ),
              );
            }, childCount: emojis.length),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomEmojiPage(Color accentColor, Color inkColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = (screenWidth / 90).floor().clamp(5, 12);

    return CustomScrollView(
      slivers: [
        _buildSectionTitle('添加的表情', inkColor),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 0).copyWith(bottom: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _pickCustomEmoji,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.05),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_rounded, size: 32, color: accentColor.withValues(alpha: 0.4)),
                  ),
                );
              }
              final rawPath = _customEmojis[index - 1];
              final parts = rawPath.split('|');
              final imagePath = parts[0];
              final videoPath = parts.length > 1 ? parts[1] : null;

              return GestureDetector(
                onTap: () {
                  if (widget.onCustomEmojiSelected != null) {
                    widget.onCustomEmojiSelected!(rawPath);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: videoPath != null
                      ? _buildLiveEmojiPreview(imagePath, videoPath)
                      : Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              );
            }, childCount: _customEmojis.length + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveEmojiPreview(String imagePath, String videoPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(imagePath), fit: BoxFit.cover),
        const Positioned(top: 4, right: 4, child: Icon(Icons.live_tv, size: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color inkColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: inkColor.withValues(alpha: 0.8),
            fontFamily: 'LXGWWenKai',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  /// 提取安卓端 Motion Photo（动态照片/Moving Picture）的视频轨道并保存到临时文件
  Future<String?> _extractAndroidMotionPhotoVideo(String imagePath, String assetId) async {
    try {
      final file = File(imagePath);
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
        
        final savedFile = File(savedPath);
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
