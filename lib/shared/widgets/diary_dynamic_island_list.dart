import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// 一个高度可复用的、集成了灵动取景头部的滚动列表组件。
/// 它将头部区域的纵向拖拽和列表区域的越界下拉（Overscroll）结合起来，
/// 共同驱动灵动取景区域的形变展开。
class DiaryDynamicIslandList extends StatefulWidget {
  /// 头部组件的基础高度（未拉伸时的“胶囊”状态高度）。
  final double baseHeaderHeight;

  /// 头部组件允许被额外拉伸的最大高度（完全展开时的“面板”状态高度）。
  final double maxExtraHeight;

  /// 动态头部的构建器。
  /// [expansionProgress] 的值域为 0.0 (完全收缩为胶囊) 到 1.0 (完全展开为大面板)。
  final Widget Function(BuildContext context, double expansionProgress, double currentExtraHeight) headerBuilder;

  /// 主列表区域。
  /// 必须是使用了 [BouncingScrollPhysics] (或类似允许在顶部产生负滚动像素的物理效果) 的滚动组件。
  /// 通常传入 ListView, CustomScrollView, 或 MasonryGridView。
  final Widget child;

  const DiaryDynamicIslandList({
    super.key,
    this.baseHeaderHeight = 80.0,
    this.maxExtraHeight = 150.0,
    required this.headerBuilder,
    required this.child,
  });

  @override
  State<DiaryDynamicIslandList> createState() => _DiaryDynamicIslandListState();
}

class _DiaryDynamicIslandListState extends State<DiaryDynamicIslandList> with SingleTickerProviderStateMixin {
  // 单一数据源：记录头部被额外拉伸的高度
  final ValueNotifier<double> _extraHeightNotifier = ValueNotifier(0.0);
  
  late AnimationController _springController;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController.unbounded(vsync: this);
    // 将动画控制器的值同步给拉伸高度状态，并限制范围
    _springController.addListener(() {
      _extraHeightNotifier.value = _springController.value.clamp(0.0, widget.maxExtraHeight);
    });
  }

  @override
  void dispose() {
    _extraHeightNotifier.dispose();
    _springController.dispose();
    super.dispose();
  }

  /// 触发一个基于物理的弹性动画（弹簧模拟），使头部回弹到基础状态 (0.0)
  /// 或者弹射到完全展开状态 (maxExtraHeight)。
  void _animateToTarget({required double targetHeight, double velocity = 0}) {
    final springDescription = const SpringDescription(
      mass: 1.0,
      stiffness: 100.0, // 调整刚度以改变弹簧的紧绷感 (符合 island-diary-animations 规范)
      damping: 15.0,    // 阻尼系数，避免过度晃动
    );

    final simulation = SpringSimulation(
      springDescription,
      _extraHeightNotifier.value,
      targetHeight,
      velocity,
    );

    _springController.animateWith(simulation);
  }

  void _handleDragEnd(double velocity) {
    // 阈值判定：如果拉伸超过了最大允许高度的一半，则自动展开到最大；否则回弹收缩。
    if (_extraHeightNotifier.value > widget.maxExtraHeight / 2) {
      _animateToTarget(targetHeight: widget.maxExtraHeight, velocity: velocity);
    } else {
      _animateToTarget(targetHeight: 0.0, velocity: velocity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==========================================
        // 1. 灵动取景头部区域 (独立手势隔离)
        // ==========================================
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (_springController.isAnimating) _springController.stop();
            
            final newHeight = _extraHeightNotifier.value + details.delta.dy;
            _extraHeightNotifier.value = newHeight.clamp(0.0, widget.maxExtraHeight);
          },
          onVerticalDragEnd: (details) {
            _handleDragEnd(details.primaryVelocity ?? 0);
          },
          child: ValueListenableBuilder<double>(
            valueListenable: _extraHeightNotifier,
            builder: (context, extraHeight, child) {
              // 计算拉伸进度 (0.0 到 1.0 之间)
              final progress = (extraHeight / widget.maxExtraHeight).clamp(0.0, 1.0);
              return SizedBox(
                height: widget.baseHeaderHeight + extraHeight,
                width: double.infinity,
                child: widget.headerBuilder(context, progress, extraHeight),
              );
            },
          ),
        ),

        // ==========================================
        // 2. 滚动列表区域 (边缘越界联动)
        // ==========================================
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                // 如果在顶部继续下拉（产生负数越界），捕获下拉偏移量
                if (notification.metrics.pixels < 0) {
                  if (_springController.isAnimating) _springController.stop();
                  
                  // 加入阻尼系数，让下拉有更沉重的物理质感
                  final dragOffset = -notification.metrics.pixels * 0.5;
                  _extraHeightNotifier.value = dragOffset.clamp(0.0, widget.maxExtraHeight);
                }
              } else if (notification is ScrollEndNotification) {
                // 滚动停止时，如果仍处于越界拉伸状态，触发回弹或展开动画
                if (notification.metrics.pixels <= 0 && _extraHeightNotifier.value > 0) {
                  _handleDragEnd(0);
                }
              }
              return false; // 返回 false 允许标准滚动行为继续冒泡
            },
            // 列表本身
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
