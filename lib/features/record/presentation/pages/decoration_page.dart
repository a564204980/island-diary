import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:island_diary/core/state/user_state.dart';
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../../data/furniture_data.dart';
import '../widgets/furniture_sprite.dart';
import '../widgets/decoration/furniture_inventory_tray.dart';
import '../widgets/isometric_grid_painter.dart';
import '../widgets/decoration/decoration_toolbar.dart';
import '../widgets/decoration/furniture_drag_overlay.dart';
import '../utils/isometric_coordinate_utils.dart';
import 'decoration_page_constants.dart';

class DecorationPage extends StatefulWidget {
  const DecorationPage({super.key});

  @override
  State<DecorationPage> createState() => _DecorationPageState();
}

class _DecorationPageState extends State<DecorationPage> with SingleTickerProviderStateMixin {
  (int, int)? _selectedCell;
  (int, int)? _ghostCell;
  FurnitureItem? _draggingItem; // 显式记录正在拖动的物品，解决 DragTarget 延迟问题
  int _draggingRotation = 0;
  double _ghostZ = 0.0; // 拖拽时的临时高度
  PlacedFurniture? _selectedFurniture;
  final List<PlacedFurniture> _placedFurniture = [];
  late List<FurnitureItem> _availableItems;
  
  String _selectedCategory = '厨房';
  String? _selectedSubCategory;

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey(); // 用于截屏的 Key

  bool _isTrayExpanded = true;
  bool _isCapturingSnapshot = false; // 是否正在捕获快照
  bool _showGrid = true; // 是否显示网格 (默认为 true)
  
  // 场景控制与交互状态
  double _currentScale = 0.6;
  double _baseScale = 0.6;
  Offset _sceneOffset = const Offset(-120, 0);
  Offset _lastFocalPoint = Offset.zero;
  bool _isInteracting = false; // 用于性能优化：交互时降低渲染质量

  AnimationController? _zoomAnimationController; // 缩放动画控制器
  double _zoomStartScale = 0.6;
  double _zoomEndScale = 0.6;

  // ui.Image? _bgImage; // 移除未使用的背景图引用

  @override
  void initState() {
    super.initState();
    _resolveImageSize();

    // 强制横屏并进入沉浸模式
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _zoomAnimationController!.addListener(() {
      if (_zoomAnimationController!.isAnimating) {
        setState(() {
          final double t = CurvedAnimation(
            parent: _zoomAnimationController!, 
            curve: Curves.easeOutCubic
          ).value;
          _currentScale = _zoomStartScale + (_zoomEndScale - _zoomStartScale) * t;
          _isInteracting = true; // 动画期间隐藏坐标
        });
      }
    });

    _zoomAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() => _isInteracting = false); // 结束后恢复
        }
      }
    });

    _availableItems = defaultFurnitureItems.map((item) {
      return FurnitureItem(
        id: item.id,
        name: item.name,
        imagePath: item.imagePath,
        spriteRect: item.spriteRect,
        category: item.category,
        subCategory: item.subCategory,
        gridW: item.gridW,
        gridH: item.gridH,
        intrinsicWidth: item.intrinsicWidth,
        intrinsicHeight: item.intrinsicHeight,
        quantity: item.quantity,
        visualScale: item.visualScale,
        visualOffset: item.visualOffset,
        visualRotationX: item.visualRotationX,
        visualRotationY: item.visualRotationY,
        visualRotationZ: item.visualRotationZ,
        visualPivot: item.visualPivot,
        backVisualScale: item.backVisualScale,
        backVisualOffset: item.backVisualOffset,
        backVisualRotationX: item.backVisualRotationX,
        backVisualRotationY: item.backVisualRotationY,
        backVisualRotationZ: item.backVisualRotationZ,
        backVisualPivot: item.backVisualPivot,
      );
    }).toList();

    // 加载已保存的家具布局
    final saved = UserState().placedFurniture.value;
    if (saved.isNotEmpty) {
      for (var sf in saved) {
        final masterItem = _availableItems.cast<FurnitureItem?>().firstWhere(
          (it) => it?.id == sf.item.id,
          orElse: () => null,
        );
        if (masterItem != null) {
          _placedFurniture.add(PlacedFurniture(
            item: masterItem,
            r: sf.r,
            c: sf.c,
            rotation: sf.rotation,
          ));
          masterItem.quantity--;
        }
      }
    }

    _sceneOffset = const Offset(-120, 0); // 默认向左偏移，避免被右侧物品栏遮挡

    // 预加载所有家具素材，确保 Painter 能在首帧拿到图片
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final item in _availableItems) {
        await FurnitureSprite.precacheItem(item, context);
        // 每加载一个大型素材就刷一下，体验更好
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // 恢复竖屏和普通 UI 模式
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _zoomAnimationController?.dispose();
    super.dispose();
  }

  void _resolveImageSize() {
    // 动态搭建模式下不再需要固定背景图
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    const double imgW = 2000; 
    const double imgH = 2000;

    double scale = screenH / imgH;
    final double fullWidth = imgW * scale;

    if (fullWidth < screenW) {
      scale = screenW / imgW;
    }

    final double w = imgW * scale * kSceneScaleFactor * _currentScale;
    final double h = imgH * scale * kSceneScaleFactor * _currentScale;

    final converter = IsometricCoordinateConverter(
      centerX: w / 2,
      centerY: h * _getGridCenterYFactor(context),
      tw: w / 28,
      th: w / 56,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 场景渲染层
          Container(
            alignment: Alignment.center,
            width: screenW,
            height: screenH,
            child: RepaintBoundary(
              key: _repaintKey,
              child: Transform.translate(
                offset: _sceneOffset,
                child: SizedBox(
                  key: _gridKey,
                  width: w,
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 背景网格与家具绘制
                      Positioned.fill(
                        child: CustomPaint(
                          painter: IsometricGridPainter(
                            rows: kGridRows,
                            cols: kGridCols,
                            fullWidth: w,
                            fullHeight: h,
                            centerYFactor: _getGridCenterYFactor(context),
                            selectedCell: _selectedCell,
                            placedItems: _placedFurniture,
                            selectedFurniture: _selectedFurniture,
                            isCapturing: _isCapturingSnapshot,
                            showGrid: _showGrid,
                            isInteracting: _isInteracting,
                            currentScale: _currentScale,
                            ghostItem: _draggingItem != null && _ghostCell != null
                                ? (
                                    _draggingItem!,
                                    _ghostCell,
                                    _draggingRotation,
                                    _isAreaAvailable(
                                      _draggingItem!,
                                      _ghostCell!.$1,
                                      _ghostCell!.$2,
                                      _draggingRotation,
                                      converter,
                                      z: _ghostZ,
                                    ),
                                    _ghostZ,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. 全屏拖拽感知层：不随场景变换，覆盖全屏以消除交互死角
          Positioned.fill(
            child: DragTarget<FurnitureItem>(
              onMove: (details) {
                final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
                if (box == null) return;
                final localPos = box.globalToLocal(details.offset);

                // 墙面物品：专用逻辑（不依赖 getGridCell 的距离阈值）
                if (_draggingItem != null && _draggingItem!.isWall) {
                  // 1. 水平位置：将光标 X 坐标投影到最近的墙面
                  // 视觉左墙(r=0,沿c轴) 在屏幕左侧(x<center)，preferLeftWall=false
                  // 视觉右墙(c=0,沿r轴) 在屏幕右侧(x>=center)，preferLeftWall=true
                  final bool preferLeft = localPos.dx >= converter.centerX;
                  final wallCell = converter.getWallCell(localPos, preferLeftWall: preferLeft);

                  // 自动根据所在墙壁更新朝向（0=左墙，1=右墙）
                  final int targetRotation = preferLeft ? 0 : 1;
                  if (_draggingRotation != targetRotation) {
                    _draggingRotation = targetRotation;
                  }

                  // 2. Z 轴：直接由光标绝对 Y 坐标映射，无增量累积
                  final double baseR = preferLeft ? wallCell.$1.toDouble() : 0;
                  final double baseC = preferLeft ? 0 : wallCell.$2.toDouble();
                  final double maxAllowableZ = (kWallGridHeight - _draggingItem!.gridH).toDouble();

                  _ghostZ = converter.getWallZ(
                    localPos,
                    r: baseR,
                    c: baseC,
                    maxZ: kWallGridHeight.toDouble(),
                  ).clamp(0.0, maxAllowableZ).roundToDouble(); // 增加 roundToDouble() 实现网格吸附

                  // 3. 以物品中心对齐格子，并限制边界
                  final int gw = _draggingItem!.gridW;
                  (int, int) centeredCell;
                  if (preferLeft) {
                    centeredCell = (
                      (wallCell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
                      0,
                    );
                  } else {
                    centeredCell = (
                      0,
                      (wallCell.$2 - (gw / 2).floor()).clamp(0, kGridCols - gw),
                    );
                  }

                  setState(() {
                    _ghostCell = centeredCell;
                    _isInteracting = true;
                  });
                  return; // 墙面物品跳过下方地面逻辑
                }

                // 地面物品：原有逻辑
                var cell = converter.getGridCell(localPos);
                if (cell != null) {
                  if (isCellExcluded(cell.$1, cell.$2)) {
                    cell = null;
                  }
                }
                if (cell != null) {
                  final finalCell = cell;
                  final activeItem = _draggingItem;
                  if (activeItem != null) {
                    int gw = activeItem.gridW;
                    int gh = activeItem.gridH;
                    if (_draggingRotation % 2 != 0) {
                      gw = activeItem.gridH;
                      gh = activeItem.gridW;
                    }
                    final centeredCell = (
                      (finalCell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
                      (finalCell.$2 - (gh / 2).floor()).clamp(0, kGridCols - gh),
                    );
                    if (centeredCell != _ghostCell) {
                      setState(() {
                        _ghostCell = centeredCell;
                        _isInteracting = true;
                      });
                    }
                  }
                }
              },
              onAccept: (item) {
                setState(() => _isInteracting = false);
                if (_ghostCell != null && item.quantity > 0) {
                  if (!_isAreaAvailable(item, _ghostCell!.$1, _ghostCell!.$2, _draggingRotation, converter, z: _ghostZ)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该区域无法放置家具'), duration: Duration(seconds: 1)));
                    setState(() { _ghostCell = null; _draggingItem = null; });
                    return;
                  }
                  setState(() {
                    _placedFurniture.add(PlacedFurniture(
                      item: item,
                      r: _ghostCell!.$1,
                      c: _ghostCell!.$2,
                      z: _ghostZ,
                      rotation: _draggingRotation,
                    ));
                    item.quantity--;
                    _ghostCell = null;
                    _draggingItem = null;
                  });
                  UserState().savePlacedFurniture(_placedFurniture);
                }
              },
              onLeave: (_) => setState(() => _ghostCell = null),
              builder: (context, _, __) => const SizedBox.shrink(),
            ),
          ),

          // 3. 全屏手势交互层
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // 单点：彻底清除当前所有选中状态，让场景回归纯净态
                setState(() {
                  _selectedFurniture = null;
                  _selectedCell = null;
                });
              },
              onLongPressStart: (details) {
                // 长按：作为“编辑意图”的唯一激活口，弹出黄色选中框、工具栏或蓝色引导框
                if (_draggingItem != null) return;
                _handleTap(details.globalPosition, converter);
              },
              onScaleStart: (details) {
                if (_draggingItem != null) return;
                _zoomAnimationController?.stop();
                setState(() {
                  _baseScale = _currentScale;
                  _lastFocalPoint = details.focalPoint;
                  _isInteracting = true;
                });
              },
              onScaleUpdate: (details) {
                if (_draggingItem != null) return;
                setState(() {
                  _currentScale = (_baseScale * details.scale).clamp(0.4, 3.5);
                  final Offset d = details.focalPoint - _lastFocalPoint;
                  _sceneOffset += d;
                  _lastFocalPoint = details.focalPoint;
                  _isInteracting = true;
                });
              },
              onScaleEnd: (details) => setState(() => _isInteracting = false),
            ),
          ),

          // 4. 装修交互 UI 层：位于手势层之上，防止工具栏操作被误认为点击网格
          if (_selectedFurniture != null)
            IgnorePointer(
              ignoring: false,
              child: Container(
                alignment: Alignment.center,
                width: screenW,
                height: screenH,
                child: Transform.translate(
                  offset: _sceneOffset,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FurnitureDragOverlay(
                          pf: _selectedFurniture!,
                          converter: converter,
                          onDragStarted: (item, rot, cell) {
                            setState(() {
                              _draggingItem = item;
                              _draggingRotation = rot;
                              _ghostCell = cell;
                              _ghostZ = _selectedFurniture?.z ?? 0.0;
                              item.quantity++;
                              _placedFurniture.remove(_selectedFurniture!);
                              _selectedFurniture = null;
                            });
                          },
                          onDragCanceled: () => setState(() { 
                            _ghostCell = null; 
                            _draggingItem = null; 
                          }),
                        ),
                        DecorationToolbar(
                          pf: _selectedFurniture!,
                          converter: converter,
                          onRotate: () {
                            final pf = _selectedFurniture!;
                            final nextRotation = (pf.rotation + 1) % 4;
                            if (_isAreaAvailable(pf.item, pf.r, pf.c, nextRotation, converter, exclude: pf)) {
                              setState(() => pf.rotation = nextRotation);
                              UserState().savePlacedFurniture(_placedFurniture);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该方向位置冲突，无法旋转'), duration: Duration(seconds: 1)));
                            }
                          },
                          onDelete: () {
                            setState(() {
                              _placedFurniture.remove(_selectedFurniture!);
                              _selectedFurniture!.item.quantity++;
                              _selectedFurniture = null;
                            });
                            UserState().savePlacedFurniture(_placedFurniture);
                          },
                          onFillAll: () => _handleFillAll(_selectedFurniture!.item),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. 静态 UI 层
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            top: 20,
            bottom: 20,
            right: _isTrayExpanded ? 0 : -295,
            child: Row(
              children: [
                _buildTrayToggle(),
                FurnitureInventoryTray(
                  availableItems: _availableItems,
                  selectedCategory: _selectedCategory,
                  selectedSubCategory: _selectedSubCategory,
                  onCategoryChanged: (cat) => setState(() {
                    _selectedCategory = cat;
                    _selectedSubCategory = null;
                  }),
                  onSubCategoryChanged: (sub) => setState(() => _selectedSubCategory = sub),
                  onDragStarted: (item) => setState(() {
                    _draggingItem = item;
                    _draggingRotation = 0;
                    _ghostZ = 0.0;
                  }),
                  onDragEnd: () => setState(() {
                    _draggingItem = null;
                    _ghostCell = null;
                  }),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () async {
                        final bytes = await _captureSnapshot();
                        await UserState().setDecorationSnapshot(bytes);
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off, color: Colors.white70),
                      onPressed: () => setState(() => _showGrid = !_showGrid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 24),
                      onPressed: _handleClearAll,
                      tooltip: '一键清除',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () => _handleZoom(0.2), tooltip: '放大'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${(_currentScale * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 8, endIndent: 8),
                      IconButton(icon: const Icon(Icons.remove, color: Colors.white70), onPressed: () => _handleZoom(-0.2), tooltip: '缩小'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleZoom(double delta) {
    if (_zoomAnimationController == null) return;
    
    _zoomStartScale = _currentScale;
    _zoomEndScale = (_zoomStartScale + delta).clamp(0.4, 2.5);
    
    if ((_zoomEndScale - _zoomStartScale).abs() < 0.01) return;

    _zoomAnimationController!.forward(from: 0);
  }

  Future<Uint8List?> _captureSnapshot() async {
    try {
      setState(() {
        _isCapturingSnapshot = true;
        _selectedFurniture = null; // 确保没有工具栏或高亮选中
      });
      // 给一点时间让 UI 渲染隐藏网格后的样子
      await Future.delayed(const Duration(milliseconds: 50));

      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isCapturingSnapshot = false);
        return null;
      }

      // 捕获为图像，降低像素比以减小体积（背景不需要超高分辨率）
      final ui.Image image = await boundary.toImage(pixelRatio: 0.8);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      setState(() => _isCapturingSnapshot = false);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing snapshot: $e');
      setState(() => _isCapturingSnapshot = false);
      return null;
    }
  }



  Widget _buildTrayToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isTrayExpanded = !_isTrayExpanded),
      child: Container(
        width: 32,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(
          _isTrayExpanded ? Icons.chevron_right : Icons.chevron_left,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }


  void _handleTap(Offset globalPos, IsometricCoordinateConverter converter) {
    setState(() {
      final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final localPos = box.globalToLocal(globalPos);

      final foregroundOrderItems = List<PlacedFurniture>.from(_placedFurniture)
        ..sort((a, b) {
          // 1. 分类权重优先：非地板类物品始终在检测列表前部 (优先检测)
          final bool isFloorA = a.item.category == '地板';
          final bool isFloorB = b.item.category == '地板';
          if (isFloorA != isFloorB) {
            return isFloorA ? 1 : -1;
          }

          int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
          int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
          
          int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
          int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;

          // B vs A to sort descending (front-most first)
          if (b.r + gwB <= a.r || b.c + ghB <= a.c) return -1;
          if (a.r + gwA <= b.r || a.c + ghA <= b.c) return 1;

          final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0;
          final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0;
          
          final cmp = depthB.compareTo(depthA);
          if (cmp == 0) {
            // Ensure higher Z items are checked before lower Z items
            return b.z.compareTo(a.z);
          }
          return cmp;
        });

      PlacedFurniture? visualHit;
      for (var pf in foregroundOrderItems) {
        if (pf.item.isWall) {
          final double h = pf.item.gridH.toDouble();
          final double l = pf.item.gridW.toDouble();
          final double baseZ = pf.z;
          List<Offset> wallPoints;
          if (pf.rotation % 2 == 0) {
            // XZ 平面 (左墙方向)
            wallPoints = [
              converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ + h),
              converter.getScreenPoint(pf.r + l, pf.c.toDouble(), baseZ + h),
              converter.getScreenPoint(pf.r + l, pf.c.toDouble(), baseZ),
              converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ),
            ];
          } else {
            // YZ 平面 (右墙方向)
            wallPoints = [
              converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ + h),
              converter.getScreenPoint(pf.r.toDouble(), pf.c + l, baseZ + h),
              converter.getScreenPoint(pf.r.toDouble(), pf.c + l, baseZ),
              converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ),
            ];
          }
          final path = Path()..addPolygon(wallPoints, true);
          if (path.contains(localPos)) {
            visualHit = pf;
            break;
          }
        } else {
          int gw = pf.item.gridW;
          int gh = pf.item.gridH;
          if (pf.rotation % 2 != 0) {
            gw = pf.item.gridH;
            gh = pf.item.gridW;
          }

          final bool isBack = (pf.rotation == 1 || pf.rotation == 2);
          final double vScale = isBack ? (pf.item.backVisualScale ?? pf.item.visualScale) : pf.item.visualScale;
          final Offset vOffset = isBack ? (pf.item.backVisualOffset ?? pf.item.visualOffset) : pf.item.visualOffset;

          final rect = converter.getFurnitureRect(
            r: pf.r,
            c: pf.c,
            gw: gw,
            gh: gh,
            visualScale: vScale,
            visualOffset: vOffset,
            intrinsicWidth: pf.item.intrinsicWidth,
            intrinsicHeight: pf.item.intrinsicHeight,
            z: pf.z,
          );

          final coreRect = Rect.fromCenter(
            center: rect.center,
            width: rect.width * 0.7, 
            height: rect.height,
          );
          if (coreRect.contains(localPos)) {
            visualHit = pf;
            break;
          }
        }
      }

      if (visualHit == null) {
        for (var pf in foregroundOrderItems) {
          if (pf.item.isWall) {
            // Wall hits are fully resolved in the first pass
            continue;
          }

          int gw = pf.item.gridW;
          int gh = pf.item.gridH;
          if (pf.rotation % 2 != 0) {
            gw = pf.item.gridH;
            gh = pf.item.gridW;
          }

          final bool isBack = (pf.rotation == 1 || pf.rotation == 2);
          final double vScale = isBack ? (pf.item.backVisualScale ?? pf.item.visualScale) : pf.item.visualScale;
          final Offset vOffset = isBack ? (pf.item.backVisualOffset ?? pf.item.visualOffset) : pf.item.visualOffset;

          final rect = converter.getFurnitureRect(
            r: pf.r,
            c: pf.c,
            gw: gw,
            gh: gh,
            visualScale: vScale,
            visualOffset: vOffset,
            intrinsicWidth: pf.item.intrinsicWidth,
            intrinsicHeight: pf.item.intrinsicHeight,
            z: pf.z,
          );
          if (rect.contains(localPos)) {
            visualHit = pf;
            break;
          }
        }
      }

      if (visualHit != null) {
        _selectedFurniture = visualHit;
        _selectedCell = null;
        return;
      }

      // 2. 如果视觉测试未中，尝试精确的网格地板测试
      var cell = converter.getGridCell(localPos);
      if (cell != null && isCellExcluded(cell.$1, cell.$2)) cell = null;

      if (cell != null) {
        final finalCell = cell;
        // 查找该格子是否属于某个家具的基础占位
        final clickedFurniture = _placedFurniture
            .cast<PlacedFurniture?>()
            .firstWhere((pf) {
              if (pf == null) return false;
              int gw = pf.item.gridW;
              int gh = pf.item.gridH;
              if (pf.rotation % 2 != 0) {
                gw = pf.item.gridH;
                gh = pf.item.gridW;
              }
              return finalCell.$1 >= pf.r &&
                  finalCell.$1 < pf.r + gw &&
                  finalCell.$2 >= pf.c &&
                  finalCell.$2 < pf.c + gh;
            }, orElse: () => null);

        if (clickedFurniture != null) {
          _selectedFurniture = clickedFurniture;
          _selectedCell = null;
        } else {
          _selectedFurniture = null;
          _selectedCell = cell;
        }
      } else {
        _selectedFurniture = null;
        _selectedCell = null;
      }
    });
  }

  void _handleFillAll(FurnitureItem item) {
    setState(() {
      // 1. 将所有现有的地板归还库存
      for (var pf in _placedFurniture.where((pf) => pf.item.isFloor)) {
        pf.item.quantity++;
      }
      // 2. 移除所有地板
      _placedFurniture.removeWhere((pf) => pf.item.isFloor);

      // 3. 计算铺满需要的行列数 (基于 24x24 网格和地板自身的 gridW/gridH)
      final int rows = (kGridRows / item.gridW).ceil();
      final int cols = (kGridCols / item.gridH).ceil();

      // 4. 批量添加
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          if (item.quantity > 0) {
            final int r = i * item.gridW;
            final int c = j * item.gridH;
            
            _placedFurniture.add(PlacedFurniture(
              item: item,
              r: r,
              c: c,
              rotation: 0,
            ));
            item.quantity--;
          }
        }
      }
      _selectedFurniture = null;
    });
    UserState().savePlacedFurniture(_placedFurniture);
  }

  void _handleClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('一键清除', style: TextStyle(color: Colors.white)),
        content: const Text('确定要清除房间内所有已摆放的家具吗？此操作不可撤销。', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // 归还库存
                for (var pf in _placedFurniture) {
                  pf.item.quantity++;
                }
                _placedFurniture.clear();
                _selectedFurniture = null;
                _selectedCell = null;
              });
              UserState().savePlacedFurniture(_placedFurniture);
              Navigator.pop(ctx);
            },
            child: const Text('确定清除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  bool _isAreaAvailable(
    FurnitureItem item,
    int r,
    int c,
    int rotation,
    IsometricCoordinateConverter converter, {
    PlacedFurniture? exclude,
    double z = 0.0,
  }) {
    bool isWall = item.isWall;
    int gw = item.gridW;
    int gh = isWall ? 1 : item.gridH; 
    
    if (rotation % 2 != 0) {
      if (isWall) {
        gw = 1; gh = item.gridW;
      } else {
        gw = item.gridH; gh = item.gridW;
      }
    }

    if (r < 0 || c < 0 || r + gw > kGridRows || c + gh > kGridCols)
      return false;

    if (isWall) {
      if (z + item.gridH > kWallGridHeight) {
        return false; // 上端超出墙壁高度
      }
    }

    // 2. 检查屏蔽区域
    for (int i = r; i < r + gw; i++) {
      for (int j = c; j < c + gh; j++) {
        if (isCellExcluded(i, j)) return false;
      }
    }

    // 3. 检查与其他家具冲突
    bool isFloor = item.isFloor;

    for (final pf in _placedFurniture) {
      if (pf == exclude) continue;
      
      bool otherIsFloor = pf.item.isFloor;
      if (isFloor != otherIsFloor) continue;

      bool otherIsWall = pf.item.isWall;
      if (isWall != otherIsWall) continue; 

      int pgw = pf.item.gridW;
      int pgh = otherIsWall ? 1 : pf.item.gridH;
      if (pf.rotation % 2 != 0) {
        if (otherIsWall) {
          pgw = 1; pgh = pf.item.gridW;
        } else {
          pgw = pf.item.gridH; pgh = pf.item.gridW;
        }
      }

      // 高度冲突判定 (判断两个在 Z 轴上的线段是否有重叠，而非仅仅起点接近)
      // 物品1的范围：[z, z + item.gridH]
      // 物品2的范围：[pf.z, pf.z + pf.item.gridH]
      // 重叠条件：max(起始) < min(结束)
      double z1End = z + item.gridH;
      double z2End = pf.z + (otherIsWall ? pf.item.gridH : 1); 
      // 对于地面物品，厚度假设为1
      
      bool heightConflict = false;
      if (item.gridH > 0) { // 避免计算异常情况
        heightConflict = (z < z2End) && (pf.z < z1End);
      } else {
        heightConflict = (z - pf.z).abs() < 1.0; 
      }

      if (r < pf.r + pgw && r + gw > pf.r && c < pf.c + pgh && c + gh > pf.c && heightConflict) {
        return false;
      }
    }

    return true;
  }

  double _getGridCenterYFactor(BuildContext context) {
    // 假设最短边 >= 600 为平板/iPad
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return isTablet ? kGridCenterYFactorIPad : kGridCenterYFactorPhone;
  }
}
