import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/emoji_mapping.dart';
import '../utils/diary_utils.dart';
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
  // 全局级别的最近使用记录
  static List<String> _globalRecentEmojis = ['😊', '😂', '🥺', '🌹', '😭'];
  // 当前面板固定展示的记录
  late List<String> _displayRecentEmojis;

  List<String> _customEmojis = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _globalRecentEmojis.removeWhere((e) => e.isEmpty); // 清理可能由于旧 bug 遗留的空记录
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
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.common, // 支持图片、视频、实况图
      ),
    );

    if (result != null && result.isNotEmpty) {
      final AssetEntity asset = result.first;
      final File? file = await asset.originFile;
      if (file == null) return;

      String finalPath = file.path;

      // 处理实况图 (Live Photo)
      if (asset.isLivePhoto) {
        // 使用针对实况图优化的 API 获取视频部分
        final File? videoFile = await asset.fileWithSubtype;
        if (videoFile != null) {
          // 这里通过简单的分隔符存储 path|videoPath，后续解析
          finalPath = '${file.path}|${videoFile.path}';
        }
      }

      setState(() {
        _customEmojis.insert(0, finalPath);
      });
      _saveCustomEmojis();
    }
  }

  void _handleEmojiTap(String unicode) {
    widget.onEmojiSelected(unicode);
    // 只更新后台队列，防止当前视图跳动
    _globalRecentEmojis.remove(unicode);
    _globalRecentEmojis.insert(0, unicode);
    if (_globalRecentEmojis.length > 8) {
      _globalRecentEmojis = _globalRecentEmojis.sublist(0, 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(
      widget.paperStyle,
      isNight,
    );
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);
    final emojis = EmojiMapping.commonEmojis;

    // 获取屏幕宽度，动态计算每行显示的表情数量，适配 iPad 等宽屏设备
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 700;

    // 基础表情每项占约 45-50 像素，iPad 上强制增加列数以实现单行效果
    final int defaultCrossAxisCount = isWide
        ? (screenWidth / 45).floor().clamp(14, 25)
        : (screenWidth / 50).floor().clamp(8, 20);

    // 自定义表情（大贴纸）每项占约 80-100 像素
    final int customCrossAxisCount = isWide
        ? (screenWidth / 80).floor().clamp(8, 15)
        : (screenWidth / 90).floor().clamp(5, 12);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // ... 略去 Category Bar 部分 ...
          Container(
            height: 48,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildCategoryTab(
                  index: 0,
                  icon: Icons.face_retouching_natural_rounded,
                  isSelected: _currentIndex == 0,
                  accentColor: accentColor,
                ),
                const SizedBox(width: 8),
                _buildCategoryTab(
                  index: 1,
                  icon: Icons.favorite_rounded,
                  isSelected: _currentIndex == 1,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),

          // 面板内容大区
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDefaultEmojiPage(
                  emojis,
                  accentColor,
                  inkColor,
                  defaultCrossAxisCount,
                ),
                _buildCustomEmojiPage(
                  accentColor,
                  inkColor,
                  customCrossAxisCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({
    required int index,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 52,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? accentColor : accentColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildCustomEmojiPage(
    Color accentColor,
    Color inkColor,
    int crossAxisCount,
  ) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSectionTitle('添加的表情', inkColor),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ).copyWith(bottom: 100),
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
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 32,
                          color: accentColor.withValues(alpha: 0.4),
                        ),
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
        ),
        _buildActionButtons(accentColor, inkColor),
      ],
    );
  }

  Widget _buildDefaultEmojiPage(
    List<Map<String, String>> emojis,
    Color accentColor,
    Color inkColor,
    int crossAxisCount,
  ) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSectionTitle('最近使用', inkColor),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final identifier = _displayRecentEmojis[index];
                  String? emojiPath = EmojiMapping.getPathForEmoji(identifier);
                  if (emojiPath == null &&
                      identifier.startsWith('[') &&
                      identifier.endsWith(']')) {
                    final name = identifier.substring(1, identifier.length - 1);
                    emojiPath = EmojiMapping.nameToPath[name];
                  }

                  return InkWell(
                    onTap: () => _handleEmojiTap(identifier),
                    child: Center(
                      child: emojiPath != null
                          ? Image.asset(
                              emojiPath,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            )
                          : Text(
                              identifier,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  );
                }, childCount: _displayRecentEmojis.length),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 4),
              sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            _buildSectionTitle('所有表情', inkColor),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ).copyWith(bottom: 100),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final emoji = emojis[index];
                  final String name = emoji['name'] ?? '';
                  final String unicodeStr = emoji['unicode'] ?? '';
                  final String identifier = unicodeStr.isNotEmpty
                      ? unicodeStr
                      : '[$name]';

                  return InkWell(
                    onTap: () => _handleEmojiTap(identifier),
                    child: Center(
                      child: Image.asset(
                        emoji['path']!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }, childCount: emojis.length),
              ),
            ),
          ],
        ),
        _buildActionButtons(accentColor, inkColor),
      ],
    );
  }

  // 固定的右下角控制按钮
  Widget _buildActionButtons(Color accentColor, Color inkColor) {
    final bool isNight = UserState().isNight;
    return Positioned(
      right: 20,
      bottom: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 删除按钮
          GestureDetector(
            onTap: widget.onBackspace,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.backspace_rounded, size: 22, color: accentColor),
            ),
          ),
          const SizedBox(width: 12),
          // 发送按钮
          GestureDetector(
            onTap: widget.onSend,
            child: Container(
              width: 64,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '发送',
                  style: TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEmojiPreview(String imagePath, String videoPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(imagePath), fit: BoxFit.cover),
        const Positioned(
          top: 4,
          right: 4,
          child: Icon(Icons.live_tv, size: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color inkColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: inkColor.withValues(alpha: 0.4),
            fontFamily: 'LXGWWenKai',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
