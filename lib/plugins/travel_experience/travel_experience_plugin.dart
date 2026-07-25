import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/plugins/island_plugin.dart';
import '../../features/record/domain/models/diary_entry.dart';
import '../../shared/widgets/island_dialog.dart';
import './dialogs/travel_ticket_dialog.dart';
import './pages/travel_ticket_printer_page.dart';

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
  Future<void> onTagAdded(
    BuildContext context,
    String tag,
    Map<String, String> annotations,
  ) async {
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
    return null;
  }

  @override
  Widget? buildTimelineMiniWidget(
    BuildContext context, {
    required String tag,
    required Map<String, String> annotations,
  }) {
    if (tag != '旅行') return null;
    if (annotations['travel_origin'] == null ||
        annotations['travel_destination'] == null) {
      return null;
    }

    final origin = annotations['travel_origin']!;
    final destination = annotations['travel_destination']!;
    final modeStr = annotations['travel_mode'] ?? 'flight';

    final isNight = Theme.of(context).brightness == Brightness.dark;
    final textColor = isNight ? Colors.white70 : const Color(0xFF5C5C5C);
    final accentColor = isNight
        ? const Color(0xFFD4A373)
        : const Color(0xFF8B5E3C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            origin,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'LXGWWenKai',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '┈┈ ',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
                Builder(
                  builder: (context) {
                    Widget customIcon;
                    if (modeStr == 'train') {
                      customIcon = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CustomPaint(
                          size: const Size(32, 8),
                          painter: TrainSilhouettePainter(
                            color: accentColor,
                            carriages: 3,
                          ),
                        ),
                      );
                    } else if (modeStr == 'ship') {
                      customIcon = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: CustomPaint(
                          size: const Size(24, 8),
                          painter: ShipSilhouettePainter(color: accentColor),
                        ),
                      );
                    } else if (modeStr == 'drive' || modeStr == 'bus') {
                      customIcon = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: CustomPaint(
                          size: const Size(20, 10),
                          painter: BusSilhouettePainter(color: accentColor),
                        ),
                      );
                    } else {
                      // flight
                      customIcon = Transform.rotate(
                        angle: math.pi / 2,
                        child: CustomPaint(
                          size: const Size(16, 16),
                          painter: AirplaneSilhouettePainter(
                            color: accentColor,
                          ),
                        ),
                      );
                    }
                    return customIcon;
                  },
                ),
                Text(
                  ' ┈┈',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            destination,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildEditorFooter(
    BuildContext context, {
    required String tag,
    required Map<String, String> annotations,
    bool isReadOnly = false,
  }) {
    if (tag != '旅行') return null;

    if (annotations['travel_origin'] == null ||
        annotations['travel_destination'] == null) {
      return null;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final origin = annotations['travel_origin']!;
        final destination = annotations['travel_destination']!;

        final modeStr = annotations['travel_mode'] ?? 'flight';
        TransportMode mode = TransportMode.flight;
        try {
          mode = TransportMode.values.firstWhere((e) => e.name == modeStr);
        } catch (_) {}

        final isNight = Theme.of(context).brightness == Brightness.dark;
        final textColor = isNight
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.black.withValues(alpha: 0.7);
        final accentColor = isNight
            ? const Color(0xFFD4A373)
            : const Color(0xFF8B5E3C);
        final lineColor = isNight
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.15);
        final containerBg = isNight
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02);

        final depStr = annotations['travel_departure_time'];
        final arrStr = annotations['travel_arrival_time'];
        String? durationStr;
        if (depStr != null && arrStr != null) {
          try {
            final dep = DateTime.parse(depStr);
            final arr = DateTime.parse(arrStr);
            final diff = arr.difference(dep);
            if (diff.inMinutes > 0) {
              final h = diff.inHours;
              final m = diff.inMinutes % 60;
              if (h > 0 && m > 0) {
                durationStr = '${h}h ${m}m';
              } else if (h > 0) {
                durationStr = '${h}h';
              } else {
                durationStr = '${m}m';
              }
            }
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: GestureDetector(
            onTap: isReadOnly
                ? null
                : () async {
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
                        annotations['travel_destination'] =
                            result['destination']!;
                      }
                      if (result['mode']?.isNotEmpty == true) {
                        annotations['travel_mode'] = result['mode']!;
                      }
                      if (result['departureTime']?.isNotEmpty == true) {
                        annotations['travel_departure_time'] =
                            result['departureTime']!;
                      }
                      if (result['arrivalTime']?.isNotEmpty == true) {
                        annotations['travel_arrival_time'] =
                            result['arrivalTime']!;
                      }
                      setState(() {});
                    }
                  },
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
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (durationStr != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              durationStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _AnimatedTransportRoute(
                            accentColor: accentColor,
                            lineColor: lineColor,
                            mode: mode,
                          ),
                        ),
                      ],
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
                            Icon(
                              Icons.location_on_rounded,
                              color: const Color(0xFFF44336),
                              size: 12,
                            ),
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
          ),
        );
      },
    );
  }

  @override
  Widget? buildEditorBackground(BuildContext context, {required String tag}) {
    return null;
  }

  @override
  Future<bool> onBeforeSave(BuildContext context, DiaryEntry entry) async {
    // 拦截保存，检查是否有 travel_cabin 属性
    if (entry.annotations['travel_cabin'] == null) {
      final modeStr = entry.annotations['travel_mode'] ?? 'ship';
      String titleText;
      String cancelText;
      String confirmText;

      switch (modeStr) {
        case 'bus':
          titleText = '本次旅途即将结束，是否确认封存旅行日志？';
          cancelText = '继续旅途';
          confirmText = '抵达';
          break;
        case 'train':
          titleText = '本次列车即将到站，是否确认封存旅行日志？';
          cancelText = '继续乘车';
          confirmText = '到站';
          break;
        case 'flight':
          titleText = '本次航班即将降落，是否确认封存飞行日志？';
          cancelText = '继续飞行';
          confirmText = '降落';
          break;
        case 'ship':
        default:
          titleText = '本次航行即将结束，是否确认封存航海日志？';
          cancelText = '继续航行';
          confirmText = '靠岸';
          break;
      }

      final bool? confirm = await IslandDialog.show<bool>(
        context,
        title: titleText,
        cancelText: cancelText,
        confirmText: confirmText,
      );
      if (confirm != true) return false;
      // 存入默认状态
      entry.annotations['travel_cabin'] = 'deck';
    }
    return true;
  }

  @override
  Future<void> onAfterSave(BuildContext context, DiaryEntry entry) async {
    // 拦截保存后，进入沉浸式相纸打印与专属纪念票根页面
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            TravelTicketPrinterPage(
              destination:
                  entry.annotations['travel_destination'] ??
                  entry.location ??
                  '未知海域',
              origin: entry.annotations['travel_origin'] ?? 'ISLAND',
              mode: entry.annotations['travel_mode'] ?? 'flight',
              date: entry.annotations['travel_departure_time'] ?? '',
              onFinished: () => Navigator.of(context).pop(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget? buildCustomTimelineView(
    BuildContext context,
    List<DiaryEntry> entries,
  ) {
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

  const _AnimatedTransportRoute({
    required this.accentColor,
    required this.lineColor,
    required this.mode,
  });

  @override
  State<_AnimatedTransportRoute> createState() =>
      _AnimatedTransportRouteState();
}

class _AnimatedTransportRouteState extends State<_AnimatedTransportRoute>
    with TickerProviderStateMixin {
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
        tween: Tween(
          begin: -0.8,
          end: 0.6,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      // 2. 遇到强逆风或气流，退回到左边 (40% -> 60%)
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: -0.4,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 20.0,
      ),
      // 3. 有一段时间匀速在飞 (60% -> 100%)
      // 在这里我们让它相对屏幕缓慢后退到起始点，配合底下的动感虚线，视觉上就是匀速前行！
      TweenSequenceItem(
        tween: Tween(
          begin: -0.4,
          end: -0.8,
        ).chain(CurveTween(curve: Curves.linear)),
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
        // 动态流动的虚线/道路/水波
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _lineController,
              builder: (context, child) {
                if (widget.mode == TransportMode.bus) {
                  return CustomPaint(
                    painter: _PerspectiveDashedLinePainter(
                      color: widget.lineColor,
                      progress: _lineController.value,
                    ),
                  );
                }
                if (widget.mode == TransportMode.ship) {
                  return CustomPaint(
                    painter: _WaveLinePainter(
                      color: widget.lineColor,
                      progress: _lineController.value,
                      speedMultiplier: 2.0, // 必须是整数，保证无缝循环
                    ),
                  );
                }
                return CustomPaint(
                  painter: _DashedLinePainter(
                    color: widget.lineColor,
                    progress: _lineController.value,
                    speedMultiplier: widget.mode == TransportMode.train
                        ? 6.0
                        : 1.0,
                  ),
                );
              },
            ),
          ),
        ),
        // 动态飞行的飞机及交通工具
        AnimatedBuilder(
          animation: _planeController,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _lineController,
              builder: (context, _) {
                final bool isLandVehicle =
                    widget.mode == TransportMode.bus ||
                    widget.mode == TransportMode.train;

                // 地面交通工具保持在正中间，飞机/船有进退动画
                final double xPos = isLandVehicle ? 0.0 : _planeAnim.value;

                final bool shouldHover =
                    widget.mode == TransportMode.flight ||
                    widget.mode == TransportMode.ship;
                double hoverY = shouldHover
                    ? (math.sin(_planeController.value * math.pi * 6) * 1.5)
                    : 0.0;

                // 火车需要 -7 偏移以使得车底正好贴合在中心虚线上，透视汽车需要居中（0.0）
                final double groundOffsetY = widget.mode == TransportMode.train
                    ? -7.0
                    : 0.0;

                // 给汽车增加轻微的颠簸感（动车行驶在无缝钢轨上很平稳，不需要上下颠簸）
                if (widget.mode == TransportMode.bus) {
                  hoverY = math.sin(_lineController.value * math.pi * 4) * 1.0;
                }

                // 给汽车/火车增加额外的动作
                double swayX = 0.0;
                double extraScale = 1.0;
                if (widget.mode == TransportMode.bus) {
                  swayX =
                      math.sin(_planeController.value * math.pi * 8) *
                      2.5; // 左右飘移
                  extraScale =
                      1.0 +
                      math.sin(_planeController.value * math.pi * 4) *
                          0.08; // 模拟加速减速
                } else if (widget.mode == TransportMode.train) {
                  swayX =
                      math.sin(_planeController.value * math.pi * 4) *
                      4.0; // 动车只有水平的加减速滑移
                }

                return Align(
                  alignment: Alignment(xPos, 0),
                  child: Transform.translate(
                    offset: Offset(
                      isLandVehicle ? swayX : 0,
                      hoverY + groundOffsetY,
                    ),
                    child: Transform.scale(scale: extraScale, child: child),
                  ),
                );
              },
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
                      painter: AirplaneSilhouettePainter(
                        color: widget.accentColor,
                      ),
                    ),
                  );
                  break;
                case TransportMode.train:
                  iconWidget = CustomPaint(
                    size: const Size(86, 16),
                    painter: TrainSilhouettePainter(color: widget.accentColor),
                  );
                  break;
                case TransportMode.bus:
                  iconWidget = CustomPaint(
                    size: const Size(40, 24),
                    painter: BusSilhouettePainter(color: widget.accentColor),
                  );
                  break;
                case TransportMode.ship:
                  iconWidget = CustomPaint(
                    size: const Size(64, 24),
                    painter: ShipSilhouettePainter(color: widget.accentColor),
                  );
                  break;
              }
              return iconWidget;
            },
          ),
        ),
        // 添加云朵
        if (widget.mode == TransportMode.flight)
          AnimatedBuilder(
            animation: _planeController,
            builder: (context, child) {
              final val = _planeController.value;
              double shift(double phase, double speed) {
                return (((phase + 1.5 - val * speed) + 300.0) % 3.0) - 1.5;
              }

              double fade(double x) {
                double absX = x.abs();
                if (absX > 0.9) return 0.0;
                if (absX < 0.5) return 1.0;
                return 1.0 - ((absX - 0.5) / 0.4);
              }

              final x1 = shift(1.5, 3.0);
              final x2 = shift(0.0, 3.0);
              final x3 = shift(1.0, 6.0);

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Align(
                    alignment: Alignment(x1, -0.8),
                    child: Icon(
                      Icons.cloud_rounded,
                      color: widget.accentColor.withValues(
                        alpha: 0.1 * fade(x1),
                      ),
                      size: 16,
                    ),
                  ),
                  Align(
                    alignment: Alignment(x2, 0.8),
                    child: Icon(
                      Icons.cloud_rounded,
                      color: widget.accentColor.withValues(
                        alpha: 0.08 * fade(x2),
                      ),
                      size: 12,
                    ),
                  ),
                  Align(
                    alignment: Alignment(x3, -0.4),
                    child: Icon(
                      Icons.cloud_rounded,
                      color: widget.accentColor.withValues(
                        alpha: 0.12 * fade(x3),
                      ),
                      size: 24,
                    ),
                  ),
                ],
              );
            },
          ),
        // 添加树木/房屋/群山
        if (widget.mode == TransportMode.bus ||
            widget.mode == TransportMode.train ||
            widget.mode == TransportMode.ship)
          AnimatedBuilder(
            animation: _planeController,
            builder: (context, child) {
              if (widget.mode == TransportMode.bus) {
                // 汽车模式：透视视角的风景（向屏幕两侧和下方散开并放大）
                final val = _planeController.value;

                Widget buildPerspectiveItem(
                  double phase,
                  double speed,
                  int side,
                  bool isHouse,
                ) {
                  // phase 控制初始相位，speed 控制移动速度
                  double p = (val * speed + phase) % 1.0;
                  // 从中心偏上（远方）移动到两侧偏下（近处）
                  // 虚线的范围是 14 到 40。考虑到图标自身的宽度，
                  // 初始偏移量设为 28，最终偏移量设为 88，确保风景完全在虚线外侧
                  double xOffset = side * (p * 60.0 + 28.0); // 距离中心的水平偏移
                  double yOffset = -5.0 + p * 22.0; // 垂直偏移
                  double scale = 0.5 + p * 1.5; // 近大远小，调大整体比例

                  // 远端淡入，近端淡出
                  double opacity = 1.0;
                  if (p < 0.2) {
                    opacity = p / 0.2;
                  } else if (p > 0.8) {
                    opacity = (1.0 - p) / 0.2;
                  }

                  return Transform.translate(
                    offset: Offset(xOffset, yOffset),
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(
                        isHouse ? Icons.home_rounded : Icons.park_rounded,
                        color: widget.accentColor.withValues(
                          alpha: 0.18 * opacity,
                        ),
                        size: isHouse ? 16 : 18, // 调大基础图标尺寸
                      ),
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    buildPerspectiveItem(0.0, 3.5, -1, false), // 左边树
                    buildPerspectiveItem(0.2, 3.5, 1, false), // 右边树
                    buildPerspectiveItem(0.5, 3.5, -1, false), // 左边树
                    buildPerspectiveItem(0.7, 3.5, 1, false), // 右边树
                    buildPerspectiveItem(0.9, 3.5, -1, false), // 左边树
                  ],
                );
              } else if (widget.mode == TransportMode.train) {
                // 动车模式：风驰电掣的横向滚动视角
                final val = _planeController.value;
                double shift(double phase, double speed) {
                  return (((phase + 1.5 - val * speed) + 300.0) % 3.0) - 1.5;
                }

                double fade(double x) {
                  double absX = x.abs();
                  if (absX > 0.9) return 0.0;
                  if (absX < 0.5) return 1.0;
                  return 1.0 - ((absX - 0.5) / 0.4);
                }

                // 增加速度并添加更多树木，制造高铁"风驰电掣"的错觉
                // 远景树林 (较小，稍慢)
                final t1 = shift(0.0, 10.0);
                final t2 = shift(1.0, 10.0);
                final t3 = shift(2.0, 10.0);

                // 近景树林 (较大，极快)
                final t4 = shift(0.5, 20.0);
                final t5 = shift(1.5, 20.0);
                final t6 = shift(2.5, 20.0);

                Widget buildTree(
                  double x,
                  double y,
                  double size,
                  double opacity,
                ) {
                  return Align(
                    alignment: Alignment(x, 0),
                    child: Transform.translate(
                      offset: Offset(0, y),
                      child: Icon(
                        Icons.park_rounded,
                        color: widget.accentColor.withValues(
                          alpha: opacity * fade(x),
                        ),
                        size: size,
                      ),
                    ),
                  );
                }

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    buildTree(t1, -5, 12, 0.10),
                    buildTree(t2, -6, 14, 0.12),
                    buildTree(t3, -4, 10, 0.08),
                    buildTree(t4, -8, 18, 0.18),
                    buildTree(t5, -9, 20, 0.22),
                    buildTree(t6, -7, 16, 0.16),
                  ],
                );
              } else if (widget.mode == TransportMode.ship) {
                // 轮船模式：远处的群山缓缓退后
                final val = _planeController.value;
                double shift(double phase, double speed) {
                  return (((phase + 1.5 - val * speed) + 300.0) % 3.0) - 1.5;
                }

                double fade(double x) {
                  double absX = x.abs();
                  if (absX > 0.9) return 0.0;
                  if (absX < 0.5) return 1.0;
                  return 1.0 - ((absX - 0.5) / 0.4);
                }

                // 群山移动很慢，代表距离很远。注意速度必须是 1.0 的整数倍才能无缝循环
                final m1 = shift(0.0, 1.0);
                final m2 = shift(1.0, 1.0);
                final m3 = shift(2.0, 1.0);

                Widget buildMountain(
                  double x,
                  double y,
                  double size,
                  double opacity,
                ) {
                  return Align(
                    alignment: Alignment(x, 0),
                    child: Transform.translate(
                      offset: Offset(0, y),
                      child: Icon(
                        Icons.terrain_rounded,
                        color: widget.accentColor.withValues(
                          alpha: opacity * fade(x),
                        ),
                        size: size,
                      ),
                    ),
                  );
                }

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    buildMountain(m1, -4, 24, 0.15),
                    buildMountain(m2, -6, 32, 0.10),
                    buildMountain(m3, -2, 28, 0.12),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double speedMultiplier;

  _DashedLinePainter({
    required this.color,
    required this.progress,
    this.speedMultiplier = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double dashWidth = 4.0;
    final double dashSpace = 4.0;
    final double step = dashWidth + dashSpace;

    // Animate to the left with speed multiplier
    final double offsetX = -(((progress * speedMultiplier) % 1.0) * step);

    double currentX = offsetX;
    final double centerY = size.height / 2;

    while (currentX < size.width) {
      if (currentX + dashWidth > 0) {
        final startX = currentX < 0 ? 0.0 : currentX;
        final endX = (currentX + dashWidth) > size.width
            ? size.width
            : (currentX + dashWidth);
        canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), paint);
      }
      currentX += step;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _WaveLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double speedMultiplier;

  _WaveLinePainter({
    required this.color,
    required this.progress,
    this.speedMultiplier = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double waveWidth = 24.0;
    final double waveHeight = 2.5;

    // 向左滚动动画
    final double offsetX = -(((progress * speedMultiplier) % 1.0) * waveWidth);

    final path = Path();
    bool first = true;

    double currentX = offsetX - waveWidth; // 从屏幕左侧外开始画，确保边缘平滑
    final double centerY = size.height / 2 + 5.0; // 把水波线往下移一点，不要淹没太多船身

    while (currentX < size.width + waveWidth) {
      if (first) {
        path.moveTo(currentX, centerY);
        first = false;
      }

      // 绘制一个完整的正弦波浪周期
      path.quadraticBezierTo(
        currentX + waveWidth * 0.25,
        centerY - waveHeight,
        currentX + waveWidth * 0.5,
        centerY,
      );
      path.quadraticBezierTo(
        currentX + waveWidth * 0.75,
        centerY + waveHeight,
        currentX + waveWidth,
        centerY,
      );

      currentX += waveWidth;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _PerspectiveDashedLinePainter extends CustomPainter {
  final Color color;
  final double progress;

  _PerspectiveDashedLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final double topY = 0.0;
    final double bottomY = size.height;

    // 控制八字形的宽窄
    final double topOffset = 14.0;
    final double bottomOffset = 40.0;

    final int dashCount = 3;
    final double totalLength = bottomY - topY;

    for (int i = -1; i < dashCount + 1; i++) {
      double phase = (i + progress) / dashCount;
      if (phase < 0.0 || phase > 1.0) continue;

      double y = topY + phase * totalLength;
      // 越靠近底部（近处），虚线越长，模拟透视效果
      double dashLen = 3.0 + phase * 6.0;

      double yEnd = y + dashLen;
      if (yEnd > bottomY) yEnd = bottomY;

      double phaseEnd = (yEnd - topY) / totalLength;

      double xLeftStart =
          centerX - (topOffset + phase * (bottomOffset - topOffset));
      double xLeftEnd =
          centerX - (topOffset + phaseEnd * (bottomOffset - topOffset));

      double xRightStart =
          centerX + (topOffset + phase * (bottomOffset - topOffset));
      double xRightEnd =
          centerX + (topOffset + phaseEnd * (bottomOffset - topOffset));

      canvas.drawLine(Offset(xLeftStart, y), Offset(xLeftEnd, yEnd), paint);
      canvas.drawLine(Offset(xRightStart, y), Offset(xRightEnd, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(_PerspectiveDashedLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
