import 'package:flutter/material.dart';
import 'package:island_diary/core/models/life_line_profile.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/frosted_rainbow.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';

import 'package:island_diary/shared/widgets/time_warp_overlay.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

/// 人生线切换与管理底部弹窗 - 深度视觉优化版
class LifeLineSwitcherSheet extends StatelessWidget {
  const LifeLineSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final isNight = userState.isNight;

    return DiaryBottomSheet(
      paperStyle: 'default',
      isDiary: false,
      showDragHandle: true,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 32 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '人生线切换',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isNight ? Colors.white : const Color(0xFF1F2937),
                      fontFamily: _getFontFamily(),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '每一个选择，都通向一个平行的时空。',
                    style: TextStyle(
                      fontSize: 13,
                      color: isNight ? Colors.white54 : Colors.black54,
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                ],
              ),
              // 强化后的新建按钮
              Container(
                decoration: BoxDecoration(
                  color: isNight ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _showCreateDialog(context),
                  icon: Icon(Icons.add_rounded, 
                    color: isNight ? Colors.white70 : const Color(0xFF4B5563),
                    size: 24,
                  ),
                  tooltip: '开启新人生',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 3. 人生线列表
          Flexible(
            child: ValueListenableBuilder<List<LifeLineProfile>>(
              valueListenable: userState.lifeLines,
              builder: (context, profiles, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: userState.currentLifeLineId,
                  builder: (context, currentId, _) {
                    return ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: profiles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final isCurrent = profile.id == currentId;
                        return _buildProfileItem(context, profile, isCurrent, isNight);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // 适配底部安全区域留白
          SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 10 : 0),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, LifeLineProfile profile, bool isCurrent, bool isNight) {
    final themeColor = const Color(0xFF818CF8);
    
    return GestureDetector(
      onTap: () {
        if (!isCurrent) {
          final isLego = UserState().selectedIslandThemeId.value == 'lego';

          if (isLego) {
            // 乐高主题：播放粒子跃迁特效
            final overlayState = Overlay.of(context, rootOverlay: true);
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final switchFuture = Future.delayed(
                const Duration(milliseconds: 900),
                () => UserState().switchLifeLine(profile.id),
              );
              late OverlayEntry entry;
              entry = OverlayEntry(
                builder: (ctx) => TimeWarpOverlay(
                  nextProfile: profile,
                  switchFuture: switchFuture,
                  onComplete: () => entry.remove(),
                ),
              );
              overlayState.insert(entry);
            });
          } else {
            // 其他主题：直接切换
            Navigator.pop(context);
            UserState().switchLifeLine(profile.id);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isCurrent 
            ? (isNight ? themeColor.withValues(alpha: 0.15) : const Color(0xFFF5F7FF))
            : (isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent 
              ? themeColor.withValues(alpha: 0.8)
              : (isNight ? const Color(0xFFD4A373).withValues(alpha: 0.15) : const Color(0xFFD4A373).withValues(alpha: 0.1)),
            width: isCurrent ? 2.0 : 1.0,
          ),
          boxShadow: isCurrent ? [
            BoxShadow(
              color: themeColor.withValues(alpha: isNight ? 0.2 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ] : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 头像区域
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCurrent 
                    ? [const Color(0xFF818CF8), const Color(0xFFC084FC)]
                    : [Colors.grey.shade400, Colors.grey.shade300],
                ),
                shape: BoxShape.circle,
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: const Color(0xFF818CF8).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ] : [],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            // 文字信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isNight ? Colors.white : const Color(0xFF1F2937),
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.bio.isEmpty ? '一个平行的时空...' : profile.bio,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isNight ? Colors.white54 : Colors.black54,
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                ],
              ),
            ),
            // 状态指示
            if (isCurrent)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF818CF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              )
            else
              IconButton(
                onPressed: () => _showDeleteConfirm(context, profile),
                icon: Icon(Icons.delete_outline_rounded, 
                  size: 20, 
                  color: isNight ? Colors.white24 : Colors.black26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }



  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('开启新的人生线', style: TextStyle(fontFamily: _getFontFamily(), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '给这个时空的你起个名字...',
            hintStyle: TextStyle(fontSize: 14),
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('保留现状', style: TextStyle(color: Colors.grey.shade600))
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                UserState().createLifeLine(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF818CF8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('开启'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, LifeLineProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('抹除「${profile.name}」的时空？', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('此操作将永久删除该人生线下的所有日记和布局，不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('保留')),
          TextButton(
            onPressed: () {
              UserState().deleteLifeLine(profile.id);
              Navigator.pop(context);
              showTopToast(
                context,
                '人生线「${profile.name}」已成功抹除 🍃',
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
              );
            },
            child: const Text('确认抹除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}
