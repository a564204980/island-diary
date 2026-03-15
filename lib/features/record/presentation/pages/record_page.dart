import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/month_calendar_card.dart';
import 'package:island_diary/features/record/presentation/widgets/record_fireflies.dart';
import 'package:island_diary/features/record/presentation/widgets/record_year_picker.dart';
import 'package:island_diary/features/record/presentation/widgets/vine_bubble_widgets.dart';
import 'package:island_diary/features/record/presentation/widgets/vine_render_helper.dart';

/// 记录页面的查看模式
enum RecordViewMode {
  calendar, // 日历视图
  bubble, // 藤蔓泡泡（对话模式）
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedYear = DateTime.now().year;
  RecordViewMode _viewMode = RecordViewMode.bubble;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, child) {
        final bool isNight = UserState().isNight;
        final int hour = DateTime.now().hour;

        String bgPath;
        if (isNight) {
          bgPath = 'assets/images/record_night.png';
        } else if (themeMode == 'light' || (hour >= 10 && hour < 18)) {
          // 强制日间或处于中午下午时段
          bgPath = 'assets/images/record_daytime2.png';
        } else {
          bgPath = 'assets/images/record_daytime.png';
        }

        // 强制全局居中，解决不同尺寸下的藤蔓对齐问题
        const Alignment bgAlignment = Alignment.center;

        // 构图与缩放优化：在手机端缩小背景并左移，以展示更多细节和灯塔
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 600;

        // 缩放比例：手机端缩小以获得更广阔的视角
        final double bgScale = isMobile ? 0.4 : 1.0;
        // 位移量：手机端位移调整
        final double bgOffsetX = isMobile ? -540.0 : 0.0;
        final double bgOffsetY = isMobile ? 20.0 : 0.0; // 往下移动一点

        return Stack(
          children: [
            // 1. 底层清晰背景 - 配合缩放和垂直/水平位移实现完美构图
            Positioned(
              top: -1000, // 垂直大幅溢出，确保缩小后不露黑边
              bottom: -1000,
              left: -1000, // 水平大幅溢出
              right: -1000,
              child: Transform.scale(
                scale: bgScale,
                child: Transform.translate(
                  offset: Offset(bgOffsetX, bgOffsetY),
                  child: Image.asset(
                    bgPath,
                    fit: BoxFit.cover,
                    alignment: bgAlignment,
                  ),
                ),
              ),
            ),

            // 1.5 氛围层：夜晚萤火虫 (仅在夜晚显示)
            if (isNight) const Positioned.fill(child: FirefliesOverlay()),

            // 2. 主体展示区域 (移除所有转场动效，实现静默瞬显)
            Positioned.fill(
              child: _buildCurrentView(isNight, themeMode),
            ),

            // 3. 顶部导航/选择器 (明确位置在顶部)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // 关键修复：确保展开年份时图标不向下偏移
                    children: [
                      // 左侧占位实现绝对居中
                      Expanded(child: Container()),
                      RecordYearPicker(
                        selectedYear: _selectedYear,
                        onYearChanged: (year) {
                          setState(() {
                            _selectedYear = year;
                          });
                        },
                      ),
                      // 右侧切换按钮
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildViewToggleButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 根据当前模式分发视图
  Widget _buildCurrentView(bool isNight, String themeMode) {
    switch (_viewMode) {
      case RecordViewMode.calendar:
        return _buildCalendarView(isNight);
      case RecordViewMode.bubble:
        return _buildVineBubbleView(isNight);
    }
  }

  /// 构建视图切换按钮
  Widget _buildViewToggleButton() {
    IconData icon;
    switch (_viewMode) {
      case RecordViewMode.calendar:
        icon = Icons.bubble_chart;
        break;
      case RecordViewMode.bubble:
        icon = Icons.calendar_month;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // 循环切换逻辑
          if (_viewMode == RecordViewMode.bubble) {
            _viewMode = RecordViewMode.calendar;
          } else {
            _viewMode = RecordViewMode.bubble;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
          ),
        ),
      ),
    );
  }

  /// 藤蔓泡泡（对话模式）视图
  Widget _buildVineBubbleView(bool isNight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<List<DiaryEntry>>(
          valueListenable: UserState().savedDiaries,
          builder: (context, allDiaries, child) {
            final diaries =
                allDiaries
                    .where((e) => e.dateTime.year == _selectedYear)
                    .toList()
                  ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            if (diaries.isEmpty) {
              return const Center(
                child: Text(
                  '等待新的回忆发芽...',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              );
            }

            const double stepHeight = 160.0;
            final double viewportHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height;
            // 计算记录内容的实际高度
            final double contentHeight = diaries.length * stepHeight + 480.0;
            // 确保滚动区域至少等于视口高度，但若内容不足则不产生强制溢出
            final double totalHeight = math.max(contentHeight, viewportHeight);

            return SizedBox(
              height: viewportHeight,
              width: constraints.maxWidth,
              child: SingleChildScrollView(
                key: const ValueKey('bubble_vine_scroll'),
                physics: const BouncingScrollPhysics(), // 使用平滑物理特性
                child: RepaintBoundary( // 核心优化：隔离背景与内容的绘制压力
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: totalHeight,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // 1. 背景层 (由 VineRenderHelper 统一托管渲染)
                        VineRenderHelper.buildVineImages(
                          totalHeight,
                          isNight: isNight,
                        ),

                        // 2. 气泡内容层
                        ...List.generate(diaries.length, (index) {
                          final diary = diaries[index];
                          final bool isLeft = index % 2 != 0;
                          final double topPos = index * stepHeight + 120;
                          // 核心：计算 Pod 中心的物理 Y 坐标 (基准下移 60px)，实现精准“吸附”
                          final double podCenterY = topPos + 60;
                          final double podX = VineRenderHelper.getVineXAt(
                            podCenterY,
                          );

                          return Positioned(
                            top: topPos,
                            left: 0,
                            right: 0,
                            child:
                                VineBubbleItem(
                                  diary: diary,
                                  isLeft: isLeft,
                                  isNight: isNight,
                                  podXOffset: podX,
                                  yOffset: 0, // 已经在 topPos 中包含了基础偏移
                                  delay: (math.Random().nextInt(400)).ms,
                                ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 恢复：卡片式日历视图
  Widget _buildCalendarView(bool isNight) {
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, child) {
        final yearDiaries = allDiaries
            .where((e) => e.dateTime.year == _selectedYear)
            .toList();

        final Set<int> months = yearDiaries
            .map((e) => e.dateTime.month)
            .toSet();
        final List<int> sortedMonths = months.toList()
          ..sort((a, b) => b.compareTo(a));

        if (sortedMonths.isEmpty) {
          final current = DateTime.now();
          if (current.year == _selectedYear) {
            sortedMonths.add(current.month);
          } else {
            return const Center(
              child: Text('暂无记录', style: TextStyle(color: Colors.white54)),
            );
          }
        }

        return ListView.builder(
          key: const ValueKey('calendar'),
          padding: const EdgeInsets.only(top: 100, bottom: 120),
          itemCount: sortedMonths.length,
          itemBuilder: (context, index) {
            final month = sortedMonths[index];
            final monthDiaries = yearDiaries
                .where((e) => e.dateTime.month == month)
                .toList();

            return MonthCalendarCard(
                  year: _selectedYear,
                  month: month,
                  monthDiaries: monthDiaries,
                  delay: (math.Random().nextInt(300)).ms,
                );
          },
        );
      },
    );
  }
}
