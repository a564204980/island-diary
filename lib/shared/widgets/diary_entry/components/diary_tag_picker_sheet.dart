import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import './diary_bottom_sheet.dart';

class DiaryTagPickerSheet extends StatefulWidget {
  final String paperStyle;
  final List<String> initialTags;
  final Function(List<String> tags) onConfirm;

  const DiaryTagPickerSheet({
    super.key,
    required this.onConfirm,
    this.paperStyle = 'classic',
    required this.initialTags,
  });

  @override
  State<DiaryTagPickerSheet> createState() => _DiaryTagPickerSheetState();
}

class _DiaryTagPickerSheetState extends State<DiaryTagPickerSheet> {
  late List<String> _selectedTags;
  final TextEditingController _inputCtrl = TextEditingController();
  final List<String> _presetTags = ['日常', '旅行', '碎碎念', '灵感', '美食', '工作', '学习', '运动', '情感', '娱乐'];

  @override
  void initState() {
    super.initState();
    _selectedTags = List<String>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().replaceAll(',', '').replaceAll('，', '');
    if (cleanTag.isEmpty) return;
    if (cleanTag.length > 8) {
      DiaryUtils.showInfoDialog(context, title: '提示', content: '标签长度不能超过8个字哦', isNight: UserState().isNight);
      return;
    }
    if (_selectedTags.contains(cleanTag)) {
      DiaryUtils.showInfoDialog(context, title: '提示', content: '已经添加过该标签了', isNight: UserState().isNight);
      return;
    }
    if (_selectedTags.length >= 5) {
      DiaryUtils.showInfoDialog(context, title: '提示', content: '最多只能添加5个标签哦', isNight: UserState().isNight);
      return;
    }

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    setState(() {
      _selectedTags.add(cleanTag);
      _inputCtrl.clear();
    });
    // 同时保存至用户历史标签，以便未来快捷选用
    UserState().addMoodTag(cleanTag);
    widget.onConfirm(_selectedTags);
  }

  void _toggleTag(String tag) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        if (_selectedTags.length >= 5) {
          DiaryUtils.showInfoDialog(context, title: '提示', content: '最多只能添加5个标签哦', isNight: UserState().isNight);
          return;
        }
        _selectedTags.add(tag);
      }
    });
    widget.onConfirm(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    // 采用与通用弹窗一致的非信纸配色，不跟随信纸材质色
    final Color inkColor;
    final Color accentColor;
    
    if (isNight) {
      inkColor = Colors.white;
      accentColor = themeId == 'cotton_candy' ? const Color(0xFFC0A6FF) : const Color(0xFFE0C097);
    } else {
      inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
      accentColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFFA68565);
    }

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      showDragHandle: true,
      isDiary: false, // 设置为 false，使其背景色使用通用主题色，不跟随信纸
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '添加标签',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                  color: inkColor.withValues(alpha: 0.9),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: inkColor.withValues(alpha: 0.5)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 自定义标签输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLength: 8,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: inkColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入自定义标签...',
                    counterText: '',
                    hintStyle: TextStyle(
                      fontFamily: fontFamily,
                      color: inkColor.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                  ),
                  onSubmitted: (val) => _addTag(val),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _addTag(_inputCtrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    '添加',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 已选定标签显示区
          if (_selectedTags.isNotEmpty) ...[
            Text(
              '已添加 (${_selectedTags.length}/5)',
              style: TextStyle(
                fontSize: 12,
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                color: inkColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '# $tag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _toggleTag(tag),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: accentColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // 推荐标签
          Text(
            '推荐标签',
            style: TextStyle(
              fontSize: 12,
              fontFamily: fontFamily,
              fontWeight: FontWeight.bold,
              color: inkColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetTags.map((tag) {
              final bool isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => _toggleTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.15) : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accentColor.withValues(alpha: 0.4) : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '# $tag',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: fontFamily,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? accentColor : inkColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
