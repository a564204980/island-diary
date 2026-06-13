import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_bottom_sheet.dart';

class WeatherType {
  final String label;
  final IconData icon;
  const WeatherType(this.label, this.icon);
}

const List<WeatherType> kWeatherTypes = [
  WeatherType("晴", Icons.wb_sunny_outlined),
  WeatherType("多云", Icons.wb_cloudy_outlined),
  WeatherType("阴", Icons.cloud_outlined),
  WeatherType("雨", Icons.umbrella_outlined),
  WeatherType("雪", Icons.ac_unit_outlined),
  WeatherType("风", Icons.air_outlined),
  WeatherType("雾霾", Icons.grain_outlined),
  WeatherType("雷暴", Icons.thunderstorm_outlined),
  WeatherType("冻雨", Icons.water_drop_outlined),
  WeatherType("冰雹", Icons.severe_cold_outlined),
  WeatherType("炎热", Icons.thermostat_outlined),
  WeatherType("严寒", Icons.ac_unit_outlined),
  WeatherType("沙尘", Icons.waves_outlined),
  WeatherType("极端风暴", Icons.cyclone_outlined),
];

class GradientSliderTrackShape extends SliderTrackShape {
  const GradientSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 6.0;
    final double trackLeft = offset.dx + 8.0;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 16.0;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF3A86C8), // 极寒 (-90°C)
          Color(0xFF70C1B3), // 寒冷 (-30°C)
          Color(0xFFB8F2E6), // 零度 (0°C)
          Color(0xFFF3C68F), // 温暖 (25°C)
          Color(0xFFEE6C4D), // 酷热 (60°C)
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(trackRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackRect.height / 2)),
      paint,
    );
  }
}

class DiaryWeatherPickerSheet extends StatefulWidget {
  final String paperStyle;
  final Function(String weather, int temperature) onConfirm;
  final String? initialWeather;
  final String? initialTemp;

  const DiaryWeatherPickerSheet({
    super.key, 
    required this.onConfirm,
    this.paperStyle = 'standard',
    this.initialWeather,
    this.initialTemp,
  });

  @override
  State<DiaryWeatherPickerSheet> createState() => _DiaryWeatherPickerSheetState();
}

class _DiaryWeatherPickerSheetState extends State<DiaryWeatherPickerSheet> {
  int _selectedIdx = -1;
  double _temperature = 20.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialWeather != null) {
      final index = kWeatherTypes.indexWhere((w) => w.label == widget.initialWeather);
      if (index != -1) {
        _selectedIdx = index;
      }
    }
    if (widget.initialTemp != null) {
      final cleaned = widget.initialTemp!.replaceAll(RegExp(r'[^0-9\.-]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        _temperature = parsed;
      }
    }
  }

  Color _getTemperatureColor(double temp) {
    final double ratio = ((temp + 90) / 150).clamp(0.0, 1.0);
    return Color.lerp(
      const Color(0xFF3A86C8), // 冰蓝
      const Color(0xFFEE6C4D), // 暖橙红
      ratio,
    )!;
  }

  String _getTemperatureStatus(double temp) {
    if (temp < -40) return "极寒";
    if (temp < -10) return "寒冷";
    if (temp < 10) return "凉爽";
    if (temp < 28) return "舒适";
    if (temp < 38) return "炎热";
    return "酷暑";
  }

  Widget _buildWeatherItem(
    int index,
    WeatherType weather,
    Color accentColor,
    Color inkColor,
    String fontFamily,
  ) {
    final isSelected = _selectedIdx == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIdx == index) {
          setState(() => _selectedIdx = -1);
          widget.onConfirm('', 20);
        } else {
          setState(() => _selectedIdx = index);
          widget.onConfirm(weather.label, _temperature.toInt());
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: 250.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSelected 
                  ? accentColor 
                  : accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? accentColor 
                    : accentColor.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ] : null,
            ),
            child: Icon(
              weather.icon,
              size: 20,
              color: isSelected ? Colors.white : inkColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weather.label,
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: fontFamily,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? accentColor : inkColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);
    final Color tempColor = _getTemperatureColor(_temperature);

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: true,
      showDragHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择天气',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                  color: inkColor.withValues(alpha: 0.9),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded, 
                  color: inkColor.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Weather Icons Row 1
          Row(
            children: List.generate(7, (index) {
              final weather = kWeatherTypes[index];
              return Expanded(
                child: _buildWeatherItem(index, weather, accentColor, inkColor, fontFamily),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Weather Icons Row 2
          Row(
            children: List.generate(7, (index) {
              final weather = kWeatherTypes[index + 7];
              return Expanded(
                child: _buildWeatherItem(index + 7, weather, accentColor, inkColor, fontFamily),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          Divider(height: 1, color: inkColor.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          
          // Temperature Module Card (Compact Version)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tempColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tempColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: Temp indicator + Status Tag (Small and tight)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.thermostat_rounded,
                          color: tempColor,
                          size: 20,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_temperature.toInt()}°C',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                            color: tempColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tempColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tempColor.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _getTemperatureStatus(_temperature),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: tempColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Row 2: Slider + Extremes side-by-side (Very space efficient)
                Row(
                  children: [
                    Text(
                      '-90°C', 
                      style: TextStyle(
                        fontSize: 10, 
                        color: inkColor.withValues(alpha: 0.4), 
                        fontFamily: fontFamily,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackShape: const GradientSliderTrackShape(),
                          thumbColor: Colors.white,
                          overlayColor: tempColor.withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                            elevation: 3,
                            pressedElevation: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _temperature,
                          min: -90,
                          max: 60,
                          onChanged: (val) {
                            setState(() => _temperature = val);
                            if (_selectedIdx != -1) {
                              widget.onConfirm(
                                kWeatherTypes[_selectedIdx].label,
                                val.toInt(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Text(
                      '60°C', 
                      style: TextStyle(
                        fontSize: 10, 
                        color: inkColor.withValues(alpha: 0.4), 
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
