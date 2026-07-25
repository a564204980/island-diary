import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/core/models/home_module_config.dart';
import 'package:island_diary/features/home/presentation/widgets/home_card_registry.dart';
import 'package:island_diary/features/home/presentation/widgets/wind_bend_card_wrapper.dart';
import 'package:island_diary/features/home/presentation/widgets/dashboard/photo_throwback_widget.dart';

/// 封装单张卡片在编辑模式下的高级弹性拖拽、有机微倾斜与角标旋转弹起动效
class HomeCardWrapper extends StatelessWidget {
  final HomeModuleItem module;
  final Widget child;
  final bool isEditMode;
  final bool isLeftColumn;
  final bool isNight;
  final List<HomeModuleItem> allModules;
  final VoidCallback onRemove;
  final VoidCallback onToggleEditMode;
  final HomeCardBuildContext cardCtx;
  final Widget pianoMoodWidget;
  final Widget photoThrowbackWidget;
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;
  final ValueNotifier<String?> hoveredSlotModuleId;
  final ValueNotifier<bool> hoveredSlotIsTall;
  final ValueNotifier<String?> justDroppedModuleId;
  final ValueNotifier<String?> removingModuleId;
  final AnimationController editModeAnim;
  final void Function(HomeModuleItem, HomeModuleItem, List<HomeModuleItem>) onSwapModules;

  const HomeCardWrapper({
    super.key,
    required this.module,
    required this.child,
    required this.isEditMode,
    required this.isNight,
    required this.allModules,
    required this.onRemove,
    required this.onToggleEditMode,
    required this.cardCtx,
    required this.pianoMoodWidget,
    required this.photoThrowbackWidget,
    required this.groupedEntries,
    required this.hoveredSlotModuleId,
    required this.hoveredSlotIsTall,
    required this.justDroppedModuleId,
    required this.removingModuleId,
    required this.editModeAnim,
    required this.onSwapModules,
    this.isLeftColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    // 取消编辑模式下的左右交替倾斜（保留缩放和阴影），避免大卡片倾斜产生"左右偏"的错位感
    final double tiltSign = 0.0;
    final shadowColor = isNight ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    Widget cardBody = AnimatedBuilder(
      animation: editModeAnim,
      builder: (context, innerChild) {
        final double t = editModeAnim.value;
        // easeOutBack 手感曲线
        final double curved = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
        return TweenAnimationBuilder<double>(
          key: ValueKey('tilt_${module.id}'),
          tween: Tween<double>(begin: tiltSign, end: tiltSign),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, animatedTilt, _) {
            return Transform.rotate(
              angle: curved * 0.035 * animatedTilt,
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
              isEditMode: isEditMode,
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
          // 左上角锁头角标 - 固定通栏指示器 (仅固定锁定的通栏模块显示，例如 piano_mood)
          Positioned(
            top: -6,
            left: 12,
            child: AnimatedScale(
              scale: isEditMode && module.id == 'piano_mood' ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: isEditMode && module.id == 'piano_mood' ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isNight
                        ? Colors.black.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNight
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
          // 仅固定通栏模块 (如 piano_mood) 上锁不参与拖拽放置与位置交换
          if (details.data.id == 'piano_mood' || module.id == 'piano_mood') {
            return false;
          }
          hoveredSlotModuleId.value = details.data.id;
          hoveredSlotIsTall.value = isLeftColumn;
          return true;
        }
        return false;
      },
      onLeave: (data) {
        if (data != null && data.id == hoveredSlotModuleId.value) {
          hoveredSlotModuleId.value = null;
        }
      },
      onAcceptWithDetails: (details) {
        hoveredSlotModuleId.value = null;
        if (!isEditMode) return;
        HapticFeedback.mediumImpact();
        onSwapModules(details.data, module, allModules);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = isEditMode && candidateData.isNotEmpty;

        final Widget cardBodyWithDrop = ValueListenableBuilder<String?>(
          valueListenable: justDroppedModuleId,
          builder: (context, droppedId, _) {
            final bool isJustDropped = (droppedId == module.id);
            if (!isJustDropped) return cardBody;

            return TweenAnimationBuilder<double>(
              key: ValueKey('drop_${module.id}'),
              tween: Tween<double>(begin: 1.08, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              onEnd: () {
                justDroppedModuleId.value = null;
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
          valueListenable: removingModuleId,
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
                    color: isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B),
                    width: 3.5,
                  )
                : null,
          ),
          child: cardBodyWithWind,
        );

        // 卡片交换时的放手落座动画 (移除 activeIndex 避免在 AnimatedPositioned 飞行过程中引发不必要的原位鬼影闪烁)
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
          child: RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey('${module.id}_card'),
              child: innerCard,
            ),
          ),
        );

        final double targetWidth = !module.isFullWidth
            ? (MediaQuery.of(context).size.width - 48.0) / 2
            : (MediaQuery.of(context).size.width - 48.0);

        final double startScale = isEditMode ? 0.965 : 1.0;
        final double startAngle = isEditMode ? (0.035 * tiltSign) : 0.0;
        final double targetAngle = 0.035 * tiltSign;

        final Widget feedbackWidget = ValueListenableBuilder<String?>(
          valueListenable: hoveredSlotModuleId,
          builder: (context, hoveredId, _) {
            final bool effectiveIsTall = (hoveredId != null && hoveredId == module.id)
                ? hoveredSlotIsTall.value
                : isLeftColumn;

            Widget dynamicFeedbackChild;
            if (module.id == 'photo_throwback') {
              dynamicFeedbackChild = PhotoThrowbackWidget(
                groupedEntries: groupedEntries,
                textColor: cardCtx.textColor,
                subtitleColor: cardCtx.subtitleColor,
                accentColor: cardCtx.accentColor,
                fontFamily: cardCtx.fontFamily,
                isNight: isNight,
                isTall: effectiveIsTall,
              );
            } else {
              dynamicFeedbackChild = HomeCardRegistry.buildCard(
                module.id,
                cardCtx,
                pianoMoodWidget,
                photoThrowbackWidget,
                isTall: effectiveIsTall,
                isEditMode: isEditMode,
              );
            }

            Widget feedbackWithMinus = Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                dynamicFeedbackChild,
                if (!module.isFullWidth)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
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
              ],
            );

            return Material(
              color: Colors.transparent,
              child: SizedBox(
                width: targetWidth,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, animValue, innerChild) {
                    final double currentScale = lerpDouble(startScale, 1.05, animValue)!;
                    final double currentAngle = lerpDouble(startAngle, targetAngle, animValue)!;
                    final double shadowOpacity = lerpDouble(0.12, 0.35, animValue)!;
                    final double shadowBlur = lerpDouble(8.0, 24.0, animValue)!;

                    return Transform.rotate(
                      angle: currentAngle,
                      child: Transform.scale(
                        scale: currentScale,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (isNight ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                    .withValues(alpha: shadowOpacity),
                                blurRadius: shadowBlur,
                                spreadRadius: 2.0 * animValue,
                                offset: Offset(0, 4.0 * animValue),
                              ),
                            ],
                          ),
                          child: innerChild,
                        ),
                      ),
                    );
                  },
                  child: RepaintBoundary(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      height: effectiveIsTall ? 296.0 : 140.0,
                      child: feedbackWithMinus,
                    ),
                  ),
                ),
              ),
            );
          },
        );

        // 仅固定锁定的通栏模块 (如 piano_mood) 处于上锁不可拖拽状态：
        // 1. 禁止拖拽位移
        // 2. 但在非编辑模式下长按依然可以触发进入编辑模式
        if (module.id == 'piano_mood') {
          if (!isEditMode) {
            return GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                onToggleEditMode();
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
            hoveredSlotModuleId.value = null;
            // 拖拽开始时同步激活编辑模式，AnimatedBuilder 驱动所有卡片平滑进场动画
            if (!isEditMode) {
              onToggleEditMode();
            }
          },
          onDragEnd: (details) {
            hoveredSlotModuleId.value = null;
            justDroppedModuleId.value = module.id;
          },
          onDraggableCanceled: (velocity, offset) {
            hoveredSlotModuleId.value = null;
            justDroppedModuleId.value = module.id;
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
}
