import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/core/services/wind_service.dart';
import 'package:island_diary/core/models/home_module_config.dart';
import 'package:island_diary/features/home/presentation/widgets/home_card_registry.dart';
import 'package:island_diary/features/home/presentation/widgets/dashboard/photo_throwback_widget.dart';
import 'package:island_diary/features/home/presentation/widgets/dashboard/piano_mood_section.dart';
import 'package:island_diary/features/home/presentation/widgets/dashboard/home_card_wrapper.dart';
import 'package:island_diary/features/home/presentation/widgets/dashboard/home_add_module_button.dart';


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
  bool _tallSlotIsOnRight = false;
  int? _hoveredColumnIndex;
  int? _lastVibratedColumn;
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
      duration: const Duration(milliseconds: 350),
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
    });
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6 || hour >= 18 || widget.isNight) {
      return Icons.nights_stay_outlined;
    }
    return Icons.wb_sunny_outlined;
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

    final photoThrowbackWidget = PhotoThrowbackWidget(
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
      child: PianoMoodSection(
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
                                        _getGreetingIcon(),
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
                                        } else {
                                          WindService.currentWind.value = WindMode.gale;
                                          UserState().cloudSpeedMultiplier.value = WindMode.gale.speedMultiplier;
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
    if (idx1 == -1 || idx2 == -1) return;

    // 普通情况：直接对调两张卡片在列表中的位置，各自保留 isFullWidth 不变
    HomeModuleItem newAt1 = item2;
    HomeModuleItem newAt2 = item1;

    // 相机卡片（camera_widget）特殊规则：
    if (item1.id == 'camera_widget' && !item1.isFullWidth && !item2.isFullWidth) {
      newAt1 = item2.copyWith(isFullWidth: false);
      newAt2 = item1.copyWith(isFullWidth: true);
    }

    updatedAll[idx1] = newAt1;
    updatedAll[idx2] = newAt2;

    _justDroppedModuleId.value = item1.id;
    UserState().saveHomeModuleConfigs(updatedAll);
  }

  /// 长模块（高卡片）跨列与多小模块进行整列对调
  void _swapColumnModules(HomeModuleItem tallModule, {required bool targetIsRightColumn, required List<HomeModuleItem> allModules}) {
    final updatedAll = List<HomeModuleItem>.from(allModules);
    final gridModules = updatedAll.where((m) => !m.isFullWidth).toList();
    if (gridModules.length < 3) return;

    final tallIndex = gridModules.indexWhere((m) => m.id == tallModule.id);
    if (tallIndex == -1) return;

    final smallModules = gridModules.where((m) => m.id != tallModule.id).toList();

    List<HomeModuleItem> newGridOrder;
    if (targetIsRightColumn) {
      // 长模块移至右列：小模块1、小模块2放在左列，长模块放在右列
      newGridOrder = [...smallModules, tallModule];
      setState(() => _tallSlotIsOnRight = true);
    } else {
      // 长模块移至左列：长模块放在左列，小模块1、小模块2放在右列
      newGridOrder = [tallModule, ...smallModules];
      setState(() => _tallSlotIsOnRight = false);
    }

    int gridIdx = 0;
    for (int i = 0; i < updatedAll.length; i++) {
      if (!updatedAll[i].isFullWidth) {
        updatedAll[i] = newGridOrder[gridIdx++];
      }
    }

    _justDroppedModuleId.value = tallModule.id;
    UserState().saveHomeModuleConfigs(updatedAll);
  }

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

    // 识别属于网格组的卡片集合（所有未设置为通栏的半宽小模块）
    final gridModules = activeModules.where((m) => !m.isFullWidth).toList();
    final processedIds = gridModules.map((m) => m.id).toSet();

    if (gridModules.length >= 2) {

      // 渲染双列网格基于 Stack + AnimatedPositioned 绝对坐标物理平移网格
      final classicGridWidget = LayoutBuilder(
        builder: (context, constraints) {
          final double halfWidth = (constraints.maxWidth - 16.0) / 2;
          final bool hasThreeGridModules = gridModules.length >= 3;
          final double gridHeight = hasThreeGridModules ? 296.0 : 140.0;

          // 动态识别高槽位：绝对由槽位与 _tallSlotIsOnRight 决定，不与特定卡片 ID 绑死
          final bool tallIsOnRight = _tallSlotIsOnRight;
          final int tallModuleIndex = (hasThreeGridModules && tallIsOnRight) ? 2 : 0;
          final HomeModuleItem? tallModule = hasThreeGridModules ? gridModules[tallModuleIndex] : null;

          // 预先计算每个模块的目标插槽坐标
          List<Widget> stackChildren = [];

          // 【核心层级修正】：将列级 DragTarget 与 Ghost 预判框放在 Stack 最底层（index 较小处）
          // 这样只有当拖拽未精准落在某张子卡片卡面上（如落在缝隙/空白区）时，才会降级由列级 DragTarget 捕获；
          // 只要精准悬停在具体小卡面上，上层的子卡片 DragTarget 将优先响应 1对1 点对点交换（任意小卡片移入高槽自动伸展变长）
          if (_isEditMode && hasThreeGridModules && tallModule != null) {
            // 1. 左列 DragTarget (当长模块处于右列且拖至左半区缝隙时激活)
            stackChildren.add(
              Positioned(
                left: 0,
                top: 0,
                width: halfWidth,
                height: gridHeight,
                child: DragTarget<HomeModuleItem>(
                  onWillAcceptWithDetails: (details) {
                    if (tallIsOnRight && details.data.id == tallModule.id) {
                      if (_lastVibratedColumn != 0) {
                        _lastVibratedColumn = 0;
                        HapticFeedback.selectionClick();
                      }
                      if (_hoveredColumnIndex != 0) {
                        setState(() => _hoveredColumnIndex = 0);
                      }
                      return true;
                    }
                    return false;
                  },
                  onLeave: (data) {
                    if (_hoveredColumnIndex == 0) {
                      setState(() {
                        _hoveredColumnIndex = null;
                        _lastVibratedColumn = null;
                      });
                    }
                  },
                  onAcceptWithDetails: (details) {
                    setState(() {
                      _hoveredColumnIndex = null;
                      _lastVibratedColumn = null;
                    });
                    HapticFeedback.mediumImpact();
                    _swapColumnModules(details.data, targetIsRightColumn: false, allModules: allModules);
                  },
                  builder: (context, candidateData, rejectedData) => const SizedBox.expand(),
                ),
              ),
            );

            // 2. 右列 DragTarget (当长模块处于左列且拖至右半区缝隙时激活)
            stackChildren.add(
              Positioned(
                left: halfWidth + 16.0,
                top: 0,
                width: halfWidth,
                height: gridHeight,
                child: DragTarget<HomeModuleItem>(
                  onWillAcceptWithDetails: (details) {
                    if (!tallIsOnRight && details.data.id == tallModule.id) {
                      if (_lastVibratedColumn != 1) {
                        _lastVibratedColumn = 1;
                        HapticFeedback.selectionClick();
                      }
                      if (_hoveredColumnIndex != 1) {
                        setState(() => _hoveredColumnIndex = 1);
                      }
                      return true;
                    }
                    return false;
                  },
                  onLeave: (data) {
                    if (_hoveredColumnIndex == 1) {
                      setState(() {
                        _hoveredColumnIndex = null;
                        _lastVibratedColumn = null;
                      });
                    }
                  },
                  onAcceptWithDetails: (details) {
                    setState(() {
                      _hoveredColumnIndex = null;
                      _lastVibratedColumn = null;
                    });
                    HapticFeedback.mediumImpact();
                    _swapColumnModules(details.data, targetIsRightColumn: true, allModules: allModules);
                  },
                  builder: (context, candidateData, rejectedData) => const SizedBox.expand(),
                ),
              ),
            );

            // 3. 跨列拖拽吸附预判框 (Ghost Slot Preview)
            if (_hoveredColumnIndex != null) {
              final double ghostLeft = (_hoveredColumnIndex == 0) ? 0.0 : (halfWidth + 16.0);
              stackChildren.add(
                Positioned(
                  left: ghostLeft,
                  top: 0,
                  width: halfWidth,
                  height: 296.0,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B),
                          width: 2.5,
                        ),
                        color: (widget.isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B))
                            .withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B))
                                .withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // 接下来将具体的卡片 AnimatedPositioned 添加到 Stack 上层（index 较大处），优先获得 Hit Test 响应
          for (int i = 0; i < gridModules.length; i++) {
            final mod = gridModules[i];

            bool isLeft = false;
            double left = 0.0;
            double top = 0.0;
            double cardHeight = 140.0;

            if (hasThreeGridModules) {
              if (tallIsOnRight) {
                // 长模块在右列
                if (i == tallModuleIndex) {
                  isLeft = false;
                  left = halfWidth + 16.0;
                  top = 0.0;
                  cardHeight = 296.0;
                } else {
                  isLeft = true;
                  left = 0.0;
                  top = (i == 0) ? 0.0 : (140.0 + 16.0);
                  cardHeight = 140.0;
                }
              } else {
                // 长模块在左列
                if (i == 0) {
                  isLeft = true;
                  left = 0.0;
                  top = 0.0;
                  cardHeight = 296.0;
                } else {
                  isLeft = false;
                  left = halfWidth + 16.0;
                  top = (i == 1) ? 0.0 : (140.0 + 16.0);
                  cardHeight = 140.0;
                }
              }
            } else {
              left = (i == 0) ? 0.0 : (halfWidth + 16.0);
              top = 0.0;
              cardHeight = 140.0;
            }

            Widget contentChild;
            if (mod.id == 'photo_throwback') {
              contentChild = PhotoThrowbackWidget(
                groupedEntries: widget.groupedEntries,
                textColor: textColor,
                subtitleColor: subtitleColor,
                accentColor: accentColor,
                fontFamily: fontFamily,
                isNight: widget.isNight,
                isTall: (i == tallModuleIndex && hasThreeGridModules),
              );
            } else {
              contentChild = HomeCardRegistry.buildCard(
                mod.id,
                cardCtx,
                pianoMoodWidget,
                photoThrowbackWidget,
                isTall: (i == tallModuleIndex && hasThreeGridModules),
                isEditMode: _isEditMode,
              );
            }

            // AnimatedPositioned 直接进入 stackChildren
            stackChildren.add(
              AnimatedPositioned(
                key: ValueKey(mod.id),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                left: left,
                top: top,
                width: halfWidth,
                height: cardHeight,
                child: HomeCardWrapper(
                  key: ValueKey('wrapper_${mod.id}'),
                  module: mod,
                  isEditMode: _isEditMode,
                  isLeftColumn: isLeft,
                  isNight: widget.isNight,
                  allModules: allModules,
                  onRemove: () => _removeModule(mod, allModules),
                  onToggleEditMode: _toggleEditMode,
                  cardCtx: cardCtx,
                  pianoMoodWidget: pianoMoodWidget,
                  photoThrowbackWidget: photoThrowbackWidget,
                  groupedEntries: widget.groupedEntries,
                  hoveredSlotModuleId: _hoveredSlotModuleId,
                  hoveredSlotIsTall: _hoveredSlotIsTall,
                  justDroppedModuleId: _justDroppedModuleId,
                  removingModuleId: _removingModuleId,
                  editModeAnim: _editModeAnim,
                  onSwapModules: _swapModules,
                  child: contentChild,
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
            HomeCardWrapper(
              key: ValueKey('wrapper_${mod.id}'),
              module: mod,
              isEditMode: _isEditMode,
              isNight: widget.isNight,
              allModules: allModules,
              onRemove: () => _removeModule(mod, allModules),
              onToggleEditMode: _toggleEditMode,
              cardCtx: cardCtx,
              pianoMoodWidget: pianoMoodWidget,
              photoThrowbackWidget: photoThrowbackWidget,
              groupedEntries: widget.groupedEntries,
              hoveredSlotModuleId: _hoveredSlotModuleId,
              hoveredSlotIsTall: _hoveredSlotIsTall,
              justDroppedModuleId: _justDroppedModuleId,
              removingModuleId: _removingModuleId,
              editModeAnim: _editModeAnim,
              onSwapModules: _swapModules,
              child: HomeCardRegistry.buildCard(mod.id, cardCtx, pianoMoodWidget, photoThrowbackWidget, isEditMode: _isEditMode),
            ),
          );
        }
      }
    } else {
      // 自由自适应流：依次平铺所有开启的卡片
      for (int i = 0; i < activeModules.length; i++) {
        final mod = activeModules[i];
        cardWidgets.add(
          HomeCardWrapper(
            key: ValueKey('wrapper_${mod.id}'),
            module: mod,
            isEditMode: _isEditMode,
            isNight: widget.isNight,
            allModules: allModules,
            onRemove: () => _removeModule(mod, allModules),
            onToggleEditMode: _toggleEditMode,
            cardCtx: cardCtx,
            pianoMoodWidget: pianoMoodWidget,
            photoThrowbackWidget: photoThrowbackWidget,
            groupedEntries: widget.groupedEntries,
            hoveredSlotModuleId: _hoveredSlotModuleId,
            hoveredSlotIsTall: _hoveredSlotIsTall,
            justDroppedModuleId: _justDroppedModuleId,
            removingModuleId: _removingModuleId,
            editModeAnim: _editModeAnim,
            onSwapModules: _swapModules,
            child: HomeCardRegistry.buildCard(mod.id, cardCtx, pianoMoodWidget, photoThrowbackWidget, isEditMode: _isEditMode),
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
          HomeAddModuleButton(
            isNight: widget.isNight,
            fontFamily: fontFamily,
            textColor: textColor,
            subtitleColor: subtitleColor,
            accentColor: accentColor,
            allModules: allModules,
            canAddModule: (item) => _canAddModule(context, allModules.where((m) => m.enabled).toList(), item),
          ),
        ],
      ],
    );
  }

  /// 实时计算给定模块列表在当前屏幕渲染下的预估总高度（包含组件间 16px 边距）
  double _calculateDashboardContentHeight(List<HomeModuleItem> modules) {
    if (modules.isEmpty) return 0.0;

    final gridModules = modules.where((m) => !m.isFullWidth).toList();
    final otherModules = modules.where((m) => m.isFullWidth).toList();

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
