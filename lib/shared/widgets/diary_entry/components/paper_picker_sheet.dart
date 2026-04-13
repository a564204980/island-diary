import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_painters.dart';

class PaperPickerSheet extends StatelessWidget {
  final String currentStyle;
  final ValueChanged<String> onStyleSelected;
  final Color accentColor;

  const PaperPickerSheet({
    super.key,
    required this.currentStyle,
    required this.onStyleSelected,
    required this.accentColor,
  });

  static const Map<String, String> styles = {
    'note1': '岛屿',
    'note2': '复古',
    'note3': '极简',
    'note4': '淡雅',
  };

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color bgColor = isNight ? const Color(0xFF2D2A26) : const Color(0xFFFDF7E9);
    final Color textColor = isNight ? Colors.white70 : const Color(0xFF5D4037);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "选择信纸风格",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor.withOpacity(0.5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final key = styles.keys.elementAt(index);
                final label = styles.values.elementAt(index);
                final isSelected = currentStyle == key;

                return GestureDetector(
                  onTap: () => onStyleSelected(key),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isNight ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentColor : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                if (key.startsWith('note'))
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/note/${key.replaceFirst('note', 'note_bg')}${['note1', 'note2', 'note3', 'note4'].contains(key) ? '.png' : '.jpg'}',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: PaperBackgroundPainter(
                                      style: key,
                                      isNight: isNight,
                                      accentColor: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? accentColor : textColor.withOpacity(0.6),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
