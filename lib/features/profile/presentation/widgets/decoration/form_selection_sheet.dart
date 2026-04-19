import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/decoration/form_grid_item.dart';

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
      'id': 'form_weixiao',
      'name': '活力微笑',
      'path': 'assets/images/emoji/weixiao.png',
      'desc': '元气满满的每一天',
    },
    {
      'id': 'form_sikao',
      'name': '沉思学者',
      'path': 'assets/images/emoji/sikao.png',
      'desc': '深夜哲思的伙伴',
    },
    {
      'id': 'form_nanguo',
      'name': '忧郁小软',
      'path': 'assets/images/emoji/nanguo.png',
      'desc': '静静陪你难过一会儿',
    },
    {
      'id': 'form_pedding',
      'name': '甜品布丁',
      'path': 'assets/images/emoji/pedding.png',
      'desc': '看起来很好吃的样子',
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF1A1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isNight ? 0.5 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                    fontFamily: 'LXGWWenKai',
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
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                userState.selectedMascotType,
                userState.unlockedMascotPaths,
                userState.vipLevel,
              ]),
              builder: (context, _) {
                final currentType = userState.selectedMascotType.value;
                final unlockedPaths = userState.unlockedMascotPaths.value;
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
                          : !unlockedPaths.contains(aPath);
                  bool bLocked =
                      (bPath == 'assets/images/emoji/marshmallow4.png')
                          ? !isVip
                          : !unlockedPaths.contains(bPath);
                  if (aLocked != bLocked) return aLocked ? 1 : -1;
                  return 0;
                });

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                    bool isLocked = !unlockedPaths.contains(path);
                    String? lockHint;
                    if (path == 'assets/images/emoji/marshmallow4.png') {
                      isLocked = !isVip;
                      lockHint = isLocked ? '星光计划专属' : null;
                    } else if (isLocked) {
                      lockHint = '待成就解锁';
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
          ),
        ],
      ),
    );
  }
}
