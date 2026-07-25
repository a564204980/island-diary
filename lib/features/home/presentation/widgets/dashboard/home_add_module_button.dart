import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/models/home_module_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/widgets/card_repository_sheet.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';

/// 编辑模式下网格下方的"扩充或添加新模块"高颜值按钮
class HomeAddModuleButton extends StatelessWidget {
  final bool isNight;
  final String fontFamily;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final List<HomeModuleItem> allModules;

  /// 校验新增模块是否超出屏幕容量的函数
  final bool Function(HomeModuleItem itemToAdd) canAddModule;

  const HomeAddModuleButton({
    super.key,
    required this.isNight,
    required this.fontFamily,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.allModules,
    required this.canAddModule,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveModules = allModules.where((m) => !m.enabled).toList();
    final isDark = isNight;
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return BouncingButton(
      scaleFactor: 0.96,
      onTap: () {
        HapticFeedback.mediumImpact();

        CardRepositorySheet.show(
          context,
          isNight: isDark,
          fontFamily: fontFamily,
          textColor: textColor,
          subtitleColor: subtitleColor,
          accentColor: accentColor,
          inactiveModules: inactiveModules,
          onAddModule: (item) {
            if (!canAddModule(item)) {
              return;
            }

            final updatedAll = List<HomeModuleItem>.from(allModules);
            final idx = updatedAll.indexWhere((m) => m.id == item.id);
            if (idx != -1) {
              updatedAll[idx] = updatedAll[idx].copyWith(enabled: true, isFullWidth: true);
              UserState().saveHomeModuleConfigs(updatedAll);
            }
          },
          onResetDefault: () {
            UserState().saveHomeModuleConfigs(HomeModuleItem.getDefaultModules());
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "添加更多小组件",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: fontFamily,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 350.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }
}
