import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/emoji_mapping.dart';

/// 表情选择面板
class EmojiPanel extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final VoidCallback? onBackspace;
  final VoidCallback? onSend;
  final Function(String)? onCustomEmojiSelected;

  const EmojiPanel({
    super.key, 
    required this.onEmojiSelected,
    this.onBackspace,
    this.onSend,
    this.onCustomEmojiSelected,
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
    final emojis = EmojiMapping.commonEmojis;

    return Container(
      color: Colors.transparent, // 跟随底部日记纸张色
      child: Column(
        children: [
          // 顶部 Category Bar (仿微信样式)
          Container(
            height: 48,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildCategoryTab(
                  index: 0,
                  icon: Icons.emoji_emotions_outlined,
                  isSelected: _currentIndex == 0,
                ),
                const SizedBox(width: 4),
                _buildCategoryTab(
                  index: 1,
                  icon: Icons.favorite_border,
                  isSelected: _currentIndex == 1,
                ),
              ],
            ),
          ),
          
          // 面板内容大区
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // 第 0 页：默认表情页
                _buildDefaultEmojiPage(emojis),
                
                // 第 1 页：自定义表情包（本地图库保存）
                _buildCustomEmojiPage(),
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
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 52,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? Colors.black87 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildCustomEmojiPage() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSectionTitle('添加的单个表情'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 自定义表情图稍大点
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickCustomEmoji,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26, width: 1.5), // 圆角虚线框其实可以用虚线库实现，为了最小依赖用实线细边替代，也可手动画 dash
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 32, color: Colors.black45),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: videoPath != null
                            ? _buildLiveEmojiPreview(imagePath, videoPath)
                            : Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              ),
                      ),
                    );
                  },
                  childCount: _customEmojis.length + 1,
                ),
              ),
            ),
          ],
        ),
        
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDefaultEmojiPage(List<Map<String, String>> emojis) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // “最近使用” 标题
            _buildSectionTitle('最近使用'),
            
            // “最近使用” 列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8, 
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final identifier = _displayRecentEmojis[index];
                    String? emojiPath = EmojiMapping.getPathForEmoji(identifier);
                    // 识别由于缺少标准 unicode 而产生的降级自定义 [名称]
                    if (emojiPath == null && identifier.startsWith('[') && identifier.endsWith(']')) {
                      final name = identifier.substring(1, identifier.length - 1);
                      emojiPath = EmojiMapping.nameToPath[name];
                    }
                    
                    return InkWell(
                      onTap: () => _handleEmojiTap(identifier),
                      child: Center(
                        child: emojiPath != null
                            ? Image.asset(emojiPath, width: 32, height: 32, fit: BoxFit.contain)
                            : Text(identifier, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                  childCount: _displayRecentEmojis.length,
                ),
              ),
            ),
            
            // 分隔间隙
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 4),
              sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            
            // “所有表情” 标题
            _buildSectionTitle('所有表情'),
            
            // “所有表情” 网格
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final emoji = emojis[index];
                    final String name = emoji['name'] ?? '';
                    final String unicodeStr = emoji['unicode'] ?? '';
                    final String identifier = unicodeStr.isNotEmpty ? unicodeStr : '[$name]';
                    
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
                  },
                  childCount: emojis.length,
                ),
              ),
            ),
          ],
        ),
        
        _buildActionButtons(),
      ],
    );
  }

  // 固定的右下角控制按钮
  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 删除按钮
          GestureDetector(
            onTap: widget.onBackspace,
            child: Container(
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: const Center(
                child: Icon(Icons.backspace_outlined, size: 20, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 发送按钮
          GestureDetector(
            onTap: widget.onSend,
            child: Container(
              width: 56,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9EED8), 
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: const Center(
                child: Text(
                  '发送',
                  style: TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 14,
                    color: Color(0xFF8B5E3C), 
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
    // 复用之前定义的微动播放器，由于它定义在另一个文件，这里简单先用图片占位或在这里也贴一份逻辑
    // 为了最小改动，这里先显示图片叠加一个实况图标标识。
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

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black45,
            fontFamily: 'LXGWWenKai',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
