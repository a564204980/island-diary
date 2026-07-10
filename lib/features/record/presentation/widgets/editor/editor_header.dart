import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

class EditorHeader extends StatelessWidget {
  final String paperStyle;
  final bool isNight;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final bool isDraft;

  const EditorHeader({
    super.key,
    required this.paperStyle,
    required this.isNight,
    required this.onBack,
    required this.onSave,
    this.isDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // 根据用户要求调整为全透明，无分割线
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
              
              const Spacer(),

              // 3. 右侧按钮组 (如果是草稿，显示草稿标识；如果不是，则用 SizedBox(width: 48) 占位保持对称)
              if (isDraft)
                _buildDraftBadge(isNight)
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDraftBadge(bool isNight) {
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    final Color inkColor = isNight
        ? Colors.white.withValues(alpha: 0.9)
        : DiaryUtils.getInkColor(paperStyle, isNight);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        '草稿',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: inkColor,
          fontFamily: fontFamily,
          letterSpacing: 1,
        ),
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

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon == Icons.chevron_left_rounded ? Icons.arrow_back_ios_new_rounded : icon,
        size: 20,
        color: isNight ? Colors.white70 : Colors.black87,
      ),
    );
  }



}
