import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

class MoodPosterWidget extends StatefulWidget {
  final List<DiaryEntry> entries;
  final bool isNight;

  const MoodPosterWidget({
    super.key,
    required this.entries,
    required this.isNight,
  });

  @override
  State<MoodPosterWidget> createState() => _MoodPosterWidgetState();
}

class _MoodPosterWidgetState extends State<MoodPosterWidget> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<void> _sharePoster() async {
    try {
      RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/soul_poster_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(buffer);

      await Share.shareXFiles([XFile(file.path)], text: '分享我在岛屿上的情绪洞察 ✨');
    } catch (e) {
      debugPrint('Error sharing poster: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = SoulSeasonLogic.getSeason(widget.entries);
    final now = DateTime.now();
    final dateRange = DateFormat('yyyy.MM').format(now);
    
    // 统计前三个关键词
    Map<String, int> tags = {};
    for (var e in widget.entries) {
      if (e.tag != null && e.tag!.isNotEmpty) {
        tags[e.tag!] = (tags[e.tag!] ?? 0) + 1;
      }
    }
    final sortedTags = tags.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(3).map((e) => e.key).toList();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.isNight ? const Color(0xFF1A1A1A) : const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(32),
                    image: DecorationImage(
                      image: const AssetImage('assets/images/paper.png'),
                      opacity: 0.1,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: season.accentColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'ISLAND DIARY',
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w900,
                                color: season.accentColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '月度情绪洞察',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: widget.isNight ? Colors.white : const Color(0xFF5D4037),
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateRange,
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.isNight ? Colors.white38 : Colors.black26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Visualized Content
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            // Large Mood Icons
                            Wrap(
                              spacing: -20,
                              children: widget.entries.take(5).map((e) {
                                final mood = kMoods[e.moodIndex % kMoods.length];
                                return Transform.rotate(
                                  angle: (widget.entries.indexOf(e) - 2) * 0.2,
                                  child: Image.asset(
                                    (e.tag != null && e.tag!.isNotEmpty) ? 'assets/images/icons/custom.png' : mood.iconPath!,
                                    width: 80,
                                    height: 80,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 40),
                            // Season Title
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: season.accentColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                season.seasonName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Poetic Description
                            Text(
                              season.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.8,
                                color: widget.isNight ? Colors.white70 : const Color(0xFF5D4037),
                                fontFamily: 'LXGWWenKai',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Keywords
                            if (topTags.isNotEmpty)
                              Wrap(
                                spacing: 12,
                                children: topTags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: season.accentColor.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '# $tag',
                                    style: TextStyle(color: season.accentColor, fontWeight: FontWeight.bold),
                                  ),
                                )).toList(),
                              ),
                          ],
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: season.accentColor.withOpacity(0.1))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '我在岛屿上，记录自己的每个瞬间',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isNight ? Colors.white24 : Colors.black26,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('💧', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Island Diary',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: season.accentColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Fake QR Code placeholder
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: season.accentColor.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(CupertinoIcons.qrcode, size: 24, color: season.accentColor.withOpacity(0.3)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 50,
            right: 50,
            child: ElevatedButton.icon(
              onPressed: _sharePoster,
              icon: const Icon(CupertinoIcons.share),
              label: const Text('生成海报并分享', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: season.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
