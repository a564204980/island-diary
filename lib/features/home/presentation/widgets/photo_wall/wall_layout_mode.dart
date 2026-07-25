import 'package:flutter/material.dart';

/// 照片墙布局模式枚举
enum WallLayoutMode {
  treemap('手帐切块', Icons.grid_view_rounded),
  scatter('倾斜散落', Icons.auto_awesome_motion_rounded),
  free('自由拖拽', Icons.touch_app_rounded);

  final String label;
  final IconData icon;
  const WallLayoutMode(this.label, this.icon);
}

extension WallLayoutModeX on WallLayoutMode {
  static WallLayoutMode fromString(String val) {
    if (val == 'scatter') return WallLayoutMode.scatter;
    if (val == 'free') return WallLayoutMode.free;
    return WallLayoutMode.treemap;
  }
}
