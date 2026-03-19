import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/shared/widgets/fireflies.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

class BarrageWall extends StatefulWidget {
  final List<DiaryEntry> entries;
  final VoidCallback? onFinished;
  final bool isNight;

  const BarrageWall({
    super.key, 
    required this.entries,
    required this.isNight,
    this.onFinished,
  });

  @override
  State<BarrageWall> createState() => _BarrageWallState();
}

class _BarrageWallState extends State<BarrageWall> with TickerProviderStateMixin {
  final List<BarrageItemData> _activeItems = [];
  final math.Random _random = math.Random();
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startPlaying();
  }

  void _startPlaying() {
    if (widget.entries.isEmpty) {
      widget.onFinished?.call();
      return;
    }

    // 顺序播放所有条目一次，显著增加间隔以降低密度 (调整为基础 5s)
    for (int i = 0; i < widget.entries.length; i++) {
       // 进一步拉开间隔，根据内容长度动态加成，让整体更有序
       final staggeredDelay = i * 5000 + _random.nextInt(3500);
       _spawnItem(i, delay: staggeredDelay);
    }
  }

  void _spawnItem(int entryIdx, {int delay = 0}) {
    if (!mounted) return;
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      final entry = widget.entries[entryIdx];
      // 速度区间更窄，移动更稳
      final duration = 14000 + _random.nextInt(2000);
      
      // --- 高度分配 (避开上下 UI) ---
      final screenHeight = MediaQuery.of(context).size.height;
      // 顶部留 80px (标题), 底部留 100px (日期/导航)
      final availableHeight = (screenHeight - 180).clamp(100.0, 500.0);
      const int laneCount = 4; // 减少航道，保证每行都有足够间距
      final laneHeight = availableHeight / laneCount;
      
      final laneIndex = entryIdx % laneCount;
      // 在航道内居中并加微量偏移
      final laneOffset = (laneIndex * laneHeight) + (laneHeight / 2) - 20; 
      final top = 80 + laneOffset;
      
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: duration),
      );

      // --- 提前触发翻页逻辑 (实现无缝切换) ---
      if (entryIdx == widget.entries.length - 1) {
        Future.delayed(Duration(milliseconds: (duration * 0.7).toInt()), () {
          if (mounted && !_isFinished) {
            _isFinished = true;
            widget.onFinished?.call();
          }
        });
      }
      
      final item = BarrageItemData(
        entry: entry,
        top: top,
        controller: controller,
      );

      setState(() {
        _activeItems.add(item);
      });

      controller.forward().then((_) {
        if (!mounted) {
          controller.dispose();
          return;
        }
        
        setState(() {
          _activeItems.remove(item);
        });
        controller.dispose();
      });
    });
  }

  @override
  void dispose() {
    for (var item in _activeItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Stack(
      children: _activeItems.map((item) {
        return Positioned(
          left: 0,
          top: item.top,
          child: AnimatedBuilder(
            animation: item.controller,
            builder: (context, child) {
              // 使用 Transform.translate 代替 Positioned.left，利用 GPU 加速，减少 Layout 次数
              final x = screenWidth - (item.controller.value * (screenWidth + 800));
              return Transform.translate(
                offset: Offset(x, 0),
                child: child!,
              );
            },
            child: BarrageContent(entry: item.entry, isNight: widget.isNight),
          ),
        );
      }).toList(),
    );
  }
}

class BarrageItemData {
  final DiaryEntry entry;
  final double top;
  final AnimationController controller;

  BarrageItemData({
    required this.entry,
    required this.top,
    required this.controller,
  });
}

class BarrageContent extends StatelessWidget {
  final DiaryEntry entry;
  final bool isNight;
  
  const BarrageContent({super.key, required this.entry, required this.isNight});

  @override
  Widget build(BuildContext context) {
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final String moodDescription = DiaryUtils.getPureMoodDescription(mood.label, entry.intensity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isNight 
          ? Colors.white.withValues(alpha: 0.15) 
          : const Color(0xFF5A3E28).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight 
            ? Colors.white.withValues(alpha: 0.2) 
            : const Color(0xFF5A3E28).withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            mood.iconPath ?? 'assets/images/icons/sun.png', 
            width: 18, 
            height: 18,
          ),
          const SizedBox(width: 6),
          // 如果有自定义标签，显示标签；否则显示标准心情描述
          if (entry.tag != null && entry.tag!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                "#${entry.tag} ",
                style: TextStyle(
                  color: isNight ? Colors.white : const Color(0xFF4A3423),
                  fontSize: 15,
                  fontFamily: 'LXGWWenKai',
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              "$moodDescription · ",
              style: TextStyle(
                color: isNight 
                  ? Colors.white.withValues(alpha: 0.7) 
                  : const Color(0xFF4A3423).withValues(alpha: 0.8),
                fontSize: 14,
                fontFamily: 'LXGWWenKai',
                fontWeight: FontWeight.bold,
              ),
            ),
          // 标准强度显示 (始终显示)
          Text(
            "强度 ${entry.intensity.toInt()} · ",
            style: TextStyle(
              color: isNight 
                ? Colors.white.withValues(alpha: 0.5) 
                : const Color(0xFF4A3423).withValues(alpha: 0.6),
              fontSize: 12,
              fontFamily: 'LXGWWenKai',
            ),
          ),
          Flexible(
            child: Text(
              entry.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isNight ? Colors.white : const Color(0xFF4A3423),
                fontFamily: 'LXGWWenKai',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                shadows: isNight ? [
                   const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                ] : [
                   Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(0, 1)),
                ]
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${entry.dateTime.hour}:${entry.dateTime.minute.toString().padLeft(2, '0')}",
            style: TextStyle(
              color: isNight 
                ? Colors.white.withValues(alpha: 0.6) 
                : const Color(0xFF4A3423).withValues(alpha: 0.7),
              fontSize: 12,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹幕场景组件：包含背景、小岛、云朵和弹幕墙
class BarrageDayScene extends StatelessWidget {
  final List<DiaryEntry> entries;
  final DateTime date;
  final VoidCallback onFinished;

  const BarrageDayScene({
    super.key,
    required this.entries,
    required this.date,
    required this.onFinished,
  });

  bool _checkIsNight(DateTime dt) {
    return dt.hour < 6 || dt.hour >= 18;
  }

  String _getBgPath(bool isNight) {
    return isNight 
      ? 'assets/images/home_wanshang_big.png' 
      : 'assets/images/home_xiatian_big.png';
  }

  String _getIslandPath(bool isNight) {
    return isNight 
      ? 'assets/images/home_small_demo2.png' 
      : 'assets/images/home_small_demo.png';
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = entries.isNotEmpty ? _checkIsNight(entries[0].dateTime) : false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Stack(
      children: [
        // 1. 背景层
        Positioned.fill(
          child: Image.asset(
            _getBgPath(isNight),
            fit: BoxFit.cover,
          ),
        ),
        
        // 2. 云朵层
        Positioned.fill(
          child: FloatingClouds(isNight: isNight, shouldAnimate: true),
        ),

        // 2.5 萤火虫层 (仅夜晚)
        if (isNight)
          const Positioned.fill(
            child: Fireflies(count: 20),
          ),

        // 3. 岛屿层
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isNight)
                Positioned(
                  bottom: screenWidth * 0.04,
                  child: Container(
                    width: isWide ? 480 : screenWidth * 0.8,
                    height: isWide ? 200 : screenWidth * 0.4,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFB347).withValues(alpha: 0.95),
                          const Color(0xFFFFB347).withValues(alpha: 0.0),
                        ],
                        stops: const [0.15, 1.0],
                      ),
                    ),
                  ),
                ),
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.4),
                child: Image.asset(
                  _getIslandPath(isNight),
                  width: (screenWidth <= 600 ? screenWidth * 0.9 : 540.0) * 1.05 * 1.8,
                  fit: BoxFit.contain,
                  color: isNight 
                    ? const Color(0xFFFFEFA1).withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Image.asset(
                _getIslandPath(isNight),
                width: (screenWidth <= 600 ? screenWidth * 0.9 : 540.0) * 1.8,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),

        // 4. 弹幕墙
        Positioned.fill(
          child: BarrageWall(
            entries: entries,
            isNight: isNight,
            onFinished: onFinished,
          ),
        ),

        // 5. 前景云层
        Positioned.fill(
          child: FloatingClouds(
            isNight: isNight,
            isForeground: true,
            shouldAnimate: true,
          ),
        ),
      ],
    );
  }
}
