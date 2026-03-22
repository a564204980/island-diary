import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
// import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/hand_drawn_divider.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
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
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          moodIndex: _currentEntry.moodIndex,
          intensity: _currentEntry.intensity,
          tag: _currentEntry.tag,
          entry: _currentEntry,
        ),
      ),
    ).then((success) {
      if (success == true) {
        try {
          final updated = UserState().savedDiaries.value.firstWhere(
            (e) => e.id == _currentEntry.id,
          );
          setState(() {
            _currentEntry = updated;
          });
        } catch (e) {
          // 如果没找到，保持原样
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
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120), // 调整顶部边距配合 SafeArea
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
            ),
          ),
          _buildFloatingActions(isNight),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(bool isNight) {
    final iconColor = isNight ? Colors.white70 : const Color(0xFF8B5E3C);
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30, // 对齐列表页工具栏高度
      child: Center(
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20), // 统一 Padding 为 20
          decoration: BoxDecoration(
            color: isNight 
                ? const Color(0xFF2C2E30) 
                : Colors.white,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                width: 40, // 统一宽度为 40
              ),
              const SizedBox(width: 40), // 统一间距为 40
              _buildActionButton(
                icon: Icons.edit_note_rounded,
                color: iconColor,
                onTap: _handleEdit,
                label: "编辑",
                iconSize: 28,
                width: 40, // 统一宽度为 40
              ),
              const SizedBox(width: 40), // 统一间距为 40
              _buildActionButton(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent.withOpacity(0.8),
                onTap: _handleDelete,
                label: "删除",
                width: 40, // 统一宽度为 40
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
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
        // 标签行
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 心情标签
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
                    mood.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            // 强度标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DiaryUtils.getMoodIntensityPrefix(mood.label, _currentEntry.intensity),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            // 天气标签
            if (_currentEntry.weather != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_currentEntry.weather} ${_currentEntry.temp ?? ''}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            // 地点标签
            if (_currentEntry.location != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: accentColor),
                    const SizedBox(width: 2),
                    Text(
                      _currentEntry.location!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 10, end: 0);
  }




  Widget _buildRichTextView(bool isNight) {
    final filteredContent = DiaryUtils.getFilteredContent(_currentEntry.content);
    
    final textStyle = TextStyle(
      fontSize: 18,
      height: 1.8,
      color: isNight ? Colors.white.withOpacity(0.85) : const Color(0xFF4A342E),
      fontFamily: 'LXGWWenKai',
    );

    // 使用 TopicTextEditingController 的解析逻辑来实现话题高亮
    final controller = TopicTextEditingController(text: filteredContent);
    controller.baseColor = textStyle.color ?? Colors.black;
    controller.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
    controller.baseFontSize = textStyle.fontSize ?? 18;

    final span = controller.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
      hideMarkdownSymbols: true, // 隐藏 Markdown 符号
    );

    return RichText(
      text: span,
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
