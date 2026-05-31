import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/core/state/user_state.dart';

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

    final themeId = UserState().selectedIslandThemeId.value;
    final bool hasPaperBg = paperStyle.startsWith('note') ||
        (paperStyle == 'classic' && themeId == 'cotton_candy');

    final Color bgColor = hasPaperBg
        ? Colors.transparent
        : (isNight 
            ? const Color(0xFF121212) 
            : (themeId == 'lego' ? const Color(0xFFFDF3E3) : const Color(0xFFFAF8F5)));
    
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
        if (!hasPaperBg)
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
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    if (isLego) {
      final Color btnColor = isNight ? const Color(0xFF2C2518) : const Color(0xFFFFFDF2); // 高保真极柔和米黄白色
      final Color depthColor = isNight ? const Color(0xFF1B160E) : const Color(0xFFEADAB9); // 3D 厚度实色积木层
      final Color shadowColor = isNight ? const Color(0x80000000) : const Color(0x3D5D4037);
      final Color arrowColor = isNight ? Colors.white70 : const Color(0xFF5D4037); // 经典的深木巧克力色

      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 38,
          margin: const EdgeInsets.only(bottom: 4), // 留出 3D 投影和软影的浮空空间
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(16), // 还原图1中温润圆润的扁矩形大圆角
            boxShadow: [
              // 1. 上层 3D 积木厚度实色层（零羽化）
              BoxShadow(
                color: depthColor,
                blurRadius: 0,
                offset: const Offset(0, 3.5),
              ),
              // 2. 底层环境遮蔽软影
              BoxShadow(
                color: shadowColor,
                blurRadius: 5.0,
                offset: const Offset(0, 5.0),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded, // 还原图1中粗壮可爱的向左直箭头，符合积木拼装感
            size: 20,
            color: arrowColor,
          ),
        ),
      );
    }

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
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    if (isLego) {
      final Color btnColor = isNight ? const Color(0xFF3B6B15) : const Color(0xFF76B131); // 乐高亮绿色塑料积木板
      final Color depthColor = isNight ? const Color(0xFF25470B) : const Color(0xFF598E20); // 3D 厚度实色积木层
      final Color shadowColor = isNight ? const Color(0x80000000) : const Color(0x3D335213); // 塑料积木底部遮蔽影
      final Color textColor = Colors.white;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 4), // 留出 3D 投影和软影的浮空空间
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(16), // 与左侧返回积木按钮完全一致的温润圆润大圆角
            boxShadow: [
              // 1. 上层 3D 积木厚度实色层（零羽化）
              BoxShadow(
                color: depthColor,
                blurRadius: 0,
                offset: const Offset(0, 3.5),
              ),
              // 2. 底层环境遮蔽软影
              BoxShadow(
                color: shadowColor,
                blurRadius: 5.0,
                offset: const Offset(0, 5.0),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 还原图1中飞向右上角的灵动纸飞机
              Transform.rotate(
                angle: -0.4, // 逆时针微调旋转，使其朝向右上角展翅高飞
                child: Icon(
                  Icons.send_rounded,
                  size: 15,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "保存",
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;

    final Color itemColor = isCottonCandyDark
        ? Colors.white
        : const Color(0xFF7A7A6A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isCottonCandyDark
              ? Colors.white.withValues(alpha: 0.3)
              : const Color(0xFFF1F1E8).withValues(alpha: isNight ? 0.1 : 1.0),
          borderRadius: BorderRadius.circular(20),
          border: isCottonCandyDark
              ? Border.all(
                  color: const Color(0xFF9986E1).withValues(alpha: 0.5),
                  width: 3,
                )
              : null,
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/save.png',
              width: 18,
              height: 18,
              color: itemColor,
            ),
            const SizedBox(width: 6),
            Text(
              "保存",
              style: TextStyle(
                fontSize: 13,
                color: itemColor,
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
