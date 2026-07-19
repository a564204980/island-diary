import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class DiaryChunshanConfigSheet extends StatefulWidget {
  final String? fontFamily;

  const DiaryChunshanConfigSheet({
    super.key,
    this.fontFamily,
  });

  static Future<void> show({
    required BuildContext context,
    String? fontFamily,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DiaryChunshanConfigSheet(
        fontFamily: fontFamily,
      ),
    );
  }

  @override
  State<DiaryChunshanConfigSheet> createState() => _DiaryChunshanConfigSheetState();
}

class _DiaryChunshanConfigSheetState extends State<DiaryChunshanConfigSheet> {
  late double _borderRadius;
  late double _spacing;
  late double _aspectRatio;
  late bool _hasBackground;

  @override
  void initState() {
    super.initState();
    _borderRadius = UserState().chunshanBorderRadius.value;
    _spacing = UserState().chunshanSpacing.value;
    _aspectRatio = UserState().chunshanAspectRatio.value;
    _hasBackground = UserState().chunshanHasBackground.value;
  }

  void _saveConfig() {
    UserState().setChunshanConfig(
      borderRadius: _borderRadius,
      spacing: _spacing,
      aspectRatio: _aspectRatio,
      hasBackground: _hasBackground,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isNight ? Colors.white : Colors.black;
    final accentColor = Theme.of(context).colorScheme.primary;

    return DiaryBottomSheet(
      paperStyle: UserState().preferredPaperStyle.value,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiaryBottomSheetHeader(
            title: '排版设置',
            fontFamily: widget.fontFamily,
            textColor: inkColor.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 8),
          
          // BorderRadius
          _buildSliderRow(
            label: '图片圆角',
            value: _borderRadius,
            min: 0,
            max: 32,
            onChanged: (val) {
              setState(() => _borderRadius = val);
              _saveConfig();
            },
            inkColor: inkColor,
            accentColor: accentColor,
          ),
          
          // Spacing
          _buildSliderRow(
            label: '图片间距',
            value: _spacing,
            min: 0,
            max: 24,
            onChanged: (val) {
              setState(() => _spacing = val);
              _saveConfig();
            },
            inkColor: inkColor,
            accentColor: accentColor,
          ),

          // AspectRatio
          _buildSliderRow(
            label: '相框比例',
            value: _aspectRatio,
            min: 1.0,
            max: 3.0,
            onChanged: (val) {
              setState(() => _aspectRatio = val);
              _saveConfig();
            },
            inkColor: inkColor,
            accentColor: accentColor,
            valueLabel: _aspectRatio.toStringAsFixed(2),
          ),

          // HasBackground
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '显示卡片边框',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: widget.fontFamily,
                  color: inkColor.withValues(alpha: 0.8),
                ),
              ),
              Switch(
                value: _hasBackground,
                activeThumbColor: accentColor,
                activeTrackColor: accentColor.withValues(alpha: 0.5),
                onChanged: (val) {
                  setState(() => _hasBackground = val);
                  _saveConfig();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color inkColor,
    required Color accentColor,
    String? valueLabel,
  }) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontFamily: widget.fontFamily,
                color: inkColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: accentColor,
                inactiveTrackColor: inkColor.withValues(alpha: 0.1),
                thumbColor: Colors.white,
                overlayColor: accentColor.withValues(alpha: 0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              valueLabel ?? value.toInt().toString(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontFamily: widget.fontFamily,
                color: inkColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
