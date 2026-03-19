import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import 'config/mood_config.dart';
import 'widgets/mood_slice_item.dart';
import 'widgets/mood_intensity_slider.dart';
import 'widgets/mood_picker_background_painter.dart';
import 'widgets/mood_tag_arc_button.dart';
import '../island_button.dart';
import '../island_alert.dart';

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  int? _selectedIndex;
  double _intensity = 6.0;
  bool _isReady = false;
  int _shakeCount = 0;
  late TextEditingController _tagController;
  late FixedExtentScrollController _intensityScrollController;
  bool _isTagEditing = false;

  static const double baseWheelSize = 400.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
    _tagController = TextEditingController();
    _intensityScrollController = FixedExtentScrollController(
      initialItem: _intensity.toInt() - 1,
    );
  }

  @override
  void dispose() {
    _tagController.dispose();
    _intensityScrollController.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPosition) {
    final double center = baseWheelSize / 2;
    final double dx = localPosition.dx - center;
    final double dy = localPosition.dy - center;
    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance < 20 || distance > baseWheelSize / 2) {
      if (_selectedIndex != null) {
        setState(() => _selectedIndex = null);
      }
      return;
    }

    final double tapAngle = math.atan2(dy, dx);
    int? bestIndex;
    double minAngleDiff = double.infinity;

    for (int i = 0; i < kMoods.length; i++) {
      final item = kMoods[i];
      final offset = item.iconOffset ?? Offset.zero;
      final itemAngle = math.atan2(offset.dy, offset.dx);

      double diff = (tapAngle - itemAngle).abs();
      if (diff > math.pi) {
        diff = 2 * math.pi - diff;
      }

      if (diff < minAngleDiff) {
        minAngleDiff = diff;
        bestIndex = i;
      }
    }

    if (bestIndex != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = (_selectedIndex == bestIndex) ? null : bestIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final displaySize = screenWidth > 600 ? 500.0 : screenWidth;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: _isReady
            ? Center(
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: displaySize,
                    height: displaySize * 1.25,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: baseWheelSize,
                        height: baseWheelSize + 100,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            _buildWheelPanel(),
                            _buildConfirmButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWheelPanel() {
    return SizedBox(
      width: baseWheelSize,
      height: baseWheelSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. 背景
          AnimatedOpacity(
            opacity: _isTagEditing ? 0.0 : 1.0,
            duration: 300.ms,
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(320, 320),
                painter: MoodPickerBackgroundPainter(),
              ),
            ).animate().fade(duration: 400.ms).scale(
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
          ),

          // 2. 心情切片层
          AnimatedOpacity(
            opacity: _isTagEditing ? 0.0 : 1.0,
            duration: 300.ms,
            child: GestureDetector(
              onTapUp: (details) {
                if (!_isTagEditing) _handleTap(details.localPosition);
              },
              child: Container(
                width: baseWheelSize,
                height: baseWheelSize,
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.translate(
                      offset: const Offset(-5, -4),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: kMoods.asMap().entries.map((entry) {
                          final index = entry.key;
                          return RepaintBoundary(
                            child: MoodSliceItem(
                              item: entry.value,
                              isSelected: _selectedIndex == index,
                              baseWheelSize: baseWheelSize,
                            ),
                          ).animate().fade(
                            delay: (index * 40).ms,
                            duration: 300.ms,
                          ).scale(
                            delay: (index * 30).ms,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                            alignment: Alignment.center,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 强度滑块
          Transform.translate(
            offset: const Offset(21, 0),
            child: AnimatedOpacity(
              opacity: _isTagEditing ? 0.0 : 1.0,
              duration: 300.ms,
              child: RepaintBoundary(
                child: MoodIntensitySlider(
                  intensity: _intensity,
                  onChanged: (val) {
                    if (!_isTagEditing) setState(() => _intensity = val);
                  },
                  radius: 138,
                ),
              ).animate().fade(
                delay: 500.ms,
                duration: 600.ms,
              ).scale(
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
            ),
          ),

          // 4. 标签按钮
          Transform.translate(
            offset: const Offset(27, 0),
            child: AnimatedOpacity(
              opacity: _isTagEditing ? 0.0 : 1.0,
              duration: 200.ms,
              child: Transform.rotate(
                angle: -5 * math.pi / 180,
                origin: const Offset(87.3, 93.6),
                child: MoodTagArcButton(
                  tag: _tagController.text,
                  isEditing: _isTagEditing,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isTagEditing = true;
                      _intensityScrollController.jumpToItem(_intensity.toInt() - 1);
                    });
                  },
                  radius: 128,
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.02, 1.02),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          ).animate().fade(delay: 600.ms, duration: 600.ms).scale(
            begin: const Offset(0.8, 0.8),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),

          // 5. 编辑覆盖层
          if (_isTagEditing) _buildEditingOverlay(),
        ],
      ).animate(target: _shakeCount.toDouble(), onPlay: (c) => c.forward(from: 0)).shake(
        hz: 6,
        curve: Curves.easeInOutCubic,
        duration: 400.ms,
        offset: const Offset(6, 0),
      ),
    );
  }

  Widget _buildEditingOverlay() {
    return TweenAnimationBuilder<double>(
      duration: 500.ms,
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final sleekGlowingDecoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF4D673).withOpacity(0.55),
              blurRadius: 25,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        );

        return Transform.scale(
          scale: value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTagInput(sleekGlowingDecoration),
              const SizedBox(width: 12),
              _buildIntensityPicker(sleekGlowingDecoration),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagInput(BoxDecoration decoration) {
    return Container(
      width: 200,
      height: 52,
      decoration: decoration,
      child: Center(
        child: TextField(
          controller: _tagController,
          textAlign: TextAlign.center,
          cursorColor: const Color(0xFF8D6E63),
          maxLength: 10,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6D4C41),
            fontWeight: FontWeight.bold,
            fontFamily: 'LXGWWenKai',
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '描述此刻的心境...',
            hintStyle: TextStyle(
              color: const Color(0xFF8D6E63).withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onSubmitted: (_) => _submitResult(),
        ),
      ),
    );
  }

  Widget _buildIntensityPicker(BoxDecoration decoration) {
    return Container(
      width: 52,
      height: 52,
      decoration: decoration,
      child: ListWheelScrollView.useDelegate(
        controller: _intensityScrollController,
        itemExtent: 28,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.2,
        perspective: 0.003,
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() => _intensity = (index + 1).toDouble());
        },
        childDelegate: ListWheelChildListDelegate(
          children: List.generate(
            10,
            (i) => Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6D4C41),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Positioned(
      bottom: 10,
      child: IslandButton(
        text: '确认',
        width: 120,
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        useHandDrawn: false,
        onTap: _submitResult,
      ).animate().fade(delay: 700.ms, duration: 500.ms).scale(
        begin: const Offset(0.8, 0.8),
        duration: 550.ms,
        curve: Curves.easeOutBack,
      ).moveY(begin: 15, end: 0, duration: 600.ms),
    );
  }

  void _submitResult() {
    final hasContent = _tagController.text.isNotEmpty || _selectedIndex != null;

    if (!hasContent) {
      setState(() => _shakeCount++);
      IslandAlert.show(
        context,
        message: '先选个心情再出发吧~',
        icon: '✨',
        withAnimation: false,
        alignment: const Alignment(0, 0.35),
      );
      return;
    }

    Navigator.pop(context, {
      'index': _selectedIndex ?? 4,
      'intensity': _intensity,
      'tag': _tagController.text.isNotEmpty ? _tagController.text : null,
    });
  }
}
