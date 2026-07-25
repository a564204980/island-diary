import 'package:flutter/material.dart';
import 'package:island_diary/core/models/home_module_config.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 岛屿卡片仓库底部抽屉 (显示未在首页展示的备选卡片)
class CardRepositorySheet extends StatelessWidget {
  final bool isNight;
  final String fontFamily;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final List<HomeModuleItem> inactiveModules;
  final Function(HomeModuleItem item) onAddModule;
  final VoidCallback onResetDefault;

  const CardRepositorySheet({
    super.key,
    required this.isNight,
    required this.fontFamily,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.inactiveModules,
    required this.onAddModule,
    required this.onResetDefault,
  });

  static void show(
    BuildContext context, {
    required bool isNight,
    required String fontFamily,
    required Color textColor,
    required Color subtitleColor,
    required Color accentColor,
    required List<HomeModuleItem> inactiveModules,
    required Function(HomeModuleItem item) onAddModule,
    required VoidCallback onResetDefault,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CardRepositorySheet(
        isNight: isNight,
        fontFamily: fontFamily,
        textColor: textColor,
        subtitleColor: subtitleColor,
        accentColor: accentColor,
        inactiveModules: inactiveModules,
        onAddModule: onAddModule,
        onResetDefault: onResetDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = isNight
        ? const Color(0xFF1E293B)
        : const Color(0xFFF0F4F8);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶端拖拽手柄条
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 头部标题与重置按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.widgets_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "岛屿卡片仓库",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  onResetDefault();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.restore_rounded, size: 16, color: subtitleColor),
                label: Text(
                  "恢复默认",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: fontFamily,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "挑选未展示的卡片，将它们摆放到你的首页吧",
            style: TextStyle(
              fontSize: 12,
              fontFamily: fontFamily,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 16),

          // 备选卡片列表
          if (inactiveModules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 44,
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "所有卡片都已展示在首页上啦！",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: fontFamily,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: inactiveModules.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final module = inactiveModules[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isNight
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            module.icon,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                module.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: fontFamily,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                module.subtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontFamily: fontFamily,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            onAddModule(module);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(
                            "添加",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// 首页卡片全能管理抽屉（供「我的」页面直接调用）
class HomeCardManagerSheet extends StatelessWidget {
  final bool isNight;
  final String fontFamily;

  const HomeCardManagerSheet({
    super.key,
    required this.isNight,
    required this.fontFamily,
  });

  static void show(
    BuildContext context, {
    required bool isNight,
    required String fontFamily,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => HomeCardManagerSheet(
        isNight: isNight,
        fontFamily: fontFamily,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = isNight ? const Color(0xFF1E293B) : const Color(0xFFF0F4F8);
    final textColor = isNight ? const Color(0xFFE3F2FD) : const Color(0xFF2C4A61);
    final subtitleColor = isNight ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF5A788F);
    final accentColor = isNight ? const Color(0xFFFFD54F) : const Color(0xFF2B7A9B);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ValueListenableBuilder<List<HomeModuleItem>>(
        valueListenable: UserState().homeModuleConfigs,
        builder: (context, allModules, child) {
          final activeModules = allModules.where((m) => m.enabled).toList();
          final inactiveModules = allModules.where((m) => !m.enabled).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶端拖拽手柄条
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isNight
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 头部标题与重置按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 22,
                        color: const Color(0xFFAB47BC),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "首页卡片自定义",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      UserState().resetHomeModuleConfigs();
                    },
                    icon: Icon(Icons.restore_rounded, size: 16, color: subtitleColor),
                    label: Text(
                      "恢复默认",
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: fontFamily,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "自由管理首页卡片的显示、隐藏与上下顺序",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: fontFamily,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: 已在首页展示的卡片
                      Text(
                        "已展示的卡片 (${activeModules.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (activeModules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "暂无卡片展示在首页，请从下方添加",
                            style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: fontFamily),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeModules.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final module = activeModules[index];
                            return _buildCardItemTile(
                              context: context,
                              module: module,
                              isNight: isNight,
                              fontFamily: fontFamily,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              accentColor: accentColor,
                              isActive: true,
                              index: index,
                              total: activeModules.length,
                              allModules: allModules,
                              activeModules: activeModules,
                            );
                          },
                        ),

                      const SizedBox(height: 20),

                      // Section 2: 备选卡片仓库
                      Text(
                        "卡片仓库/未展示 (${inactiveModules.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (inactiveModules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "所有卡片都已展示在首页上啦！",
                            style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: fontFamily),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: inactiveModules.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final module = inactiveModules[index];
                            return _buildCardItemTile(
                              context: context,
                              module: module,
                              isNight: isNight,
                              fontFamily: fontFamily,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              accentColor: accentColor,
                              isActive: false,
                              index: index,
                              total: inactiveModules.length,
                              allModules: allModules,
                              activeModules: activeModules,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardItemTile({
    required BuildContext context,
    required HomeModuleItem module,
    required bool isNight,
    required String fontFamily,
    required Color textColor,
    required Color subtitleColor,
    required Color accentColor,
    required bool isActive,
    required int index,
    required int total,
    required List<HomeModuleItem> allModules,
    required List<HomeModuleItem> activeModules,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(module.icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: fontFamily,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: fontFamily,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (isActive) ...[
            // 排序按纽
            if (index > 0)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                color: accentColor,
                onPressed: () {
                  _moveModule(index, -1, activeModules, allModules);
                },
              ),
            if (index < total - 1)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                color: accentColor,
                onPressed: () {
                  _moveModule(index, 1, activeModules, allModules);
                },
              ),
            // 移除按纽
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Color(0xFFE63946)),
              onPressed: () {
                final updated = allModules.map((m) {
                  if (m.id == module.id) return m.copyWith(enabled: false);
                  return m;
                }).toList();
                UserState().saveHomeModuleConfigs(updated);
              },
            ),
          ] else ...[
            // 添加按钮
            ElevatedButton.icon(
              onPressed: () {
                final updated = allModules.map((m) {
                  if (m.id == module.id) return m.copyWith(enabled: true, isFullWidth: true);
                  return m;
                }).toList();
                UserState().saveHomeModuleConfigs(updated);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 15),
              label: Text(
                "添加",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _moveModule(int currentIndex, int direction, List<HomeModuleItem> activeModules, List<HomeModuleItem> allModules) {
    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= activeModules.length) return;

    final item1 = activeModules[currentIndex];
    final item2 = activeModules[targetIndex];

    final updatedAll = List<HomeModuleItem>.from(allModules);
    final idx1 = updatedAll.indexWhere((m) => m.id == item1.id);
    final idx2 = updatedAll.indexWhere((m) => m.id == item2.id);

    if (idx1 != -1 && idx2 != -1) {
      final temp = updatedAll[idx1];
      updatedAll[idx1] = updatedAll[idx2];
      updatedAll[idx2] = temp;
      UserState().saveHomeModuleConfigs(updatedAll);
    }
  }
}
