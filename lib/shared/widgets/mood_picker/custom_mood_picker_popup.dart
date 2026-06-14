import 'dart:io';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/redbook_asset_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CustomMoodPickerPage extends StatefulWidget {
  final String paperStyle;
  final bool isNight;
  final bool isFromEditor;

  const CustomMoodPickerPage({
    super.key,
    required this.paperStyle,
    required this.isNight,
    this.isFromEditor = true,
  });

  @override
  State<CustomMoodPickerPage> createState() => _CustomMoodPickerPageState();
}

class _CustomMoodPickerPageState extends State<CustomMoodPickerPage> {
  final TextEditingController _controller = TextEditingController();
  int _selectedGridIndex = 1; // 默认选中系统表情的第1个（index = 1）
  String? _selectedInspirationTag;
  String? _errorText;

  SharedPreferences? _prefs;
  List<String> _inspirationTags = ["想念", "委屈", "焦虑", "空空的", "释然", "被治愈"];
  List<String> _recentMoodTags = [];
  List<String> _customEmojis = []; // 存放自定义表情文件名，例如 emoji_123.png

  static const List<Map<String, String>> emojis = [
    {'label': '开心', 'icon': 'assets/icons/custom1.png'},
    {'label': '平静', 'icon': 'assets/icons/custom2.png'},
    {'label': '低落', 'icon': 'assets/icons/custom3.png'},
    {'label': '烦躁', 'icon': 'assets/icons/custom4.png'},
    {'label': '疲惫', 'icon': 'assets/icons/custom5.png'},
    {'label': '惊喜', 'icon': 'assets/icons/custom6.png'},
    {'label': '害羞', 'icon': 'assets/icons/custom7.png'},
    {'label': '焦虑', 'icon': 'assets/icons/custom8.png'},
    {'label': '委屈', 'icon': 'assets/icons/custom9.png'},
    {'label': '无聊', 'icon': 'assets/icons/custom10.png'},
    {'label': '期待', 'icon': 'assets/icons/custom11.png'},
    {'label': '自定义12', 'icon': 'assets/icons/custom12.png'},
    {'label': '自定义13', 'icon': 'assets/icons/custom13.png'},
    {'label': '自定义14', 'icon': 'assets/icons/custom14.png'},
    {'label': '自定义15', 'icon': 'assets/icons/custom15.png'},
    {'label': '自定义16', 'icon': 'assets/icons/custom16.png'},
    {'label': '自定义17', 'icon': 'assets/icons/custom17.png'},
    {'label': '自定义18', 'icon': 'assets/icons/custom18.png'},
    {'label': '自定义19', 'icon': 'assets/icons/custom19.png'},
    {'label': '自定义20', 'icon': 'assets/icons/custom20.png'},
    {'label': '自定义21', 'icon': 'assets/icons/custom21.png'},
    {'label': '自定义22', 'icon': 'assets/icons/custom22.png'},
    {'label': '自定义23', 'icon': 'assets/icons/custom23.png'},
    {'label': '自定义24', 'icon': 'assets/icons/custom24.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();

    final List<String>? savedInspiration = _prefs!.getStringList('custom_inspiration_tags');
    if (savedInspiration != null) {
      _inspirationTags = savedInspiration;
    }

    final List<String>? savedRecent = _prefs!.getStringList('recent_custom_mood_tags');
    if (savedRecent != null) {
      _recentMoodTags = savedRecent;
    }

    final List<String>? savedCustomEmojis = _prefs!.getStringList('user_imported_emojis');
    if (savedCustomEmojis != null) {
      _customEmojis = savedCustomEmojis;
    }

    setState(() {});
  }

  Future<void> _saveRecentMood(String tag) async {
    if (_prefs == null) return;
    final list = List<String>.from(_recentMoodTags);
    list.remove(tag);
    list.insert(0, tag);
    if (list.length > 10) {
      list.removeLast();
    }
    _recentMoodTags = list;
    await _prefs!.setStringList('recent_custom_mood_tags', list);
  }

  Future<void> _importCustomEmoji() async {
    try {
      final List<AssetEntity>? result = await RedBookAssetPicker.pick(
        context,
        maxAssets: 1,
        requestType: RequestType.image,
      );
      if (result == null || result.isEmpty) return;
      final File? file = await result.first.file;
      if (file == null) return;

      final Directory docDir = await getApplicationDocumentsDirectory();
      final Directory emojiDir = Directory('${docDir.path}/custom_emojis');
      if (!await emojiDir.exists()) {
        await emojiDir.create(recursive: true);
      }

      final String fileName = 'emoji_${DateTime.now().millisecondsSinceEpoch}.png';
      await file.copy('${emojiDir.path}/$fileName');

      final list = List<String>.from(_customEmojis);
      list.add(fileName);
      _customEmojis = list;
      if (_prefs != null) {
        await _prefs!.setStringList('user_imported_emojis', list);
      }

      setState(() {
        _selectedGridIndex = 1 + emojis.length + _customEmojis.length - 1;
      });
    } catch (e) {
      debugPrint("Import emoji error: $e");
    }
  }

  void _onLongPressCustomEmoji(int customEmojiIndex) {
    final String fileName = _customEmojis[customEmojiIndex];
    showDialog(
      context: context,
      builder: (context) {
        final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, widget.isNight);
        final themeId = UserState().selectedIslandThemeId.value;
        final bool isLego = themeId == 'lego';
        final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

        return AlertDialog(
          backgroundColor: widget.isNight ? const Color(0xFF241E3D) : const Color(0xFFFAF8F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLego ? 8.0 : 16.0),
          ),
          title: Text(
            "删除表情",
            style: TextStyle(fontFamily: fontFamily, color: inkColor),
          ),
          content: Text(
            "确定要删除这个自定义表情吗？",
            style: TextStyle(fontFamily: fontFamily, color: inkColor.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("取消", style: TextStyle(fontFamily: fontFamily, color: inkColor.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final Directory docDir = await getApplicationDocumentsDirectory();
                  final File file = File('${docDir.path}/custom_emojis/$fileName');
                  if (await file.exists()) {
                    await file.delete();
                  }

                  setState(() {
                    final gridIndexToDelete = 1 + emojis.length + customEmojiIndex;
                    _customEmojis.removeAt(customEmojiIndex);
                    if (_prefs != null) {
                      _prefs!.setStringList('user_imported_emojis', _customEmojis);
                    }
                    if (_selectedGridIndex == gridIndexToDelete) {
                      _selectedGridIndex = 1;
                    } else if (_selectedGridIndex > gridIndexToDelete) {
                      _selectedGridIndex--;
                    }
                  });
                } catch (e) {
                  debugPrint("Delete emoji error: $e");
                }
              },
              child: const Text("删除", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTagDialog() {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, widget.isNight);
        final themeId = UserState().selectedIslandThemeId.value;
        final bool isLego = themeId == 'lego';
        final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';
        
        final Color themeAccentColor = DiaryUtils.getAccentColor(widget.paperStyle, widget.isNight);
        final Color primaryColor = isLego
            ? (widget.isNight ? const Color(0xFFFFA726) : const Color(0xFFFF9800))
            : (themeId == 'cotton_candy'
                ? const Color(0xFFC0A6FF)
                : themeAccentColor);

        return AlertDialog(
          backgroundColor: widget.isNight ? const Color(0xFF241E3D) : const Color(0xFFFAF8F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLego ? 8.0 : 16.0),
          ),
          title: Text("添加灵感标签", style: TextStyle(fontFamily: fontFamily, color: inkColor)),
          content: TextField(
            controller: tagController,
            autofocus: true,
            maxLength: 10,
            style: TextStyle(fontFamily: fontFamily, color: inkColor),
            decoration: InputDecoration(
              hintText: "输入新标签名称",
              hintStyle: TextStyle(color: inkColor.withValues(alpha: 0.3)),
              counterText: "",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("取消", style: TextStyle(fontFamily: fontFamily, color: inkColor.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () async {
                final text = tagController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context);
                  if (!_inspirationTags.contains(text)) {
                    setState(() {
                      _inspirationTags.add(text);
                      if (_prefs != null) {
                        _prefs!.setStringList('custom_inspiration_tags', _inspirationTags);
                      }
                    });
                  }
                }
              },
              child: Text("添加", style: TextStyle(fontFamily: fontFamily, color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _onLongPressTag(String tag) {
    showDialog(
      context: context,
      builder: (context) {
        final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, widget.isNight);
        final themeId = UserState().selectedIslandThemeId.value;
        final bool isLego = themeId == 'lego';
        final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

        return AlertDialog(
          backgroundColor: widget.isNight ? const Color(0xFF241E3D) : const Color(0xFFFAF8F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLego ? 8.0 : 16.0),
          ),
          title: Text("删除标签", style: TextStyle(fontFamily: fontFamily, color: inkColor)),
          content: Text("确定要删除“$tag”这个标签吗？", style: TextStyle(fontFamily: fontFamily, color: inkColor.withValues(alpha: 0.8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("取消", style: TextStyle(fontFamily: fontFamily, color: inkColor.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _inspirationTags.remove(tag);
                  if (_selectedInspirationTag == tag) {
                    _selectedInspirationTag = null;
                  }
                  if (_prefs != null) {
                    _prefs!.setStringList('custom_inspiration_tags', _inspirationTags);
                  }
                });
              },
              child: const Text("删除", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAddEmojiItem(Color primaryColor, Color inkColor, double defaultRadius) {
    return GestureDetector(
      onTap: _importCustomEmoji,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: inkColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          color: widget.isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: inkColor.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiItem(int gridIndex, Color primaryColor, Color inkColor) {
    final int totalCount = 1 + emojis.length + _customEmojis.length;
    if (gridIndex >= totalCount) return const SizedBox.shrink();

    if (gridIndex == 0) {
      final themeId = UserState().selectedIslandThemeId.value;
      final bool isLego = themeId == 'lego';
      final double defaultRadius = isLego ? 8.0 : (themeId == 'cotton_candy' ? 24.0 : 16.0);
      return _buildAddEmojiItem(primaryColor, inkColor, defaultRadius);
    }

    final bool isSelected = _selectedGridIndex == gridIndex;
    final bool isCustom = gridIndex > emojis.length;

    String? assetPath;
    String? customFileName;
    String label = "";

    if (!isCustom) {
      final emoji = emojis[gridIndex - 1];
      assetPath = emoji['icon'];
      label = emoji['label']!;
    } else {
      customFileName = _customEmojis[gridIndex - 1 - emojis.length];
      label = "自定义";
    }

    final Color itemBgColor = isSelected
        ? primaryColor.withValues(alpha: 0.12)
        : Colors.transparent;

    Widget emojiWidget;
    if (isCustom) {
      final String directPath = '${DiaryUtils.documentsDirPath}/$customFileName';
      final String subDirPath = '${DiaryUtils.documentsDirPath}/custom_emojis/$customFileName';
      final File file = File(subDirPath).existsSync() ? File(subDirPath) : File(directPath);
      emojiWidget = Image.file(
        file,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.mood, color: primaryColor.withValues(alpha: 0.3)),
      );
      emojiWidget = ClipOval(child: emojiWidget);
    } else {
      emojiWidget = Image.asset(
        assetPath!,
        width: 44,
        height: 44,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.mood, color: primaryColor.withValues(alpha: 0.3)),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGridIndex = gridIndex;
          if (!isCustom) {
            _selectedInspirationTag = null;
            _controller.text = label;
          }
        });
      },
      onLongPress: isCustom ? () => _onLongPressCustomEmoji(gridIndex - 1 - emojis.length) : null,
      child: AnimatedScale(
        scale: isSelected ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: itemBgColor,
            border: Border.all(
              color: isSelected ? primaryColor.withValues(alpha: 0.25) : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Center(
            child: emojiWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildAddTagChip(Color primaryColor, Color inkColor, double chipRadius, String fontFamily) {
    return GestureDetector(
      onTap: _showAddTagDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isNight ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F2EB),
          borderRadius: BorderRadius.circular(chipRadius),
          border: Border.all(
            color: inkColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: inkColor.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              "新增",
              style: TextStyle(
                fontSize: 13,
                color: inkColor.withValues(alpha: 0.6),
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMoodTags(Color primaryColor, Color inkColor, double chipRadius, String fontFamily) {
    if (_recentMoodTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "最近使用",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: inkColor.withValues(alpha: 0.7),
            fontFamily: fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentMoodTags.length,
            itemBuilder: (context, idx) {
              final tag = _recentMoodTags[idx];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.text = tag;
                      _selectedInspirationTag = null;
                      _errorText = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isNight
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF7F2EB),
                      borderRadius: BorderRadius.circular(chipRadius),
                      border: Border.all(
                        color: inkColor.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: inkColor.withValues(alpha: 0.7),
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircleBtn({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isNight,
    required String themeId,
  }) {
    final bool isLego = themeId == 'lego';

    if (isLego) {
      final Color btnColor = isNight ? const Color(0xFF2C2518) : const Color(0xFFFFFDF2);
      final Color depthColor = isNight ? const Color(0xFF1B160E) : const Color(0xFFEADAB9);
      final Color shadowColor = isNight ? const Color(0x80000000) : const Color(0x3D5D4037);
      final Color arrowColor = isNight ? Colors.white70 : const Color(0xFF5D4037);

      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 38,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: depthColor,
                blurRadius: 0,
                offset: const Offset(0, 3.5),
              ),
              BoxShadow(
                color: shadowColor,
                blurRadius: 5.0,
                offset: const Offset(0, 5.0),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: arrowColor,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon == Icons.chevron_left_rounded ? Icons.arrow_back_ios_new_rounded : icon,
        size: 20,
        color: isNight ? Colors.white70 : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(
      widget.paperStyle,
      widget.isNight,
    );
    final bool isDark = widget.isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final bool isCottonCandy = themeId == 'cotton_candy';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    final Color themeAccentColor = DiaryUtils.getAccentColor(widget.paperStyle, isDark);
    final Color primaryColor = isLego
        ? (isDark ? const Color(0xFFFFA726) : const Color(0xFFFF9800))
        : (isCottonCandy
            ? const Color(0xFFC0A6FF)
            : themeAccentColor);

    final Color bgColor = isDark
        ? (isCottonCandy
            ? const Color(0xFF241E3D).withValues(alpha: 0.95)
            : const Color(0xFF121212))
        : (themeId == 'cotton_candy' && widget.paperStyle == 'classic'
            ? const Color(0xFFFBF3E9)
            : const Color(0xFFFAF8F5));

    final double defaultRadius = isLego ? 8.0 : (isCottonCandy ? 24.0 : 16.0);
    final double chipRadius = isLego ? 8.0 : 20.0;

    final Border textfieldBorder = isLego
        ? Border.all(color: isDark ? Colors.white70 : Colors.black, width: 1.8)
        : Border.all(color: isCottonCandy
            ? const Color(0xFFC0A6FF).withValues(alpha: 0.4)
            : inkColor.withValues(alpha: 0.15));

    Border tagBorder(bool isSelected) => isSelected
        ? Border.all(color: primaryColor, width: isLego ? 1.8 : 1.2)
        : (isLego
            ? Border.all(color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.8), width: 1.2)
            : Border.all(color: isCottonCandy
                ? const Color(0xFFC0A6FF).withValues(alpha: 0.2)
                : inkColor.withValues(alpha: 0.08)));

    final int totalEmojiCount = 1 + emojis.length + _customEmojis.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: bgColor,
              child: (themeId == 'cotton_candy' && widget.paperStyle == 'classic')
                  ? Image.asset(
                      isDark
                          ? 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_night_bg.png'
                          : 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_bg.png',
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          _buildCircleBtn(
                            context: context,
                            icon: Icons.chevron_left_rounded,
                            onTap: () => Navigator.pop(context),
                            isNight: isDark,
                            themeId: themeId,
                          ),
                          const Spacer(),
                          Text(
                            "创建此刻心情",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: inkColor.withValues(alpha: 0.9),
                              fontFamily: fontFamily,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              "心情标签",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: inkColor.withValues(alpha: 0.7),
                                fontFamily: fontFamily,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(defaultRadius),
                                border: textfieldBorder,
                              ),
                              child: TextField(
                                controller: _controller,
                                maxLength: 10,
                                onChanged: (val) {
                                  if (_errorText != null) {
                                    setState(() => _errorText = null);
                                  }
                                },
                                style: TextStyle(color: inkColor, fontFamily: fontFamily),
                                decoration: InputDecoration(
                                  hintText: "比如：期待又紧张",
                                  errorText: _errorText,
                                  counterText: "",
                                  errorStyle: TextStyle(
                                    fontSize: 12,
                                    fontFamily: fontFamily,
                                  ),
                                  hintStyle: TextStyle(
                                    color: inkColor.withValues(alpha: 0.3),
                                    fontSize: 14,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            _buildRecentMoodTags(primaryColor, inkColor, chipRadius, fontFamily),
                            const SizedBox(height: 28),
                            Text(
                              "灵感标签",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: inkColor.withValues(alpha: 0.7),
                                fontFamily: fontFamily,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ..._inspirationTags.map((tag) {
                                  final bool isSelected = _selectedInspirationTag == tag;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedInspirationTag = isSelected ? null : tag;
                                        if (!isSelected) {
                                          _controller.text = tag;
                                          _errorText = null;
                                        }
                                      });
                                    },
                                    onLongPress: () => _onLongPressTag(tag),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isLego
                                                ? primaryColor
                                                : primaryColor.withValues(alpha: isDark ? 0.25 : 0.12))
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.05)
                                                : const Color(0xFFF7F2EB)),
                                        borderRadius: BorderRadius.circular(chipRadius),
                                        border: tagBorder(isSelected),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? (isLego ? (isDark ? Colors.black : Colors.white) : primaryColor)
                                              : inkColor.withValues(alpha: 0.6),
                                          fontFamily: fontFamily,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                _buildAddTagChip(primaryColor, inkColor, chipRadius, fontFamily),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "选择一个表情",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: inkColor.withValues(alpha: 0.7),
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: totalEmojiCount,
                              itemBuilder: (context, index) => _buildEmojiItem(index, primaryColor, inkColor),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _AnimatedButton(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : inkColor.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(24),
                                    border: isLego
                                        ? Border.all(color: isDark ? Colors.white30 : Colors.black, width: 1.5)
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "取消",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: inkColor.withValues(alpha: 0.6),
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _AnimatedButton(
                                onTap: () async {
                                  final String tagText = _controller.text.trim();
                                  if (tagText.isEmpty) {
                                    setState(() => _errorText = "请给这一刻起个名字吧");
                                    return;
                                  }

                                  await _saveRecentMood(tagText);
                                  if (!context.mounted) return;

                                  final isCustom = _selectedGridIndex > emojis.length;
                                  if (isCustom) {
                                    final customFileName = _customEmojis[_selectedGridIndex - 1 - emojis.length];
                                    Navigator.pop(context, {
                                      'index': 100 + (_selectedGridIndex - 1 - emojis.length),
                                      'tag': tagText,
                                      'intensity': 6.0,
                                      'customMoodIcon': customFileName,
                                    });
                                  } else {
                                    Navigator.pop(context, {
                                      'index': _selectedGridIndex - 1,
                                      'tag': tagText,
                                      'intensity': 6.0,
                                    });
                                  }
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: isLego
                                        ? null
                                        : LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                                          ),
                                    color: isLego ? primaryColor : null,
                                    borderRadius: BorderRadius.circular(24),
                                    border: isLego
                                        ? Border.all(color: isDark ? Colors.white70 : Colors.black, width: 1.5)
                                        : null,
                                    boxShadow: isLego
                                        ? [
                                            BoxShadow(
                                              color: isDark ? const Color(0xFF1B160E) : const Color(0xFFEADAB9),
                                              blurRadius: 0,
                                              offset: const Offset(0, 3.5),
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: primaryColor.withValues(alpha: 0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.isFromEditor ? "保存这份心情" : "完成并返回",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isLego ? (isDark ? Colors.black : Colors.white) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _AnimatedButton({required this.onTap, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOutCubic,
        child: widget.child,
      ),
    );
  }
}
