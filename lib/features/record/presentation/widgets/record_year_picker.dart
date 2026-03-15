import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 顶部玻璃拟态年份选择器
class RecordYearPicker extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  const RecordYearPicker({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  State<RecordYearPicker> createState() => _RecordYearPickerState();
}

class _RecordYearPickerState extends State<RecordYearPicker> {
  bool _isExpanded = false;

  // 模拟可选年份列表，实际开发中可以从数据中提取
  final List<int> _years = [
    DateTime.now().year,
    DateTime.now().year - 1,
    DateTime.now().year - 2,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, child) {
        final bool isNight = UserState().isNight;

        return GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isNight
                  ? const Color(0xFF736675).withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isNight
                    ? const Color(0xFFFFF176).withOpacity(0.5)
                    : const Color(0xFFFFF176).withOpacity(0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFF176).withOpacity(isNight ? 0.2 : 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isNight ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.selectedYear} 年',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isNight
                                  ? Colors.white.withOpacity(0.95)
                                  : Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: isNight
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      if (_isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: _years
                                .where((y) => y != widget.selectedYear)
                                .map(
                                  (year) => GestureDetector(
                                    onTap: () {
                                      widget.onYearChanged(year);
                                      setState(() => _isExpanded = false);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '$year 年',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isNight
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
