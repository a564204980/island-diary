import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AchievementCategoryStrip extends StatelessWidget {
  final List<String> categories;
  final int activeIndex;
  final Function(int) onCategoryChanged;
  final bool isNight;

  const AchievementCategoryStrip({
    super.key,
    required this.categories,
    required this.activeIndex,
    required this.onCategoryChanged,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = activeIndex == index;
          return GestureDetector(
            onTap: () => onCategoryChanged(index),
            child: AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isNight ? const Color(0xFFFFF176) : Colors.black) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected && !isNight ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? (isNight ? Colors.black : Colors.white) 
                      : (isNight ? Colors.white38 : Colors.black38),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
