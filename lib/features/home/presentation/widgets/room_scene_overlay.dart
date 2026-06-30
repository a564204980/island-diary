import 'dart:math' show sqrt, exp;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// State & Controllers
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/presentation/controllers/decoration_controller.dart';
import 'package:island_diary/features/record/domain/models/furniture_item.dart';
import 'package:island_diary/features/record/domain/models/placed_furniture.dart';
import 'package:island_diary/features/record/presentation/pages/decoration_page_constants.dart';

// Utils & Painters
import 'package:island_diary/features/record/presentation/utils/isometric_coordinate_utils.dart';
import 'package:island_diary/features/record/presentation/utils/wall_pattern_painter.dart';
import 'package:island_diary/features/record/presentation/utils/floor_pattern_painter.dart';
import 'package:island_diary/features/record/presentation/widgets/furniture_renderer.dart';
import 'package:island_diary/features/record/presentation/widgets/furniture_sprite.dart';

// Widgets
import 'package:island_diary/features/record/presentation/widgets/decoration/furniture_drag_overlay.dart';
import 'package:island_diary/features/record/presentation/widgets/decoration/decoration_toolbar.dart';
import 'package:island_diary/features/record/presentation/widgets/decoration/furniture_dyeing_dialog.dart';

class RoomDecorationPage extends StatefulWidget {
  const RoomDecorationPage({super.key});

  @override
  State<RoomDecorationPage> createState() => _RoomDecorationPageState();
}

class _RoomDecorationPageState extends State<RoomDecorationPage>
    with TickerProviderStateMixin {
  late DecorationController _controller;
  final GlobalKey _paintKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();

  Offset _panOffset = const Offset(0.0, 90.0);
  double _scale = 1.8;
  bool _isTrayExpanded = false;

  // 时间基准动量 Ticker
  Ticker? _flingTicker;
  Offset _flingVel = Offset.zero; // px/s
  Duration? _prevElapsed;

  static const double _maxPanX = 260.0;
  static const double _maxPanY = 260.0;

  // 橡皮筋效果
  double _rubber(double val, double maxVal) {
    if (val.abs() <= maxVal) return val;
    final over = val.abs() - maxVal;
    return (val > 0 ? 1.0 : -1.0) * (maxVal + over * 0.25);
  }

  Offset _applyRubber(Offset o) =>
      Offset(_rubber(o.dx, _maxPanX), _rubber(o.dy, _maxPanY));

  void _onPanStart(DragStartDetails _) {
    _flingTicker?.stop();
    _flingVel = Offset.zero;
    _prevElapsed = null;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _panOffset = _applyRubber(_panOffset + d.delta);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    _flingVel = d.velocity.pixelsPerSecond;
    _prevElapsed = null;

    _flingTicker?.dispose();
    _flingTicker = createTicker((elapsed) {
      final dt = _prevElapsed == null
          ? 0.016
          : ((elapsed - _prevElapsed!).inMicroseconds / 1e6).clamp(0.001, 0.05);
      _prevElapsed = elapsed;

      final disp = _flingVel * dt;
      _flingVel = _flingVel * exp(-4.5 * dt);

      if (_panOffset.dx.abs() > _maxPanX) {
        final spring = (_maxPanX - _panOffset.dx.abs()) * 18.0 * dt;
        _flingVel = Offset(
          _flingVel.dx + (_panOffset.dx > 0 ? spring : -spring),
          _flingVel.dy,
        );
      }
      if (_panOffset.dy.abs() > _maxPanY) {
        final spring = (_maxPanY - _panOffset.dy.abs()) * 18.0 * dt;
        _flingVel = Offset(
          _flingVel.dx,
          _flingVel.dy + (_panOffset.dy > 0 ? spring : -spring),
        );
      }

      setState(() {
        _panOffset = _applyRubber(_panOffset + disp);
      });

      final inBounds =
          _panOffset.dx.abs() <= _maxPanX && _panOffset.dy.abs() <= _maxPanY;
      if (_flingVel.distance < 8.0 && inBounds) {
        _flingTicker?.stop();
      }
    });
    _flingTicker!.start();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = DecorationController();
    _controller.init(context, vsync: this).then((_) {
      if (mounted) setState(() {});
    });
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flingTicker?.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  IsometricCoordinateConverter _getConverter(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.40; // 适当向上偏移，给底部家具选择栏留空间

    final rx = w * 0.42;
    final ry = rx * 0.596;

    const thick = 12.0;
    final dLen = sqrt(rx * rx + ry * ry);
    final inL = Offset(rx / dLen * thick, ry / dLen * thick);
    final inR = Offset(-rx / dLen * thick, ry / dLen * thick);

    final pBackIn = Offset(cx, cy - ry) + inL + inR;
    final pFront = Offset(cx, cy + ry);

    final pLeft = Offset(cx - rx, cy);
    final pLeftIn = pLeft + inL;
    final pRight = Offset(cx + rx, cy);
    final pRightIn = pRight + inR;

    final double tw = (pRightIn.dx - pLeftIn.dx) / 24.0;
    final double th = (pFront.dy - pBackIn.dy) / 24.0;
    final double centerY = (pBackIn.dy + pFront.dy) / 2.0;

    return IsometricCoordinateConverter(
      centerX: cx,
      centerY: centerY,
      tw: tw,
      th: th,
    );
  }

  void _handleLongPressEnd() {
    final size = MediaQuery.of(context).size;
    final converter = _getConverter(size);
    final bool hasMoved =
        _controller.originalFurnitureData == null ||
        (_controller.ghostCell?.$1 != _controller.originalFurnitureData!.r ||
            _controller.ghostCell?.$2 != _controller.originalFurnitureData!.c ||
            _controller.ghostZ != _controller.originalFurnitureData!.z ||
            _controller.draggingRotation != _controller.originalFurnitureData!.rotation);

    if (_controller.ghostCell != null &&
        (!hasMoved ||
            _controller.isAreaAvailable(
              _controller.draggingItem!,
              _controller.ghostCell!.$1,
              _controller.ghostCell!.$2,
              _controller.draggingRotation,
              converter,
              z: _controller.ghostZ,
              exclude: _controller.draggingOriginalPF,
            ))) {
      _controller.placeFurniture(
        _controller.draggingItem!,
        r: _controller.ghostCell!.$1,
        c: _controller.ghostCell!.$2,
        z: _controller.ghostZ,
        rotation: _controller.draggingRotation,
      );
    } else {
      _controller.cancelDragging();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final converter = _getConverter(size);

    // 计算操作工具栏的位置
    RenderBox? paintBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    Offset sceneOrigin = paintBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    return Scaffold(
      backgroundColor: const Color(0xFFA8C898),
      body: DragTarget<FurnitureItem>(
        onMove: (details) {
          final renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPos = renderBox.globalToLocal(details.offset);
            _controller.updateDragPosition(localPos, converter);
          }
        },
        onAcceptWithDetails: (details) {
          final item = details.data;
          _controller.updateInteracting(false);
          if (_controller.ghostCell != null &&
              (item.quantity > 0 || _controller.draggingOriginalPF != null)) {
            if (_controller.isAreaAvailable(
              item,
              _controller.ghostCell!.$1,
              _controller.ghostCell!.$2,
              _controller.draggingRotation,
              converter,
              z: _controller.ghostZ,
              exclude: _controller.draggingOriginalPF,
            )) {
              _controller.placeFurniture(
                item,
                r: _controller.ghostCell!.$1,
                c: _controller.ghostCell!.$2,
                z: _controller.ghostZ,
                rotation: _controller.draggingRotation,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('该区域无法放置家具'),
                  duration: Duration(seconds: 1),
                ),
              );
              _controller.cancelDragging();
            }
          }
        },
        onLeave: (_) => _controller.selectCell(null),
        builder: (context, _, _) => Stack(
          children: [
            // 可拖拽场景
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _onPanStart(details);
                  _controller.updateInteracting(true);
                },
                onPanUpdate: (details) {
                  if (!_controller.isLongPressDragging && _controller.draggingItem == null) {
                    _onPanUpdate(details);
                  } else {
                    final renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final localPos = renderBox.globalToLocal(details.globalPosition);
                      _controller.updateDragPosition(localPos, converter);
                    }
                  }
                },
                onPanEnd: (details) {
                  _onPanEnd(details);
                  _controller.updateInteracting(false);
                  if (_controller.isLongPressDragging) {
                    _handleLongPressEnd();
                  }
                },
                onTapUp: (details) {
                  final renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    final hit = _controller.findVisualHit(localPos, converter);
                    if (hit != null) {
                      _controller.selectFurniture(hit);
                    } else {
                      _controller.selectFurniture(null);
                      if (_isTrayExpanded) {
                        setState(() {
                          _isTrayExpanded = false;
                        });
                      }
                    }
                  }
                },
                onLongPressStart: (details) {
                  final renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    final hit = _controller.findVisualHit(localPos, converter);
                    if (hit != null) {
                      HapticFeedback.mediumImpact();
                      _controller.originalFurnitureData = hit;
                      _controller.draggingOriginalPF = hit;
                      _controller.draggingItem = hit.item;
                      _controller.draggingRotation = hit.rotation;
                      _controller.ghostCell = (hit.r, hit.c);
                      _controller.ghostZ = hit.z;
                      _controller.isLongPressDragging = true;
                      _controller.updateInteracting(true);
                      _controller.selectFurniture(null);
                      _controller.updateDragPosition(localPos, converter, isFirstFrame: true);
                    }
                  }
                },
                onLongPressMoveUpdate: (details) {
                  if (_controller.isLongPressDragging) {
                    final renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final localPos = renderBox.globalToLocal(details.globalPosition);
                      _controller.updateDragPosition(localPos, converter);
                    }
                  }
                },
                onLongPressEnd: (details) {
                  if (_controller.isLongPressDragging) {
                    _handleLongPressEnd();
                  }
                },
                child: Transform.translate(
                  offset: _panOffset,
                  child: Transform.scale(
                    scale: _scale,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        key: _paintKey,
                        size: size,
                        painter: _IsometricRoomPainter(
                          placedItems: _controller.placedFurniture,
                          selectedFurniture: _controller.selectedFurniture,
                          bouncingItem: _controller.bouncingFurniture,
                          bounceScale: _controller.bounceScale,
                          ghostItem: _controller.draggingItem != null && _controller.ghostCell != null
                              ? (
                                  _controller.draggingItem!,
                                  _controller.ghostCell,
                                  _controller.draggingRotation,
                                  _controller.isAreaAvailable(
                                    _controller.draggingItem!,
                                    _controller.ghostCell!.$1,
                                    _controller.ghostCell!.$2,
                                    _controller.draggingRotation,
                                    converter,
                                    z: _controller.ghostZ,
                                    exclude: _controller.draggingOriginalPF,
                                  ),
                                  _controller.ghostZ,
                                )
                              : null,
                          showGrid: _controller.showGrid || _controller.isInteracting,
                          isInteracting: _controller.isInteracting,
                          currentScale: _controller.currentScale,
                          dyeVersion: _controller.dyeVersion,
                          wallColorLeft: _controller.wallColorLeft,
                          wallColorRight: _controller.wallColorRight,
                          wallPattern: _controller.wallPattern,
                          floorColor: _controller.floorColor,
                          floorPattern: _controller.floorPattern,
                          converter: converter,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 家具编辑操作覆盖工具栏 (选中时浮现)
            if (_controller.selectedFurniture != null) ...[
              IgnorePointer(
                ignoring: false,
                child: Stack(
                  children: [
                    FurnitureDragOverlay(
                      pf: _controller.selectedFurniture!,
                      converter: converter,
                      sceneOffset: sceneOrigin,
                      onDragStarted: (item, rot, cell) {
                        _controller.draggingItem = item;
                        _controller.draggingRotation = rot;
                        _controller.ghostCell = cell;
                        _controller.ghostZ = _controller.selectedFurniture?.z ?? 0.0;
                        _controller.draggingOriginalPF = _controller.selectedFurniture;
                        _controller.selectFurniture(null);
                      },
                      onDragCanceled: _controller.cancelDragging,
                    ),
                    DecorationToolbar(
                      pf: _controller.selectedFurniture!,
                      converter: converter,
                      sceneOffset: sceneOrigin,
                      onRotate: () => _controller.rotateFurniture(converter),
                      onDelete: () => _controller.deleteFurniture(_controller.selectedFurniture!),
                      onFillAll: () => {},
                      onDye: () {
                        showDialog(
                          context: context,
                          builder: (context) => FurnitureDyeingDialog(
                            pf: _controller.selectedFurniture!,
                            onVariantSelected: (variant) {
                              _controller.updatePlacedFurnitureVariant(
                                _controller.selectedFurniture!,
                                variant,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            // —— 左侧缩放控制器组件 ——
            Positioned(
              left: 19,
              top: 100,
              child: SizedBox(
                width: 36,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CuteIconButton(
                      isAdd: true,
                      onTap: () {
                        setState(() {
                          _scale = (_scale + 0.1).clamp(0.6, 1.8);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CuteVerticalSlider(
                      value: _scale,
                      min: 0.6,
                      max: 1.8,
                      onChanged: (val) {
                        setState(() {
                          _scale = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CuteIconButton(
                      isAdd: false,
                      onTap: () {
                        setState(() {
                          _scale = (_scale - 0.1).clamp(0.6, 1.8);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // —— 顶部导航栏 ——
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // 保存快照并返回
                          final navigator = Navigator.of(context);
                          final bytes = await _captureSnapshot();
                          await UserState().setDecorationSnapshot(bytes);
                          if (navigator.context.mounted) navigator.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D3818).withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF3D2010),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '我的小屋',
                        style: TextStyle(
                          color: Color(0xFF3D2010),
                          fontSize: 18,
                          fontFamily: 'LXGWWenKai',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 网格开关
                      IconButton(
                        icon: Icon(
                          _controller.showGrid ? Icons.grid_on : Icons.grid_off,
                          color: const Color(0xFF3D2010),
                        ),
                        onPressed: _controller.toggleGrid,
                      ),
                      // 清除全部按钮
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Color(0xFFD9534F),
                        ),
                        onPressed: _handleClearAll,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // —— 底部类似图2的家具物品选择面板 ——
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CuteFurnitureSelectorTray(
                controller: _controller,
                getConverter: () => converter,
                isExpanded: _isTrayExpanded,
                onCategorySelected: (catValue) {
                  setState(() {
                    if (_controller.selectedCategory == catValue && _isTrayExpanded) {
                      _isTrayExpanded = false;
                    } else {
                      _isTrayExpanded = true;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('一键清除', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要清除房间内所有已摆放的家具吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              _controller.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text(
              '确定清除',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureSnapshot() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 0.8);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

/// 等角投影室内画笔
class _IsometricRoomPainter extends CustomPainter {
  final List<PlacedFurniture> placedItems;
  final PlacedFurniture? selectedFurniture;
  final PlacedFurniture? bouncingItem;
  final double bounceScale;
  final (FurnitureItem, (int, int)?, int, bool, double)? ghostItem;
  final bool showGrid;
  final bool isInteracting;
  final double currentScale;
  final int dyeVersion;
  final Color wallColorLeft;
  final Color wallColorRight;
  final WallPattern wallPattern;
  final Color floorColor;
  final FloorPattern floorPattern;
  final IsometricCoordinateConverter converter;

  _IsometricRoomPainter({
    required this.placedItems,
    this.selectedFurniture,
    this.bouncingItem,
    this.bounceScale = 1.0,
    this.ghostItem,
    required this.showGrid,
    required this.isInteracting,
    required this.currentScale,
    required this.dyeVersion,
    required this.wallColorLeft,
    required this.wallColorRight,
    required this.wallPattern,
    required this.floorColor,
    required this.floorPattern,
    required this.converter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 颜色
    final wallL = wallColorLeft;
    final wallR = wallColorRight;
    const wallCutL = Color(0xFF7A5028); // 左端垂直切面（与地板左前沿一致）
    const wallCutR = Color(0xFF6E4820); // 右端垂直切面（与地板右前沿一致）
    const wallTopL = Color(0xFF9B6B3A); // 左墙顶厚（与地板面一致）
    final floorTop = floorColor; // 地板面
    const floorEL = Color(0xFF7A5028); // 地板左前沿
    const floorER = Color(0xFF6E4820); // 地板右前沿（稍深）
    const outline = Color(0xFF5D3418); // 轮廓深棕
    const bg = Color(0xFFA8C898); // 背景

    final cx = w * 0.5;
    final cy = h * 0.40;

    final rx = w * 0.42;
    final ry = rx * 0.596; // 约 30 度角

    final wallH = rx * 0.9;
    final pBack = Offset(cx, cy - ry);
    final pRight = Offset(cx + rx, cy);
    final pFront = Offset(cx, cy + ry);
    final pLeft = Offset(cx - rx, cy);

    final tBack = pBack.translate(0, -wallH);
    final tRight = pRight.translate(0, -wallH);
    final tLeft = pLeft.translate(0, -wallH);

    const thick = 12.0;
    final dLen = sqrt(rx * rx + ry * ry);

    final inL = Offset(rx / dLen * thick, ry / dLen * thick);
    final inR = Offset(-rx / dLen * thick, ry / dLen * thick);

    const stepH = 12.0; // 垂直底座高度
    const slopeH = 6.0; // 倾斜过渡高度
    const stepW = 4.0; // 步进宽度
    final outL = inL * (-stepW / thick);
    final outR = inR * (-stepW / thick);

    final pLeftOut = pLeft + outL;
    final pRightOut = pRight + outR;

    final pLeftIn = pLeft + inL;
    final pRightIn = pRight + inR;
    final pBackIn = pBack + inL + inR;

    final tLeftIn = tLeft + inL;
    final tRightIn = tRight + inR;
    final tBackIn = tBack + inL + inR;

    const edgeH = 12.0;

    // 1. 背景
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = bg);

    // 2. 左墙内表面
    _fill(canvas, [pBackIn, pLeftIn, tLeftIn, tBackIn], wallL);

    // 3. 右墙内表面
    _fill(canvas, [pBackIn, pRightIn, tRightIn, tBackIn], wallR);

    // 3.1 绘制墙壁花纹
    WallPatternPainter.paint(
      canvas: canvas,
      converter: converter,
      pattern: wallPattern,
      isLeft: true,
      rows: 24,
      cols: 24,
      baseColor: wallL,
    );
    WallPatternPainter.paint(
      canvas: canvas,
      converter: converter,
      pattern: wallPattern,
      isLeft: false,
      rows: 24,
      cols: 24,
      baseColor: wallR,
    );

    // 4. 地板面（被墙壁覆盖后的内部地板，圆角化处理以防尖角溢出）
    const double tFront = 0.04;
    final pFrontLInner = pFront + (pLeftIn - pFront) * tFront;
    final pFrontRInner = pFront + (pRightIn - pFront) * tFront;
    final floorTopPath = Path()
      ..moveTo(pBackIn.dx, pBackIn.dy)
      ..lineTo(pRightIn.dx, pRightIn.dy)
      ..lineTo(pFrontRInner.dx, pFrontRInner.dy)
      ..quadraticBezierTo(pFront.dx, pFront.dy, pFrontLInner.dx, pFrontLInner.dy)
      ..lineTo(pLeftIn.dx, pLeftIn.dy)
      ..close();
    canvas.drawPath(floorTopPath, Paint()..color = floorTop);

    // 4.05 绘制地板花纹
    FloorPatternPainter.paint(
      canvas: canvas,
      converter: converter,
      pattern: floorPattern,
      rows: 24,
      cols: 24,
      baseColor: floorTop,
    );

    // 4.1 绘制 24x24 地板网格线
    if (showGrid) {
      canvas.save();
      canvas.clipPath(floorTopPath);
      final gridPaint = Paint()
        ..color = outline.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      final vL = pLeftIn - pBackIn;
      final vR = pRightIn - pBackIn;

      for (int r = 1; r < 24; r++) {
        final start = pBackIn + vL * (r / 24.0);
        final end = pBackIn + vL * (r / 24.0) + vR;
        canvas.drawLine(start, end, gridPaint);
      }
      for (int c = 1; c < 24; c++) {
        final start = pBackIn + vR * (c / 24.0);
        final end = pBackIn + vR * (c / 24.0) + vL;
        canvas.drawLine(start, end, gridPaint);
      }
      canvas.restore();
    }

    final cornerPaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    const rBackTemp = 0.04;
    final pInnerStartTemp = tBackIn + (tRightIn - tBackIn) * rBackTemp;
    final pInnerEndTemp = tBackIn + (tLeftIn - tBackIn) * rBackTemp;
    final tBackInCurveCenter =
        pInnerEndTemp * 0.25 + tBackIn * 0.5 + pInnerStartTemp * 0.25;
    canvas.drawLine(pBackIn, tBackInCurveCenter, cornerPaint);
    canvas.drawLine(pBackIn, pLeftIn, cornerPaint);
    canvas.drawLine(pBackIn, pRightIn, cornerPaint);

    // 4.2 核心步骤：渲染已摆放的家具与拖拽预览
    _drawAllFurniture(canvas, converter, converter.tw, converter.th);

    // 计算切面与顶部的圆角过渡顶点
    const rEnd = 0.004;
    final pTopLeft = tLeft + (tBack - tLeft) * rEnd;
    final pVertLeft = tLeft + (pLeft - tLeft) * (rEnd * 1.5);
    final pTopLeftIn = tLeftIn + (tBackIn - tLeftIn) * rEnd;
    final pVertLeftIn = tLeftIn + (pLeftIn - tLeftIn) * (rEnd * 1.5);

    final pTopRight = tRight + (tBack - tRight) * rEnd;
    final pVertRight = tRight + (pRight - tRight) * (rEnd * 1.5);
    final pTopRightIn = tRightIn + (tBackIn - tRightIn) * rEnd;
    final pVertRightIn = tRightIn + (pRightIn - tRightIn) * (rEnd * 1.5);

    final pLeftStepTop =
        tLeft + (pLeft - tLeft) * ((wallH - stepH - slopeH) / wallH);
    final pLeftStepBottom =
        tLeft + (pLeft - tLeft) * ((wallH - stepH) / wallH) + outL;
    final pRightStepTop =
        tRight + (pRight - tRight) * ((wallH - stepH - slopeH) / wallH);
    final pRightStepBottom =
        tRight + (pRight - tRight) * ((wallH - stepH) / wallH) + outR;

    // 5. 左端垂直切面
    final leftCutPath = Path()
      ..moveTo(pTopLeftIn.dx, pTopLeftIn.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..quadraticBezierTo(tLeft.dx, tLeft.dy, pVertLeft.dx, pVertLeft.dy)
      ..lineTo(pLeftStepTop.dx, pLeftStepTop.dy)
      ..lineTo(pLeftStepBottom.dx, pLeftStepBottom.dy)
      ..lineTo(pLeftOut.dx, pLeftOut.dy)
      ..lineTo(pLeftIn.dx, pLeftIn.dy)
      ..lineTo(pVertLeftIn.dx, pVertLeftIn.dy)
      ..quadraticBezierTo(tLeftIn.dx, tLeftIn.dy, pTopLeftIn.dx, pTopLeftIn.dy)
      ..close();
    canvas.drawPath(leftCutPath, Paint()..color = wallCutL);

    // 6. 右端垂直切面
    final rightCutPath = Path()
      ..moveTo(pTopRightIn.dx, pTopRightIn.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..quadraticBezierTo(tRight.dx, tRight.dy, pVertRight.dx, pVertRight.dy)
      ..lineTo(pRightStepTop.dx, pRightStepTop.dy)
      ..lineTo(pRightStepBottom.dx, pRightStepBottom.dy)
      ..lineTo(pRightOut.dx, pRightOut.dy)
      ..lineTo(pRightIn.dx, pRightIn.dy)
      ..lineTo(pVertRightIn.dx, pVertRightIn.dy)
      ..quadraticBezierTo(
        tRightIn.dx,
        tRightIn.dy,
        pTopRightIn.dx,
        pTopRightIn.dy,
      )
      ..close();
    canvas.drawPath(rightCutPath, Paint()..color = wallCutR);

    // 7. 墙顶面
    const rBack = 0.04;
    final pOuterStart = tBack + (tLeft - tBack) * rBack;
    final pOuterEnd = tBack + (tRight - tBack) * rBack;
    final pInnerStart = tBackIn + (tRightIn - tBackIn) * rBack;
    final pInnerEnd = tBackIn + (tLeftIn - tBackIn) * rBack;

    final wallTopPath = Path()
      ..moveTo(pTopLeftIn.dx, pTopLeftIn.dy)
      ..lineTo(pInnerEnd.dx, pInnerEnd.dy)
      ..quadraticBezierTo(
        tBackIn.dx,
        tBackIn.dy,
        pInnerStart.dx,
        pInnerStart.dy,
      )
      ..lineTo(pTopRightIn.dx, pTopRightIn.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pOuterEnd.dx, pOuterEnd.dy)
      ..quadraticBezierTo(tBack.dx, tBack.dy, pOuterStart.dx, pOuterStart.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..close();
    canvas.drawPath(wallTopPath, Paint()..color = wallTopL);

    // 8. 地板前沿与圆角化
    final fFL = pFront.translate(0, edgeH);
    final fLL = pLeftOut.translate(0, edgeH);
    final fRL = pRightOut.translate(0, edgeH);

    final pFrontL = pFront + (pLeftOut - pFront) * tFront;
    final pFrontR = pFront + (pRightOut - pFront) * tFront;

    final fFLLeft = fFL + (fLL - fFL) * tFront;
    final fFLRight = fFL + (fRL - fFL) * tFront;

    final pFrontMid = pFrontL * 0.25 + pFront * 0.5 + pFrontR * 0.25;
    final fFLMid = fFLLeft * 0.25 + fFL * 0.5 + fFLRight * 0.25;

    final ctrlL = pFrontL * 0.5 + pFront * 0.5;
    final ctrlR = pFront * 0.5 + pFrontR * 0.5;
    final ctrlFLLeft = fFLLeft * 0.5 + fFL * 0.5;
    final ctrlFLRight = fFL * 0.5 + fFLRight * 0.5;

    final pathLeftFront = Path()
      ..moveTo(pLeftOut.dx, pLeftOut.dy)
      ..lineTo(pFrontL.dx, pFrontL.dy)
      ..quadraticBezierTo(ctrlL.dx, ctrlL.dy, pFrontMid.dx, pFrontMid.dy)
      ..lineTo(fFLMid.dx, fFLMid.dy)
      ..quadraticBezierTo(ctrlFLLeft.dx, ctrlFLLeft.dy, fFLLeft.dx, fFLLeft.dy)
      ..lineTo(fLL.dx, fLL.dy)
      ..close();
    canvas.drawPath(pathLeftFront, Paint()..color = floorEL);

    final pathRightFront = Path()
      ..moveTo(pFrontMid.dx, pFrontMid.dy)
      ..quadraticBezierTo(ctrlR.dx, ctrlR.dy, pFrontR.dx, pFrontR.dy)
      ..lineTo(pRightOut.dx, pRightOut.dy)
      ..lineTo(fRL.dx, fRL.dy)
      ..lineTo(fFLRight.dx, fFLRight.dy)
      ..quadraticBezierTo(ctrlFLRight.dx, ctrlFLRight.dy, fFLMid.dx, fFLMid.dy)
      ..close();
    canvas.drawPath(pathRightFront, Paint()..color = floorER);

    // 10. 主轮廓描边
    final sp = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final pathTop = Path()
      ..moveTo(pLeftIn.dx, pLeftIn.dy)
      ..lineTo(pFrontL.dx, pFrontL.dy)
      ..quadraticBezierTo(pFront.dx, pFront.dy, pFrontR.dx, pFrontR.dy)
      ..lineTo(pRightIn.dx, pRightIn.dy);
    canvas.drawPath(pathTop, sp);

    final pathBottom = Path()
      ..moveTo(fLL.dx, fLL.dy)
      ..lineTo(fFLLeft.dx, fFLLeft.dy)
      ..quadraticBezierTo(fFL.dx, fFL.dy, fFLRight.dx, fFLRight.dy)
      ..lineTo(fRL.dx, fRL.dy);
    canvas.drawPath(pathBottom, sp);

    canvas.drawLine(pLeftOut, fLL, sp);
    canvas.drawLine(pRightOut, fRL, sp);



    final pathLeftEndOut = Path()
      ..moveTo(pLeftOut.dx, pLeftOut.dy)
      ..lineTo(pLeftStepBottom.dx, pLeftStepBottom.dy)
      ..lineTo(pLeftStepTop.dx, pLeftStepTop.dy)
      ..lineTo(pVertLeft.dx, pVertLeft.dy)
      ..quadraticBezierTo(tLeft.dx, tLeft.dy, pTopLeft.dx, pTopLeft.dy);
    canvas.drawPath(pathLeftEndOut, sp);

    final pathLeftEndIn = Path()
      ..moveTo(pLeftIn.dx, pLeftIn.dy)
      ..lineTo(pVertLeftIn.dx, pVertLeftIn.dy)
      ..quadraticBezierTo(tLeftIn.dx, tLeftIn.dy, pTopLeftIn.dx, pTopLeftIn.dy);
    canvas.drawPath(pathLeftEndIn, sp);

    final pathWallTopIn = Path()
      ..moveTo(pTopLeftIn.dx, pTopLeftIn.dy)
      ..lineTo(pInnerEnd.dx, pInnerEnd.dy)
      ..quadraticBezierTo(
        tBackIn.dx,
        tBackIn.dy,
        pInnerStart.dx,
        pInnerStart.dy,
      )
      ..lineTo(pTopRightIn.dx, pTopRightIn.dy);
    canvas.drawPath(pathWallTopIn, sp);

    final pathWallTopOut = Path()
      ..moveTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pOuterStart.dx, pOuterStart.dy)
      ..quadraticBezierTo(tBack.dx, tBack.dy, pOuterEnd.dx, pOuterEnd.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy);
    canvas.drawPath(pathWallTopOut, sp);

    final pathRightEndOut = Path()
      ..moveTo(pTopRight.dx, pTopRight.dy)
      ..quadraticBezierTo(tRight.dx, tRight.dy, pVertRight.dx, pVertRight.dy)
      ..lineTo(pRightStepTop.dx, pRightStepTop.dy)
      ..lineTo(pRightStepBottom.dx, pRightStepBottom.dy)
      ..lineTo(pRightOut.dx, pRightOut.dy);
    canvas.drawPath(pathRightEndOut, sp);

    final pathRightEndIn = Path()
      ..moveTo(pTopRightIn.dx, pTopRightIn.dy)
      ..quadraticBezierTo(
        tRightIn.dx,
        tRightIn.dy,
        pVertRightIn.dx,
        pVertRightIn.dy,
      )
      ..lineTo(pRightIn.dx, pRightIn.dy);
    canvas.drawPath(pathRightEndIn, sp);
  }

  void _drawAllFurniture(Canvas canvas, IsometricCoordinateConverter converter, double tw, double th) {
    final draggingOriginal = ghostItem != null ? placedItems.where((pf) => pf.item.id == ghostItem!.$1.id).firstOrNull : null;
    final List<PlacedFurniture> sortedItems = List<PlacedFurniture>.from(placedItems.where((pf) => pf != draggingOriginal))
      ..sort((a, b) {
        if (a.item.isFloor != b.item.isFloor) return a.item.isFloor ? -1 : 1;
        if (a.item.isWall != b.item.isWall) return a.item.isWall ? -1 : 1;
        
        bool aIsCarpet = a.item.subCategory == '地毯';
        bool bIsCarpet = b.item.subCategory == '地毯';
        if (aIsCarpet != bIsCarpet) return aIsCarpet ? -1 : 1;

        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;

        if (a.r >= b.r + gwB || a.c >= b.c + ghB) return 1;
        if (b.r >= a.r + gwA || b.c >= a.c + ghA) return -1;
        if (a.z != b.z) return a.z.compareTo(b.z);
        return (a.r + a.c).compareTo(b.r + b.c);
      });

    final floorPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(24, 0, 0),
        converter.getScreenPoint(24, 24, 0),
        converter.getScreenPoint(0, 24, 0),
      ], true);

    for (final pf in sortedItems) {
      if (pf == selectedFurniture) {
        FurnitureRenderer.drawSelectionFootprint(canvas, pf, converter, tw, th);
      }

      final bool needsClip = pf.item.isFloor || pf.item.subCategory == '地毯';
      if (needsClip) {
        canvas.save();
        canvas.clipPath(floorPath);
      }

      FurnitureRenderer.draw(
        canvas: canvas,
        item: pf.item,
        r: pf.r,
        c: pf.c,
        z: pf.z,
        rotation: pf.rotation,
        converter: converter,
        tw: tw,
        th: th,
        bounceScale: (pf == bouncingItem) ? bounceScale : 1.0,
      );

      if (needsClip) {
        canvas.restore();
      }
    }

    if (ghostItem != null && ghostItem!.$2 != null) {
      final cell = ghostItem!.$2!;
      FurnitureRenderer.draw(
        canvas: canvas,
        item: ghostItem!.$1,
        r: cell.$1,
        c: cell.$2,
        z: ghostItem!.$5,
        rotation: ghostItem!.$3,
        converter: converter,
        tw: tw,
        th: th,
        opacity: 0.6,
        isValid: ghostItem!.$4,
      );
    }
  }

  void _fill(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _IsometricRoomPainter old) => true;
}

class CuteVerticalSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const CuteVerticalSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  void _handleDragUpdate(double localY, double maxHeight) {
    final double trackHeight = maxHeight - 30;
    if (trackHeight <= 0) return;

    final double progress = (1.0 - ((localY - 15) / trackHeight)).clamp(
      0.0,
      1.0,
    );
    onChanged(min + progress * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        _handleDragUpdate(details.localPosition.dy, 120.0);
      },
      onTapDown: (details) {
        _handleDragUpdate(details.localPosition.dy, 120.0);
      },
      child: CustomPaint(
        size: const Size(36, 120),
        painter: _CuteVerticalSliderPainter(value: value, min: min, max: max),
      ),
    );
  }
}

class _CuteVerticalSliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  _CuteVerticalSliderPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    const trackW = 20.0;
    const thumbRadius = 13.0;

    final outlinePaint = Paint()
      ..color = const Color(0xFF5D3418)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final trackRect = Rect.fromLTWH(cx - trackW / 2, 0, trackW, h);
    final trackRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(10),
    );

    canvas.save();
    canvas.clipRRect(trackRRect);

    final bgPaint = Paint()..color = const Color(0xFFB57448);
    canvas.drawRect(trackRect, bgPaint);

    final double progress = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final double thumbY = (1.0 - progress) * (h - 30.0) + 15.0;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB3D2EE), Color(0xFF8AB5E0)],
      ).createShader(
        Rect.fromLTWH(cx - trackW / 2, thumbY, trackW, h - thumbY),
      );

    canvas.drawRect(
      Rect.fromLTWH(cx - trackW / 2, thumbY, trackW, h - thumbY),
      activePaint,
    );

    canvas.restore();
    canvas.drawRRect(trackRRect, outlinePaint);

    final thumbCenter = Offset(cx, thumbY);
    final shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: thumbCenter.translate(0, 2),
          radius: thumbRadius,
        ),
      );
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0x335D3418)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    final thumbPaint = Paint()..color = const Color(0xFFFB784E);
    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
    canvas.drawCircle(thumbCenter, thumbRadius, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _CuteVerticalSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max;
  }
}

class CuteIconButton extends StatelessWidget {
  final bool isAdd;
  final VoidCallback onTap;

  const CuteIconButton({super.key, required this.isAdd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: const Size(36, 36),
        painter: _CuteIconButtonPainter(isAdd: isAdd),
      ),
    );
  }
}

class _CuteIconButtonPainter extends CustomPainter {
  final bool isAdd;

  _CuteIconButtonPainter({required this.isAdd});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 1.5;

    final outlinePaint = Paint()
      ..color = const Color(0xFF5D3418)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy + 1.5), radius: radius));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0x335D3418)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    final bgPaint = Paint()..color = const Color(0xFFFCD39B);
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);
    canvas.drawCircle(Offset(cx, cy), radius, outlinePaint);

    final innerPaint = Paint()..color = const Color(0xFFC7ECF4);
    final innerStrokePaint = Paint()
      ..color = const Color(0xFF5D3418)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(cx, cy);
    final iconPath = Path();

    if (isAdd) {
      iconPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 14, height: 5),
          const Radius.circular(1.5),
        ),
      );
      iconPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 5, height: 14),
          const Radius.circular(1.5),
        ),
      );
    } else {
      iconPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 14, height: 5),
          const Radius.circular(1.5),
        ),
      );
    }

    canvas.drawPath(iconPath, innerPaint);
    canvas.drawPath(iconPath, innerStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _CuteIconButtonPainter oldDelegate) {
    return oldDelegate.isAdd != isAdd;
  }
}

/// 底部双排分页物品选择面板
class CuteFurnitureSelectorTray extends StatefulWidget {
  final DecorationController controller;
  final IsometricCoordinateConverter Function() getConverter;
  final bool isExpanded;
  final Function(String) onCategorySelected;

  const CuteFurnitureSelectorTray({
    super.key,
    required this.controller,
    required this.getConverter,
    required this.isExpanded,
    required this.onCategorySelected,
  });

  @override
  State<CuteFurnitureSelectorTray> createState() => _CuteFurnitureSelectorTrayState();
}

class _CuteFurnitureSelectorTrayState extends State<CuteFurnitureSelectorTray> {
  int _currentPage = 0;

  static const List<Map<String, String>> _categories = [
    {'label': '家具', 'value': '家具'},
    {'label': '墙饰', 'value': '墙饰'},
    {'label': '摆件', 'value': '摆件'},
    {'label': '地饰', 'value': '地饰'},
    {'label': '装修', 'value': '硬装'},
  ];

  @override
  Widget build(BuildContext context) {
    final availableItems = widget.controller.availableItems;
    final selectedCategory = widget.controller.selectedCategory;
    final selectedSubCategory = widget.controller.selectedSubCategory;

    final subCategories = availableItems
        .where((e) => e.category == selectedCategory)
        .map((e) => e.subCategory)
        .toSet()
        .toList();

    final filteredItems = availableItems.where((item) {
      bool matchCat = item.category == selectedCategory;
      bool matchSub = selectedSubCategory == null || item.subCategory == selectedSubCategory;
      return matchCat && matchSub;
    }).toList();

    final int itemsPerPage = 10;
    final int totalPages = (filteredItems.length / itemsPerPage).ceil();
    final int totalPageSafe = totalPages == 0 ? 1 : totalPages;
    if (_currentPage >= totalPageSafe) {
      _currentPage = 0;
    }

    final pageItems = filteredItems.skip(_currentPage * itemsPerPage).take(itemsPerPage).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.isExpanded ? const Color(0xFFFEF9EB) : const Color(0xFF8B5E3C),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(
          color: widget.isExpanded ? const Color(0xFFE8D4B4) : const Color(0xFF8B5E3C),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 顶部棕色木质分类栏
            Container(
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5E3C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                children: [
                  // 分类选项，包裹在 Expanded 中以自适应剩余空间
                  Expanded(
                    child: Row(
                      children: _categories.map((cat) {
                        final bool isSelected = selectedCategory == cat['value'] && widget.isExpanded;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              widget.onCategorySelected(cat['value']!);
                              widget.controller.setCategory(cat['value']!);
                              setState(() {
                                _currentPage = 0;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFEF9EB) : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                cat['label']!,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF8B5E3C) : const Color(0xFFE8D4B4),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 默认排序按钮
                  GestureDetector(
                    onTap: () {
                      // 默认排序点击
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '默认排序',
                            style: TextStyle(
                              color: Color(0xFF8B5E3C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.swap_vert_rounded,
                            color: Color(0xFF8B5E3C),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 二级展示区域
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              firstCurve: Curves.easeInCubic,
              secondCurve: Curves.easeOutCubic,
              crossFadeState: widget.isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 二级子分类导航 (使用横向图标列表)
                  Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F3DF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSubCatIconPill(
                          label: '全部',
                          isSelected: selectedSubCategory == null,
                          onTap: () {
                            widget.controller.setSubCategory(null);
                            setState(() {
                              _currentPage = 0;
                            });
                          },
                        ),
                        ...subCategories.map((sub) => _buildSubCatIconPill(
                              label: sub,
                              isSelected: selectedSubCategory == sub,
                              onTap: () {
                                widget.controller.setSubCategory(sub);
                                setState(() {
                                  _currentPage = 0;
                                });
                              },
                            )),
                      ],
                    ),
                  ),

                  // 3. 分页物品网格 (2行 5列 = 10个格子)
                  SizedBox(
                    height: 172,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) {
                        final item = pageItems[index];
                        final bool isOutOfStock = item.quantity <= 0;

                        return LongPressDraggable<FurnitureItem>(
                          delay: const Duration(milliseconds: 300),
                          data: item,
                          maxSimultaneousDrags: isOutOfStock ? 0 : 1,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: SizedBox(
                            width: 60,
                            height: 60,
                            child: FurnitureSprite(item: item),
                          ),
                          onDragStarted: () {
                            widget.controller.draggingItem = item;
                            widget.controller.draggingRotation = 0;
                            widget.controller.ghostZ = 0.0;
                            widget.controller.ghostCell = (12, 12);
                            widget.controller.updateInteracting(true);
                          },
                          onDragEnd: (details) {
                            widget.controller.cancelDragging();
                          },
                          child: GestureDetector(
                            onTap: () {
                              if (item.quantity > 0) {
                                widget.controller.addFurniture(item);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE8D4B4), width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0C000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: AspectRatio(
                                        aspectRatio: item.intrinsicWidth / item.intrinsicHeight,
                                        child: FurnitureSprite(item: item),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: const Color(0xFF8B5E3C).withValues(alpha: 0.5),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4A373),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 4. 页码与翻页
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left_rounded, color: Color(0xFF8B5E3C), size: 28),
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentPage + 1}/$totalPageSafe',
                          style: const TextStyle(
                            color: Color(0xFF5D3418),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_right_rounded, color: Color(0xFF8B5E3C), size: 28),
                          onPressed: _currentPage < totalPageSafe - 1
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                  });
                                }
                              : null,
                        ),
                      ],
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

  IconData _getSubCatIcon(String subCategory) {
    switch (subCategory) {
      case '全部':
        return Icons.grid_view_rounded;
      case '沙发':
      case '沙发椅':
        return Icons.weekend_rounded;
      case '椅凳':
      case '椅子':
      case '单人椅':
        return Icons.chair_rounded;
      case '桌子':
      case '桌几':
      case '书桌':
      case '餐桌':
      case '茶几':
        return Icons.table_restaurant_rounded;
      case '柜子':
      case '收纳':
      case '书柜':
      case '衣柜':
      case '架子':
        return Icons.shelves;
      case '床':
      case '床铺':
      case '双人床':
      case '单人床':
        return Icons.bed_rounded;
      case '绿植':
      case '盆栽':
      case '植物':
        return Icons.local_florist_rounded;
      case '卫浴':
      case '卫生间':
      case '马桶':
      case '浴缸':
        return Icons.bathtub_rounded;
      case '灯具':
      case '照明':
      case '灯':
        return Icons.lightbulb_rounded;
      case '地饰':
      case '地毯':
        return Icons.layers_rounded;
      case '挂画':
      case '挂饰':
      case '壁饰':
      case '墙饰':
      case '墙面':
        return Icons.wallpaper_rounded;
      case '家电':
      case '电视':
      case '冰箱':
      case '空调':
        return Icons.ac_unit_rounded;
      case '相框':
        return Icons.portrait_rounded;
      case '宠物':
        return Icons.pets_rounded;
      case '厨房':
        return Icons.kitchen_rounded;
      case '客厅':
        return Icons.weekend_rounded;
      case '玩具':
        return Icons.toys_rounded;
      case '电脑':
        return Icons.laptop_chromebook_rounded;
      case '墙纸':
        return Icons.wallpaper_rounded;
      case '地砖':
        return Icons.grid_on_rounded;
      case '邮箱':
        return Icons.mail_rounded;
      case '地板':
        return Icons.border_all_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Widget _buildSubCatIconPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE89A3E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          _getSubCatIcon(label),
          size: 20,
          color: isSelected ? Colors.white : const Color(0xFF8B5E3C).withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

