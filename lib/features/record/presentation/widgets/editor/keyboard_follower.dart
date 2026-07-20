import 'package:flutter/material.dart';

class KeyboardFollower extends StatefulWidget {
  final Widget child;
  const KeyboardFollower({super.key, required this.child});

  @override
  State<KeyboardFollower> createState() => KeyboardFollowerState();
}

class KeyboardFollowerState extends State<KeyboardFollower> {
  double _maxKeyboardHeight = 320;
  double _lastInset = 0;
  bool _isOpening = false;
  int _durationMs = 120;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    if (bottomInset > _maxKeyboardHeight) {
      _maxKeyboardHeight = bottomInset;
    }

    final double jump = bottomInset - _lastInset;

    // 状态机：精准识别正常动画 vs 被打断的闪现(Snap)
    if (jump > 5) {
      if (!_isOpening) {
        _isOpening = true;
        // 核心解法：如果是非0起步（说明中途被打断），或者单帧跳跃极大（说明系统放弃了动画直接弹），
        // 那么我们也直接放弃动画，时间设为0，实现瞬间物理级贴合！
        if (_lastInset > 0 || jump > _maxKeyboardHeight * 0.6) {
          _durationMs = 0;
        } else {
          _durationMs = 120; // 正常超前动画
        }
      }
    } else if (jump < -5) {
      if (_isOpening) {
        _isOpening = false;
        // 收起时同理，如果被打断或跳变极大，直接归零
        if (_lastInset < _maxKeyboardHeight * 0.9 ||
            jump < -(_maxKeyboardHeight * 0.6)) {
          _durationMs = 0;
        } else {
          _durationMs = 120;
        }
      }
    }

    if (bottomInset == 0) {
      _isOpening = false;
      _durationMs = 0;
    }

    _lastInset = bottomInset;
    final double targetHeight = _isOpening ? _maxKeyboardHeight : 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: targetHeight),
        duration: Duration(milliseconds: _durationMs),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, child) {
          final double actualBottom = bottomInset > animatedValue
              ? bottomInset
              : animatedValue;
          return Padding(
            padding: EdgeInsets.only(bottom: actualBottom),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
