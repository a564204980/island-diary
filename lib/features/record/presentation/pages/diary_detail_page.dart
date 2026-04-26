// Analysis Flush: 强制刷新库摘要以解决 Bad state 错误
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
// import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/hand_drawn_divider.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
// import 'package:lunar/lunar.dart'; // 移除未使用导入
import '../widgets/diary/diary_timeline.dart';
import '../widgets/diary/diary_replies.dart';
import '../widgets/moments_reply_dialog.dart';

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
              color: widget.isNight ? Colors.white10 : const Color(0xFFE8D5B5),
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

  @override
  Widget build(BuildContext context) {
    final bgColor = _effectiveIsNight
        ? const Color(0xFF13131F)
        : const Color(0xFFF7F2E9);
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
                if (_currentEntry.paperStyle.startsWith('note'))
                  Positioned.fill(
                    child: Image.asset(
                      DiaryUtils.getPaperBackgroundPath(_currentEntry.paperStyle, widget.isNight),
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
                      isNight: _effectiveIsNight && !_currentEntry.paperStyle.startsWith('note'),
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
                        const SizedBox(height: 20),
                        _buildRichTextView(),
                        const SizedBox(height: 12),
                        _buildImagesView(),
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
            border: Border.all(color: inkColor.withValues(alpha: 0.1), width: 0.5),
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
    final quote = DiaryUtils.getMoodQuote(mood.label);

    final baseGlowColor = mood.glowColor ?? const Color(0xFFD4A373);
    final accentColor = _effectiveIsNight
        ? baseGlowColor
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
        const SizedBox(height: 12),
        // 第二行：治愈语录
        Text(
          quote,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: DiaryUtils.getInkColor(
              _currentEntry.paperStyle,
              widget.isNight,
            ).withValues(alpha: 0.6),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 12),
        // 第三行：手绘分割线
        CustomPaint(
          size: const Size(double.infinity, 2),
          painter: HandDrawnLinePainter(
            color: _effectiveIsNight
                ? DiaryUtils.getInkColor(
                    _currentEntry.paperStyle,
                    _effectiveIsNight,
                  ).withValues(alpha: 0.1)
                : DiaryUtils.getInkColor(
                    _currentEntry.paperStyle,
                    _effectiveIsNight,
                  ).withValues(alpha: 0.3),
            strokeWidth: 1.5,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
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
                          : (mood.iconPath ?? 'assets/images/icons/sun.png'),
                      width: 14,
                      height: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            // 强度标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DiaryUtils.getMoodIntensityPrefix(
                  mood.label,
                  _currentEntry.intensity,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            // 天气标签
            if (_currentEntry.weather != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_currentEntry.weather} ${_currentEntry.temp ?? ''}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            // 地点标签
            if (_currentEntry.location != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: accentColor,
                    ),
                    const SizedBox(width: 2),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 120,
                      ),
                      child: Text(
                        _currentEntry.location!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentEntry.customDate!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            // 自定义时间标签
            if (_currentEntry.customTime != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 12,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentEntry.customTime!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
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

  Widget _buildRichTextView() {
    final filteredContent = DiaryUtils.getFilteredContent(
      _currentEntry.content,
    );

    final textStyle = TextStyle(
      fontSize: 18,
      height: 1.8,
      color: DiaryUtils.getInkColor(
        _currentEntry.paperStyle,
        widget.isNight,
      ),
      fontFamily: 'LXGWWenKai',
    );

    // 使用 DiaryTextEditingController 的解析逻辑来实现富文本展示
    final controller = DiaryTextEditingController(text: filteredContent);
    controller.baseColor = textStyle.color ?? Colors.black;
    controller.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
    controller.baseFontSize = textStyle.fontSize ?? 18;

    final span = controller.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
      hideMarkdownSymbols: true, // 隐藏 Markdown 符号
    );

    return RichText(
      text: span,
    ).animate().fadeIn(delay: 300.ms, duration: 800.ms);
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
