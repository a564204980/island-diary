// Analysis Flush: 强制刷新库摘要以解决 Bad state 错误
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
// import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_text_context_menu.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/image_group_block.dart';
import '../widgets/diary/diary_timeline.dart';
import '../widgets/diary/diary_replies.dart';
import '../widgets/diary_reply_sheet.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_image_collage.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';


class DiaryDetailPage extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNight;
  final bool showFloatingActions;
  final VoidCallback? onBack;

  const DiaryDetailPage({
    super.key,
    required this.entry,
    this.isNight = false,
    this.showFloatingActions = true,
    this.onBack,
  });

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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isNight
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isNight
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "确定要抹去这段回忆吗？",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.isNight
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF2C2C2C),
                        fontFamily: 'LXGWWenKai',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 0.5,
                color: widget.isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "保留",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'LXGWWenKai',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: widget.isNight ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 50,
                    color: widget.isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        UserState().deleteDiary(_currentEntry.id);
                        showTopToast(
                          context,
                          '回忆已成功抹去 🍃',
                          icon: Icons.delete_outline_rounded,
                          iconColor: const Color(0xFFEF4444),
                        );
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "抹去",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'LXGWWenKai',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD35D5D), // 高级砖红
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutQuart).fadeIn(duration: 200.ms),
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
    if (weather.contains("炎热") || weather.contains("热")) {
      return Icons.thermostat_outlined;
    }
    if (weather.contains("严寒") || weather.contains("冷")) {
      return Icons.ac_unit_outlined;
    }
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
              top: widget.showFloatingActions,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      if (!widget.showFloatingActions)
                        SizedBox(
                          height: MediaQuery.of(context).padding.top + kToolbarHeight,
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            16,
                            24,
                            80,
                          ), // 调整边距配合 SafeArea
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 8),
                              ..._buildBlocksView(),
                              if (_currentEntry.replies.isNotEmpty)
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.showFloatingActions)
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
    // 为了高级质感，我们采用更低的不透明度并结合毛玻璃效果
    final barBgColor = _currentEntry.paperStyle.startsWith('note')
        ? (isNight ? const Color(0x992C2E30) : const Color(0xB3FFFFFF))
        : paperBaseColor.withValues(alpha: 0.85);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: barBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isNight
                      ? const Color(0xFFD4A373).withValues(alpha: 0.15)
                      : inkColor.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: iconColor,
                    onTap: widget.onBack ?? () => Navigator.pop(context),
                    label: "返回",
                    width: 36,
                    iconSize: 22,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: iconColor,
                    onTap: _showReplySheet,
                    label: "回应",
                    iconSize: 22,
                    width: 36,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.edit_note_rounded,
                    color: iconColor,
                    onTap: _handleEdit,
                    label: "编辑",
                    iconSize: 26,
                    width: 36,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    // 删除图标也使用统一的墨水色（或非常柔和的莫兰迪红），体现克制的高级感
                    color: isNight ? const Color(0xFFC47B7B) : inkColor.withValues(alpha: 0.8),
                    onTap: _handleDelete,
                    label: "删除",
                    iconSize: 22,
                    width: 36,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }

  void _showReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaryReplySheet(
        isNight: _effectiveIsNight,
        paperStyle: _currentEntry.paperStyle,
        onConfirm: _handleReplySubmit,
      ),
    );
  }

  void _handleReplySubmit(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一行：大日期排版
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              dt.day.toString(),
              style: TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.w500,
                color: DiaryUtils.getInkColor(
                  _currentEntry.paperStyle,
                  widget.isNight,
                ),
                fontFamily: 'Georgia', // 具有优雅衬线感的字体
                height: 1.0,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${dt.year}年${dt.month}月",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DiaryUtils.getInkColor(
                      _currentEntry.paperStyle,
                      widget.isNight,
                    ).withValues(alpha: 0.6),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][dt.weekday - 1]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: DiaryUtils.getInkColor(
                      _currentEntry.paperStyle,
                      widget.isNight,
                    ).withValues(alpha: 0.8),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 浮动信息：心情标签 + 地点 + 天气
        // 标签行
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 归属书籍标签
            if (_currentEntry.bookId != null &&
                _currentEntry.bookId != 'default' &&
                _currentEntry.bookId!.isNotEmpty)
              (() {
                final books = UserState().savedBooks.value;
                final book = books.firstWhere(
                  (b) => b.id == _currentEntry.bookId,
                  orElse: () => DiaryBook(name: ''),
                );
                if (book.name.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A373).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD4A373).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.book_rounded,
                        size: 13,
                        color: Color(0xFFD4A373),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '收纳至：${book.name}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !_effectiveIsNight
                              ? const Color(0xFF8E5A30)
                              : const Color(0xFFFFCC99),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                );
              })(),
            // 心情标签
            (() {
              final parsed = ParsedTags.parse(_currentEntry.tag, _currentEntry.moodIndex);
              final String moodLabel = parsed.customMood ?? mood.label;
              final String iconPath = (_currentEntry.moodIndex >= 0 && _currentEntry.moodIndex <= 23)
                  ? 'assets/icons/custom${_currentEntry.moodIndex + 1}.png'
                  : (mood.iconPath ?? 'assets/icons/happy.png');
              final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xFFF2F2F2).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFD8D8D8).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'mood_$_currentEntry.id',
                      child: hasCustomIcon
                          ? Image.file(
                              File(parsed.customMoodIconPath!),
                              width: 16,
                              height: 16,
                            )
                          : Image.asset(
                              iconPath,
                              width: 16,
                              height: 16,
                            ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        moodLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: !_effectiveIsNight
                              ? const Color(0xFF5C5C5C)
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })(),
            // 日记多标签
            ...ParsedTags.parse(_currentEntry.tag, _currentEntry.moodIndex).tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xFFF2F2F2).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFD8D8D8).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: !_effectiveIsNight
                        ? const Color(0xFF5C5C5C)
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              );
            }),
            // 天气标签
            if (_currentEntry.weather != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: !_effectiveIsNight
                      ? const Color(0xFFF2F2F2).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFD8D8D8).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWeatherIcon(_currentEntry.weather),
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF5C5C5C)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${_currentEntry.weather} ${_currentEntry.temp ?? ''}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: !_effectiveIsNight
                            ? const Color(0xFF5C5C5C)
                            : Colors.white.withValues(alpha: 0.75),
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
                      ? const Color(0xFFF2F2F2).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFD8D8D8).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF5C5C5C)
                          : Colors.white.withValues(alpha: 0.6),
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
                          fontWeight: FontWeight.w500,
                          color: !_effectiveIsNight
                              ? const Color(0xFF5C5C5C)
                              : Colors.white.withValues(alpha: 0.75),
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
                      ? const Color(0xFFF2F2F2).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFD8D8D8).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF5C5C5C)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currentEntry.customDate!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: !_effectiveIsNight
                            ? const Color(0xFF5C5C5C)
                            : Colors.white.withValues(alpha: 0.75),
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
                      ? const Color(0xFFF2F2F2).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: !_effectiveIsNight
                        ? const Color(0xFFD8D8D8).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: !_effectiveIsNight
                          ? const Color(0xFF5C5C5C)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currentEntry.customTime!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: !_effectiveIsNight
                            ? const Color(0xFF5C5C5C)
                            : Colors.white.withValues(alpha: 0.75),
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
    final filteredContent = DiaryUtils.getFilteredContent(_currentEntry.content);
    final hasText = filteredContent.trim().isNotEmpty;

    if (_currentEntry.blocks.isEmpty) {
      return [
        if (hasText) ...[
          _buildRichTextView(),
          const SizedBox(height: 12),
        ],
        _buildImagesView(),
      ];
    }

    final List<Widget> list = [];
    final textStyle = TextStyle(
      fontSize: 20,
      height: 1.8,
      color: DiaryUtils.getInkColor(_currentEntry.paperStyle, widget.isNight),
      fontFamily: 'LXGWWenKai',
    );

    if (_currentEntry.isImageGrid && !_currentEntry.isMixedLayout) {
      return [
        if (hasText) ...[
          _buildRichTextView(),
          const SizedBox(height: 12),
        ],
        _buildImagesView(),
      ];
    }

    final List<DiaryBlock> originalBlocks = _currentEntry.blocks.map((b) => DiaryBlock.fromMap(Map<String, dynamic>.from(b as Map))).toList();
    final processedBlocks = ImageGroupBlock.preprocess(
      originalBlocks,
      isMixedLayout: _currentEntry.isMixedLayout,
      isImageGrid: _currentEntry.isImageGrid,
    );

    final List<DiaryBlock> displayBlocks = processedBlocks;

    bool isFirst = true;
    int textBlockIndex = 0;
    for (var block in displayBlocks) {
      if (block is TextBlock) {
        final currentBlockIndex = textBlockIndex;
        textBlockIndex++;
        final tc = block.controller;
        if (tc is DiaryTextEditingController) {
          final hasOtherContent = processedBlocks.any((item) => item is! TextBlock || item.controller.text.trim().isNotEmpty);
          if (tc.text.trim().isEmpty && hasOtherContent) {
            continue;
          }

          tc.baseColor = textStyle.color ?? Colors.black;
          tc.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
          tc.baseFontSize = textStyle.fontSize ?? 20;

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
              child: _buildSelectableRichText(span, currentBlockIndex, textStyle, controller: tc),
            ),
          );
          isFirst = false;
        }
      } else if (block is ImageBlock) {
        final path = block.file.path;
        final bool isWide = MediaQuery.of(context).size.width > 800;

        list.add(
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWide
                    ? 520
                    : double.infinity,
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
              child: GestureDetector(
                onTap: () => _showImagePreviewDialog(path, block.id),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DiaryUtils.buildImage(path, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        );
        isFirst = false;
      } else if (block is ImageGroupBlock) {
        final List<String> paths = block.images.map((img) => img.file.path).toList();
        final bool isWide = MediaQuery.of(context).size.width > 800;

        list.add(
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWide
                    ? 520
                    : double.infinity,
              ),
              margin: EdgeInsets.only(top: isFirst ? 8 : 12, bottom: 12),
              child: DiaryImageCollage(
                imagePaths: paths,
                onTapImage: (idx, _) {
                  _showImagePreviewDialog(block.images[idx].file.path, block.images[idx].id);
                },
              ),
            ),
          ),
        );
        isFirst = false;
      }
    }

    return list;
  }

  void _showImagePreviewDialog(String path, String id) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Hero(
            tag: id,
            child: DiaryUtils.buildImage(path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }


  Widget _buildRichTextView() {
    final filteredContent = DiaryUtils.getFilteredContent(
      _currentEntry.content,
    );

    final textStyle = TextStyle(
      fontSize: 20,
      height: 1.8,
      color: DiaryUtils.getInkColor(_currentEntry.paperStyle, widget.isNight),
      fontFamily: 'LXGWWenKai',
    );

    final controller = DiaryTextEditingController(text: filteredContent);
    controller.baseColor = textStyle.color ?? Colors.black;
    controller.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
    controller.baseFontSize = textStyle.fontSize ?? 20;

    final span = controller.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
      hideMarkdownSymbols: true,
      annotations: _currentEntry.annotations,
      blockIndex: 0,
      onAnnotationTap: (key) => _showAnnotationSheet(key: key),
    );

    return _buildSelectableRichText(span, 0, textStyle, controller: controller)
        .animate()
        .fadeIn(delay: 300.ms, duration: 800.ms);
  }

  Widget _buildSelectableRichText(TextSpan span, int blockIndex, TextStyle textStyle, {DiaryTextEditingController? controller}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (controller != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (builderContext, value, child) {
                  return CustomPaint(
                    painter: DiaryCirclePainter(
                      context: builderContext,
                      controller: controller,
                      inkColor: textStyle.color ?? Colors.black,
                      blockIndex: blockIndex,
                    ),
                  );
                },
              ),
            ),
          ),
        SelectableText.rich(
          span,
          style: textStyle,
          selectionHeightStyle: BoxHeightStyle.tight,
          selectionWidthStyle: BoxWidthStyle.tight,
          contextMenuBuilder: (context, editableTextState) {
            return DiaryTextContextMenu(
              editableTextState: editableTextState,
              blockIndex: blockIndex,
              annotations: _currentEntry.annotations,
              onAddAnnotation: ({key, required blockIndex, required start, required end, required selectedText}) {
                _showAnnotationSheet(
                  key: key,
                  blockIndex: blockIndex,
                  start: start,
                  end: end,
                  selectedText: selectedText,
                );
              },
              onDeleteAnnotation: (key) {
                final newAnnotations = Map<String, String>.from(_currentEntry.annotations);
                newAnnotations.remove(key);
                final updated = _currentEntry.copyWith(annotations: newAnnotations);
                UserState().updateDiary(updated);
                setState(() {
                  _currentEntry = updated;
                });
              },
            );
          },
        ),
      ],
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
    final String actualKey = key ?? "${blockIndex}_${start}_$end";
    
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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                              width: 3.0,
                            ),
                          ),
                        ),
                        child: Text(
                          "“$actualSelectedText”",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: inkColor.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                            fontFamily: 'LXGWWenKai',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFCFAF2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isNight ? Colors.white12 : const Color(0xFFE5DDD5),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: textController,
                        autofocus: true,
                        maxLines: 3,
                        maxLength: 200,
                        style: TextStyle(
                          color: inkColor,
                          fontSize: 15,
                          fontFamily: 'LXGWWenKai',
                        ),
                        decoration: InputDecoration(
                          hintText: "写下关于这一段的感悟或注解...",
                          hintStyle: TextStyle(
                            color: inkColor.withValues(alpha: 0.35),
                            fontSize: 14.5,
                            fontFamily: 'LXGWWenKai',
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color: inkColor.withValues(alpha: 0.4),
                            fontFamily: 'LXGWWenKai',
                            fontSize: 11,
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
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
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
                                // 移除所有与当前选区有重叠 of 旧批注，防止重复/并存多个气泡
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
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA68565),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
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
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_currentEntry.isImageGrid) {
      if (images.length <= 3) {
        final paths = images.map((img) => img['path'] as String).toList();
        return DiaryImageCollage(
          imagePaths: paths,
          spacing: 8.0,
          borderRadius: 12.0,
        ).animate().fadeIn(delay: 500.ms, duration: 800.ms);
      }

      // 超过3张：只显示前3张，第3张加遮罩显示剩余数量
      return LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 8;
          final double itemSize = (constraints.maxWidth - spacing * 2) / 3;
          final displayImages = images.take(3).toList();
          final remaining = images.length - 3;

          return Row(
            spacing: spacing,
            children: List.generate(3, (index) {
              final image = displayImages[index];
              final path = image['path'];
              final isLast = index == 2;

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SizedBox(
                      width: itemSize,
                      height: itemSize,
                      child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
                    ),
                    if (isLast)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: Center(
                            child: Text(
                              '+$remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
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
