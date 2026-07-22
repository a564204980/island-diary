import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/core/services/wind_service.dart';
import 'package:island_diary/core/models/home_module_config.dart';
import 'package:island_diary/features/home/presentation/widgets/home_card_registry.dart';
import 'package:island_diary/features/home/presentation/widgets/card_repository_sheet.dart';
import 'package:island_diary/features/home/presentation/widgets/wind_bend_card_wrapper.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';


class HomeDashboardView extends StatefulWidget {
  final bool isNight;
  final String themeId;
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;

  const HomeDashboardView({
    super.key,
    required this.isNight,
    required this.themeId,
    required this.groupedEntries,
  });

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  final ValueNotifier<String?> _hoveredSlotModuleId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _hoveredSlotIsTall = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _justDroppedModuleId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _removingModuleId = ValueNotifier<String?>(null);

  /// 显式动画控制器：驱动所有卡片的编辑模式进场/退场动画（缩放 + 倾斜 + 阴影）
  /// 使用 AnimationController 而非 ImplicitlyAnimatedWidget，完全绕开 widget 树协调问题
  late final AnimationController _editModeAnim;

  @override
  void initState() {
    super.initState();
    _editModeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _editModeAnim.dispose();
    _hoveredSlotModuleId.dispose();
    _hoveredSlotIsTall.dispose();
    _justDroppedModuleId.dispose();
    _removingModuleId.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    if (_isEditMode) {
      _editModeAnim.forward(); // 驱动所有卡片平滑进入编辑态
      showTopToast(context, '✨ 已进入编辑模式，可点击 - 移除卡片或拖拽调整顺序');
    } else {
      _editModeAnim.reverse(); // 反向播放退出编辑态
    }
  }

  void _removeModule(HomeModuleItem module, List<HomeModuleItem> allModules) {
    if (_removingModuleId.value != null) return;
    _removingModuleId.value = module.id;
    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 320), () {
      final updated = allModules.map((m) {
        if (m.id == module.id) {
          return m.copyWith(enabled: false);
        }
        return m;
      }).toList();
      UserState().saveHomeModuleConfigs(updated);
      _removingModuleId.value = null;
      if (mounted) {
        showTopToast(context, '✨ 已将「${module.title}」吹回卡片仓库～');
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = UserState().userName.value.isEmpty ? "岛主" : UserState().userName.value;
    if (hour < 5) return "夜深了，$name";
    if (hour < 9) return "早上好，$name";
    if (hour < 12) return "上午好，$name";
    if (hour < 14) return "中午好，$name";
    if (hour < 18) return "下午好，$name";
    if (hour < 22) return "晚上好，$name";
    return "夜深了，$name";
  }

  void _openEditorWithDate(BuildContext context, DateTime date, DiaryEntry? existingEntry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(
          initialDate: date,
          entry: existingEntry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = widget.themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    // 配色系统：融入海洋/云朵背景的清爽温柔冷色调
    final textColor = widget.isNight ? const Color(0xFFE3F2FD) : const Color(0xFF2C4A61);
    final subtitleColor = widget.isNight ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF5A788F);
    final accentColor = widget.isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B);

    // 计算过去7天的日期
    final today = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    // 辅助方法：获取某天的第一条日记记录
    DiaryEntry? getEntryForDate(DateTime date) {
      for (var map in widget.groupedEntries) {
        final key = map.keys.first;
        if (key.year == date.year && key.month == date.month && key.day == date.day) {
          final entries = map.values.first;
          if (entries.isNotEmpty) return entries.first;
        }
      }
      return null;
    }

    final cardCtx = HomeCardBuildContext(
      context: context,
      isNight: widget.isNight,
      themeId: widget.themeId,
      fontFamily: fontFamily,
      textColor: textColor,
      subtitleColor: subtitleColor,
      accentColor: accentColor,
      groupedEntries: widget.groupedEntries,
      last7Days: last7Days,
      getEntryForDate: getEntryForDate,
      openEditorWithDate: (date, entry) => _openEditorWithDate(context, date, entry),
      buildGlassCard: _buildGlassCard,
    );

    final photoThrowbackWidget = _PhotoThrowbackWidget(
      groupedEntries: widget.groupedEntries,
      textColor: textColor,
      subtitleColor: subtitleColor,
      accentColor: accentColor,
      fontFamily: fontFamily,
      isNight: widget.isNight,
    );

    final pianoMoodWidget = _buildGlassCard(
      onTap: null,
      padding: const EdgeInsets.all(12),
      isRow: true,
      child: _PianoMoodSection(
        last7Days: last7Days,
        getEntryForDate: getEntryForDate,
        openEditorWithDate: (date, entry) => _openEditorWithDate(context, date, entry),
        textColor: textColor,
        subtitleColor: subtitleColor,
        accentColor: accentColor,
        fontFamily: fontFamily,
        isNight: widget.isNight,
      ),
    );

    final double bottomPadding = (115.0 + MediaQuery.of(context).padding.bottom).clamp(40.0, 160.0);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: bottomPadding),
        child: ValueListenableBuilder<List<HomeModuleItem>>(
          valueListenable: UserState().homeModuleConfigs,
          builder: (context, allModules, child) {
            final activeModules = allModules.where((m) => m.enabled).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 顶部问候与编辑控制
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _getGreeting(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: fontFamily,
                                            color: textColor,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        widget.isNight ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
                                        size: 22,
                                        color: accentColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ValueListenableBuilder<WindMode>(
                                  valueListenable: WindService.currentWind,
                                  builder: (context, currentWindMode, _) {
                                    final bool isGale = (currentWindMode == WindMode.gale);
                                    return BouncingButton(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        if (isGale) {
                                          WindService.currentWind.value = WindMode.breeze;
                                          UserState().cloudSpeedMultiplier.value = WindMode.breeze.speedMultiplier;
                                          showTopToast(context, '🍃 已恢复微风');
                                        } else {
                                          WindService.currentWind.value = WindMode.gale;
                                          UserState().cloudSpeedMultiplier.value = WindMode.gale.speedMultiplier;
                                          showTopToast(context, '🌬️ 狂风大作！竹子弯腰啦');
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: isGale
                                              ? (widget.isNight
                                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                                                  : const Color(0xFF0284C7).withValues(alpha: 0.2))
                                              : (widget.isNight
                                                  ? Colors.white.withValues(alpha: 0.12)
                                                  : Colors.white.withValues(alpha: 0.5)),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isGale
                                                ? (widget.isNight ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                                : (widget.isNight
                                                    ? Colors.white.withValues(alpha: 0.2)
                                                    : Colors.white.withValues(alpha: 0.6)),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isGale
                                                  ? (widget.isNight ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.2))
                                                  : Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          isGale ? "🌬️ 狂风中" : "🌬️ 狂风",
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: fontFamily,
                                            color: isGale
                                                ? (widget.isNight ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                                : textColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ValueListenableBuilder<List<DiaryEntry>>(
                              valueListenable: UserState().savedDiaries,
                              builder: (context, diaries, child) {
                                return ValueListenableBuilder<WindMode>(
                                  valueListenable: WindService.currentWind,
                                  builder: (context, wind, _) {
                                    return Row(
                                      children: [
                                        Text(
                                          "登岛第 ${diaries.length} 天  ·  打捞韶华里的碎片",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: fontFamily,
                                            color: subtitleColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: widget.isNight
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.white.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            wind.label,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: fontFamily,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // 右上角「完成」按钮（仅在编辑模式下平滑淡入弹起）
                      AnimatedScale(
                        scale: _isEditMode ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: _isEditMode ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_isEditMode,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _toggleEditMode();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "完成",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: fontFamily,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),

                  // 动态渲染的卡片排版流
                  _buildDynamicCardStream(
                    context,
                    activeModules: activeModules,
                    allModules: allModules,
                    cardCtx: cardCtx,
                    pianoMoodWidget: pianoMoodWidget,
                    photoThrowbackWidget: photoThrowbackWidget,
                    fontFamily: fontFamily,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _swapModules(HomeModuleItem item1, HomeModuleItem item2, List<HomeModuleItem> allModules) {
    final updatedAll = List<HomeModuleItem>.from(allModules);
    final idx1 = updatedAll.indexWhere((m) => m.id == item1.id);
    final idx2 = updatedAll.indexWhere((m) => m.id == item2.id);

    if (idx1 != -1 && idx2 != -1 && idx1 != idx2) {
      final temp = updatedAll[idx1];
      updatedAll[idx1] = updatedAll[idx2];
      updatedAll[idx2] = temp;
      UserState().saveHomeModuleConfigs(updatedAll);
    }
  }

  /// 动态卡片流生成器：自动识别经典两列网格与自由流排版，并支持自适应长矮形变
  Widget _buildDynamicCardStream(
    BuildContext context, {
    required List<HomeModuleItem> activeModules,
    required List<HomeModuleItem> allModules,
    required HomeCardBuildContext cardCtx,
    required Widget pianoMoodWidget,
    required Widget photoThrowbackWidget,
    required String fontFamily,
    required Color textColor,
    required Color subtitleColor,
    required Color accentColor,
  }) {
    List<Widget> cardWidgets = [];

    // 识别属于网格组的卡片集合 ('photo_throwback', 'photo_wall', 'gravity_box')
    final processedIds = {'photo_throwback', 'photo_wall', 'gravity_box'};
    final gridModules = activeModules.where((m) => processedIds.contains(m.id)).toList();

    if (gridModules.length >= 2) {

      // 渲染双列网格基于 Stack + AnimatedPositioned 绝对坐标物理平移网格
      // 关键：AnimatedPositioned 必须直接作为 Stack 的子节点且持有 key，
      // Flutter 才能跨 rebuild 通过 key 匹配并驱动平移动画，Builder 包装会阻断此机制
      final classicGridWidget = LayoutBuilder(
        builder: (context, constraints) {
          final double halfWidth = (constraints.maxWidth - 16.0) / 2;
          final bool hasThreeGridModules = gridModules.length >= 3;
          final double gridHeight = hasThreeGridModules ? 296.0 : 140.0;

          // 预先计算每个模块的目标插槽坐标
          List<Widget> stackChildren = [];
          for (int i = 0; i < gridModules.length; i++) {
            final mod = gridModules[i];
            final bool isLeft = (i == 0 && hasThreeGridModules);
            final double left = (i == 0) ? 0.0 : (halfWidth + 16.0);
            final double top = (i == 0 || i == 1) ? 0.0 : (140.0 + 16.0);
            final double cardHeight = isLeft ? 296.0 : 140.0;

            Widget contentChild;
            if (mod.id == 'photo_throwback') {
              contentChild = _PhotoThrowbackWidget(
                groupedEntries: widget.groupedEntries,
                textColor: textColor,
                subtitleColor: subtitleColor,
                accentColor: accentColor,
                fontFamily: fontFamily,
                isNight: widget.isNight,
                isTall: isLeft,
              );
            } else {
              contentChild = HomeCardRegistry.buildCard(
                mod.id,
                cardCtx,
                pianoMoodWidget,
                photoThrowbackWidget,
                isTall: isLeft,
                isEditMode: _isEditMode,
              );
            }

            // AnimatedPositioned 直接进入 stackChildren，不套 Builder
            // 这样 Flutter 可以通过 key 找到同一个模块的旧 AnimatedPositioned 并驱动动画
            stackChildren.add(
              AnimatedPositioned(
                key: ValueKey(mod.id),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                left: left,
                top: top,
                width: halfWidth,
                height: cardHeight,
                child: _buildCardWrapper(
                  module: mod,
                  child: contentChild,
                  isEditMode: _isEditMode,
                  activeIndex: activeModules.indexOf(mod),
                  activeTotal: activeModules.length,
                  allModules: allModules,
                  onRemove: () => _removeModule(mod, allModules),
                  cardCtx: cardCtx,
                  pianoMoodWidget: pianoMoodWidget,
                  photoThrowbackWidget: photoThrowbackWidget,
                  isLeftColumn: isLeft,
                ),
              ),
            );
          }

          return SizedBox(
            height: gridHeight,
            width: constraints.maxWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: stackChildren,
            ),
          );
        },
      );

      // 处理其他非网格组的卡片（如近七日心情、每日灵感等）
      bool classicGridAdded = false;

      for (int i = 0; i < activeModules.length; i++) {
        final mod = activeModules[i];
        if (processedIds.contains(mod.id)) {
          if (!classicGridAdded) {
            cardWidgets.add(classicGridWidget);
            classicGridAdded = true;
          }
        } else {
          cardWidgets.add(
            _buildCardWrapper(
              module: mod,
              child: HomeCardRegistry.buildCard(mod.id, cardCtx, pianoMoodWidget, photoThrowbackWidget, isEditMode: _isEditMode),
              isEditMode: _isEditMode,
              activeIndex: i,
              activeTotal: activeModules.length,
              allModules: allModules,
              onRemove: () => _removeModule(mod, allModules),
              cardCtx: cardCtx,
              pianoMoodWidget: pianoMoodWidget,
              photoThrowbackWidget: photoThrowbackWidget,
            ),
          );
        }
      }
    } else {
      // 自由自适应流：依次平铺所有开启的卡片
      for (int i = 0; i < activeModules.length; i++) {
        final mod = activeModules[i];
        cardWidgets.add(
          _buildCardWrapper(
            module: mod,
            child: HomeCardRegistry.buildCard(mod.id, cardCtx, pianoMoodWidget, photoThrowbackWidget, isEditMode: _isEditMode),
            isEditMode: _isEditMode,
            activeIndex: i,
            activeTotal: activeModules.length,
            allModules: allModules,
            onRemove: () => _removeModule(mod, allModules),
            cardCtx: cardCtx,
            pianoMoodWidget: pianoMoodWidget,
            photoThrowbackWidget: photoThrowbackWidget,
          ),
        );
      }
    }

    final inactiveModules = allModules.where((m) => !m.enabled).toList();
    final bool shouldShowAddBtn = _isEditMode &&
        (activeModules.length == 3 || inactiveModules.isNotEmpty);

    return Column(
      children: [
        for (int i = 0; i < cardWidgets.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          cardWidgets[i].animate().fade(duration: 500.ms, delay: (100 * i).ms),
        ],
        if (shouldShowAddBtn) ...[
          const SizedBox(height: 16),
          _buildAddModuleButton(
            context,
            allModules: allModules,
            cardCtx: cardCtx,
            fontFamily: fontFamily,
            textColor: textColor,
            subtitleColor: subtitleColor,
            accentColor: accentColor,
          ),
        ],
      ],
    );
  }

  /// 实时计算给定模块列表在当前屏幕渲染下的预估总高度（包含组件间 16px 边距）
  double _calculateDashboardContentHeight(List<HomeModuleItem> modules) {
    if (modules.isEmpty) return 0.0;

    final processedIds = {'photo_throwback', 'photo_wall', 'gravity_box'};
    final gridModules = modules.where((m) => processedIds.contains(m.id)).toList();
    final otherModules = modules.where((m) => !processedIds.contains(m.id)).toList();

    double totalHeight = 0.0;
    int groupCount = 0;

    // 1. 经典网格组高度
    if (gridModules.isNotEmpty) {
      if (gridModules.length >= 3) {
        totalHeight += 296.0;
      } else {
        totalHeight += 140.0;
      }
      groupCount++;
    }

    // 2. 通栏/独立卡片高度
    for (var mod in otherModules) {
      if (mod.id == 'piano_mood') {
        totalHeight += 145.0;
      } else if (mod.id == 'inspiration_quote') {
        totalHeight += 110.0;
      } else {
        totalHeight += 140.0;
      }
      groupCount++;
    }

    // 3. 各卡片/组之间的 16px 垂直边距
    if (groupCount > 1) {
      totalHeight += (groupCount - 1) * 16.0;
    }

    return totalHeight;
  }

  /// 获取当前设备屏幕在避开顶部状态栏、问候标头以及底部悬浮菜单栏后的净可用卡片高度
  double _getMaxAvailableDashboardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topReserved = MediaQuery.of(context).padding.top + 70.0 + 48.0;
    final bottomReserved = 115.0 + MediaQuery.of(context).padding.bottom;
    return (screenHeight - topReserved - bottomReserved).clamp(100.0, 2000.0);
  }

  /// 校验新增指定模块后，总高度是否会超出可用屏幕容量（避免被底部小软/菜单栏遮挡）
  bool _canAddModule(BuildContext context, List<HomeModuleItem> activeModules, HomeModuleItem itemToAdd) {
    final testList = List<HomeModuleItem>.from(activeModules)..add(itemToAdd);
    final projectedHeight = _calculateDashboardContentHeight(testList);
    final maxHeight = _getMaxAvailableDashboardHeight(context);
    return projectedHeight <= maxHeight;
  }

  /// 渲染编辑模式下网格下方的“扩充或添加新模块”高颜值按钮
  Widget _buildAddModuleButton(
    BuildContext context, {
    required List<HomeModuleItem> allModules,
    required HomeCardBuildContext cardCtx,
    required String fontFamily,
    required Color textColor,
    required Color subtitleColor,
    required Color accentColor,
  }) {
    final inactiveModules = allModules.where((m) => !m.enabled).toList();
    final isDark = widget.isNight;
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return BouncingButton(
      scaleFactor: 0.96,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (inactiveModules.isEmpty) {
          showTopToast(context, '✨ 所有的岛屿特色卡片都已经展示在主页啦～');
          return;
        }

        final activeModules = allModules.where((m) => m.enabled).toList();

        CardRepositorySheet.show(
          context,
          isNight: isDark,
          fontFamily: fontFamily,
          textColor: textColor,
          subtitleColor: subtitleColor,
          accentColor: accentColor,
          inactiveModules: inactiveModules,
          onAddModule: (item) {
            if (!_canAddModule(context, activeModules, item)) {
              showTopToast(context, '✨ 屏幕空间有限，请先移除部分卡片后再添加「${item.title}」哦～');
              return;
            }

            final updatedAll = List<HomeModuleItem>.from(allModules);
            final idx = updatedAll.indexWhere((m) => m.id == item.id);
            if (idx != -1) {
              updatedAll[idx].enabled = true;
              UserState().saveHomeModuleConfigs(updatedAll);
              showTopToast(context, '🎉 已将「${item.title}」添加到主页');
            }
          },
          onResetDefault: () {
            UserState().saveHomeModuleConfigs(HomeModuleItem.getDefaultModules());
            showTopToast(context, '🔄 已恢复默认卡片排版');
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "添加更多小组件",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: fontFamily,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 350.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  /// 封装单张卡片在编辑模式下的高级弹性拖拽、有机微倾斜与角标旋转弹起动效
  Widget _buildCardWrapper({
    required HomeModuleItem module,
    required Widget child,
    required bool isEditMode,
    required int activeIndex,
    required int activeTotal,
    required List<HomeModuleItem> allModules,
    required VoidCallback onRemove,
    required HomeCardBuildContext cardCtx,
    required Widget pianoMoodWidget,
    required Widget photoThrowbackWidget,
    bool isLeftColumn = false,
  }) {
    // 用 AnimatedBuilder 直接监听 _editModeAnim controller，
    // 确保每帧都能可靠驱动缩放/倾斜/阴影动画，完全不依赖 widget 树协调
    final double tiltSign = activeIndex % 2 == 0 ? 1.0 : -1.0;
    final shadowColor = widget.isNight ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    Widget cardBody = AnimatedBuilder(
      animation: _editModeAnim,
      builder: (context, innerChild) {
        final double t = _editModeAnim.value;
        // easeOutBack 手感曲线
        final double curved = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
        return Transform.rotate(
          angle: curved * 0.035 * tiltSign,
          child: Transform.scale(
            scale: 1.0 - curved * 0.035, // 1.0 → 0.965
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: t > 0.01
                    ? [
                        BoxShadow(
                          color: shadowColor.withValues(alpha: 0.25 * t),
                          blurRadius: 20 * t,
                          spreadRadius: 2 * t,
                        ),
                      ]
                    : [],
              ),
              child: innerChild,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            ignoring: isEditMode,
            child: WindBendCardWrapper(
              isTall: isLeftColumn || module.isFullWidth,
              child: child,
            ),
          ),

          // 右上角红圈 - 移除图标 (旋转 + 弹簧回弹淡入)
          Positioned(
            top: -6,
            right: -6,
            child: AnimatedRotation(
              turns: isEditMode ? 0.0 : -0.1,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                scale: isEditMode ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: isEditMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: !isEditMode,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onRemove();
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE63946),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.remove_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 左上角锁头角标 - 固定通栏指示器 (编辑模式下显示)
          Positioned(
            top: -6,
            left: 12,
            child: AnimatedScale(
              scale: isEditMode && module.isFullWidth ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: isEditMode && module.isFullWidth ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: widget.isNight
                        ? Colors.black.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isNight
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: cardCtx.accentColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "固定通栏",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: cardCtx.fontFamily,
                          color: cardCtx.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // 统一 Widget 结构，保证进入/退出编辑模式时 AnimatedRotation 与 AnimatedScale 拥有完整平滑的过渡动画
    return DragTarget<HomeModuleItem>(
      key: ValueKey(module.id),
      onWillAcceptWithDetails: (details) {
        if (isEditMode && details.data.id != module.id) {
          // 上锁固定通栏模块不参与拖拽放置与位置交换
          if (details.data.isFullWidth || module.isFullWidth) {
            return false;
          }
          _hoveredSlotModuleId.value = details.data.id;
          _hoveredSlotIsTall.value = isLeftColumn;
          return true;
        }
        return false;
      },
      onLeave: (data) {
        if (data != null && data.id == _hoveredSlotModuleId.value) {
          _hoveredSlotModuleId.value = null;
        }
      },
      onAcceptWithDetails: (details) {
        _hoveredSlotModuleId.value = null;
        if (!isEditMode) return;
        HapticFeedback.mediumImpact();
        _swapModules(details.data, module, allModules);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = isEditMode && candidateData.isNotEmpty;

        final Widget cardBodyWithDrop = ValueListenableBuilder<String?>(
          valueListenable: _justDroppedModuleId,
          builder: (context, droppedId, _) {
            final bool isJustDropped = (droppedId == module.id);
            if (!isJustDropped) return cardBody;

            return TweenAnimationBuilder<double>(
              key: ValueKey('drop_${module.id}'),
              tween: Tween<double>(begin: 1.08, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              onEnd: () {
                _justDroppedModuleId.value = null;
              },
              builder: (context, dropScale, child) {
                return Transform.scale(
                  scale: dropScale,
                  child: child,
                );
              },
              child: cardBody,
            );
          },
        );

        final Widget cardBodyWithWind = ValueListenableBuilder<String?>(
          valueListenable: _removingModuleId,
          builder: (context, removingId, child) {
            final bool isRemoving = (removingId == module.id);
            if (!isRemoving) return child!;

            return TweenAnimationBuilder<double>(
              key: ValueKey('wind_remove_${module.id}'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, t, innerChild) {
                final double opacity = (1.0 - t).clamp(0.0, 1.0);
                final double translateY = -75.0 * t; // 顺风向上飘起 75px
                final double translateX = -25.0 * tiltSign * t; // 沿卡片倾斜方向向侧面微飘 25px
                final double extraAngle = 0.14 * tiltSign * t; // 随风旋转 8°
                final double scale = 1.0 - 0.3 * t; // 逐渐微缩

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(translateX, translateY),
                    child: Transform.rotate(
                      angle: extraAngle,
                      child: Transform.scale(
                        scale: scale,
                        child: innerChild,
                      ),
                    ),
                  ),
                );
              },
              child: child,
            );
          },
          child: cardBodyWithDrop,
        );

        final Widget innerCard = AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: isHovered
                ? Border.all(
                    color: widget.isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B),
                    width: 3.5,
                  )
                : null,
          ),
          child: cardBodyWithWind,
        );

        // 卡片交换时的软弹簧平滑位移与放手落座动画
        final Widget animatedCard = AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('${module.id}_$activeIndex'),
            child: innerCard,
          ),
        );

        final double targetWidth = (module.id == 'photo_throwback' || module.id == 'photo_wall' || module.id == 'gravity_box')
            ? 165.0
            : (MediaQuery.of(context).size.width - 48.0);

        final double startScale = isEditMode ? 0.965 : 1.0;
        final double startAngle = isEditMode ? (0.035 * tiltSign) : 0.0;
        final double targetAngle = 0.035 * tiltSign;

        final Widget feedbackWidget = ValueListenableBuilder<String?>(
          valueListenable: _hoveredSlotModuleId,
          builder: (context, hoveredId, _) {
            final bool effectiveIsTall = (hoveredId == module.id)
                ? _hoveredSlotIsTall.value
                : isLeftColumn;

            Widget dynamicFeedbackChild;
            if (module.id == 'photo_throwback') {
              dynamicFeedbackChild = _PhotoThrowbackWidget(
                groupedEntries: widget.groupedEntries,
                textColor: cardCtx.textColor,
                subtitleColor: cardCtx.subtitleColor,
                accentColor: cardCtx.accentColor,
                fontFamily: cardCtx.fontFamily,
                isNight: widget.isNight,
                isTall: effectiveIsTall,
              );
            } else {
              dynamicFeedbackChild = HomeCardRegistry.buildCard(
                module.id,
                cardCtx,
                pianoMoodWidget,
                photoThrowbackWidget,
                isTall: effectiveIsTall,
                isEditMode: _isEditMode,
              );
            }

            return Material(
              color: Colors.transparent,
              child: SizedBox(
                width: targetWidth,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  builder: (context, animValue, innerChild) {
                    final double currentScale = lerpDouble(startScale, 1.05, animValue)!;
                    final double currentAngle = lerpDouble(startAngle, targetAngle, animValue)!;
                    return Transform.rotate(
                      angle: currentAngle,
                      child: Transform.scale(
                        scale: currentScale,
                        child: innerChild,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: effectiveIsTall ? 296.0 : 140.0,
                    child: dynamicFeedbackChild,
                  ),
                ),
              ),
            );
          },
        );

        // 固定通栏模块 (isFullWidth) 处于上锁状态：
        // 1. 禁止拖拽位移
        // 2. 但在非编辑模式下长按依然可以触发进入编辑模式 (图1状态)
        if (module.isFullWidth) {
          if (!isEditMode) {
            return GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _toggleEditMode();
              },
              child: animatedCard,
            );
          }
          return animatedCard;
        }

        // 长按 500ms 后触发拖拽，同时进入编辑模式并播放 AnimatedBuilder 动画
        // 不再提前 300ms 进入编辑态，避免产生不必要的图2中间状态
        return LongPressDraggable<HomeModuleItem>(
          data: module,
          delay: isEditMode ? const Duration(milliseconds: 100) : const Duration(milliseconds: 500),
          onDragStarted: () {
            HapticFeedback.mediumImpact();
            // 拖拽开始时同步激活编辑模式，AnimatedBuilder 驱动所有卡片平滑进场动画
            if (!_isEditMode) {
              _toggleEditMode();
            }
          },
          onDragEnd: (details) {
            _justDroppedModuleId.value = module.id;
          },
          onDraggableCanceled: (velocity, offset) {
            _justDroppedModuleId.value = module.id;
          },
          feedback: feedbackWidget,
          childWhenDragging: Opacity(
            opacity: 0.2,
            child: Transform.rotate(
              angle: 0.035 * tiltSign,
              child: Transform.scale(
                scale: 0.965,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
          child: animatedCard,
        );
      },
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    bool isRow = false,
    double? height,
  }) {
    final cardBg = widget.isNight
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.18);
    final borderColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.45);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: isRow ? null : (height ?? 140),
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// 左侧：大方块时光相框组件 (那年今日)
class _PhotoThrowbackWidget extends StatefulWidget {
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;
  final bool isTall;

  const _PhotoThrowbackWidget({
    required this.groupedEntries,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
    this.isTall = true,
  });

  @override
  State<_PhotoThrowbackWidget> createState() => _PhotoThrowbackWidgetState();
}

class _PhotoThrowbackWidgetState extends State<_PhotoThrowbackWidget> {
  static String? _cachedSessionImagePath;

  @override
  void initState() {
    super.initState();
    _ensureSessionImage();
  }

  @override
  void didUpdateWidget(covariant _PhotoThrowbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSessionImage();
  }

  void _ensureSessionImage() {
    // 若已有有效缓存，直接保留不刷新
    if (_cachedSessionImagePath != null) {
      if (_cachedSessionImagePath!.startsWith('assets/')) return;
      if (File(_cachedSessionImagePath!).existsSync()) return;
    }

    final validPaths = <String>[];

    // 1. 与 PhotoWallCard 一致：优先从 groupedEntries 提取有真实文件的相片
    for (var group in widget.groupedEntries) {
      for (var entryList in group.values) {
        for (var entry in entryList) {
          for (var block in entry.blocks) {
            if (block['type'] == 'image' && block['path'] != null) {
              final p = block['path'].toString();
              if (File(p).existsSync()) {
                validPaths.add(p);
              }
            }
          }
        }
      }
    }

    // 2. 兜底全量检索 UserState().savedDiaries
    if (validPaths.isEmpty) {
      for (var entry in UserState().savedDiaries.value) {
        for (var block in entry.blocks) {
          if (block['type'] == 'image') {
            final p = (block['path'] ?? block['url'] ?? block['value'] ?? block['imagePath'])?.toString();
            if (p != null && File(p).existsSync()) {
              validPaths.add(p);
            }
          }
        }
      }
    }

    if (validPaths.isNotEmpty) {
      final random = math.Random();
      _cachedSessionImagePath = validPaths[random.nextInt(validPaths.length)];
    } else if (UserState().savedDiaries.value.isNotEmpty || widget.groupedEntries.isNotEmpty) {
      // 3. 只要岛上有日记数据，默认精选一张岛屿回忆插画背景图
      final presetBgs = [
        'assets/images/emoji/modules_bg/4.png',
        'assets/images/emoji/modules_bg/5.png',
        'assets/images/emoji/modules_bg/6.png',
        'assets/images/emoji/modules_bg/7.png',
        'assets/images/emoji/modules_bg/8.png',
        'assets/images/emoji/modules_bg/9.png',
        'assets/images/emoji/modules_bg/10.png',
        'assets/images/emoji/modules_bg/11.png',
        'assets/images/emoji/modules_bg/12.png',
      ];
      final random = math.Random();
      _cachedSessionImagePath = presetBgs[random.nextInt(presetBgs.length)];
    } else {
      _cachedSessionImagePath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _cachedSessionImagePath;
    final borderColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.45);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity, // 始终撑满父容器宽度，无论是长方块还是矮方块插槽
      height: widget.isTall ? 296 : 140, // 296 时为长方块，140 时自动变成矮方块！
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: imagePath != null
            ? Stack(
                children: [
                  // 相片层
                  Positioned.fill(
                    child: imagePath.startsWith('assets/')
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildFallbackContent(),
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildFallbackContent(),
                          ),
                  ),

                  // 渐变阴影层：在有用户照片时叠加黑色渐变遮罩以保证白色文字可读性
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 内容层（有照片时）
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "随机掉落的记忆碎片",
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: widget.fontFamily,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _buildFallbackContent(),
      ),
    );
  }

  Widget _buildFallbackContent() {
    final isDark = widget.isNight;
    final accent = widget.accentColor;
    final subCol = widget.subtitleColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(23),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.20),
                ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部艺术感拍立得空状态插图
          Expanded(
            child: Center(
              child: Container(
                width: 90,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.4),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 相框底衬
                    Icon(
                      Icons.filter_hdr_rounded,
                      size: 40,
                      color: accent.withValues(alpha: 0.65),
                    ),
                    // 右上角微光闪烁星芒
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 0, end: -6, duration: 2500.ms, curve: Curves.easeInOutSine),
            ),
          ),

          // 底部标题与精致副标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "随机掉落的记忆碎片",
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: widget.fontFamily,
                  color: subCol,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

/// 右侧下方：正念呼吸小组件
class _MindfulBreathingWidget extends StatefulWidget {
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;

  const _MindfulBreathingWidget({
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
  });

  @override
  State<_MindfulBreathingWidget> createState() => _MindfulBreathingWidgetState();
}

class _MindfulBreathingWidgetState extends State<_MindfulBreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 10秒一个呼吸循环 (4秒吸气，2秒屏息，4秒呼气)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.55, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              Icons.spa_outlined,
              size: 16,
              color: widget.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              "正念空间",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: widget.fontFamily,
                color: widget.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "吸气... 呼气...",
          style: TextStyle(
            fontSize: 11,
            fontFamily: widget.fontFamily,
            color: widget.subtitleColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = _scaleAnimation.value;
                final opacity = _opacityAnimation.value;
                return Container(
                  width: 52 * scale,
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor.withValues(alpha: opacity * 0.5),
                        widget.accentColor.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: opacity * 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: opacity * 0.15),
                        blurRadius: 12 * scale,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 音符粒子数据模型
class _NoteParticleData {
  final String id;
  final int keyIndex;
  final String noteText;

  _NoteParticleData({
    required this.id,
    required this.keyIndex,
    required this.noteText,
  });
}

/// 近七日心情 - 琴键与音符联动组件
class _PianoMoodSection extends StatefulWidget {
  final List<DateTime> last7Days;
  final DiaryEntry? Function(DateTime date) getEntryForDate;
  final Function(DateTime date, DiaryEntry? entry) openEditorWithDate;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;

  const _PianoMoodSection({
    required this.last7Days,
    required this.getEntryForDate,
    required this.openEditorWithDate,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
  });

  @override
  State<_PianoMoodSection> createState() => _PianoMoodSectionState();
}

class _PianoMoodSectionState extends State<_PianoMoodSection> {
  // 7 个经典的音符名称符
  static const List<String> _notes = ['♪ Do', '♫ Re', '♬ Mi', '♩ Fa', '♭ Sol', '♮ La', '♯ Ti'];
  final List<_NoteParticleData> _activeParticles = [];

  void _triggerNoteParticle(int index) {
    final noteText = _notes[index % _notes.length];
    final particle = _NoteParticleData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      keyIndex: index,
      noteText: noteText,
    );

    setState(() {
      _activeParticles.add(particle);
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() {
          _activeParticles.removeWhere((p) => p.id == particle.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: widget.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                "近七日心情",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: widget.fontFamily,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final double keyWidth = constraints.maxWidth / 7.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. 7 个天数胶囊 (外观与形状 100% 保持完全不变)
                Row(
                  children: List.generate(7, (index) {
                    final date = widget.last7Days[index];
                    final entry = widget.getEntryForDate(date);
                    final moodIndex = entry?.moodIndex;
                    final mood = (moodIndex != null && moodIndex >= 0 && moodIndex < kMoods.length)
                        ? kMoods[moodIndex]
                        : null;

                    double gradientStart = 0.7;
                    if (entry != null && entry.content.isNotEmpty) {
                      final length = entry.content.length;
                      gradientStart = 0.7 - (length / 300) * 0.7;
                      if (gradientStart < 0.0) gradientStart = 0.0;
                    }

                    return Expanded(
                      child: BouncingButton(
                        onTap: () async {
                          // 按压琴键触发对应的蹦出音符离场动效
                          _triggerNoteParticle(index);

                          await Future.delayed(const Duration(milliseconds: 150));
                          if (context.mounted) {
                            widget.openEditorWithDate(date, entry);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: mood != null
                                ? null
                                : (widget.isNight
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.2)),
                            gradient: mood != null
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [gradientStart, 1.0],
                                    colors: [
                                      widget.isNight
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.65),
                                      (mood.glowColor ?? Colors.grey)
                                          .withValues(alpha: widget.isNight ? 0.25 : 0.15),
                                    ],
                                  )
                                : null,
                            border: Border.all(
                              color: mood != null
                                  ? (mood.glowColor ?? Colors.grey)
                                      .withValues(alpha: widget.isNight ? 0.3 : 0.2)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${date.day}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: widget.fontFamily,
                                  color: widget.textColor.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              mood != null && mood.iconPath != null
                                  ? Image.asset(mood.iconPath!, width: 30, height: 30)
                                  : Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color: widget.subtitleColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              Text(
                                mood != null ? mood.label : " ",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: widget.fontFamily,
                                  color: widget.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // 2. 按压琴键从顶端欢快蹦出的音符粒子层 (Do, Re, Mi, Fa, Sol, La, Ti)
                ..._activeParticles.map((particle) {
                  final double noteLeft = particle.keyIndex * keyWidth + (keyWidth / 2.0) - 20;

                  return Positioned(
                    key: ValueKey(particle.id),
                    left: noteLeft,
                    top: -6,
                    child: IgnorePointer(
                      child: Text(
                        particle.noteText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.isNight
                              ? const Color(0xFFE29578)
                              : widget.accentColor,
                          shadows: [
                            Shadow(
                              color: widget.isNight
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.8),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .moveY(begin: 0, end: -36, duration: 750.ms, curve: Curves.easeOutBack)
                    .scale(begin: const Offset(0.4, 0.4), end: const Offset(1.15, 1.15), duration: 750.ms, curve: Curves.easeOutBack)
                    .fadeOut(delay: 400.ms, duration: 350.ms),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}

