import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

class CustomMoodPickerPopup extends StatefulWidget {
  final String paperStyle;
  final bool isNight;
  final Function(Map<String, dynamic>) onSave;

  const CustomMoodPickerPopup({
    super.key,
    required this.paperStyle,
    required this.isNight,
    required this.onSave,
  });

  @override
  State<CustomMoodPickerPopup> createState() => _CustomMoodPickerPopupState();
}

class _CustomMoodPickerPopupState extends State<CustomMoodPickerPopup> {
  final TextEditingController _controller = TextEditingController();
  int _selectedEmojiIndex = 0;
  String? _selectedInspirationTag;
  String? _errorText;

  static const List<String> inspirationTags = [
    "想念",
    "委屈",
    "焦虑",
    "空空的",
    "释然",
    "被治愈",
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildEmojiItem(int index) {
    if (index >= emojis.length) return const SizedBox.shrink();
    final bool isSelected = _selectedEmojiIndex == index;
    final emoji = emojis[index];
    final Color primaryColor = widget.isNight
        ? const Color(0xFFC0A6FF)
        : const Color(0xFFFFA726);

    return GestureDetector(
      onTap: () => setState(() => _selectedEmojiIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withAlpha(0),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withAlpha(102)
                  : primaryColor.withAlpha(0),
              blurRadius: isSelected ? 15.0 : 0.0,
              spreadRadius: isSelected ? 2.0 : 0.0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: Center(
            child: Image.asset(
              emoji['icon']!,
              width: 44,
              height: 44,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.mood, color: primaryColor.withAlpha(77)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(
      widget.paperStyle,
      widget.isNight,
    );
    final Color primaryColor = widget.isNight
        ? const Color(0xFFC0A6FF)
        : const Color(0xFFFFA726); // Dreamy purple in night mode, energetic orange in day mode
    final bool isDark = widget.isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    final Color bgColor = isDark
        ? (themeId == 'cotton_candy'
            ? const Color(0xFF241E3D).withValues(alpha: 0.95)
            : const Color(0xFF1E1E1E))
        : const Color(0xFFFFF9F2);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: DiaryUtils.getPopupDecoration(
          widget.paperStyle,
          widget.isNight,
          customBgColor: bgColor,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部指示条
              const SizedBox(height: 4),
              DiaryUtils.buildPopupDragHandle(
                widget.paperStyle,
                widget.isNight,
                inkColor,
              ),
              const SizedBox(height: 16),
              // 标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "创建此刻心情",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: inkColor.withAlpha(230),
                          fontFamily: fontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "给这一刻起个名字",
                        style: TextStyle(
                          fontSize: 14,
                          color: inkColor.withAlpha(102),
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: inkColor.withAlpha(77),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 心情标签输入
              Text(
                "心情标签",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: inkColor.withAlpha(153),
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(13) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: inkColor.withAlpha(20)),
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
                    counterText: "", // 隐藏右下角的计数器，保持简约
                    errorStyle: TextStyle(
                      fontSize: 12,
                      fontFamily: fontFamily,
                    ),
                    hintStyle: TextStyle(
                      color: inkColor.withAlpha(51),
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
              const SizedBox(height: 24),
              // 灵感标签
              Text(
                "灵感标签",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: inkColor.withAlpha(153),
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: inspirationTags.map((tag) {
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withAlpha(25)
                            : (isDark
                                  ? Colors.white.withAlpha(13)
                                  : const Color(0xFFF7F2EB)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryColor : primaryColor.withAlpha(0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? primaryColor
                              : inkColor.withAlpha(153),
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // 选择一个表情
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "选择一个表情",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: inkColor.withAlpha(153),
                      fontFamily: fontFamily,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "滑动查看更多",
                    style: TextStyle(
                      fontSize: 12,
                      color: inkColor.withAlpha(102),
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: inkColor.withAlpha(102),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 136,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) => _buildEmojiItem(index),
                  clipBehavior: Clip.none,
                ),
              ),
              const SizedBox(height: 32),
              // 底部按钮
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(13)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: inkColor.withAlpha(25)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "取消",
                          style: TextStyle(
                            fontSize: 16,
                            color: inkColor.withAlpha(102),
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final String tagText = _controller.text.trim();
                        if (tagText.isEmpty) {
                          setState(() => _errorText = "请给这一刻起个名字吧");
                          return;
                        }

                        widget.onSave({
                          'index': _selectedEmojiIndex,
                          'tag': tagText,
                          'intensity': 6.0,
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withAlpha(204)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(77),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "保存这份心情",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
