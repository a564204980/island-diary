import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lunar/lunar.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';

/// 日历网格面板：单月视图带记录列表版
class DiaryCalendarPanel extends StatefulWidget {
  final bool isNight;
  final Function(DateTime) onDateSelected;

  const DiaryCalendarPanel({
    super.key,
    required this.isNight,
    required this.onDateSelected,
    this.onShareMonth,
  });

  final Function(DateTime)? onShareMonth;

  @override
  State<DiaryCalendarPanel> createState() => _DiaryCalendarPanelState();
}

class _DiaryCalendarPanelState extends State<DiaryCalendarPanel> {
  final ScrollController _scrollController = ScrollController();
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  bool _slideRightToLeft = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 获取中文星期
  String _getWeekdayChinese(int weekday) {
    const weekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    if (weekday >= 1 && weekday <= 7) {
      return weekDays[weekday - 1];
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final isLego = themeId == 'lego';
    final fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, _) {
        final year = _focusedMonth.year;
        final month = _focusedMonth.month;

        // 当前月份所有日记
        final monthDiaries = allDiaries.where((d) => d.dateTime.year == year && d.dateTime.month == month).toList();

        // 阴历/节假日数据计算
        final int daysInMonth = DateTime(year, month + 1, 0).day;
        final int firstDayWeekday = DateTime(year, month, 1).weekday;
        final int emptySlotsBefore = firstDayWeekday - 1;

        // 整理当前月份每天的日记映射
        final Map<int, List<DiaryEntry>> dayMap = {};
        for (var entry in monthDiaries) {
          final d = entry.dateTime.day;
          dayMap.putIfAbsent(d, () => []).add(entry);
        }

        // 当前选中的日记列表
        final selectedDayDiaries = _selectedDay != null && _selectedDay!.year == year && _selectedDay!.month == month
            ? (dayMap[_selectedDay!.day] ?? [])
            : <DiaryEntry>[];

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 日历网格卡片容器
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                decoration: BoxDecoration(
                  color: widget.isNight ? const Color(0xFF212831) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: widget.isNight ? 0.45 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: widget.isNight
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // 月份切换栏
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: widget.isNight ? Colors.white70 : Colors.black87,
                              ),
                              onPressed: () {
                                setState(() {
                                  _slideRightToLeft = false;
                                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                                  _selectedDay = null; // 切换月份后清空当前选中天
                                });
                              },
                            ),
                            Text(
                              "${_focusedMonth.year}.${_focusedMonth.month.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontFamily,
                                color: widget.isNight ? Colors.white : Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: widget.isNight ? Colors.white70 : Colors.black87,
                              ),
                              onPressed: () {
                                setState(() {
                                  _slideRightToLeft = true;
                                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                                  _selectedDay = null;
                                });
                              },
                            ),
                          ],
                        ),
                        if (widget.onShareMonth != null && monthDiaries.isNotEmpty)
                          GestureDetector(
                            onTap: () => widget.onShareMonth!(_focusedMonth),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.ios_share_rounded,
                                size: 19,
                                color: widget.isNight
                                    ? Colors.white24
                                    : Colors.black.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 星期标头
                    _buildWeekHeader(widget.isNight, fontFamily),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final isEntering = child.key == ValueKey<DateTime>(_focusedMonth);
                        final double dx = _slideRightToLeft ? 1.0 : -1.0;
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(isEntering ? dx * 0.25 : -dx * 0.25, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: GridView.builder(
                        key: ValueKey<DateTime>(_focusedMonth),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: daysInMonth + emptySlotsBefore,
                        itemBuilder: (context, index) {
                          if (index < emptySlotsBefore) {
                            return const SizedBox.shrink();
                          }

                          final int day = index - emptySlotsBefore + 1;
                          final cellDate = DateTime(year, month, day);
                          final entries = dayMap[day];
                          final bool isToday = DateTime.now().year == year &&
                              DateTime.now().month == month &&
                              DateTime.now().day == day;
                          final bool isSelected = _selectedDay != null &&
                              _selectedDay!.year == year &&
                              _selectedDay!.month == month &&
                              _selectedDay!.day == day;

                          return _CalendarDayCell(
                            date: cellDate,
                            entries: entries,
                            isToday: isToday,
                            isSelected: isSelected,
                            isNight: widget.isNight,
                            onTap: () {
                              setState(() {
                                _selectedDay = cellDate;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. 月份记录统计信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$month月记录",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: widget.isNight ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    ),
                  ),
                  Text(
                    "${monthDiaries.length}条",
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isNight ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. 选中日期的详细日记记录
              if (_selectedDay != null)
                Column(
                  key: ValueKey(_selectedDay),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_selectedDay!.day} ${_getWeekdayChinese(_selectedDay!.weekday)}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                            color: widget.isNight ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                          ),
                        ),
                        Text(
                          "${selectedDayDiaries.length}条",
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isNight ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (selectedDayDiaries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "这一天没有记录日记哦~",
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isNight ? Colors.white24 : Colors.black26,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                      )
                    else
                      ...selectedDayDiaries.map((entry) => _buildDiaryDetailCard(entry, widget.isNight, fontFamily)),
                  ],
                ).animate(key: ValueKey(_selectedDay)).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekHeader(bool isNight, String fontFamily) {
    final List<String> weekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isNight ? Colors.white38 : Colors.black.withValues(alpha: 0.35),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDiaryDetailCard(DiaryEntry entry, bool isNight, String fontFamily) {
    final cardColor = isNight ? const Color(0xFF212831) : Colors.white;
    final labelColor = isNight ? Colors.white38 : Colors.black45;
    final valueColor = isNight ? Colors.white70 : Colors.black87;

    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final badgeColor = mood.glowColor ?? const Color(0xFFD4A373);

    // 提取日记中的照片列表
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();
    String bgAsset = DiaryUtils.getPaperBackgroundPath(entry.paperStyle, isNight);
    if (bgAsset.isEmpty) {
      bgAsset = isNight
          ? 'assets/images/note/note_night_bg1.png'
          : 'assets/images/note/note_bg1.png';
    }

    // 日记内容提取逻辑
    final String plainContent = DiaryUtils.getFilteredContent(entry.content).trim();

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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNight ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isNight
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            width: 0.5,
          ),
          image: DecorationImage(
            image: AssetImage(bgAsset),
            fit: BoxFit.cover,
            opacity: isNight ? 0.40 : 0.82,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：手写笔圆形图标
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isNight ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFAF6F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.edit_note_rounded,
                  color: isNight ? Colors.white54 : const Color(0xFF8D827A),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 中间：日记文字与心情状态
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "日记内容",
                    style: TextStyle(
                      fontSize: 12,
                      color: labelColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plainContent.isNotEmpty ? plainContent : "无文字内容",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                      fontFamily: fontFamily,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 心情状态药丸 (含心情表情图)
                  Builder(
                    builder: (context) {
                      final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
                      final String moodLabel = parsed.customMood ?? mood.label;
                      final String iconPath = parsed.customMood != null
                          ? (entry.moodIndex >= 0 && entry.moodIndex <= 23
                              ? 'assets/icons/custom${entry.moodIndex + 1}.png'
                              : 'assets/images/icons/custom.png')
                          : (mood.iconPath ?? 'assets/icons/happy.png');
                      final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isNight
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF2F2F2).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isNight
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFD8D8D8).withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            hasCustomIcon
                                ? Image.file(
                                    File(parsed.customMoodIconPath!),
                                    width: 14,
                                    height: 14,
                                    errorBuilder: (c, e, s) => Icon(
                                      Icons.mood,
                                      size: 14,
                                      color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                                    ),
                                  )
                                : Image.asset(
                                    iconPath,
                                    width: 14,
                                    height: 14,
                                    errorBuilder: (c, e, s) => Icon(
                                      Icons.mood,
                                      size: 14,
                                      color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                                    ),
                                  ),
                            const SizedBox(width: 5),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                moodLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isNight ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF5C5C5C),
                                  fontFamily: fontFamily,
                                ),
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

            // 右侧：更多按钮及日记照片预览
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: isNight ? Colors.white30 : Colors.black26,
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DiaryUtils.buildImage(
                          images.first['path'],
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                size: 9,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "${images.length}",
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LunarCacheData {
  final String lunarStr;
  final bool isImportantFest;

  _LunarCacheData(this.lunarStr, this.isImportantFest);
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<DiaryEntry>? entries;
  final bool isToday;
  final bool isSelected;
  final bool isNight;
  final VoidCallback onTap;

  static final Map<String, _LunarCacheData> _lunarCache = {};

  const _CalendarDayCell({
    required this.date,
    this.entries,
    required this.isToday,
    required this.isSelected,
    required this.isNight,
    required this.onTap,
  });

  static const Set<String> _importantFests = {
    '元旦', '除夕', '春节', '元宵节', '清明', '劳动节', '端午节', '中秋节', '国庆节',
    '情人节', '妇女节', '儿童节', '教师节', '圣诞节', '冬至', '七夕', '重阳', '腊八',
  };

  _LunarCacheData _getLunarData(DateTime date) {
    final key = "${date.year}-${date.month}-${date.day}";
    if (_lunarCache.containsKey(key)) {
      return _lunarCache[key]!;
    }

    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    final solarFests = solar.getFestivals();
    final lunarFests = lunar.getFestivals();
    final jieQi = lunar.getJieQi();

    String? importantFest;
    for (final f in [
      ...solarFests,
      ...lunarFests,
      if (jieQi.isNotEmpty) jieQi,
    ]) {
      if (_importantFests.any((important) => f.contains(important))) {
        importantFest = _importantFests.firstWhere((important) => f.contains(important));
        break;
      }
    }

    String lunarStr;
    if (importantFest != null) {
      lunarStr = importantFest;
    } else {
      if (lunar.getDay() == 1) {
        lunarStr = '${lunar.getMonthInChinese()}月';
      } else {
        lunarStr = lunar.getDayInChinese();
      }
    }

    final data = _LunarCacheData(lunarStr, importantFest != null);
    _lunarCache[key] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEntry = entries != null && entries!.isNotEmpty;
    
    // 收集当天所有日记里的所有图片
    final List<String> allImages = [];
    int? moodIdx;
    
    if (hasEntry) {
      for (var entry in entries!) {
        for (var block in entry.blocks) {
          if (block['type'] == 'image' && block['path'] != null) {
            allImages.add(block['path'] as String);
          }
        }
      }
      // 如果没有图片，则取最后一条日记的心情图标
      if (allImages.isEmpty) {
        moodIdx = entries!.last.moodIndex;
      }
    }

    final lunarData = _getLunarData(date);
    final lunarStr = lunarData.lunarStr;
    final bool isImportantFest = lunarData.isImportantFest;

    final TextStyle dayStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      fontFamily: 'LXGWWenKai',
      color: hasEntry
          ? Colors.white
          : (isNight
                ? Colors.white.withValues(alpha: 0.85)
                : const Color(0xFF2C2E30)),
      shadows: hasEntry
          ? [
              const Shadow(
                blurRadius: 4,
                color: Colors.black87,
                offset: Offset(0, 1.5),
              ),
            ]
          : null,
    );

    final Color lunarColor = isImportantFest
        ? (hasEntry ? Colors.white : const Color(0xFFE1AF78))
        : (isNight ? Colors.white.withValues(alpha: 0.45) : Colors.black45);

    final TextStyle lunarStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      fontFamily: 'LXGWWenKai',
      color: hasEntry ? Colors.white70 : lunarColor,
      shadows: hasEntry
          ? [
              const Shadow(
                blurRadius: 3,
                color: Colors.black54,
                offset: Offset(0, 1),
              ),
            ]
          : null,
      height: 1.1,
    );

    final BorderSide borderSide = isSelected
        ? const BorderSide(color: Color(0xFFE1AF78), width: 2.2)
        : (isToday
            ? BorderSide(color: const Color(0xFFE1AF78).withValues(alpha: 0.6), width: 1.5)
            : (hasEntry
                ? BorderSide(color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.12), width: 1.0)
                : BorderSide(color: isNight ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03), width: 0.5)));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.35 : 0.2)
              : (isToday
                    ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.2 : 0.1)
                    : (hasEntry
                          ? (isNight ? const Color(0xFF3B3E42) : Colors.white)
                          : (isNight
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.black.withValues(alpha: 0.008)))),
          borderRadius: BorderRadius.circular(10),
          boxShadow: hasEntry
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.45 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 图片背景或拼图组件
            if (allImages.isNotEmpty)
              Positioned.fill(
                child: _buildGridImages(allImages),
              ),

            if (allImages.isEmpty && moodIdx != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    kMoods[moodIdx.clamp(0, kMoods.length - 1)].iconPath!,
                    width: 32,
                    height: 32,
                    opacity: const AlwaysStoppedAnimation(0.8),
                  ),
                ),
              ),

            // 日期数字
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${date.day}", style: dayStyle),
                  if (!hasEntry) ...[
                    const SizedBox(height: 1),
                    Text(lunarStr, style: lunarStyle),
                  ],
                ],
              ),
            ),

            // 顶层覆盖的完美圆角边框，确保图片边缘不会因圆角公式计算产生错位
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.fromBorderSide(borderSide),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建拼图宫格逻辑
  Widget _buildGridImages(List<String> images) {
    // 用 SizedBox.expand 确保图片在 Expanded 内始终铺满
    Widget tile(String path) => SizedBox.expand(
      child: ClipRect(
        child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
      ),
    );

    final int count = images.length;
    if (count == 1) {
      return tile(images[0]);
    } else if (count == 2) {
      // 2张图：左右平分
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(images[0])),
          const SizedBox(width: 1),
          Expanded(child: tile(images[1])),
        ],
      );
    } else if (count == 3) {
      // 3张图：左侧单张，右侧上下两张
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(images[0])),
          const SizedBox(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[1])),
                const SizedBox(height: 1),
                Expanded(child: tile(images[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4张及以上：2x2 田字格拼图，右下角覆盖 +N
      final int remaining = count - 4;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[0])),
                const SizedBox(width: 1),
                Expanded(child: tile(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[2])),
                const SizedBox(width: 1),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      tile(images[3]),
                      if (remaining > 0)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.9,
                              colors: [
                                Colors.black.withValues(alpha: 0.72),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "+$remaining",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
