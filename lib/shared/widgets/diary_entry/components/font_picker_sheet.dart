import 'package:flutter/material.dart';

class DiaryFontPickerSheet extends StatelessWidget {
  final String currentFontFamily;
  final ValueChanged<String> onApplyFontFamily;

  const DiaryFontPickerSheet({
    super.key,
    required this.currentFontFamily,
    required this.onApplyFontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> fonts = [
      {'label': '霞鹜文楷', 'value': 'LXGWWenKai'},
      {'label': '方正楷体', 'value': 'FZKai'},
      {'label': '阿里巴巴普惠', 'value': 'Alibaba'},
      {'label': '抖音真体', 'value': 'Douyin'},
      {'label': '荆南波波黑', 'value': 'JingNan'},
      {'label': '西木手写', 'value': 'Nishiki'},
    ];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
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
            '常用字体',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5E3C),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
              final isSelected = currentFontFamily == font['value'];
              return GestureDetector(
                onTap: () => onApplyFontFamily(font['value']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5E3C)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(
                        0xFF8B5E3C,
                      ).withOpacity(isSelected ? 1.0 : 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      font['label']!,
                      style: TextStyle(
                        fontFamily: font['value'],
                        fontSize: 14,
                        color: isSelected ? Colors.white : const Color(0xFF8B5E3C),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
