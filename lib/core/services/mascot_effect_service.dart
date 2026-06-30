import 'package:flutter/material.dart';

/// 专属装扮全屏特效大管家
class MascotEffectService {
  static final MascotEffectService _instance = MascotEffectService._internal();
  factory MascotEffectService() => _instance;
  MascotEffectService._internal();

  /// 检测并播放专属装扮特效
  void checkAndPlayEffect(BuildContext context, String? decorationId) {
    if (decorationId == null || decorationId.isEmpty) return;
  }
}
