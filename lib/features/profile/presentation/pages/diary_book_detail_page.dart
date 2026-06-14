import 'package:flutter/material.dart';
import 'dart:io';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/diary_book_reader_page.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:share_plus/share_plus.dart' as sp;
import 'package:intl/intl.dart';

class DiaryBookDetailPage extends StatefulWidget {
  final DiaryBook book;
  const DiaryBookDetailPage({super.key, required this.book});

  @override
  State<DiaryBookDetailPage> createState() => _DiaryBookDetailPageState();
}

class _DiaryBookDetailPageState extends State<DiaryBookDetailPage> {
  bool _descending = true; // 默认最新在最前

  Widget _buildRichText(String text, TextStyle style, {int? maxLines, TextOverflow? overflow}) {
    final chunks = EmojiMapping.parseText(text);
    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        children: chunks.map((chunk) {
          if (chunk.isEmoji) {
            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Image.asset(
                  chunk.emojiPath!,
                  width: (style.fontSize ?? 15) + 2.0,
                  height: (style.fontSize ?? 15) + 2.0,
                ),
              ),
            );
          }
          return TextSpan(text: chunk.text, style: style);
        }).toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMissingTitles();
    });
  }

  /// 异步检测缺少的标题并提炼反哺本地数据库
  Future<void> _fetchMissingTitles() async {
    final diaries = UserState().savedDiaries.value
        .where((d) => d.bookId == widget.book.id)
        .toList();
    final missing = diaries
        .where((d) => d.title == null || d.title!.trim().isEmpty)
        .toList();

    if (missing.isEmpty) return;

    try {
      // 快速更新到本地数据库
      for (var entry in missing) {
        final titleResult = _getFallbackTitle(entry);
        final updated = entry.copyWith(title: titleResult);
        await UserState().updateDiary(updated);
      }
    } catch (_) {}
  }

  /// 离线兜底方案：无文字时根据媒体类型生成，有文字时提取日记首行 12 个字文摘
  String _getFallbackTitle(DiaryEntry entry) {
    final hasImages = entry.blocks.any((b) => b['type'] == 'image');
    final hasAudio = entry.blocks.any((b) => b['type'] == 'audio');

    if (entry.content.trim().isEmpty) {
      if (hasImages) return '定格瞬间';
      if (hasAudio) return '听见时光';
      return '无标题';
    }

    // 过滤Markdown的一些常用符号，并清除可能混入的 mood 和 mood_icon 标签字符串
    String plain = entry.content.replaceAll(RegExp(r'[#*`_\-–—]'), '').trim();
    plain = plain.replaceAll(RegExp(r'mood(_icon)?:\s*[^\n,;]+[,;]?'), '').trim();
    final lines = plain
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      if (hasImages) return '定格瞬间';
      if (hasAudio) return '听见时光';
      return '无标题';
    }
    return lines.first;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';
    final bookColor = Color(widget.book.coverColorValue);

    return Scaffold(
      backgroundColor: isNight
          ? const Color(0xFF13131F)
          : const Color(0xFFFDFCF7),
      appBar: _buildAppBar(context, isNight, isLego, fontFamily),
      body: ValueListenableBuilder<List<DiaryEntry>>(
        valueListenable: UserState().savedDiaries,
        builder: (context, diaries, _) {
          final bookDiaries = diaries
              .where((d) => d.bookId == widget.book.id)
              .toList();
          // 根据排序状态进行排序
          if (_descending) {
            bookDiaries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          } else {
            bookDiaries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          }

          // 统计计算
          final int totalDiaries = bookDiaries.length;
          final uniqueDays = bookDiaries
              .map(
                (d) =>
                    '${d.dateTime.year}-${d.dateTime.month}-${d.dateTime.day}',
              )
              .toSet()
              .length;
          final String createdAtStr = DateFormat(
            'yyyy-MM-dd',
          ).format(widget.book.createdAt);

          // 按月份将日记分组
          final Map<int, List<DiaryEntry>> monthlyDiaries = {};
          for (var d in bookDiaries) {
            monthlyDiaries.putIfAbsent(d.dateTime.month, () => []).add(d);
          }
          final sortedMonths = monthlyDiaries.keys.toList();
          if (_descending) {
            sortedMonths.sort((a, b) => b.compareTo(a)); // 降序
          } else {
            sortedMonths.sort((a, b) => a.compareTo(b)); // 升序
          }

          return SafeArea(
            top: false,
            bottom: true,
            child: Column(
              children: [
                // 页面内容滚动区域
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 封面与手帐统计卡片
                      _buildHeaderCard(
                        isNight,
                        isLego,
                        bookColor,
                        totalDiaries,
                        uniqueDays,
                        createdAtStr,
                        fontFamily,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 22,
                                color: Color(0xFFA68565),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '按月份整理你的日记章节',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: fontFamily,
                                  fontWeight: FontWeight.w500,
                                  color: isNight
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF2C2C2C),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _descending = !_descending;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              color: Colors.transparent, // 增加点击区域
                              child: Row(
                                children: [
                                  Text(
                                    '排序',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: fontFamily,
                                      color: isNight
                                          ? Colors.white54
                                          : const Color(0xFF757575),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _descending
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    size: 16,
                                    color: isNight
                                        ? Colors.white54
                                        : const Color(0xFF757575),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 目录列表
                      if (bookDiaries.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isNight
                                      ? Colors.black26
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.history_edu_rounded, // 鹅毛笔图标
                                  size: 32,
                                  color: const Color(
                                    0xFFA68565,
                                  ).withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '扉页尚空，等待落笔',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: fontFamily,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: isNight
                                      ? Colors.white70
                                      : const Color(0xFF5C5C5C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '在这本手账里，写下你的第一个故事',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: fontFamily,
                                  color: isNight
                                      ? Colors.white38
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () async {
                                  UserState().isDiarySheetOpen.value = true;
                                  await Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 350),
                                      reverseTransitionDuration: const Duration(milliseconds: 250),
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          DiaryEditorPage(
                                            moodIndex: 4,
                                            intensity: 6,
                                            bookId: widget.book.id,
                                          ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
                                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                        );
                                        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                          CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                        );
                                        return FadeTransition(
                                          opacity: fadeAnimation,
                                          child: ScaleTransition(
                                            scale: scaleAnimation,
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                  UserState().isDiarySheetOpen.value = false;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA68565),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFA68565,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.edit_note_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '提笔记录',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: fontFamily,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...sortedMonths.map((month) {
                          final entries = monthlyDiaries[month]!;
                          return _buildMonthSection(
                            context,
                            month,
                            entries,
                            bookDiaries,
                            isNight,
                            fontFamily,
                          );
                        }),
                    ],
                  ),
                ),

                // 3. 底部“开始阅读”大按钮
                if (bookDiaries.isNotEmpty)
                  Builder(
                    builder: (context) {
                      // 克隆并强制按时间升序排序，使阅读总是从最早的第一篇日记开始
                      final readingList = List<DiaryEntry>.from(bookDiaries)
                        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _buildReadBtn(
                          context,
                          readingList,
                          isNight,
                          isLego,
                          fontFamily,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建与图1一致的标准 AppBar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isNight,
    bool isLego,
    String fontFamily,
  ) {
    if (isLego) {
      // Lego 主题保留拟物风格
      return AppBar(
        backgroundColor: isNight
            ? const Color(0xFF13131F)
            : const Color(0xFFFFFDF2),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNight
                  ? const Color(0xFF2C2518)
                  : const Color(0xFFFFFDF2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isNight
                      ? const Color(0xFF1B160E)
                      : const Color(0xFFEADAB9),
                  blurRadius: 0,
                  offset: const Offset(0, 3.5),
                ),
              ],
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: isNight ? Colors.white70 : const Color(0xFF5D4037),
            ),
          ),
        ),
        title: Text(
          '书籍目录',
          style: TextStyle(
            color: isNight ? Colors.white : Colors.black87,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              size: 22,
              color: isNight ? Colors.white70 : Colors.black87,
            ),
            onPressed: () {
              final diaries = UserState().savedDiaries.value
                  .where((d) => d.bookId == widget.book.id)
                  .toList();
              final createdAtStr = DateFormat(
                'yyyy-MM-dd',
              ).format(widget.book.createdAt);
              final text =
                  '《${widget.book.name}》\n共记录了 ${diaries.length} 篇回忆。\n创于 $createdAtStr。';
              // ignore: deprecated_member_use
              sp.Share.share(text);
            },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isNight ? Colors.white70 : Colors.black87,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '书籍目录',
        style: TextStyle(
          color: isNight ? Colors.white : Colors.black87,
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_rounded,
            size: 22,
            color: isNight ? Colors.white70 : Colors.black87,
          ),
          onPressed: () {
            final diaries = UserState().savedDiaries.value
                .where((d) => d.bookId == widget.book.id)
                .toList();
            final createdAtStr = DateFormat(
              'yyyy-MM-dd',
            ).format(widget.book.createdAt);
            final text =
                '《${widget.book.name}》\n共记录了 ${diaries.length} 篇回忆。\n创于 $createdAtStr。';
            // ignore: deprecated_member_use
            sp.Share.share(text);
          },
        ),
      ],
    );
  }

  /// 绘制圆圈返回/分享按钮（仅Lego主题列表页使用）
  Widget _buildCircleBtn({
    required IconData icon,
    required bool isNight,
    required bool isLego,
    required VoidCallback? onTap,
  }) {
    if (onTap == null) {
      return const SizedBox(width: 40, height: 40);
    }

    if (isLego) {
      final Color btnColor = isNight
          ? const Color(0xFF2C2518)
          : const Color(0xFFFFFDF2);
      final Color depthColor = isNight
          ? const Color(0xFF1B160E)
          : const Color(0xFFEADAB9);
      final Color shadowColor = isNight
          ? const Color(0x80000000)
          : const Color(0x3D5D4037);
      final Color arrowColor = isNight
          ? Colors.white70
          : const Color(0xFF5D4037);

      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 38,
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(14),
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
          child: Icon(icon, size: 18, color: arrowColor),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon == Icons.chevron_left_rounded
            ? Icons.arrow_back_ios_new_rounded
            : icon,
        size: 20,
        color: isNight ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildHeaderCard(
    bool isNight,
    bool isLego,
    Color bookColor,
    int totalDiaries,
    int uniqueDays,
    String createdAtStr,
    String fontFamily,
  ) {
    final description = widget.book.description;
    final hasDesc = description != null && description.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiniBookCover(bookColor),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // 书名
                Text(
                  widget.book.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                    letterSpacing: 0.5,
                    color: isNight
                        ? Colors.white.withValues(alpha: 0.95)
                        : const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 6),
                // 简介（两行结构，减弱层级）
                if (hasDesc)
                  Text(
                    description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white38 : Colors.black45,
                    ),
                  )
                else
                  Text(
                    '记录岛屿的点滴回忆',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white38 : Colors.black45,
                    ),
                  ),
                const SizedBox(height: 18),
                // 统计数据
                Row(
                  children: [
                    _buildCompactStat(totalDiaries.toString(), '篇', isNight),
                    const SizedBox(width: 20),
                    _buildCompactStat(uniqueDays.toString(), '天', isNight),
                    const SizedBox(width: 20),
                    _buildCompactStat(
                      createdAtStr.replaceAll('-', '.'),
                      '创建',
                      isNight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String unit, bool isNight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            color: isNight
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isNight ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  /// 绘制微缩极简书籍封面
  Widget _buildMiniBookCover(Color bookColor) {
    final bool hasCustomCover =
        widget.book.customCoverPath != null &&
        File(widget.book.customCoverPath!).existsSync();
    final bool isNight = UserState().isNight;

    // 降低饱和度，增加莫兰迪色调
    Color displayColor = hasCustomCover
        ? Colors.transparent
        : bookColor.withValues(alpha: 0.85);

    return SizedBox(
      width: 86,
      height: 118,
      child: Stack(
        children: [
          // 1. 纸张厚度（底层白边）
          Positioned(
            left: 4,
            top: 2,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isNight
                    ? const Color(0xFFC0C0C0)
                    : const Color(0xFFF4F1EA), // 纸张色
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: isNight ? Colors.black38 : Colors.black12,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.3 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 0.5,
                    color: Colors.black12,
                    margin: const EdgeInsets.only(right: 2),
                  ),
                  Container(
                    width: 0.5,
                    color: Colors.black12,
                    margin: const EdgeInsets.only(right: 2),
                  ),
                ],
              ),
            ),
          ),

          // 2. 书脊与硬皮封面
          Positioned(
            left: 0,
            top: 0,
            right: 4,
            bottom: 3, // 露出底部纸张
            child: Container(
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                image: hasCustomCover
                    ? DecorationImage(
                        image: FileImage(File(widget.book.customCoverPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                child: Stack(
                  children: [
                    // 莫兰迪滤镜
                    if (!hasCustomCover)
                      Container(
                        color: isNight
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.15),
                      ),

                    // 书脊阴影过渡
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 书脊边缘高光
                    Positioned(
                      left: 1,
                      top: 0,
                      bottom: 0,
                      width: 1,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    // 书皮内部翻折沟槽
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
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

  Widget _buildMonthSection(
    BuildContext context,
    int month,
    List<DiaryEntry> entries,
    List<DiaryEntry> bookDiaries,
    bool isNight,
    String fontFamily,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题与篇数 tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$month 月',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia', // 参考图片中的衬线风格字体
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isNight
                      ? const Color(0xFFA68565).withValues(alpha: 0.2)
                      : const Color(0xFFF7F2EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entries.length} 篇',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isNight
                        ? const Color(0xFFD4A373)
                        : const Color(0xFFA68565),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 列表时间轴区
          Stack(
            children: [
              // 虚线
              Positioned(
                left: 3.7, // 节点中心位置
                top: 20, // 起点稍微下移
                bottom: 20, // 终点稍微上移
                child: CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: _DashedLinePainter(
                    color: isNight ? Colors.white24 : const Color(0xFFD8D2C4),
                  ),
                ),
              ),
              // 节点列表
              Column(
                children: entries.map((entry) {
                  final dateStr = entry.dateTime.day.toString().padLeft(2, '0');
                  
                  // 过滤标题中残留的 tag 字符串以防止豆腐块显示，若无标题或标题为“未命名回忆”则默认显示第一句话
                  String titleStr = entry.title ?? '';
                  titleStr = titleStr.replaceAll(RegExp(r'mood(_icon)?:\s*[^\n,;]+[,;]?'), '').trim();
                  if (titleStr.isEmpty || titleStr == '未命名回忆') {
                    titleStr = _getFallbackTitle(entry);
                  }
                  // 去除因为历史数据缓存或先前自动截断产生的尾部省略号
                  titleStr = titleStr.replaceAll(RegExp(r'\s*\.{3,}$'), '');
                  titleStr = titleStr.replaceAll(RegExp(r'\s*…+$'), '');

                  // 获取心情数据并解析 customMood
                  final mood = kMoods[entry.moodIndex.clamp(0, kMoods.length - 1)];
                  final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
                  final String iconPath = parsed.customMood != null
                      ? (entry.moodIndex >= 0 && entry.moodIndex <= 23
                          ? 'assets/icons/custom${entry.moodIndex + 1}.png'
                          : 'assets/images/icons/custom.png')
                      : (mood.iconPath ?? 'assets/icons/happy.png');
                  final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final sortedList = List<DiaryEntry>.from(bookDiaries)
                        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                      final initialIdx = sortedList.indexWhere(
                        (e) => e.id == entry.id,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryBookReaderPage(
                            entries: sortedList,
                            initialIndex: initialIdx >= 0 ? initialIdx : 0,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 节点圆点
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isNight
                                  ? const Color(0xFFD4A373)
                                  : const Color(0xFFD4C9BA),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 日期
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Georgia', // 对应日期的字体
                              fontWeight: FontWeight.w600,
                              color: isNight
                                  ? const Color(0xFFD4A373)
                                  : const Color(0xFFA68565),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // 标题
                          Expanded(
                            child: _buildRichText(
                              titleStr,
                              TextStyle(
                                fontSize: 15,
                                fontFamily: fontFamily,
                                color: isNight
                                    ? Colors.white70
                                    : const Color(0xFF4A4A4A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadBtn(
    BuildContext context,
    List<DiaryEntry> bookDiaries,
    bool isNight,
    bool isLego,
    String fontFamily,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DiaryBookReaderPage(entries: bookDiaries, initialIndex: 0),
            ),
          );
        },
        child: Container(
          width: 140,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFA68565),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA68565).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '开始阅读',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: Colors.white,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double dashHeight = 4, dashSpace = 4, startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
