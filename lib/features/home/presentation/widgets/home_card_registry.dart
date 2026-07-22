import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';

// Card widgets
import 'package:island_diary/features/home/presentation/widgets/photo_wall_card.dart';
import 'package:island_diary/features/home/presentation/widgets/treasure_gravity_box.dart';
import 'package:island_diary/features/home/presentation/widgets/random_memory_overlay.dart';
import 'package:island_diary/features/home/presentation/widgets/inspiration_quote_card.dart';

/// 卡片构建参数管道
class HomeCardBuildContext {
  final BuildContext context;
  final bool isNight;
  final String themeId;
  final String fontFamily;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;
  final List<DateTime> last7Days;
  final DiaryEntry? Function(DateTime date) getEntryForDate;
  final Function(DateTime date, DiaryEntry? entry) openEditorWithDate;
  final Widget Function({
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    bool isRow,
    double? height,
  }) buildGlassCard;

  HomeCardBuildContext({
    required this.context,
    required this.isNight,
    required this.themeId,
    required this.fontFamily,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.groupedEntries,
    required this.last7Days,
    required this.getEntryForDate,
    required this.openEditorWithDate,
    required this.buildGlassCard,
  });
}

/// 首页卡片注册表中心
class HomeCardRegistry {
  /// 根据模块 ID 渲染对应的 Widget，支持 isTall 动态自适应拉长
  static Widget buildCard(String id, HomeCardBuildContext ctx, Widget pianoMoodWidget, Widget photoThrowbackWidget, {bool isTall = false, bool isEditMode = false}) {
    switch (id) {
      case 'photo_throwback':
        return GestureDetector(
          onTap: () {
            RandomMemoryOverlay.show(ctx.context, isNight: ctx.isNight);
          },
          child: photoThrowbackWidget,
        );

      case 'photo_wall':
        return PhotoWallCard(
          groupedEntries: ctx.groupedEntries,
          textColor: ctx.textColor,
          subtitleColor: ctx.subtitleColor,
          accentColor: ctx.accentColor,
          fontFamily: ctx.fontFamily,
          isNight: ctx.isNight,
          isTall: isTall,
        );

      case 'gravity_box':
        return ctx.buildGlassCard(
          onTap: null,
          padding: EdgeInsets.zero,
          height: isTall ? 296 : 140,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
                  ? constraints.maxWidth
                  : 160;
              return TreasureGravityBoxWidget(
                width: w,
                height: isTall ? 296 : 140,
                textColor: ctx.textColor,
                subtitleColor: ctx.subtitleColor,
                accentColor: ctx.accentColor,
                fontFamily: ctx.fontFamily,
              );
            },
          ),
        );

      case 'piano_mood':
        return pianoMoodWidget;

      case 'inspiration_quote':
        return InspirationQuoteCard(
          textColor: ctx.textColor,
          subtitleColor: ctx.subtitleColor,
          accentColor: ctx.accentColor,
          fontFamily: ctx.fontFamily,
          isNight: ctx.isNight,
          isEditMode: isEditMode,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
