import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

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

class DiaryWeatherPickerSheet extends StatefulWidget {
  final String paperStyle;
  final Function(String weather, int temperature) onConfirm;

  const DiaryWeatherPickerSheet({
    super.key, 
    required this.onConfirm,
    this.paperStyle = 'standard',
  });

  @override
  State<DiaryWeatherPickerSheet> createState() => _DiaryWeatherPickerSheetState();
}

class _DiaryWeatherPickerSheetState extends State<DiaryWeatherPickerSheet> {
  int _selectedIdx = -1;
  double _temperature = 20.0;

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(widget.paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部装饰条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择天气',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LXGWWenKai',
                  color: accentColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: accentColor.withValues(alpha: 0.6)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Weather Icons Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: kWeatherTypes.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIdx == index;
              final weather = kWeatherTypes[index];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIdx = index);
                  widget.onConfirm(weather.label, _temperature.toInt());
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: 300.ms,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: Icon(
                        weather.icon,
                        size: 22,
                        color: isSelected ? Colors.white : inkColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weather.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? accentColor : inkColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          Divider(height: 1, color: accentColor.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          
          // Temperature Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${_temperature.toInt()}°C',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'LXGWWenKai',
                color: accentColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // Temperature Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.15),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
              trackHeight: 4,
            ),
            child: Slider(
              value: _temperature,
              min: -90,
              max: 60,
              onChanged: (val) {
                setState(() => _temperature = val);
              },
            ),
          ),
          
          // Slider Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-90°C', style: TextStyle(fontSize: 12, color: accentColor.withValues(alpha: 0.4), fontFamily: 'LXGWWenKai')),
                Text('60°C', style: TextStyle(fontSize: 12, color: accentColor.withValues(alpha: 0.4), fontFamily: 'LXGWWenKai')),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
