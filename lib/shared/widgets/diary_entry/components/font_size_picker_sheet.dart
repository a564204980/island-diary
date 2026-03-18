import 'package:flutter/material.dart';

class DiaryFontSizePickerSheet extends StatelessWidget {
  final double currentFontSize;
  final ValueChanged<double> onApplyFontSize;

  const DiaryFontSizePickerSheet({
    super.key,
    required this.currentFontSize,
    required this.onApplyFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sizes = [
      {'label': '极小', 'value': 14.0},
      {'label': '小', 'value': 17.0},
      {'label': '默认', 'value': 20.0},
      {'label': '大', 'value': 24.0},
      {'label': '极大', 'value': 28.0},
      {'label': '特大', 'value': 32.0},
    ];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          const Text(
            '设置文字大小',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5E3C),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: sizes.map((size) {
              final isSelected = currentFontSize == size['value'];
              return GestureDetector(
                onTap: () => onApplyFontSize(size['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5E3C)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(
                        0xFF8B5E3C,
                      ).withOpacity(isSelected ? 1.0 : 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    size['label'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF8B5E3C),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // 微调滑块
          Row(
            children: [
              const Icon(Icons.text_fields, size: 20, color: Color(0xFF8B5E3C)),
              Expanded(
                child: Slider(
                  value: currentFontSize.clamp(12.0, 40.0),
                  min: 12,
                  max: 40,
                  divisions: 28,
                  activeColor: const Color(0xFF8B5E3C),
                  inactiveColor: const Color(0xFF8B5E3C).withOpacity(0.2),
                  onChanged: onApplyFontSize,
                ),
              ),
              Text(
                '${currentFontSize.toInt()}',
                style: const TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5E3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
