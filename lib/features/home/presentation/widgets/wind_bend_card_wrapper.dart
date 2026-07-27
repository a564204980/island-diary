import 'package:flutter/material.dart';

/// 首页模块包裹器 (风吹倾斜特效已停用，保持模块平整静止)
class WindBendCardWrapper extends StatelessWidget {
  final Widget child;

  /// 是否为竖长条卡片 (保留参数签名以兼容外部调用)
  final bool isTall;
  final bool isEditMode;

  const WindBendCardWrapper({
    super.key,
    required this.child,
    this.isTall = false,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

