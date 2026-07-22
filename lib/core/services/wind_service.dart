import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 岛屿风速模式枚举
enum WindMode {
  none('☁️ 无风', 0.15),
  breeze('🍃 微风', 1.0),
  moderate('💨 中风', 2.5),
  gale('🌬️ 狂风', 6.0);

  final String label;
  final double speedMultiplier;

  const WindMode(this.label, this.speedMultiplier);
}

/// 海岛随机风速系统服务
class WindService {
  /// 当前岛屿风速状态监听器
  static final ValueNotifier<WindMode> currentWind = ValueNotifier<WindMode>(WindMode.breeze);

  /// 依据加权概率模型分配风速
  /// 概率占比：微风(45%)、无风(30%)、中风(20%)、狂风(5%)
  static WindMode randomizeWind() {
    final random = math.Random().nextDouble() * 100.0;
    WindMode selected;

    if (random < 45.0) {
      selected = WindMode.breeze; // 45%
    } else if (random < 75.0) {
      selected = WindMode.none; // 30%
    } else if (random < 95.0) {
      selected = WindMode.moderate; // 20%
    } else {
      selected = WindMode.gale; // 5% 狂风低概率
    }

    currentWind.value = selected;
    UserState().cloudSpeedMultiplier.value = selected.speedMultiplier;
    return selected;
  }
}
