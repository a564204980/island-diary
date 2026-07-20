import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/home/presentation/widgets/random_memory_overlay.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';

class HomeDashboardView extends StatelessWidget {
  final bool isNight;
  final String themeId;
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;

  const HomeDashboardView({
    super.key,
    required this.isNight,
    required this.themeId,
    required this.groupedEntries,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = UserState().userName.value.isEmpty ? "岛主" : UserState().userName.value;
    if (hour < 5) return "夜深了，$name";
    if (hour < 9) return "早上好，$name";
    if (hour < 12) return "上午好，$name";
    if (hour < 14) return "中午好，$name";
    if (hour < 18) return "下午好，$name";
    if (hour < 22) return "晚上好，$name";
    return "夜深了，$name";
  }

  void _openEditorWithMood(BuildContext context, int moodIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(
          moodIndex: moodIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    // 配色系统：融入海洋背景的清爽冷色调
    final textColor = isNight ? const Color(0xFFE3F2FD) : const Color(0xFF1E3A52);
    final subtitleColor = isNight ? const Color(0xFF90CAF9) : const Color(0xFF4A6B82);
    final accentColor = isNight ? const Color(0xFFFFD54F) : const Color(0xFFD87C30);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 3),
            
            // 顶部问候与登岛天数
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: fontFamily,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isNight ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
                      size: 24,
                      color: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<List<DiaryEntry>>(
                  valueListenable: UserState().savedDiaries,
                  builder: (context, diaries, child) {
                    return Text(
                      "登岛第 ${diaries.length} 天  ·  打捞韶华里的碎片",
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: fontFamily,
                        color: subtitleColor,
                        letterSpacing: 0.5,
                      ),
                    );
                  }
                ),
              ],
            ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
            
            const SizedBox(height: 32),

            // 中间网格：左侧时光相框（双倍高），右侧两小块（轨迹 + 正念）
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：时光相框 (大方块，高296)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      RandomMemoryOverlay.show(context, isNight: isNight);
                    },
                    child: _PhotoThrowbackWidget(
                      groupedEntries: groupedEntries,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      accentColor: accentColor,
                      fontFamily: fontFamily,
                      isNight: isNight,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 150.ms).scale(begin: const Offset(0.97, 0.97)),
                ),
                const SizedBox(width: 16),
                // 右侧：情绪轨迹 (高140) + 正念空间 (高140)
                Expanded(
                  child: Column(
                    children: [
                      _buildGlassCard(
                        onTap: null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.waves_rounded,
                                  size: 18,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "情绪轨迹",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "记录点滴涟漪",
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: fontFamily,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildWeeklyHeatmap(textColor, subtitleColor, accentColor),
                          ],
                        ),
                      ).animate().fade(duration: 600.ms, delay: 200.ms).scale(begin: const Offset(0.97, 0.97)),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        onTap: null,
                        child: _MindfulBreathingWidget(
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          accentColor: accentColor,
                          fontFamily: fontFamily,
                        ),
                      ).animate().fade(duration: 600.ms, delay: 300.ms).scale(begin: const Offset(0.97, 0.97)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 底部一键心情印章
            _buildGlassCard(
              onTap: null,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              isRow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "此刻心情...",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final moodIndex = [0, 1, 2, 3, 4][index];
                      final mood = kMoods[moodIndex];
                      return GestureDetector(
                        onTap: () => _openEditorWithMood(context, moodIndex),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isNight 
                                    ? Colors.white.withValues(alpha: 0.08) 
                                    : Colors.white.withValues(alpha: 0.4),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: mood.iconPath != null
                                  ? Image.asset(mood.iconPath!, width: 28, height: 28)
                                  : const Icon(Icons.mood, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mood.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: fontFamily,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ).animate().fade(duration: 600.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    bool isRow = false,
  }) {
    final cardBg = isNight
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.18);
    final borderColor = isNight
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.45);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: isRow ? null : 140,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _buildWeeklyHeatmap(Color textColor, Color subtitleColor, Color accentColor) {
    final today = DateTime.now();
    final last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    
    final entryMap = <String, bool>{};
    for (var group in groupedEntries) {
      final date = group.keys.first;
      entryMap["${date.year}-${date.month}-${date.day}"] = true;
    }

    final inactiveColor = isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.35);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: last7Days.map((date) {
        final key = "${date.year}-${date.month}-${date.day}";
        final hasEntry = entryMap[key] ?? false;
        
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasEntry ? accentColor : Colors.transparent,
            border: Border.all(
              color: hasEntry ? accentColor : inactiveColor,
              width: 1.5,
            ),
            boxShadow: hasEntry ? [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ] : null,
          ),
        );
      }).toList(),
    );
  }
}

/// 左侧：大方块时光相框组件 (那年今日)
class _PhotoThrowbackWidget extends StatefulWidget {
  final List<Map<DateTime, List<DiaryEntry>>> groupedEntries;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;

  const _PhotoThrowbackWidget({
    required this.groupedEntries,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
  });

  @override
  State<_PhotoThrowbackWidget> createState() => _PhotoThrowbackWidgetState();
}

class _PhotoThrowbackWidgetState extends State<_PhotoThrowbackWidget> {
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _selectRandomImage();
  }

  @override
  void didUpdateWidget(covariant _PhotoThrowbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupedEntries != widget.groupedEntries) {
      _selectRandomImage();
    }
  }

  void _selectRandomImage() {
    final paths = <String>[];
    for (var group in widget.groupedEntries) {
      for (var entryList in group.values) {
        for (var entry in entryList) {
          for (var block in entry.blocks) {
            if (block['type'] == 'image' && block['path'] != null) {
              paths.add(block['path'].toString());
            }
          }
        }
      }
    }

    if (paths.isNotEmpty) {
      final validPaths = paths.where((p) => File(p).existsSync()).toList();
      if (validPaths.isNotEmpty) {
        final random = math.Random();
        _selectedImagePath = validPaths[random.nextInt(validPaths.length)];
      } else {
        _selectedImagePath = null;
      }
    } else {
      _selectedImagePath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _selectedImagePath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 296, // 140 * 2 + 16 (spacing)
        child: Stack(
          children: [
            // 相片层
            if (imagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildFallbackGradient(),
                ),
              )
            else
              Positioned.fill(child: _buildFallbackGradient()),

            // 渐变阴影层，确保文字识别度
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),

            // 内容层
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.auto_awesome_motion_outlined,
                    size: 24,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "那年今日",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: widget.fontFamily,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "翻开记忆的旧相片",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: widget.fontFamily,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isNight
              ? [
                  const Color(0xFF1E3A52).withValues(alpha: 0.7),
                  const Color(0xFF0F2537).withValues(alpha: 0.9),
                ]
              : [
                  const Color(0xFFBBDEFB).withValues(alpha: 0.5),
                  const Color(0xFFE3F2FD).withValues(alpha: 0.3),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_library_outlined,
          size: 36,
          color: widget.isNight ? Colors.white30 : Colors.black12,
        ),
      ),
    );
  }
}

/// 右侧下方：正念呼吸小组件
class _MindfulBreathingWidget extends StatefulWidget {
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;

  const _MindfulBreathingWidget({
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
  });

  @override
  State<_MindfulBreathingWidget> createState() => _MindfulBreathingWidgetState();
}

class _MindfulBreathingWidgetState extends State<_MindfulBreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 10秒一个呼吸循环 (4秒吸气，2秒屏息，4秒呼气)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.55, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              Icons.spa_outlined,
              size: 16,
              color: widget.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              "正念空间",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: widget.fontFamily,
                color: widget.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "吸气... 呼气...",
          style: TextStyle(
            fontSize: 11,
            fontFamily: widget.fontFamily,
            color: widget.subtitleColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = _scaleAnimation.value;
                final opacity = _opacityAnimation.value;
                return Container(
                  width: 52 * scale,
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor.withValues(alpha: opacity * 0.5),
                        widget.accentColor.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: opacity * 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: opacity * 0.15),
                        blurRadius: 12 * scale,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
