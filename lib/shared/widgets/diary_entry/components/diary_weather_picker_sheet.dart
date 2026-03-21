import 'package:flutter/material.dart';

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
  final Function(String weather, int temperature) onConfirm;

  const DiaryWeatherPickerSheet({super.key, required this.onConfirm});

  @override
  State<DiaryWeatherPickerSheet> createState() => _DiaryWeatherPickerSheetState();
}

class _DiaryWeatherPickerSheetState extends State<DiaryWeatherPickerSheet> {
  int _selectedIdx = -1;
  double _temperature = 20.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '天气',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LXGWWenKai',
                  color: Color(0xFF8B5E3C),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8B5E3C)),
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
              mainAxisSpacing: 12,
              crossAxisSpacing: 4,
              childAspectRatio: 0.8,
            ),
            itemCount: kWeatherTypes.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIdx == index;
              final weather = kWeatherTypes[index];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIdx = index);
                  // Optionally confirm immediately on icon tap if desired, 
                  // but user screenshot has a slider, so maybe confirm label + temp later.
                  // For now, let's just make it selectable.
                  widget.onConfirm(weather.label, _temperature.toInt());
                },
                child: Column(
                  children: [
                    Icon(
                      weather.icon,
                      size: 24,
                      color: isSelected ? const Color(0xFF8B5E3C) : Colors.black45,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'LXGWWenKai',
                        color: isSelected ? const Color(0xFF8B5E3C) : Colors.black26,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 24),
          
          // Temperature Display
          Text(
            '${_temperature.toInt()}°C',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              color: Color(0xFF8B5E3C),
            ),
          ),
          
          // Temperature Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B5E3C),
              inactiveTrackColor: const Color(0xFF8B5E3C).withOpacity(0.12),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF8B5E3C).withOpacity(0.1),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-90°C', style: TextStyle(fontSize: 11, color: const Color(0xFF8B5E3C).withOpacity(0.4), fontFamily: 'LXGWWenKai')),
                Text('60°C', style: TextStyle(fontSize: 11, color: const Color(0xFF8B5E3C).withOpacity(0.4), fontFamily: 'LXGWWenKai')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
