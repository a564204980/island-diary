import 'package:flutter/material.dart';

class EditorTagBar extends StatelessWidget {
  final String paperStyle;
  final bool isNight;
  final Color accentColor;
  final dynamic mood; // 对应 kMoods 的元素
  final String? currentTag;
  final String? weather;
  final String? temp;
  final String? location;
  final String? customDate;
  final String? customTime;
  final VoidCallback onMoodTap;

  const EditorTagBar({
    super.key,
    required this.paperStyle,
    required this.isNight,
    required this.accentColor,
    this.mood,
    this.currentTag,
    this.weather,
    this.temp,
    this.location,
    this.customDate,
    this.customTime,
    required this.onMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNote = paperStyle.startsWith('note');
    final tagBgColor = isNote
        ? Colors.white.withValues(alpha: 0.4)
        : isNight ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1);
    
    final tagBorderColor = isNight
        ? Colors.white.withValues(alpha: 0.55)
        : accentColor.withValues(alpha: isNote ? 0.2 : 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // 心情标签
          GestureDetector(
            onTap: onMoodTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tagBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mood == null && (currentTag == null || currentTag!.isEmpty))
                    Icon(Icons.add_circle_outline, size: 14, color: accentColor)
                  else
                    Image.asset(
                      (currentTag != null && currentTag!.isNotEmpty)
                          ? 'assets/images/icons/custom.png'
                          : (mood.iconPath!),
                      width: 14,
                      height: 14,
                      color: mood == null ? accentColor : null,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    mood == null && (currentTag == null || currentTag!.isEmpty)
                        ? '选择心情'
                        : (currentTag != null && currentTag!.isNotEmpty)
                            ? '心情：$currentTag'
                            : '心情：${mood.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 天气
          if (weather != null)
            _buildTagItem(tagBgColor, tagBorderColor, "$weather ${temp ?? ''}"),
            
          // 地点
          if (location != null)
            _buildTagItem(
              tagBgColor, 
              tagBorderColor, 
              location!, 
              icon: Icons.location_on_outlined
            ),
            
          // 自定义日期
          if (customDate != null)
            _buildTagItem(
              tagBgColor, 
              tagBorderColor, 
              customDate!, 
              icon: Icons.calendar_today_outlined
            ),
            
          // 自定义时间
          if (customTime != null)
            _buildTagItem(
              tagBgColor, 
              tagBorderColor, 
              customTime!, 
              icon: Icons.access_time_outlined
            ),
        ],
      ),
    );
  }

  Widget _buildTagItem(Color bgColor, Color borderColor, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
