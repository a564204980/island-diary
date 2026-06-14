import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';

class DiaryDraftsPage extends StatefulWidget {
  const DiaryDraftsPage({super.key});

  @override
  State<DiaryDraftsPage> createState() => _DiaryDraftsPageState();
}

class _DiaryDraftsPageState extends State<DiaryDraftsPage> {
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "今天 ${DateFormat('HH:mm').format(dt)}";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return "昨天 ${DateFormat('HH:mm').format(dt)}";
    }
    return DateFormat('MM-dd HH:mm').format(dt);
  }

  void _clearAll(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 20, left: 24, right: 24),
                child: Text(
                  "确定要清空所有草稿吗？",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              Container(
                height: 0.5,
                color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(dialogCtx),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "取消",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            color: isNight ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 50,
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        UserState().clearAllDrafts();
                        Navigator.pop(dialogCtx);
                        showTopToast(
                          context,
                          '所有草稿已成功清空 🍃',
                          icon: Icons.delete_outline_rounded,
                          iconColor: const Color(0xFFEF4444),
                        );
                        try {
                          HapticFeedback.mediumImpact();
                        } catch (_) {}
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "清空",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD35D5D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteDraft(BuildContext context, String draftId) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 20, left: 24, right: 24),
                child: Text(
                  "确定要删除这篇草稿吗？",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              Container(
                height: 0.5,
                color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(dialogCtx),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "取消",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            color: isNight ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 50,
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        UserState().deleteDraftEntry(draftId);
                        Navigator.pop(dialogCtx);
                        showTopToast(
                          context,
                          '草稿已成功删除 🍃',
                          icon: Icons.delete_outline_rounded,
                          iconColor: const Color(0xFFEF4444),
                        );
                        try {
                          HapticFeedback.mediumImpact();
                        } catch (_) {}
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "删除",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD35D5D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    final Color bgColor = isNight ? const Color(0xFF121218) : const Color(0xFFFAF9F6);
    final Color cardBgColor = isNight ? const Color(0xFF1E1E28) : Colors.white;
    final Color textColor = isNight ? Colors.white : const Color(0xFF1F2937);
    final Color subTextColor = isNight ? Colors.white54 : const Color(0xFF6B7280);
    final Color borderColor = isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    return Stack(
      children: [
        // 1. 全屏背景
        Positioned.fill(
          child: Container(color: bgColor),
        ),
        // 2. 页面主体（Scaffold 保持透明背景，限制滚动视口）
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "草稿箱",
              style: TextStyle(
                color: textColor,
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              ValueListenableBuilder<List<DiaryDraft>>(
                valueListenable: UserState().savedDrafts,
                builder: (context, drafts, _) {
                  if (drafts.isEmpty) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () => _clearAll(context),
                    child: Text(
                      "清空",
                      style: TextStyle(
                        color: const Color(0xFFD35D5D),
                        fontFamily: fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ValueListenableBuilder<List<DiaryDraft>>(
            valueListenable: UserState().savedDrafts,
            builder: (context, drafts, _) {
              if (drafts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 64,
                        color: isNight ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "草稿箱空空如也",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: fontFamily,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "随手写下但未发布的内容会保存在这里",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: fontFamily,
                          color: subTextColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  
                  // 提取首张图片
                  String? imagePath;
                  if (draft.blocks != null) {
                    for (var block in draft.blocks!) {
                      if (block['type'] == 'image' && block['filePath'] != null) {
                        imagePath = block['filePath'] as String;
                        break;
                      }
                    }
                  }

                  // 获取心情图标
                  final parsed = ParsedTags.parse(draft.tag, draft.moodIndex);
                  String moodIcon = 'assets/icons/happy.png';
                  String moodLabel = '未记录';
                  String? customMoodIconPath = parsed.customMoodIconPath;

                  if (parsed.customMood != null) {
                    moodLabel = parsed.customMood!;
                    moodIcon = (draft.moodIndex != null && draft.moodIndex! >= 0 && draft.moodIndex! <= 23)
                        ? 'assets/icons/custom${draft.moodIndex! + 1}.png'
                        : 'assets/images/icons/custom.png';
                  } else if (draft.moodIndex != null && draft.moodIndex! >= 0 && draft.moodIndex! < kMoods.length) {
                    final mood = kMoods[draft.moodIndex!];
                    moodIcon = mood.iconPath ?? moodIcon;
                    moodLabel = mood.label;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isNight ? 0.15 : 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiaryEditorPage(
                                draft: draft,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 心情区域
                              Column(
                                children: [
                                  DiaryUtils.buildImage(
                                    customMoodIconPath ?? moodIcon,
                                    width: 28,
                                    height: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    moodLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: fontFamily,
                                      color: subTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // 文本区域
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final String plainText = draft.content.trim();
                                        if (plainText.isEmpty) {
                                          return Text(
                                            "无文字内容",
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                              fontFamily: fontFamily,
                                              color: subTextColor.withValues(alpha: 0.5),
                                            ),
                                          );
                                        }

                                        final baseStyle = TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          fontFamily: fontFamily,
                                          color: textColor.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w500,
                                        );

                                        final List<InlineSpan> spans = EmojiMapping.parseText(plainText).map((chunk) {
                                          if (chunk.isEmoji) {
                                            return WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                                child: Image.asset(
                                                  chunk.emojiPath!,
                                                  width: baseStyle.fontSize! * 1.2,
                                                  height: baseStyle.fontSize! * 1.2,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            );
                                          }
                                          return TextSpan(text: chunk.text, style: baseStyle);
                                        }).toList();

                                        return RichText(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(children: spans),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _formatDateTime(draft.updatedAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subTextColor.withValues(alpha: 0.6),
                                        fontFamily: 'sans-serif',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 右侧多媒体缩略图/删除按钮
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (imagePath != null) ...[
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderColor, width: 0.5),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: DiaryUtils.buildImage(imagePath, fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: const Color(0xFFD35D5D).withValues(alpha: 0.8),
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteDraft(context, draft.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
