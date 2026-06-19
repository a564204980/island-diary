import 'package:flutter/material.dart';
import 'dart:io';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:share_plus/share_plus.dart' as sp;
import 'package:intl/intl.dart';
import 'package:island_diary/features/profile/presentation/pages/diary_book_export_page.dart';
import 'package:island_diary/features/profile/presentation/pages/diary_book_detail_reader_page.dart';
import 'package:island_diary/features/profile/presentation/widgets/dashed_line_painter.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';

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

  /// 智能提取日记第一句话（不含末尾标点，当句末标点句过长时，智能在逗号处切分）
  String _getFirstSentence(String text) {
    if (text.isEmpty) return text;
    
    // 1. 先尝试以句号、问号、感叹号、分号或换行（句末标点）进行第一轮切分
    final RegExp endSentenceRegex = RegExp(r'[。？！；!?;\n]');
    final endMatch = endSentenceRegex.firstMatch(text);
    String candidate = text;
    if (endMatch != null) {
      // 截取至标点符号之前，不显示末尾标点
      candidate = text.substring(0, endMatch.start).trim();
    }
    
    // 2. 如果切出的句子依然较长（大于 14 个字），则尝试在第一个逗号处切分，提高列表排版美感
    if (candidate.length > 14) {
      final RegExp commaRegex = RegExp(r'[，,]');
      final commaMatch = commaRegex.firstMatch(candidate);
      if (commaMatch != null) {
        // 截取至逗号之前，不显示逗号
        final String subSentence = candidate.substring(0, commaMatch.start).trim();
        // 保证切分后的内容至少 4 个字，避免截出“今天”等无实际意义的极短词
        if (subSentence.length >= 4) {
          return subSentence;
        }
      }
    }
    
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    return ValueListenableBuilder<List<DiaryBook>>(
      valueListenable: UserState().savedBooks,
      builder: (context, books, _) {
        final book = books.firstWhere((b) => b.id == widget.book.id, orElse: () => widget.book);
        final bookColor = Color(book.coverColorValue);

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF13131F)
              : const Color(0xFFFDFCF7),
          appBar: _buildAppBar(context, book, isNight, isLego, fontFamily),
          body: ValueListenableBuilder<List<DiaryEntry>>(
            valueListenable: UserState().savedDiaries,
            builder: (context, diaries, _) {
              final bookDiaries = diaries
                  .where((d) => d.bookId == book.id)
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
          ).format(book.createdAt);

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
                        context,
                        book,
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

                // 3. 底部“导出成书”大按钮
                if (bookDiaries.isNotEmpty)
                  Builder(
                    builder: (context) {
                      // 导出时按时间升序排序，从第一篇到最后一篇
                      final exportList = List<DiaryEntry>.from(bookDiaries)
                        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _buildExportBtn(
                          context,
                          book,
                          exportList,
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
  },
);
}

  /// 构建与图1一致的标准 AppBar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    DiaryBook book,
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
              color: isNight ? Colors.white70 : const Color(0xFF5D4037),
            ),
            onPressed: () {
              final diaries = UserState().savedDiaries.value
                  .where((d) => d.bookId == book.id)
                  .toList();
              final createdAtStr = DateFormat(
                'yyyy-MM-dd',
              ).format(book.createdAt);
              final text =
                  '《${book.name}》\n共记录了 ${diaries.length} 篇回忆。\n创于 $createdAtStr。';
              sp.SharePlus.instance.share(sp.ShareParams(text: text));
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
                .where((d) => d.bookId == book.id)
                .toList();
            final createdAtStr = DateFormat(
              'yyyy-MM-dd',
            ).format(book.createdAt);
            final text =
                '《${book.name}》\n共记录了 ${diaries.length} 篇回忆。\n创于 $createdAtStr。';
            sp.SharePlus.instance.share(sp.ShareParams(text: text));
          },
        ),
      ],
    );
  }



  Widget _buildHeaderCard(
    BuildContext context,
    DiaryBook book,
    bool isNight,
    bool isLego,
    Color bookColor,
    int totalDiaries,
    int uniqueDays,
    String createdAtStr,
    String fontFamily,
  ) {
    final description = book.description;
    final hasDesc = description.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiniBookCover(book, bookColor),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // 书名
                Text(
                  book.name,
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
  Widget _buildMiniBookCover(DiaryBook book, Color bookColor) {
    final bool hasCustomCover =
        book.customCoverPath != null &&
        File(book.customCoverPath!).existsSync();
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
                        image: FileImage(File(book.customCoverPath!)),
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
                  painter: DashedLinePainter(
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
                  // 强制提取只保留第一句话
                  titleStr = _getFirstSentence(titleStr);
                  // 去除因为历史数据缓存或先前自动截断产生的尾部省略号
                  titleStr = titleStr.replaceAll(RegExp(r'\s*\.{3,}$'), '');
                  titleStr = titleStr.replaceAll(RegExp(r'\s*…+$'), '');



                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryBookDetailReaderPage(
                            entries: bookDiaries,
                            initialIndex: bookDiaries.indexOf(entry),
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
                          const SizedBox(width: 12),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _showEditTitleDialog(context, entry, titleStr, isNight, fontFamily);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: isNight ? Colors.white38 : Colors.black38,
                              ),
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

  Widget _buildExportBtn(
    BuildContext context,
    DiaryBook book,
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
              builder: (context) => DiaryBookExportPage(
                book: book,
                diaries: bookDiaries,
              ),
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
              '导出成书',
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

  void _showEditTitleDialog(BuildContext context, DiaryEntry entry, String currentTitle, bool isNight, String fontFamily) {
    final controller = TextEditingController(text: currentTitle);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 310,
            decoration: BoxDecoration(
              color: isNight ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Text(
                    '修改章节标题',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                
                // 输入框
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isNight 
                          ? Colors.white.withValues(alpha: 0.04) 
                          : const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isNight 
                            ? Colors.white.withValues(alpha: 0.08) 
                            : Colors.black.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: fontFamily,
                        color: isNight ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF2C2C2C),
                      ),
                      decoration: InputDecoration(
                        hintText: '写个有意义的标题吧...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: fontFamily,
                          color: isNight ? Colors.white38 : Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // 分割线
                Container(
                  height: 0.5,
                  color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            "取消",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isNight ? Colors.white54 : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5,
                      height: 48,
                      color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final newTitle = controller.text.trim();
                          final updated = entry.copyWith(title: newTitle);
                          await UserState().updateDiary(updated);
                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            showTopToast(
                              context,
                              '标题修改成功',
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF10B981),
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            "确定",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFA68565),
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
        );
      },
    );
  }
}

