// Analysis Flush: 强制刷新库摘要以解决 Bad state 错误
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
// import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import '../widgets/diary/diary_timeline.dart';
import '../widgets/diary/diary_replies.dart';
import '../widgets/moments_reply_dialog.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class DiaryDetailPage extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNight;

  const DiaryDetailPage({super.key, required this.entry, this.isNight = false});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late DiaryEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  void _handleDelete() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isNight
                ? const Color(0xFF2D2A26)
                : const Color(0xFFFDF7E9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isNight
                  ? const Color(0xFFD4A373).withValues(alpha: 0.2)
                  : const Color(0xFFE8D5B5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🏝️", style: TextStyle(fontSize: 32)),
              const SizedBox(height: 16),
              Text(
                "确定要抹去这段回忆吗？",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isNight
                      ? Colors.white70
                      : const Color(0xFF5D4037),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "保留下",
                      style: TextStyle(
                        color: widget.isNight ? Colors.white30 : Colors.black26,
                        fontFamily: 'LXGWWenKai',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      UserState().deleteDiary(_currentEntry.id);
                      Navigator.pop(context); // 关闭弹窗
                      Navigator.pop(context); // 返回列表
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A373),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "确定抹去",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _handleEdit() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          moodIndex: _currentEntry.moodIndex,
          intensity: _currentEntry.intensity,
          tag: _currentEntry.tag,
          entry: _currentEntry,
        ),
      ),
    ).then((success) {
      if (success == true) {
        try {
          final updated = UserState().savedDiaries.value.firstWhere(
            (e) => e.id == _currentEntry.id,
          );
          setState(() {
            _currentEntry = updated;
          });
        } catch (e) {
          // 如果没找到，保持原样
        }
      }
    });
  }

  bool get _effectiveIsNight => widget.isNight;

  IconData _getWeatherIcon(String? weather) {
    if (weather == null) return Icons.wb_sunny_outlined;
    if (weather.contains("晴")) return Icons.wb_sunny_outlined;
    if (weather.contains("多云")) return Icons.wb_cloudy_outlined;
    if (weather.contains("阴")) return Icons.cloud_outlined;
    if (weather.contains("雨")) return Icons.umbrella_outlined;
    if (weather.contains("雪")) return Icons.ac_unit_outlined;
    if (weather.contains("风")) return Icons.air_outlined;
    if (weather.contains("雾")) return Icons.grain_outlined;
    if (weather.contains("雷")) return Icons.thunderstorm_outlined;
    if (weather.contains("冰雹")) return Icons.severe_cold_outlined;
    if (weather.contains("炎热") || weather.contains("热"))
      return Icons.thermostat_outlined;
    if (weather.contains("严寒") || weather.contains("冷"))
      return Icons.ac_unit_outlined;
    return Icons.wb_sunny_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _effectiveIsNight
        ? const Color(0xFF13131F)
        : (UserState().selectedIslandThemeId.value == 'cotton_candy' &&
                  _currentEntry.paperStyle == 'classic'
              ? const Color(0xFFFBF3E9)
              : const Color(0xFFF7F2E9));
    final mood = kMoods[_currentEntry.moodIndex.clamp(0, kMoods.length - 1)];
    final baseGlowColor = mood.glowColor ?? const Color(0xFFD4A373);
    final accentColor = _effectiveIsNight
        ? baseGlowColor
        : Color.lerp(baseGlowColor, Colors.black, 0.45)!;
    final inkColor = DiaryUtils.getInkColor(
      _currentEntry.paperStyle,
      widget.isNight,
    );

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 信纸底色与纹理层
          Positioned.fill(
            child: Stack(
              children: [
                if (_currentEntry.paperStyle.startsWith('note') ||
                    (_currentEntry.paperStyle == 'classic' &&
                        UserState().selectedIslandThemeId.value ==
                            'cotton_candy'))
                  Positioned.fill(
                    child: Image.asset(
                      _currentEntry.paperStyle == 'classic'
                          ? (widget.isNight
                                ? 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_night_bg.png'
                                : 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_bg.png')
                          : DiaryUtils.getPaperBackgroundPath(
                              _currentEntry.paperStyle,
                              widget.isNight,
                            ),
                      fit: BoxFit.cover,
                      // note 系列现在自带夜间背景图，不再需要额外的颜色叠加遮罩
                      color: null,
                      colorBlendMode: null,
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: PaperBackgroundPainter(
                      style: _currentEntry.paperStyle,
                      isNight:
                          _effectiveIsNight &&
                          !_currentEntry.paperStyle.startsWith('note') &&
                          !(_currentEntry.paperStyle == 'classic' &&
                              UserState().selectedIslandThemeId.value ==
                                  'cotton_candy'),
                      accentColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      120,
                    ), // 调整顶部边距配合 SafeArea
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 8),
                        ..._buildBlocksView(),
                        const SizedBox(height: 48),
                        DiaryTimeline(
                          replies: _currentEntry.replies,
                          isNight: _effectiveIsNight,
                          inkColor: inkColor,
                          accentColor: accentColor,
                        ),
                        DiaryReplies(
                          replies: _currentEntry.replies,
                          isNight: _effectiveIsNight,
                          inkColor: inkColor,
                          accentColor: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildFloatingActions(_effectiveIsNight),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(bool isNight) {
    // 获取基于信纸的动态墨水色和背景色
    final Color inkColor = DiaryUtils.getInkColor(
      _currentEntry.paperStyle,
      isNight,
    );
    final Color paperBaseColor = DiaryUtils.getPaperBaseColor(
      _currentEntry.paperStyle,
      isNight,
    );

    // 图标主色使用墨水色，非活跃状态略带透明
    final iconColor = inkColor.withValues(alpha: 0.9);
    // 悬浮条背景跟随信纸基色，但在 note 系列背景下保持较高的不透明度以防背景干扰
    final barBgColor = _currentEntry.paperStyle.startsWith('note')
        ? (isNight ? const Color(0xFF2C2E30) : Colors.white)
        : paperBaseColor.withValues(alpha: 0.98);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Center(
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: barBgColor,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: isNight
                  ? const Color(0xFFD4A373).withValues(alpha: 0.15)
                  : inkColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.arrow_back_ios_new_rounded,
                color: iconColor,
                onTap: () => Navigator.pop(context),
                label: "返回",
                width: 40,
              ),
              const SizedBox(width: 30),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: iconColor,
                onTap: _showReplySheet,
                label: "回应",
                iconSize: 24,
                width: 40,
              ),
              const SizedBox(width: 30),
              _buildActionButton(
                icon: Icons.edit_note_rounded,
                color: iconColor,
                onTap: _handleEdit,
                label: "编辑",
                iconSize: 28,
                width: 40,
              ),
              const SizedBox(width: 30),
              _buildActionButton(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent.withValues(alpha: 0.75),
                onTap: _handleDelete,
                label: "删除",
                width: 40,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  void _showReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MomentsReplySheet(
        isNight: _effectiveIsNight,
        onConfirm: _handleReplySubmit,
      ),
    );
  }

  void _handleReplySubmit(String content) async {
    if (content.trim().isEmpty) return;

    await UserState().addReplyToDiary(_currentEntry.id, content);

    if (mounted) {
      // 刷新当前页面状态
      final updated = UserState().savedDiaries.value.firstWhere(
        (e) => e.id == _currentEntry.id,
      );
      setState(() {
        _currentEntry = updated;
      });
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    double iconSize = 24,
    double width = 72,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 54,
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildHeader() {
    final dt = _currentEntry.dateTime;
    final mood = kMoods[_currentEntry.moodIndex.clamp(0, kMoods.length - 1)];
    final dateStr = "${dt.year}年${dt.month}月${dt.day}日";
    final timeStr =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark =
        (themeId == 'cotton_candy') && _effectiveIsNight;
    final baseGlowColor = mood.glowColor ?? const Color(0xFFD4A373);
    final accentColor = _effectiveIsNight
        ? (isCottonCandyDark ? const Color(0xFFC0A6FF) : baseGlowColor)
        : Color.lerp(baseGlowColor, Colors.black, 0.45)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一行：大时间 + 日期
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: DiaryUtils.getInkColor(
                  _currentEntry.paperStyle,
                  widget.isNight,
                ),
                fontFamily: 'LXGWWenKai',
                letterSpacing: -1,
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: DiaryUtils.getInkColor(
                  _currentEntry.paperStyle,
                  widget.isNight,
                ).withValues(alpha: 0.7),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 浮动信息：心情标签 + 地点 + 天气
        // 标签行
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 心情标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: !_effectiveIsNight
                    ? const Color(0xAAFFFDF9)
                    : accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(
                  !_effectiveIsNight ? 15 : 10,
                ),
                border: Border.all(
                  color: !_effectiveIsNight
                      ? const Color(0xFFE5DEC9)
                      : accentColor.withValues(alpha: 0.45),
                  width: !_effectiveIsNight ? 0.6 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'mood_${_currentEntry.id}',
                    child: Image.asset(
                      (_currentEntry.tag != null &&
                              _currentEntry.tag!.isNotEmpty)
                          ? 'assets/images/icons/custom.png'
                          : (mood.iconPath ?? 'assets/icons/happy.png'),
                      width: 16,
                      height: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !_effectiveIsNight
                          ? const Color(0xFF7A7060)
                          : accentColor,
                    ),
                  ),
                ],
              ),
            ),
            // 天气标签
            if (_currentEntry.weather != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xAAFFFDF9)
                      : accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    !_effectiveIsNight ? 15 : 10,
                  ),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFE5DEC9)
                        : accentColor.withValues(alpha: 0.45),
                    width: !_effectiveIsNight ? 0.6 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWeatherIcon(_currentEntry.weather),
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF7A7060)
                          : accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${_currentEntry.weather} ${_currentEntry.temp ?? ''}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !_effectiveIsNight
                            ? const Color(0xFF7A7060)
                            : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            // 地点标签
            if (_currentEntry.location != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xAAFFFDF9)
                      : accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    !_effectiveIsNight ? 15 : 10,
                  ),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFE5DEC9)
                        : accentColor.withValues(alpha: 0.45),
                    width: !_effectiveIsNight ? 0.6 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF7A7060)
                          : accentColor,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 120,
                      ),
                      child: Text(
                        _currentEntry.location!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !_effectiveIsNight
                              ? const Color(0xFF7A7060)
                              : accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 自定义日期标签
            if (_currentEntry.customDate != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xAAFFFDF9)
                      : accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    !_effectiveIsNight ? 15 : 10,
                  ),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFE5DEC9)
                        : accentColor.withValues(alpha: 0.45),
                    width: !_effectiveIsNight ? 0.6 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF7A7060)
                          : accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currentEntry.customDate!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !_effectiveIsNight
                            ? const Color(0xFF7A7060)
                            : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            // 自定义时间标签
            if (_currentEntry.customTime != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xAAFFFDF9)
                      : accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    !_effectiveIsNight ? 15 : 10,
                  ),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFE5DEC9)
                        : accentColor.withValues(alpha: 0.45),
                    width: !_effectiveIsNight ? 0.6 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF7A7060)
                          : accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currentEntry.customTime!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !_effectiveIsNight
                            ? const Color(0xFF7A7060)
                            : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 10, end: 0);
  }

  List<Widget> _buildBlocksView() {
    if (_currentEntry.blocks.isEmpty) {
      return [
        _buildRichTextView(),
        const SizedBox(height: 12),
        _buildImagesView(),
      ];
    }

    final List<Widget> list = [];
    final textStyle = TextStyle(
      fontSize: 18,
      height: 1.8,
      color: DiaryUtils.getInkColor(_currentEntry.paperStyle, widget.isNight),
      fontFamily: 'LXGWWenKai',
    );

    if (_currentEntry.isImageGrid) {
      return [
        _buildRichTextView(),
        const SizedBox(height: 12),
        _buildImagesView(),
      ];
    }

    bool isFirst = true;
    int textBlockIndex = 0;
    for (var b in _currentEntry.blocks) {
      final type = b['type'];
      if (type == 'text') {
        final currentBlockIndex = textBlockIndex;
        textBlockIndex++;
        final block = DiaryBlock.fromMap(Map<String, dynamic>.from(b as Map));
        if (block is TextBlock) {
          final tc = block.controller;
          if (tc is DiaryTextEditingController) {
            tc.baseColor = textStyle.color ?? Colors.black;
            tc.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
            tc.baseFontSize = textStyle.fontSize ?? 18;

            final span = tc.buildTextSpan(
              context: context,
              style: textStyle,
              withComposing: false,
              hideMarkdownSymbols: true,
              annotations: _currentEntry.annotations,
              blockIndex: currentBlockIndex,
              onAnnotationTap: (key) => _showAnnotationSheet(key: key),
            );

            list.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildSelectableRichText(span, currentBlockIndex, textStyle),
              ),
            );
            isFirst = false;
          }
          block.dispose();
        }
      } else if (type == 'image') {
        final path = b['path'];
        if (path != null && path.toString().isNotEmpty) {
          final bool isWide = MediaQuery.of(context).size.width > 800;

          list.add(
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWide
                      ? 520
                      : MediaQuery.of(context).size.width * 0.85,
                ),
                margin: EdgeInsets.only(top: isFirst ? 8 : 12, bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DiaryUtils.buildImage(path, fit: BoxFit.contain),
                ),
              ),
            ),
          );
          isFirst = false;
        }
      }
    }

    return list;
  }

  Widget _buildRichTextView() {
    final filteredContent = DiaryUtils.getFilteredContent(
      _currentEntry.content,
    );

    final textStyle = TextStyle(
      fontSize: 18,
      height: 1.8,
      color: DiaryUtils.getInkColor(_currentEntry.paperStyle, widget.isNight),
      fontFamily: 'LXGWWenKai',
    );

    final controller = DiaryTextEditingController(text: filteredContent);
    controller.baseColor = textStyle.color ?? Colors.black;
    controller.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
    controller.baseFontSize = textStyle.fontSize ?? 18;

    final span = controller.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
      hideMarkdownSymbols: true,
      annotations: _currentEntry.annotations,
      blockIndex: 0,
      onAnnotationTap: (key) => _showAnnotationSheet(key: key),
    );

    return _buildSelectableRichText(span, 0, textStyle)
        .animate()
        .fadeIn(delay: 300.ms, duration: 800.ms);
  }

  Widget _buildSelectableRichText(TextSpan span, int blockIndex, TextStyle textStyle) {
    return SelectableText.rich(
      span,
      style: textStyle,
      contextMenuBuilder: (context, editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        if (selection.isCollapsed) return const SizedBox.shrink();

        final text = editableTextState.textEditingValue.text;
        final selectedText = selection.start >= 0 && selection.end <= text.length
            ? text.substring(selection.start, selection.end)
            : '';

        // 如果选择的文本仅包含 Object Replacement Character (\uFFFC，代表 WidgetSpan，如小气泡或图片)
        // 则直接隐藏选区工具栏，不弹出 tooltip
        if (selectedText.isEmpty || selectedText.trim().runes.every((r) => r == 0xFFFC)) {
          return const SizedBox.shrink();
        }

        // 检查选区是否与已有批注有重叠
        Map<String, dynamic>? overlappingAnn;
        for (var entry in _currentEntry.annotations.entries) {
          final parts = entry.key.split('_');
          if (parts.length == 3 && int.tryParse(parts[0]) == blockIndex) {
            final annStart = int.tryParse(parts[1]);
            final annEnd = int.tryParse(parts[2]);
            if (annStart != null && annEnd != null) {
              if (selection.start < annEnd && selection.end > annStart) {
                overlappingAnn = {
                  'key': entry.key,
                  'start': annStart,
                  'end': annEnd,
                };
                break;
              }
            }
          }
        }

        // 如果存在重叠的批注，且当前选区未完全覆盖它，则自动扩展选区至整个批注范围
        if (overlappingAnn != null) {
          final int annStart = overlappingAnn['start'];
          final int annEnd = overlappingAnn['end'];
          if (selection.start != annStart || selection.end != annEnd) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              editableTextState.updateEditingValue(
                editableTextState.textEditingValue.copyWith(
                  selection: TextSelection(baseOffset: annStart, extentOffset: annEnd),
                ),
              );
            });
            return const SizedBox.shrink();
          }
        }

        return CustomSingleChildLayout(
          delegate: TextSelectionToolbarLayoutDelegate(
            anchorAbove: editableTextState.contextMenuAnchors.primaryAnchor,
            anchorBelow: editableTextState.contextMenuAnchors.secondaryAnchor ?? editableTextState.contextMenuAnchors.primaryAnchor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToolbarButton("复制", () {
                      editableTextState.copySelection(SelectionChangedCause.toolbar);
                      editableTextState.hideToolbar();
                    }, false),
                    const SizedBox(width: 4),
                    _buildToolbarButton("批注", () {
                      editableTextState.hideToolbar();
                      final selectedText = editableTextState.textEditingValue.text.substring(
                        selection.start,
                        selection.end,
                      );
                      _showAnnotationSheet(
                        blockIndex: blockIndex,
                        start: selection.start,
                        end: selection.end,
                        selectedText: selectedText,
                      );
                    }, false),
                    if (overlappingAnn != null) ...[
                      const SizedBox(width: 4),
                      _buildToolbarButton("删除", () {
                        final newAnnotations = Map<String, String>.from(_currentEntry.annotations);
                        newAnnotations.remove(overlappingAnn!['key']);
                        final updated = _currentEntry.copyWith(annotations: newAnnotations);
                        UserState().updateDiary(updated);
                        setState(() {
                          _currentEntry = updated;
                        });
                        editableTextState.hideToolbar();
                      }, false),
                    ],
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(12, 6),
                painter: _ToolbarArrowPainter(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbarButton(String label, VoidCallback onTap, bool isHighlighted) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFFDF0CD) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  static const List<Map<String, String>> _annotationColors = [
    {'name': '经典黄', 'value': '#F7E5B4'},
    {'name': '柔和粉', 'value': '#F7DAD3'},
    {'name': '天空灰', 'value': '#DFE5E6'},
  ];

  void _showAnnotationSheet({
    String? key,
    int? blockIndex,
    int? start,
    int? end,
    String? selectedText,
  }) {
    final bool isEdit = key != null;
    final String actualKey = key ?? "${blockIndex}_${start}_${end}";
    
    Map<String, dynamic>? annData;
    if (isEdit) {
      final jsonStr = _currentEntry.annotations[actualKey] ?? '';
      try {
        annData = jsonDecode(jsonStr);
      } catch (_) {}
    }
    
    final String initialText = annData?['comment'] ?? (isEdit ? _currentEntry.annotations[actualKey] ?? '' : '');
    final String initialColor = annData?['colorHex'] ?? '#F7E5B4';
    final String actualSelectedText = annData?['selectedText'] ?? selectedText ?? '';
    
    final textController = TextEditingController(text: initialText);
    String selectedColorHex = initialColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final isNight = widget.isNight;
        final inkColor = DiaryUtils.getInkColor(_currentEntry.paperStyle, isNight);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DiaryBottomSheet(
              paperStyle: _currentEntry.paperStyle,
              showDragHandle: true,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: inkColor.withValues(alpha: 0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? "修改批注" : "添加批注",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: inkColor,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                    if (actualSelectedText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9F6EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                              width: 4.5,
                            ),
                          ),
                        ),
                        child: Text(
                          "“$actualSelectedText”",
                          style: TextStyle(
                            fontSize: 14,
                            color: inkColor.withValues(alpha: 0.65),
                            fontStyle: FontStyle.italic,
                            fontFamily: 'LXGWWenKai',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: isNight ? 0.05 : 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: textController,
                        autofocus: true,
                        maxLines: 3,
                        maxLength: 200,
                        style: TextStyle(
                          color: inkColor,
                          fontSize: 16,
                          fontFamily: 'LXGWWenKai',
                        ),
                        decoration: InputDecoration(
                          hintText: "写下关于这一段的感悟或注解...",
                          hintStyle: TextStyle(
                            color: inkColor.withValues(alpha: 0.4),
                            fontSize: 15,
                            fontFamily: 'LXGWWenKai',
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color: inkColor.withValues(alpha: 0.5),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "选择高亮背景颜色",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: inkColor.withValues(alpha: 0.7),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _annotationColors.map((colorMap) {
                        final hex = colorMap['value']!;
                        final isSelected = selectedColorHex == hex;
                        final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedColorHex = hex;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (isNight ? Colors.white : const Color(0xFF333333))
                                      : (isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.08)),
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: isSelected ? 0.4 : 0.1),
                                    blurRadius: isSelected ? 8 : 4,
                                    spreadRadius: isSelected ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Color(0xFF333333),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "取消",
                            style: TextStyle(
                              color: inkColor.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontFamily: 'LXGWWenKai',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final text = textController.text.trim();
                            if (text.isNotEmpty) {
                              final newAnnotations = Map<String, String>.from(_currentEntry.annotations);
                              if (!isEdit && blockIndex != null && start != null && end != null) {
                                // 移除所有与当前选区有重叠的旧批注，防止重复/并存多个气泡
                                newAnnotations.removeWhere((k, v) {
                                  final parts = k.split('_');
                                  if (parts.length == 3 && int.tryParse(parts[0]) == blockIndex) {
                                    final annStart = int.tryParse(parts[1]);
                                    final annEnd = int.tryParse(parts[2]);
                                    if (annStart != null && annEnd != null) {
                                      return start < annEnd && end > annStart;
                                    }
                                  }
                                  return false;
                                });
                              }
                              final data = {
                                'selectedText': actualSelectedText,
                                'comment': text,
                                'colorHex': selectedColorHex,
                              };
                              newAnnotations[actualKey] = jsonEncode(data);
                              final updated = _currentEntry.copyWith(annotations: newAnnotations);
                              UserState().updateDiary(updated);
                              setState(() {
                                _currentEntry = updated;
                              });
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                            foregroundColor: const Color(0xFF333333),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "确认",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LXGWWenKai',
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagesView() {
    final images = _currentEntry.blocks
        .where((b) => b['type'] == 'image')
        .toList();
    if (images.isEmpty) return const SizedBox.shrink();

    if (_currentEntry.isImageGrid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 8;
          final double itemSize = (constraints.maxWidth - spacing * 2) / 3;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: images.map((image) {
              final path = image['path'];
              return Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
                ),
              );
            }).toList(),
          );
        },
      ).animate().fadeIn(delay: 500.ms, duration: 800.ms);
    }

    return Column(
      children: images.map((image) {
        final path = image['path'];
        final bool isWide = MediaQuery.of(context).size.width > 800;

        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWide ? 520 : MediaQuery.of(context).size.width * 0.85,
            ),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DiaryUtils.buildImage(path, fit: BoxFit.contain),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 500.ms, duration: 800.ms);
  }
}

class _ToolbarArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
