import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/redbook_asset_picker.dart';
import 'dart:convert';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class RecentMoodItem {
  final String tag;
  final String iconPath;
  final int index;
  final String type; // 'standard', 'pack', 'user'

  RecentMoodItem({
    required this.tag,
    required this.iconPath,
    required this.index,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'iconPath': iconPath,
        'index': index,
        'type': type,
      };

  factory RecentMoodItem.fromJson(Map<String, dynamic> json) => RecentMoodItem(
        tag: json['tag'],
        iconPath: json['iconPath'],
        index: json['index'],
        type: json['type'] ?? 'user',
      );
}

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
  String? _errorText;

  SharedPreferences? _prefs;
  List<RecentMoodItem> _recentMoods = [];
  List<String> _customEmojis = []; // 存放自定义表情文件名，例如 emoji_123.png

  static const List<Map<String, String>> standardEmojis = [
    {'label': '开心', 'icon': 'assets/icons/happy.png'},
    {'label': '平静', 'icon': 'assets/icons/calm.png'},
    {'label': '低落', 'icon': 'assets/icons/down.png'},
    {'label': '烦躁', 'icon': 'assets/icons/irritated.png'},
    {'label': '疲惫', 'icon': 'assets/icons/tired.png'},
    {'label': '惊喜', 'icon': 'assets/icons/surprise.png'},
    {'label': '害羞', 'icon': 'assets/icons/shy.png'},
    {'label': '焦虑', 'icon': 'assets/icons/anxious.png'},
    {'label': '委屈', 'icon': 'assets/icons/wronged.png'},
    {'label': '无聊', 'icon': 'assets/icons/bored.png'},
    {'label': '期待', 'icon': 'assets/icons/expect.png'},
  ];

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

    final List<String>? savedRecent = _prefs!.getStringList('recent_custom_moods_v2');
    if (savedRecent != null) {
      _recentMoods = savedRecent.map((e) {
        try {
          return RecentMoodItem.fromJson(jsonDecode(e));
        } catch (_) {
          return null;
        }
      }).whereType<RecentMoodItem>().toList();
    }

    final List<String>? savedCustomEmojis = _prefs!.getStringList('user_imported_emojis');
    if (savedCustomEmojis != null) {
      _customEmojis = savedCustomEmojis;
    }

    setState(() {});
  }

  Future<void> _saveRecentMoodItem(RecentMoodItem item) async {
    if (_prefs == null) return;
    
    // Remove if exists (by tag name to avoid duplicate names)
    _recentMoods.removeWhere((e) => e.tag == item.tag);
    _recentMoods.insert(0, item);
    
    if (_recentMoods.length > 10) {
      _recentMoods.removeLast();
    }
    
    final listStr = _recentMoods.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs!.setStringList('recent_custom_moods_v2', listStr);
  }

  Future<String> _ensureStandardAssetInFileSystem(String assetPath) async {
    try {
      final Directory docDir = await getApplicationDocumentsDirectory();
      final Directory emojiDir = Directory('${docDir.path}/custom_emojis');
      if (!await emojiDir.exists()) {
        await emojiDir.create(recursive: true);
      }
      final String fileName = assetPath.split('/').last;
      final File file = File('${emojiDir.path}/$fileName');
      if (!await file.exists()) {
        final byteData = await rootBundle.load(assetPath);
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
      return fileName;
    } catch (e) {
      debugPrint("Error copying standard asset to filesystem: $e");
      return assetPath;
    }
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
        _selectedGridIndex = 1 + standardEmojis.length + emojis.length + _customEmojis.length - 1;
        _controller.text = "自定义";
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
    final int standardCount = standardEmojis.length;
    final int customCount = emojis.length;
    final int totalCount = 1 + standardCount + customCount + _customEmojis.length;
    if (gridIndex >= totalCount) return const SizedBox.shrink();

    if (gridIndex == 0) {
      final themeId = UserState().selectedIslandThemeId.value;
      final bool isLego = themeId == 'lego';
      final double defaultRadius = isLego ? 8.0 : (themeId == 'cotton_candy' ? 24.0 : 16.0);
      return _buildAddEmojiItem(primaryColor, inkColor, defaultRadius);
    }

    final bool isSelected = _selectedGridIndex == gridIndex;
    final bool isStandard = gridIndex >= 1 && gridIndex < 1 + standardCount;
    final bool isPackCustom = gridIndex >= 1 + standardCount && gridIndex < 1 + standardCount + customCount;
    final bool isUserCustom = gridIndex >= 1 + standardCount + customCount;

    String? assetPath;
    String? customFileName;
    String label = "";

    if (isStandard) {
      final emoji = standardEmojis[gridIndex - 1];
      assetPath = emoji['icon'];
      label = emoji['label']!;
    } else if (isPackCustom) {
      final emoji = emojis[gridIndex - 1 - standardCount];
      assetPath = emoji['icon'];
      label = emoji['label']!;
    } else if (isUserCustom) {
      customFileName = _customEmojis[gridIndex - 1 - standardCount - customCount];
      label = "自定义";
    }

    final Color itemBgColor = isSelected
        ? primaryColor.withValues(alpha: 0.12)
        : Colors.transparent;

    Widget emojiWidget;
    if (isUserCustom) {
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
          _controller.text = label;
        });
      },
      onLongPress: isUserCustom ? () => _onLongPressCustomEmoji(gridIndex - 1 - standardCount - customCount) : null,
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

  Widget _buildLivePreview(Color primaryColor, Color inkColor, double radius, String fontFamily) {
    final int standardCount = standardEmojis.length;
    final int customCount = emojis.length;
    final int totalCount = 1 + standardCount + customCount + _customEmojis.length;

    String? assetPath;
    String? customFileName;
    bool isUserCustom = false;

    if (_selectedGridIndex >= 1 && _selectedGridIndex < 1 + standardCount) {
      assetPath = standardEmojis[_selectedGridIndex - 1]['icon'];
    } else if (_selectedGridIndex >= 1 + standardCount && _selectedGridIndex < 1 + standardCount + customCount) {
      assetPath = emojis[_selectedGridIndex - 1 - standardCount]['icon'];
    } else if (_selectedGridIndex >= 1 + standardCount + customCount && _selectedGridIndex < totalCount) {
      customFileName = _customEmojis[_selectedGridIndex - 1 - standardCount - customCount];
      isUserCustom = true;
    } else {
      assetPath = 'assets/icons/happy.png'; // fallback
    }

    Widget previewIcon;
    if (isUserCustom && customFileName != null) {
      final String directPath = '${DiaryUtils.documentsDirPath}/$customFileName';
      final String subDirPath = '${DiaryUtils.documentsDirPath}/custom_emojis/$customFileName';
      final File file = File(subDirPath).existsSync() ? File(subDirPath) : File(directPath);
      previewIcon = Image.file(
        file,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.mood, size: 80, color: primaryColor.withValues(alpha: 0.3)),
      );
      previewIcon = ClipOval(child: previewIcon);
    } else {
      previewIcon = Image.asset(
        assetPath ?? 'assets/icons/happy.png',
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.mood, size: 80, color: primaryColor.withValues(alpha: 0.3)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_selectedGridIndex),
              child: previewIcon,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            maxLength: 10,
            textAlign: TextAlign.center,
            onChanged: (val) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            style: TextStyle(
              color: inkColor,
              fontFamily: fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: "给这个心情起个名字...",
              errorText: _errorText,
              counterText: "",
              errorStyle: TextStyle(
                fontSize: 12,
                fontFamily: fontFamily,
              ),
              hintStyle: TextStyle(
                color: inkColor.withValues(alpha: 0.3),
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMoods(Color primaryColor, Color inkColor, double chipRadius, String fontFamily) {
    if (_recentMoods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "最近使用",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: inkColor.withValues(alpha: 0.8),
            fontFamily: fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentMoods.length,
            itemBuilder: (context, idx) {
              final item = _recentMoods[idx];
              
              Widget iconWidget;
              if (item.type == 'user') {
                final String directPath = '${DiaryUtils.documentsDirPath}/${item.iconPath}';
                final String subDirPath = '${DiaryUtils.documentsDirPath}/custom_emojis/${item.iconPath}';
                final File file = File(subDirPath).existsSync() ? File(subDirPath) : File(directPath);
                iconWidget = Image.file(
                  file, width: 28, height: 28, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(Icons.mood, size: 28, color: primaryColor.withValues(alpha: 0.3)),
                );
                iconWidget = ClipOval(child: iconWidget);
              } else {
                iconWidget = Image.asset(
                  item.iconPath, width: 28, height: 28,
                  errorBuilder: (c, e, s) => Icon(Icons.mood, size: 28, color: primaryColor.withValues(alpha: 0.3)),
                );
              }

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.text = item.tag;
                      _errorText = null;
                      
                      _selectedGridIndex = item.index;
                      final totalCount = 1 + standardEmojis.length + emojis.length + _customEmojis.length;
                      if (_selectedGridIndex < 1 || _selectedGridIndex >= totalCount) {
                        _selectedGridIndex = 1;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isNight
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: inkColor.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconWidget,
                        const SizedBox(width: 8),
                        Text(
                          item.tag,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: inkColor.withValues(alpha: 0.8),
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
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
                            const SizedBox(height: 16),
                            _buildLivePreview(primaryColor, inkColor, defaultRadius, fontFamily),
                            const SizedBox(height: 32),
                            _buildRecentMoods(primaryColor, inkColor, chipRadius, fontFamily),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "表情资源库",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: inkColor.withValues(alpha: 0.8),
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

                                  final int standardCount = standardEmojis.length;
                                  final int customCount = emojis.length;
                                  final bool isStandard = _selectedGridIndex >= 1 && _selectedGridIndex < 1 + standardCount;
                                  final bool isPackCustom = _selectedGridIndex >= 1 + standardCount && _selectedGridIndex < 1 + standardCount + customCount;
                                  final bool isUserCustom = _selectedGridIndex >= 1 + standardCount + customCount;
                                  
                                  String? assetPath;
                                  String type = 'user';
                                  
                                  if (isStandard) {
                                    assetPath = standardEmojis[_selectedGridIndex - 1]['icon']!;
                                    type = 'standard';
                                  } else if (isPackCustom) {
                                    assetPath = emojis[_selectedGridIndex - 1 - standardCount]['icon']!;
                                    type = 'pack';
                                  } else if (isUserCustom) {
                                    assetPath = _customEmojis[_selectedGridIndex - 1 - standardCount - customCount];
                                    type = 'user';
                                  }

                                  if (assetPath != null) {
                                    final item = RecentMoodItem(
                                      tag: tagText,
                                      iconPath: assetPath,
                                      index: _selectedGridIndex,
                                      type: type,
                                    );
                                    await _saveRecentMoodItem(item);
                                  }

                                  if (!context.mounted) return;

                                  if (isStandard) {
                                    final String assetPath = standardEmojis[_selectedGridIndex - 1]['icon']!;
                                    final String fileName = await _ensureStandardAssetInFileSystem(assetPath);
                                    
                                    if (!context.mounted) return;
                                    Navigator.pop(context, {
                                      'index': 200 + (_selectedGridIndex - 1),
                                      'tag': tagText,
                                      'intensity': 6.0,
                                      'customMoodIcon': fileName,
                                    });
                                  } else if (isPackCustom) {
                                    Navigator.pop(context, {
                                      'index': _selectedGridIndex - 1 - standardCount,
                                      'tag': tagText,
                                      'intensity': 6.0,
                                    });
                                  } else if (isUserCustom) {
                                    final customFileName = _customEmojis[_selectedGridIndex - 1 - standardCount - customCount];
                                    Navigator.pop(context, {
                                      'index': 100 + (_selectedGridIndex - 1 - standardCount - customCount),
                                      'tag': tagText,
                                      'intensity': 6.0,
                                      'customMoodIcon': customFileName,
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
