import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:intl/intl.dart';

class EditorHeader extends StatelessWidget {
  final String paperStyle;
  final bool isNight;
  final DateTime dateTime;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onDateTap;

  const EditorHeader({
    super.key,
    required this.paperStyle,
    required this.isNight,
    required this.dateTime,
    required this.onBack,
    required this.onSave,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final String dateStr = DateFormat('yyyy年M月d日').format(dateTime);
    final String weekStr = _getChineseWeekDay(dateTime.weekday);
    final String timeStr = DateFormat('HH:mm').format(dateTime);

    final Color bgColor = isNight ? const Color(0xFF121212) : const Color(0xFFFAF8F5);
    // 如果是特定的信纸，可以从 DiaryUtils 获取对应的背景色
    
    return Container(
      color: bgColor, // 确保置顶时遮挡下方文字
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // 1. 左侧返回按钮
              _buildCircleBtn(
                icon: Icons.chevron_left_rounded,
                onTap: onBack,
                isNight: isNight,
              ),
              
              // 2. 中间日期时间
              Expanded(
                child: GestureDetector(
                  onTap: onDateTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "$dateStr  $weekStr  $timeStr",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: inkColor.withValues(alpha: 0.6),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: inkColor.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 右侧按钮组
              _buildSaveBtn(isNight: isNight, onTap: onSave),
            ],
          ),
        ),
        // 底部细横线 (提高显见度)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 0.8,
          color: inkColor.withValues(alpha: 0.1),
        ),
      ],
    ),
  );
}

  Widget _buildCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isNight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isNight ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSaveBtn({required bool isNight, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1E8).withValues(alpha: isNight ? 0.1 : 1.0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/save.png',
              width: 18,
              height: 18,
              color: const Color(0xFF7A7A6A),
            ),
            const SizedBox(width: 6),
            const Text(
              "保存",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A7A6A),
                fontWeight: FontWeight.bold,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChineseWeekDay(int weekday) {
    const weeks = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"];
    return weeks[weekday - 1];
  }
}
