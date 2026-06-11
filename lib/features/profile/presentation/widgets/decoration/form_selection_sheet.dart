import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/form_grid_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class MascotFormSelectionSheet extends StatelessWidget {
  final bool isNight;
  final UserState userState;

  static const List<Map<String, String>> mascotForms = [
    {
      'id': 'form_marshmallow',
      'name': '云织',
      'path': 'assets/images/emoji/marshmallow.png',
      'desc': '软绵绵的最初陪伴，编织每一天的温柔',
      'rarity': '传说',
    },

    {
      'id': 'form_marshmallow2',
      'name': '笃守',
      'path': 'assets/images/emoji/marshmallow2.png',
      'desc': '汪汪！不论何时，都是你最忠实的森林伙伴',
      'rarity': '普通',
    },
    {
      'id': 'form_marshmallow3',
      'name': '灵犀',
      'path': 'assets/images/emoji/marshmallow3.png',
      'desc': '敏捷聪慧的灵之化身，洞察林间的秘密',
      'rarity': '卓越',
    },
    {
      'id': 'form_marshmallow4',
      'name': '霜见',
      'path': 'assets/images/emoji/marshmallow4.png',
      'desc': '月光般轻盈恬静，静谧守望你的思绪',
      'rarity': '传说',
    },
  ];

  const MascotFormSelectionSheet({
    super.key,
    required this.isNight,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    return DiaryBottomSheet(
       paperStyle: 'default',
       showDragHandle: true,
       isDiary: false,
       padding: EdgeInsets.only(
         left: 0,
         right: 0,
         top: 12,
         bottom: 12 + MediaQuery.of(context).padding.bottom,
       ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_fix_high_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  '变更形象',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : const Color(0xFF1F2937),
                    fontFamily: _getFontFamily(),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isNight ? Colors.white38 : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              userState.selectedMascotType,
              userState.vipLevel,
            ]),
            builder: (context, _) {
              final currentType = userState.selectedMascotType.value;
              final isVip = userState.isVip.value;

              final targetPaths = [
                'assets/images/emoji/marshmallow.png',
                'assets/images/emoji/marshmallow2.png',
                'assets/images/emoji/marshmallow3.png',
                'assets/images/emoji/marshmallow4.png',
              ];
              final filteredForms = mascotForms
                  .where((f) => targetPaths.contains(f['path']))
                  .toList();

              filteredForms.sort((a, b) {
                final aPath = a['path']!;
                final bPath = b['path']!;
                bool aLocked =
                    (aPath == 'assets/images/emoji/marshmallow4.png')
                    ? !isVip
                    : false;
                bool bLocked =
                    (bPath == 'assets/images/emoji/marshmallow4.png')
                    ? !isVip
                    : false;
                if (aLocked != bLocked) return aLocked ? 1 : -1;
                return 0;
              });

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: filteredForms.length,
                itemBuilder: (context, index) {
                  final form = filteredForms[index];
                  final path = form['path']!;
                  bool isLocked = false;
                  String? lockHint;
                  if (path == 'assets/images/emoji/marshmallow4.png') {
                    isLocked = !isVip;
                    lockHint = isLocked ? '星光计划专属' : null;
                  }
                  return FormGridItem(
                    form: form,
                    isSelected: currentType == path,
                    isNight: isNight,
                    isLocked: isLocked,
                    lockHint: lockHint,
                    index: index,
                    shouldAnimate: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}
