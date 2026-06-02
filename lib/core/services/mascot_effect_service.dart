import 'package:flutter/material.dart';
import 'gundam_helmet_effect.dart';

/// 专属装扮全屏特效大管家
class MascotEffectService {
  static final MascotEffectService _instance = MascotEffectService._internal();
  factory MascotEffectService() => _instance;
  MascotEffectService._internal();

  /// 缓存最后一次在装扮中心播放过特效的装饰品 ID，防止短时间内重复触发
  String? _lastPlayedDecoId;

  /// 检测并播放专属装扮特效
  void checkAndPlayEffect(BuildContext context, String? decorationId) {
    if (decorationId == null || decorationId.isEmpty) return;

    // TODO: 待后续重新实现专属装扮特效
  }

  /// 内部通过 Overlay 浮层展示特效，以达到真正的全屏遮罩效果
  void _showEffect(BuildContext context, Widget effectWidget) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return effectWidget;
      },
    );

    overlayState.insert(overlayEntry);

    // 监听特效自己通知销毁或定时销毁
    // 我们的特效在内部播放完毕后，会自动通知并安全从 Overlay 移除
    // 特效总时长延长：5秒闪电雷暴 + 2秒左右的 HUD 启动展示，延时设为 7500ms 后自动移除
    Future.delayed(const Duration(milliseconds: 7500), () {
      try {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      } catch (_) {}
    });
  }

  /// 重置已播放状态（如果需要）
  void reset() {
    _lastPlayedDecoId = null;
  }
}
