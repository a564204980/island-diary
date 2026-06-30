import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

void showCustomColorPickerBottomSheet(
  BuildContext context, {
  required Color initialColor,
  required ValueChanged<Color> onColorSelected,
  String title = '自定义颜色',
}) {
  final hsv = HSVColor.fromColor(initialColor);
  double currentHue = hsv.hue;
  double currentSaturation = hsv.saturation;
  double currentValue = hsv.value;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final pickerColor = HSVColor.fromAHSV(1.0, currentHue, currentSaturation, currentValue).toColor();
          final String hexColor = '#${pickerColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
          
          return DiaryBottomSheet(
            paperStyle: 'default',
            showDragHandle: true,
            isDiary: false,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, size: 20, color: Color(0xFF5A3E28)),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'LXGWWenKai',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A3E28),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 1. 色相卡片
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '色调',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${currentHue.toInt()}°',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF0000),
                                  Color(0xFFFFFF00),
                                  Color(0xFF00FF00),
                                  Color(0xFF00FFFF),
                                  Color(0xFF0000FF),
                                  Color(0xFFFF00FF),
                                  Color(0xFFFF0000),
                                ],
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: Colors.white,
                              trackHeight: 10.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0,
                                elevation: 2.0,
                                pressedElevation: 4.0,
                              ),
                              overlayColor: Colors.white.withValues(alpha: 0.2),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            ),
                            child: Slider(
                              value: currentHue,
                              min: 0.0,
                              max: 360.0,
                              onChanged: (val) {
                                setSheetState(() {
                                  currentHue = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. 饱和度卡片
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '鲜艳度',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(currentSaturation * 100).toInt()}%',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  HSVColor.fromAHSV(1.0, currentHue, 1.0, 1.0).toColor(),
                                ],
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: Colors.white,
                              trackHeight: 10.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0,
                                elevation: 2.0,
                                pressedElevation: 4.0,
                              ),
                              overlayColor: Colors.white.withValues(alpha: 0.2),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            ),
                            child: Slider(
                              value: currentSaturation,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                setSheetState(() {
                                  currentSaturation = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. 亮度卡片
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '明暗度',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(currentValue * 100).toInt()}%',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black,
                                  HSVColor.fromAHSV(1.0, currentHue, currentSaturation, 1.0).toColor(),
                                ],
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: Colors.white,
                              trackHeight: 10.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0,
                                elevation: 2.0,
                                pressedElevation: 4.0,
                              ),
                              overlayColor: Colors.white.withValues(alpha: 0.2),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            ),
                            child: Slider(
                              value: currentValue,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                setSheetState(() {
                                  currentValue = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 预览与确定
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: pickerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: pickerColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hexColor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A3E28),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onColorSelected(pickerColor);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3E28),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '确定使用该颜色',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
