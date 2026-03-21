import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/diary_entry/diary_entry_sheet.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/hand_drawn_divider.dart';
// import 'package:lunar/lunar.dart'; // 移除未使用导入

class DiaryDetailPage extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNight;

  const DiaryDetailPage({
    super.key,
    required this.entry,
    this.isNight = false,
  });

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late DiaryEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  void _handleDelete() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isNight ? const Color(0xFF2D2A26) : const Color(0xFFFDF7E9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isNight ? Colors.white10 : const Color(0xFFE8D5B5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🏮",
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 16),
              Text(
                "确定要抹去这段回忆吗？",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isNight ? Colors.white70 : const Color(0xFF5D4037),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "保留下",
                      style: TextStyle(
                        color: widget.isNight ? Colors.white30 : Colors.black26,
                        fontFamily: 'LXGWWenKai',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      UserState().deleteDiary(_currentEntry);
                      Navigator.pop(context); // 关闭弹窗
                      Navigator.pop(context); // 返回列表
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A373),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "确定抹去",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _handleEdit() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => MoodDiaryEntrySheet(
        moodIndex: _currentEntry.moodIndex,
        intensity: _currentEntry.intensity,
        tag: _currentEntry.tag,
        entry: _currentEntry,
      ),
    ).then((success) {
      if (success == true) {
        // 通过 UserState 寻找更新后的条目
        try {
          final updated = UserState().savedDiaries.value.firstWhere(
            (e) => e.id == _currentEntry.id,
          );
          setState(() {
            _currentEntry = updated;
          });
        } catch (e) {
          // 如果没找到（极其罕见的情况），则保持现状
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = widget.isNight;
    final bgColor = isNight ? const Color(0xFF13131F) : const Color(0xFFF7F2E9);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true, 
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 40), // 减少底部边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isNight),
            const SizedBox(height: 32),
            _buildRichTextView(isNight),
            const SizedBox(height: 48),
            _buildImages(isNight),
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingActions(isNight),
    );
  }

  Widget _buildFloatingActions(bool isNight) {
    final iconColor = isNight ? Colors.white70 : const Color(0xFF8B5E3C);
    
    return Container(
      height: 100, // 足够高以包含悬浮位置偏移
      color: Colors.transparent, // 保持全透明背景
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 30, // 距离屏幕物理底部的固定偏移
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isNight 
                    ? const Color(0xFF2C2E30) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: iconColor,
                    onTap: () => Navigator.pop(context),
                    label: "返回",
                    width: 68,
                  ),
                  _buildVerticalDivider(isNight),
                  _buildActionButton(
                    icon: Icons.edit_note_rounded,
                    color: iconColor,
                    onTap: _handleEdit,
                    label: "编辑",
                    iconSize: 28,
                    width: 68,
                  ),
                  _buildVerticalDivider(isNight),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent.withOpacity(0.8),
                    onTap: _handleDelete,
                    label: "删除",
                    width: 68,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    double iconSize = 24,
    double width = 72,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: 54,
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildVerticalDivider(bool isNight) {
    return Container(
      width: 1,
      height: 20,
      color: isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
    );
  }

  Widget _buildHeader(bool isNight) {
    final dt = _currentEntry.dateTime;
    final mood = kMoods[_currentEntry.moodIndex.clamp(0, kMoods.length - 1)];
    final dateStr = "${dt.year}年${dt.month}月${dt.day}日";
    final timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    final quote = DiaryUtils.getMoodQuote(mood.label);

    final baseGlowColor = mood.glowColor ?? const Color(0xFFD4A373);
    final accentColor = isNight 
        ? baseGlowColor 
        : Color.lerp(baseGlowColor, Colors.black, 0.45)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一行：大时间 + 日期
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: isNight ? accentColor : const Color(0xFF8B5E3C),
                fontFamily: 'LXGWWenKai',
                letterSpacing: -1,
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isNight ? Colors.white38 : const Color(0xFFAFA296),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 第二行：治愈语录
        Text(
          quote,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: isNight ? Colors.white38 : const Color(0xFFAFA296),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 12),
        // 第三行：手绘分割线
        CustomPaint(
          size: const Size(double.infinity, 2),
          painter: HandDrawnLinePainter(
            color: isNight ? Colors.white10 : const Color(0xFF8B5E3C).withOpacity(0.5),
            strokeWidth: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        // 浮动信息：心情标签 + 地点 + 天气
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'mood_${_currentEntry.id}',
                    child: Image.asset(
                      mood.iconPath ?? 'assets/images/icons/sun.png',
                      width: 14,
                      height: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DiaryUtils.getPureMoodDescription(mood.label, _currentEntry.intensity),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildQuickInfo(isNight),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildQuickInfo(bool isNight) {
    final info = DiaryUtils.getExtraInfoFromContent(_currentEntry.content);
    final textColor = isNight ? Colors.white30 : const Color(0xFF8B7E74);

    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (info.containsKey('location')) ...[
              const Text(" · ", style: TextStyle(color: Colors.black12)),
              Icon(Icons.location_on_outlined, size: 12, color: textColor),
              const SizedBox(width: 2),
              Text(info['location']!, style: TextStyle(fontSize: 12, color: textColor)),
            ],
            if (info.containsKey('weather')) ...[
              const Text(" · ", style: TextStyle(color: Colors.black12)),
              Icon(Icons.wb_cloudy_outlined, size: 12, color: textColor),
              const SizedBox(width: 2),
              Text("${info['weather']} ${info['temp']}", style: TextStyle(fontSize: 12, color: textColor)),
            ],
            if (_currentEntry.tag != null && _currentEntry.tag!.isNotEmpty) ...[
              const Text(" · ", style: TextStyle(color: Colors.black12)),
              Text("# ${_currentEntry.tag}", style: TextStyle(fontSize: 12, color: textColor)),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildRichTextView(bool isNight) {
    final filteredContent = DiaryUtils.getFilteredContent(_currentEntry.content);
    final chunks = EmojiMapping.parseText(filteredContent);
    
    final textStyle = TextStyle(
      fontSize: 18,
      height: 1.8,
      color: isNight ? Colors.white.withOpacity(0.85) : const Color(0xFF4A342E),
      fontFamily: 'LXGWWenKai',
    );

    return RichText(
      text: TextSpan(
        children: chunks.map((chunk) {
          if (chunk.isEmoji) {
            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Image.asset(
                  chunk.emojiPath!,
                  width: 24,
                  height: 24,
                ),
              ),
            );
          }
          return TextSpan(text: chunk.text, style: textStyle);
        }).toList(),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 800.ms);
  }

  Widget _buildImages(bool isNight) {
    final images = _currentEntry.blocks.where((b) => b['type'] == 'image').toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final path = images[index]['path'];
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: DiaryUtils.buildImage(
            path,
            fit: BoxFit.cover,
          ),
        );
      },
    ).animate().fadeIn(delay: 500.ms, duration: 800.ms);
  }
}
