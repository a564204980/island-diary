import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 将 MediaQuery.viewInsetsOf(context) 监听隔离到此组件，
/// 防止每次键盘动画帧都重绘整个富文本编辑区（极易引起卡顿）
/// 键盘与底部工具栏同步布局层。
///
/// 设计原则：本 widget 自主注册 [WidgetsBindingObserver]，直接从 [View] 读取
/// 物理键盘高度，通过自身 setState 驱动底部位置更新，**不订阅 MediaQuery.viewInsetsOf**
/// （避免 MediaQuery 重建链），也不依赖父级 setState（避免整页重建），
/// 从根本上消除键盘弹出时工具栏卡一卡的问题。
class KeyboardSyncLayout extends StatefulWidget {
  final Widget editorContent;
  final Widget bottomBar;
  final double toolbarOnlyHeight;
  final bool isPanelOpen;
  /// 已稳定的键盘高度 notifier（面板展开时用于固定底部）
  final ValueListenable<double> keyboardHeightNotifier;

  const KeyboardSyncLayout({
    super.key,
    required this.editorContent,
    required this.bottomBar,
    required this.toolbarOnlyHeight,
    required this.isPanelOpen,
    required this.keyboardHeightNotifier,
  });

  @override
  State<KeyboardSyncLayout> createState() => _KeyboardSyncLayoutState();
}

class _KeyboardSyncLayoutState extends State<KeyboardSyncLayout>
    with WidgetsBindingObserver {
  /// 当前键盘高度（逻辑像素），从 View.viewInsets 直接读取，随动画每帧更新
  double _currentKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化时读一次当前值
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateKeyboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 键盘或窗口尺寸变化时由系统自动调用（每帧一次，与键盘动画同步）
  @override
  void didChangeMetrics() {
    _updateKeyboard();
  }

  void _updateKeyboard() {
    if (!mounted) return;
    final view = View.of(context);
    final double newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if ((newHeight - _currentKeyboardHeight).abs() > 0.5) {
      setState(() => _currentKeyboardHeight = newHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top + 56;

    // 面板展开时：固定在已稳定的键盘高度处（避免面板收起后跳回）
    // 键盘弹出时：实时跟随 _currentKeyboardHeight（每帧平滑更新）
    final double storedHeight = widget.keyboardHeightNotifier.value;
    final double bottomBarBottom = widget.isPanelOpen
        ? max(storedHeight, 0.0)
        : _currentKeyboardHeight;

    return Stack(
      children: [
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          bottom: 0, // 核心修复：永远不要在键盘动画期间缩小视口高度！这会和光标滚动动画产生严重冲突导致“一卡一卡”。
          child: widget.editorContent,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomBarBottom,
          child: widget.bottomBar,
        ),
      ],
    );
  }
}
