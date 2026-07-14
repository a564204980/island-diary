import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/plugins/island_plugin.dart';
import '../../features/record/domain/models/diary_entry.dart';
import './dialogs/travel_ticket_dialog.dart';

class TravelExperiencePlugin extends ExperiencePlugin {
  @override
  String get pluginId => 'exp_travel_001';

  @override
  String get name => '岛屿航行体验';

  @override
  String get description => '赋予旅行日记专属的航海记录与回顾体验。';

  @override
  String get version => '1.0.0';

  @override
  String get previewImageUrl => '';

  @override
  List<String> get targetTags => ['旅行'];

  @override
  Future<void> onTagAdded(BuildContext context, String tag, Map<String, String> annotations) async {
    if (tag != '旅行') return;
    
    final result = await TravelTicketDialog.show(
      context,
      initialOrigin: annotations['travel_origin'],
      initialDestination: annotations['travel_destination'],
    );
    
    if (result != null) {
      if (result['origin']?.isNotEmpty == true) {
        annotations['travel_origin'] = result['origin']!;
      }
      if (result['destination']?.isNotEmpty == true) {
        annotations['travel_destination'] = result['destination']!;
      }
      if (result['mode']?.isNotEmpty == true) {
        annotations['travel_mode'] = result['mode']!;
      }
      if (result['departureTime']?.isNotEmpty == true) {
        annotations['travel_departure_time'] = result['departureTime']!;
      }
      if (result['arrivalTime']?.isNotEmpty == true) {
        annotations['travel_arrival_time'] = result['arrivalTime']!;
      }
    }
  }

  @override
  Widget? buildEditorHeader(BuildContext context, {required String tag}) {
    // TODO: 重新设计航行状态
    return null;
  }

  @override
  Widget? buildEditorFooter(BuildContext context, {required String tag, required Map<String, String> annotations}) {
    if (tag != '旅行') return null;
    
    final origin = annotations['travel_origin'];
    final destination = annotations['travel_destination'];
    
    if (origin == null || destination == null) return null;

    final modeStr = annotations['travel_mode'] ?? 'flight';
    TransportMode mode = TransportMode.flight;
    try {
      mode = TransportMode.values.firstWhere((e) => e.name == modeStr);
    } catch (_) {}

    final isNight = Theme.of(context).brightness == Brightness.dark;
    final textColor = isNight ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.7);
    final accentColor = isNight ? const Color(0xFFD4A373) : const Color(0xFF8B5E3C);
    final lineColor = isNight ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15);
    final containerBg = isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02);
    
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Origin
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '启程',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    origin,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Center Transport Icon + Dotted Line
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _AnimatedTransportRoute(
                  accentColor: accentColor, 
                  lineColor: lineColor,
                  mode: mode,
                ),
              ),
            ),
            
            // Destination
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '抵达',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.location_on_rounded, color: const Color(0xFFF44336), size: 12),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? buildEditorBackground(BuildContext context, {required String tag}) {
    // TODO: 返回航行背景 (如轻微水波纹动画)
    return null;
  }

  @override
  Future<bool> onBeforeSave(BuildContext context, DiaryEntry entry) async {
    // 拦截保存，检查是否有 travel_cabin 属性
    if (entry.annotations['travel_cabin'] == null) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('准备靠岸'),
          content: const Text('本次航行即将结束，是否确认封存航海日志？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('继续航行'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('靠岸'),
            ),
          ],
        )
      );
      if (confirm != true) return false;
      // 存入默认状态
      entry.annotations['travel_cabin'] = 'deck';
    }
    return true;
  }

  @override
  Future<void> onAfterSave(BuildContext context, DiaryEntry entry) async {
    // 日记保存完毕，弹出专属登船牌 (Boarding Pass) 动画。
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('登船牌已生成'),
        content: SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sailing_rounded, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text('抵达时间: ${entry.dateTime.toIso8601String().substring(0, 10)}'),
              Text('天气邮戳: ${entry.weather ?? "未知"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('收纳至航海日志'),
          )
        ],
      )
    );
  }

  @override
  Widget? buildCustomTimelineView(BuildContext context, List<DiaryEntry> entries) {
    // 渲染简单的航海日志视图
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.anchor_rounded, color: Colors.blue),
            title: Text('航线: ${entry.location ?? "未知海域"}'),
            subtitle: Text('情绪: ${entry.moodIndex}'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}

class _AnimatedTransportRoute extends StatefulWidget {
  final Color accentColor;
  final Color lineColor;
  final TransportMode mode;

  const _AnimatedTransportRoute({required this.accentColor, required this.lineColor, required this.mode});

  @override
  State<_AnimatedTransportRoute> createState() => _AnimatedTransportRouteState();
}

class _AnimatedTransportRouteState extends State<_AnimatedTransportRoute> with TickerProviderStateMixin {
  late AnimationController _lineController;
  late AnimationController _planeController;
  late Animation<double> _planeAnim;

  @override
  void initState() {
    super.initState();
    // 虚线向左流动的动画 (0 -> 1)
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 控制虚线流动速度
    )..repeat();

    // 飞机航行逻辑的动画 (0 -> 1)
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000), // 一个完整的循环需要7秒
    )..repeat();

    _planeAnim = TweenSequence<double>([
      // 1. 刚开始正常飞，飞到快到右边，速度降下来 (0 -> 40%)
      TweenSequenceItem(
        tween: Tween(begin: -0.8, end: 0.6).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      // 2. 遇到强逆风或气流，退回到左边 (40% -> 60%)
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: -0.4).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 20.0,
      ),
      // 3. 有一段时间匀速在飞 (60% -> 100%)
      // 在这里我们让它相对屏幕缓慢后退到起始点，配合底下的动感虚线，视觉上就是匀速前行！
      TweenSequenceItem(
        tween: Tween(begin: -0.4, end: -0.8).chain(CurveTween(curve: Curves.linear)),
        weight: 40.0,
      ),
    ]).animate(_planeController);
  }

  @override
  void dispose() {
    _lineController.dispose();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 动态流动的虚线
        SizedBox(
          height: 20,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _lineController,
            builder: (context, child) {
              return CustomPaint(
                painter: _DashedLinePainter(
                  color: widget.lineColor,
                  progress: _lineController.value,
                ),
              );
            },
          ),
        ),
        // 动态飞行的飞机
        AnimatedBuilder(
          animation: _planeController,
          builder: (context, child) {
            // 添加基于正弦曲线的上下悬浮呼吸感
            final double hoverY = math.sin(_planeController.value * math.pi * 6) * 1.5;
            
            return Align(
              alignment: Alignment(_planeAnim.value, 0),
              child: Transform.translate(
                offset: Offset(0, hoverY),
                child: child,
              ),
            );
          },
          child: Builder(
            builder: (context) {
              Widget iconWidget;
              switch (widget.mode) {
                case TransportMode.flight: 
                  iconWidget = Transform.rotate(
                    angle: 1.5708, // airplane needs 90 degree rotation
                    child: CustomPaint(
                      size: const Size(20, 20),
                      painter: AirplaneSilhouettePainter(color: widget.accentColor),
                    ),
                  );
                  break;
                case TransportMode.train: 
                  iconWidget = CustomPaint(
                    size: const Size(24, 24),
                    painter: TrainSilhouettePainter(color: widget.accentColor),
                  );
                  break;
                case TransportMode.bus: 
                  iconWidget = CustomPaint(
                    size: const Size(24, 24),
                    painter: BusSilhouettePainter(color: widget.accentColor),
                  );
                  break;
                case TransportMode.ship: 
                  iconWidget = CustomPaint(
                    size: const Size(24, 24),
                    painter: ShipSilhouettePainter(color: widget.accentColor),
                  );
                  break;
              }
              return iconWidget;
            }
          ),
        ),
        // 添加云朵
        if (widget.mode == TransportMode.flight)
          AnimatedBuilder(
            animation: _planeController,
            builder: (context, child) {
              final val = _planeController.value;
              // 云朵向左移动。为保证无缝循环，speed必须是模域(3.0)的整数倍
              // span = 3.0 (对应 Alignment -1.5 到 1.5)
              double shift(double phase, double speed) {
                 return (((phase + 1.5 - val * speed) + 300.0) % 3.0) - 1.5;
              }
              
              // 根据横向坐标计算淡入淡出比例 (中心1.0，边缘0.0)
              double fade(double x) {
                 double absX = x.abs();
                 if (absX > 0.9) return 0.0; // 在边缘外完全透明
                 if (absX < 0.5) return 1.0; // 在中心区域完全不透明
                 return 1.0 - ((absX - 0.5) / 0.4); // 平滑过渡
              }
              
              final x1 = shift(1.5, 3.0);
              final x2 = shift(0.0, 3.0);
              final x3 = shift(1.0, 6.0);
              
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Align(
                    alignment: Alignment(x1, -0.8),
                    child: Icon(Icons.cloud_rounded, color: widget.accentColor.withValues(alpha: 0.1 * fade(x1)), size: 16),
                  ),
                  Align(
                    alignment: Alignment(x2, 0.8),
                    child: Icon(Icons.cloud_rounded, color: widget.accentColor.withValues(alpha: 0.08 * fade(x2)), size: 12),
                  ),
                  Align(
                    alignment: Alignment(x3, -0.4),
                    child: Icon(Icons.cloud_rounded, color: widget.accentColor.withValues(alpha: 0.12 * fade(x3)), size: 24),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double progress;

  _DashedLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double dashWidth = 4.0;
    final double dashSpace = 4.0;
    final double step = dashWidth + dashSpace;
    
    // Animate to the left
    final double offsetX = - (progress * step);
    
    double currentX = offsetX;
    final double centerY = size.height / 2;
    
    while (currentX < size.width) {
      if (currentX + dashWidth > 0) {
        final startX = currentX < 0 ? 0.0 : currentX;
        final endX = (currentX + dashWidth) > size.width ? size.width : (currentX + dashWidth);
        canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), paint);
      }
      currentX += step;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}
