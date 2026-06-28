import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_date_picker_sheet.dart';

class DiarySearchPanel extends StatefulWidget {
  final Function(String query, int? moodIndex, DateTime? date) onSearch;
  final VoidCallback onClear;
  final bool isNight;
  final DateTime? initialDate;

  const DiarySearchPanel({
    super.key,
    required this.onSearch,
    required this.onClear,
    this.isNight = false,
    this.initialDate,
  });

  @override
  State<DiarySearchPanel> createState() => _DiarySearchPanelState();
}

class _DiarySearchPanelState extends State<DiarySearchPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int? _selectedMoodIndex;
  DateTime? _selectedDate;
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 延迟 350ms 等弹窗滑出动画完全结束后再唤起键盘，防止两组动画抢占渲染资源导致卡顿
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  // 与 diary_editor_page 相同的模式：在 didChangeDependencies 里缓存键盘高度，
  // build() 不直接订阅 viewInsets，键盘动画期间背景页面完全不重建
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset > 100 && inset > _keyboardHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && inset > _keyboardHeight) {
          setState(() => _keyboardHeight = inset);
        }
      });
    } else if (inset < 10 && _keyboardHeight > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _keyboardHeight = 0);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    widget.onSearch(_controller.text, _selectedMoodIndex, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final isCottonCandy = themeId == 'cotton_candy';
    final isCottonCandyDark = isCottonCandy && widget.isNight;

    final textColor = widget.isNight ? Colors.white70 : Colors.black87;
    final hintColor = widget.isNight ? Colors.white38 : Colors.black38;
    final Color highlightColor = isCottonCandyDark
        ? const Color(0xFFC0A6FF)
        : const Color(0xFFE1AF78);

    final screenHeight = MediaQuery.sizeOf(context).height;
    return Container(
      height: screenHeight * 0.8,
      child: DiaryBottomSheet(
        paperStyle: 'default',
        showDragHandle: true,
        isDiary: false,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isNight
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isNight
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _handleSearch(),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textColor, fontFamily: 'LXGWWenKai', fontSize: 14.5),
              decoration: InputDecoration(
                hintText: "寻找某段回忆...",
                hintStyle: TextStyle(
                  color: hintColor,
                  fontFamily: 'LXGWWenKai',
                  fontSize: 14.5,
                ),
                border: InputBorder.none,
                icon: Icon(CupertinoIcons.search, color: highlightColor, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: hintColor,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                          _handleSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 日期筛选
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "按日期筛选",
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.6),
                  fontFamily: 'LXGWWenKai',
                  fontWeight: FontWeight.bold,
                ),
              ),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                        });
                        _handleSearch();
                      },
                      child: Text(
                        "清除日期",
                        style: TextStyle(
                          fontSize: 12,
                          color: highlightColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DiaryDatePickerSheet(
                      initialDate: _selectedDate ?? DateTime.now(),
                      onConfirm: (picked) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        Navigator.pop(context);
                        _handleSearch();
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isNight
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDate != null
                          ? highlightColor.withValues(alpha: 0.5)
                          : (widget.isNight
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _selectedDate != null
                            ? highlightColor
                            : hintColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? "选择日期..."
                            : "${_selectedDate!.year}年${_selectedDate!.month}月${_selectedDate!.day}日",
                        style: TextStyle(
                          color: _selectedDate != null ? textColor : hintColor,
                          fontSize: 14,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
 
              const SizedBox(height: 24),
 
              // 心情筛选标题
              Text(
                "按心情筛选",
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.6),
                  fontFamily: 'LXGWWenKai',
                  fontWeight: FontWeight.bold,
                ),
              ),
 
              const SizedBox(height: 12),
 
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 强制每行显示 7 个
                  crossAxisSpacing: 6, // 稍微缩小横向间距，保证文字排版空间
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.73, // 宽高比：高度大于宽度，给下方文字预留空间
                ),
                itemCount: kMoods.length,
                itemBuilder: (context, index) {
                  final mood = kMoods[index];
                  final isSelected = _selectedMoodIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMoodIndex = isSelected ? null : index;
                      });
                      _handleSearch();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 图标容器
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(5),
                          transform: isSelected
                              ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (mood.glowColor ?? Colors.amber).withValues(alpha: 0.25)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (mood.glowColor ?? Colors.amber).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Image.asset(
                            mood.iconPath ?? 'assets/icons/happy.png',
                            width: 30,
                            height: 30,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 中文文本标签
                        Text(
                          mood.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? (mood.glowColor ?? highlightColor) 
                                : textColor.withValues(alpha: 0.7),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
  }
}
