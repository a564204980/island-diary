import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';
import 'package:island_diary/core/services/ai_service.dart';
import 'package:island_diary/shared/services/export_service.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:intl/intl.dart';

class DiaryBookDetailPage extends StatefulWidget {
  final DiaryBook book;
  const DiaryBookDetailPage({super.key, required this.book});

  @override
  State<DiaryBookDetailPage> createState() => _DiaryBookDetailPageState();
}

class _DiaryBookDetailPageState extends State<DiaryBookDetailPage> {
  bool _isProcessingAI = false;
  bool _descending = true; // 默认最新在最前

  @override
  void initState() {
    super.initState();
    _fetchMissingTitles();
  }

  /// 异步检测缺少的 AI 标题并提炼反哺本地数据库
  Future<void> _fetchMissingTitles() async {
    final diaries = UserState().savedDiaries.value.where((d) => d.bookId == widget.book.id).toList();
    final missing = diaries.where((d) => d.title == null || d.title!.trim().isEmpty).toList();

    if (missing.isEmpty) return;

    setState(() {
      _isProcessingAI = true;
    });

    final apiKey = UserState().deepseekApiKey.value;
    final hasKey = apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY';

    try {
      // 1. 并发执行所有日记的 AI 标题提取，若失败则并发走兜底
      final List<String> results = await Future.wait(
        missing.map((entry) async {
          if (hasKey) {
            try {
              final cleanTitle = await AIService().summarizeDiaryTitle(apiKey, entry.content);
              if (cleanTitle != null && cleanTitle.trim().isNotEmpty) {
                return cleanTitle;
              }
            } catch (_) {}
          }
          return _getFallbackTitle(entry.content);
        }),
      );

      // 2. 并发提取结束后，快速更新到本地数据库
      for (int i = 0; i < missing.length; i++) {
        final entry = missing[i];
        final titleResult = results[i];
        final updated = entry.copyWith(title: titleResult);
        await UserState().updateDiary(updated);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  /// 离线兜底方案：提取日记首行 12 个字文摘
  String _getFallbackTitle(String content) {
    // 过滤Markdown的一些常用符号
    String plain = content.replaceAll(RegExp(r'[#*`_\-–—]'), '').trim();
    final lines = plain.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return '无标题...';
    String firstLine = lines.first;
    if (firstLine.length > 12) {
      return '${firstLine.substring(0, 12)}...';
    }
    return firstLine;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';
    final bookColor = Color(widget.book.coverColorValue);

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF13131F) : const Color(0xFFFDFCF7),
      body: ValueListenableBuilder<List<DiaryEntry>>(
        valueListenable: UserState().savedDiaries,
        builder: (context, diaries, _) {
          final bookDiaries = diaries.where((d) => d.bookId == widget.book.id).toList();
          // 根据排序状态进行排序
          if (_descending) {
            bookDiaries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          } else {
            bookDiaries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          }

          // 提取年份，若没有日记，则显示日记本创建年份或当前年份
          final String displayYear = bookDiaries.isNotEmpty
              ? (_descending ? '${bookDiaries.first.dateTime.year}年' : '${bookDiaries.last.dateTime.year}年')
              : '${widget.book.createdAt.year}年';

          // 统计计算
          final int totalDiaries = bookDiaries.length;
          final uniqueDays = bookDiaries.map((d) => '${d.dateTime.year}-${d.dateTime.month}-${d.dateTime.day}').toSet().length;
          final String createdAtStr = DateFormat('yyyy-MM-dd').format(widget.book.createdAt);

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
            child: Column(
              children: [
                // 1. 拟物化顶部 AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircleBtn(
                        icon: Icons.chevron_left_rounded,
                        isNight: isNight,
                        isLego: isLego,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        displayYear,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white : Colors.black87,
                        ),
                      ),
                      _buildCircleBtn(
                        icon: Icons.share_rounded,
                        isNight: isNight,
                        isLego: isLego,
                        onTap: bookDiaries.isNotEmpty
                            ? () async {
                                final userName = UserState().userName.value.isEmpty ? "我" : UserState().userName.value;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('正在制作并排版岁月成书 PDF，请稍候...')),
                                );
                                try {
                                  await ExportService.exportToPdf(bookDiaries, widget.book.name, userName);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('导出失败: $e')),
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),

                // 2. 页面内容滚动区域
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 封面与手帐统计卡片
                      _buildHeaderCard(isNight, isLego, bookColor, totalDiaries, uniqueDays, createdAtStr, fontFamily),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                size: 16,
                                color: isNight ? Colors.white54 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.book.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: fontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: isNight ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              if (_isProcessingAI) ...[
                                const SizedBox(width: 10),
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI提炼中...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isNight ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              _descending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              size: 18,
                              color: const Color(0xFFD4A373),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _descending ? '最新在前' : '最早在前',
                            onPressed: () {
                              setState(() {
                                _descending = !_descending;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 目录列表
                      if (bookDiaries.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.chrome_reader_mode_outlined,
                                size: 48,
                                color: isNight ? Colors.white24 : Colors.black12,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '暂无日记目录，快去写篇日记吧~',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: fontFamily,
                                  color: isNight ? Colors.white30 : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 16),
                               GestureDetector(
                                 onTap: () async {
                                   UserState().isDiarySheetOpen.value = true;
                                   await Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => const DiaryEditorPage(moodIndex: 4, intensity: 6),
                                     ),
                                   );
                                   UserState().isDiarySheetOpen.value = false;
                                 },
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                   decoration: BoxDecoration(
                                     color: const Color(0xFFD4A373),
                                     borderRadius: BorderRadius.circular(20),
                                   ),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                                       const SizedBox(width: 8),
                                       Text(
                                         '去写日记',
                                         style: TextStyle(
                                           fontSize: 13,
                                           fontWeight: FontWeight.bold,
                                           color: Colors.white,
                                           fontFamily: fontFamily,
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
                          return _buildMonthSection(context, month, entries, isNight, fontFamily);
                        }),
                    ],
                  ),
                ),

                // 3. 底部“开始阅读”大按钮
                if (bookDiaries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: _buildReadBtn(context, bookDiaries.first, isNight, isLego, fontFamily),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 绘制圆圈返回/分享按钮
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
      final Color btnColor = isNight ? const Color(0xFF2C2518) : const Color(0xFFFFFDF2);
      final Color depthColor = isNight ? const Color(0xFF1B160E) : const Color(0xFFEADAB9);
      final Color shadowColor = isNight ? const Color(0x80000000) : const Color(0x3D5D4037);
      final Color arrowColor = isNight ? Colors.white70 : const Color(0xFF5D4037);

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
          child: Icon(
            icon,
            size: 18,
            color: arrowColor,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Icon(
          icon == Icons.chevron_left_rounded ? Icons.arrow_back_ios_new_rounded : icon,
          size: 20,
          color: isNight ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  /// 绘制封面 + 统计卡片
  Widget _buildHeaderCard(
    bool isNight,
    bool isLego,
    Color bookColor,
    int totalDiaries,
    int uniqueDays,
    String createdAtStr,
    String fontFamily,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isNight
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧缩微版长方形书本封面 (带金属活页圈)
          _buildMiniBookCover(bookColor),
          const SizedBox(width: 24),

          // 右侧三行统计数据
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatLine(Icons.calendar_today_rounded, '已记录天数', '$uniqueDays 天', isNight, fontFamily),
                const SizedBox(height: 10),
                _buildStatLine(Icons.edit_note_rounded, '累计篇数', '$totalDiaries 篇', isNight, fontFamily),
                const SizedBox(height: 10),
                _buildStatLine(Icons.schedule_rounded, '创于日期', createdAtStr, isNight, fontFamily),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLine(IconData icon, String label, String value, bool isNight, String fontFamily) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD4A373)),
        const SizedBox(width: 8),
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 12,
            fontFamily: fontFamily,
            color: isNight ? Colors.white54 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            color: isNight ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 绘制缩微活页装订日记本
  Widget _buildMiniBookCover(Color bookColor) {
    return SizedBox(
      width: 76,
      height: 106,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 书本主体
          Positioned(
            left: 10, // 缩进10，给左侧金属环留出稍微一点的空白距离
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: (widget.book.customCoverPath == null || !File(widget.book.customCoverPath!).existsSync())
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          bookColor,
                          bookColor.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                image: (widget.book.customCoverPath != null && File(widget.book.customCoverPath!).existsSync())
                    ? DecorationImage(
                        image: FileImage(File(widget.book.customCoverPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: UserState().isNight
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 书脊阴影
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          bottomLeft: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // 书脊压印线
                  Positioned(
                    left: 6,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  // 书本的缩微Logo与文字
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_added_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
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

          // 金属活页圈（与书本边缘留出一丁点儿空白）
          Positioned(
            left: 2, // 相比以前完全贴靠，留出 2dp 与最外边缘的空白距离，使得视觉更通透
            top: 10,
            bottom: 10,
            width: 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return Container(
                  width: 10,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 1,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFEEEEEE),
                        Color(0xFFB0B0B0),
                        Color(0xFF666666),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 按月份渲染目录折叠卡片
  Widget _buildMonthSection(
    BuildContext context,
    int month,
    List<DiaryEntry> entries,
    bool isNight,
    String fontFamily,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isNight
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: const Color(0xFFD4A373),
          collapsedIconColor: Colors.grey,
          title: Text(
            '$month月',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
              color: isNight ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: entries.map((entry) {
            final dateStr = '${entry.dateTime.month}月${entry.dateTime.day}日';
            final titleStr = entry.title ?? '未命名章节';
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiaryDetailPage(
                      entry: entry,
                      isNight: isNight,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isNight
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: fontFamily,
                        color: const Color(0xFFD4A373),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        titleStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: fontFamily,
                          color: isNight ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: isNight ? Colors.white24 : Colors.black26,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 绘制精致的开始阅读按钮
  Widget _buildReadBtn(
    BuildContext context,
    DiaryEntry firstEntry,
    bool isNight,
    bool isLego,
    String fontFamily,
  ) {
    if (isLego) {
      final Color btnColor = isNight ? const Color(0xFF3B6B15) : const Color(0xFF76B131);
      final Color depthColor = isNight ? const Color(0xFF25470B) : const Color(0xFF598E20);
      final Color shadowColor = isNight ? const Color(0x80000000) : const Color(0x3D335213);

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryDetailPage(
                entry: firstEntry,
                isNight: isNight,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: depthColor,
                blurRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: shadowColor,
                blurRadius: 5.0,
                offset: const Offset(0, 6.0),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '开始阅读',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailPage(
              entry: firstEntry,
              isNight: isNight,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF2C2E35) : const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4A373),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFFD4A373),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '开始阅读',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4A373),
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
