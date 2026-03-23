import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:island_diary/core/state/user_state.dart';
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../../data/furniture_data.dart';
import '../widgets/furniture_sprite.dart';
import '../widgets/isometric_grid_painter.dart';
import 'decoration_page_constants.dart';

class DecorationPage extends StatefulWidget {
  const DecorationPage({super.key});

  @override
  State<DecorationPage> createState() => _DecorationPageState();
}

class _DecorationPageState extends State<DecorationPage> {
  (int, int)? _selectedCell;
  (int, int)? _ghostCell;
  FurnitureItem? _draggingItem; // 显式记录正在拖动的物品，解决 DragTarget 延迟问题
  int _draggingRotation = 0;
  PlacedFurniture? _selectedFurniture;
  final List<PlacedFurniture> _placedFurniture = [];
  late List<FurnitureItem> _availableItems;
  
  String _selectedCategory = '厨房';
  String? _selectedSubCategory;

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey(); // 用于截屏的 Key

  bool _isTrayExpanded = true;
  bool _isCapturingSnapshot = false; // 是否正在捕获快照
  double _sceneOffsetX = 0; // 手动记录平移偏移量

  ui.Image? _bgImage;

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

    _sceneOffsetX = -120; // 默认向左偏移，避免被右侧物品栏遮挡
  }

  @override
  void dispose() {
    // 恢复竖屏和普通 UI 模式
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _resolveImageSize() {
    const path = 'assets/images/decoration/furniture/house.png';
    const image = AssetImage(path);
    image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(() {
                _bgImage = info.image;
              });
            }
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_bgImage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    final double imgW = _bgImage!.width.toDouble();
    final double imgH = _bgImage!.height.toDouble();

    double scale = screenH / imgH;
    final double fullWidth = imgW * scale;

    if (fullWidth < screenW) {
      scale = screenW / imgW;
    }

    final double w = imgW * scale * kSceneScaleFactor;
    final double h = imgH * scale * kSceneScaleFactor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            width: screenW,
            height: screenH,
            child: RepaintBoundary(
              key: _repaintKey,
              child: Transform.translate(
                offset: Offset(_sceneOffsetX, 0),
                child: SizedBox(
                  key: _gridKey,
                  width: w,
                  height: h,
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/decoration/furniture/house.png',
                        fit: BoxFit.cover,
                        width: w,
                        height: h,
                      ),
                      Positioned.fill(
                      child: DragTarget<FurnitureItem>(
                        onMove: (details) {
                          final RenderBox? box =
                              _gridKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box == null) return;

                          // 统一使用 globalToLocal 获取相对于网格画布的本地坐标
                          final localPos = box.globalToLocal(details.offset);

                          // 使用 DragAnchor.pointer 后，localPos 已经是手指位置
                          // 我们只需要一个极小的偏移（如 10 像素）来确保手指不完全挡住选中框中心点即可，甚至可以为 0
                          final correctedPos = Offset(
                            localPos.dx,
                            localPos.dy + 10,
                          );

                          final cell = _hitTestGrid(correctedPos, w, h);
                          if (cell != _ghostCell) {
                            setState(() {
                              _ghostCell = cell;
                            });
                          }
                        },
                        onAccept: (item) {
                          if (_ghostCell != null && item.quantity > 0) {
                            if (!_isAreaAvailable(
                              item,
                              _ghostCell!.$1,
                              _ghostCell!.$2,
                              _draggingRotation,
                            )) {
                              setState(() {
                                _ghostCell = null;
                                _draggingItem = null;
                              });
                              return;
                            }
                            setState(() {
                              _placedFurniture.add(
                                PlacedFurniture(
                                  item: item,
                                  r: _ghostCell!.$1,
                                  c: _ghostCell!.$2,
                                  rotation: _draggingRotation, // 使用记录的旋转角度
                                ),
                              );
                              item.quantity--;
                              _ghostCell = null;
                              _draggingItem = null;
                            });
                            UserState().savePlacedFurniture(_placedFurniture);
                          }
                        },
                        onLeave: (data) => setState(() {
                          _ghostCell = null;
                        }),
                        builder: (context, candidateData, rejectedData) {
                          // 优先使用显式记录的拖拽物品，确保起始瞬间不掉帧
                          final activeItem =
                              _draggingItem ??
                              (candidateData.isNotEmpty
                                  ? candidateData.first
                                  : null);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) =>
                                _handleTap(details.localPosition, w, h),
                            onPanUpdate: (details) {
                              if (activeItem != null) return;
                              setState(() {
                                _sceneOffsetX += details.delta.dx;
                              });
                            },
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
                                ghostItem: activeItem != null
                                    ? (
                                        activeItem,
                                        _ghostCell,
                                        _draggingRotation,
                                        _ghostCell == null ||
                                            _isAreaAvailable(
                                              activeItem,
                                              _ghostCell!.$1,
                                              _ghostCell!.$2,
                                              _draggingRotation,
                                            ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedFurniture != null) ...[
                      _buildDragOverlay(w, h),
                      _buildToolbar(w, h),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            top: 20,
            bottom: 20,
            right: _isTrayExpanded ? 0 : -295,
            child: Row(
              children: [
                _buildTrayToggle(),
                _buildFurnitureTray(),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () async {
                // 在退出前捕获快照
                final bytes = await _captureSnapshot();
                await UserState().setDecorationSnapshot(bytes);
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
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

  Widget _buildDragOverlay(double w, double h) {
    final pf = _selectedFurniture!;
    final centerX = w / 2;
    final centerY = h * _getGridCenterYFactor(context);

    int gw = pf.item.gridW;
    int gh = pf.item.gridH;
    if (pf.rotation % 2 != 0) {
      gw = pf.item.gridH;
      gh = pf.item.gridW;
    }

    final pt = _getScreenPoint(
      pf.r + gw / 2.0,
      pf.c + gh / 2.0,
      centerX,
      centerY,
      w / 22,
      w / 44,
    );

    // 估算家具在屏幕上的大致大小
    // 为了简单起见，我们使用 _getScreenPoint 逻辑中的 scale
    final double u = (pf.r + gw / 2.0) / kGridRows;
    final double v = (pf.c + gh / 2.0) / kGridCols;
    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    final double itemW = (w / 22) * gw * scale * 0.8;
    final double spriteH =
        itemW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
    final double overlayH = spriteH + 60; // 稍微多一点区域以便点击到顶部

    return Positioned(
      left: pt.dx - itemW / 2,
      top: pt.dy - overlayH + (gw * w / 88) * scale + 40,
      width: itemW,
      height: overlayH,
      child: LongPressDraggable<FurnitureItem>(
        delay: const Duration(milliseconds: 300), // 更短的延迟，更灵敏
        hapticFeedbackOnStart: true,
        dragAnchorStrategy: pointerDragAnchorStrategy, // 确保 details.offset 指向手指
        data: pf.item,
        feedback: const SizedBox.shrink(),
        onDragStarted: () {
          setState(() {
            _draggingItem = pf.item; // 记录正在拖动的物品
            _draggingRotation = pf.rotation;
            _ghostCell = (pf.r, pf.c);
            pf.item.quantity++;
            _placedFurniture.remove(pf);
            _selectedFurniture = null;
          });
        },
        onDraggableCanceled: (velocity, offset) {
          // 如果拖拽取消，将物品放回原处
          setState(() {
            _placedFurniture.add(pf);
            pf.item.quantity--;
            _ghostCell = null;
            _draggingItem = null;
          });
        },
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildToolbar(double w, double h) {
    // 简单的工具栏实现，定位逻辑后续优化
    final pf = _selectedFurniture!;
    final centerX = w / 2;
    final centerY = h * _getGridCenterYFactor(context);

    int gw = pf.item.gridW;
    int gh = pf.item.gridH;
    if (pf.rotation % 2 != 0) {
      gw = pf.item.gridH;
      gh = pf.item.gridW;
    }

    final pt = _getScreenPoint(
      pf.r + gw / 2.0,
      pf.c + gh / 2.0,
      centerX,
      centerY,
      w / 22,
      w / 44,
    );

    // 将工具栏放在物品的最上方，避免遮挡长按热区
    final double u = (pf.r + gw / 2.0) / kGridRows;
    final double v = (pf.c + gh / 2.0) / kGridCols;
    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;
    final double itemW = (w / 22) * gw * scale * 0.8;
    final double itemH =
        itemW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);

    return Positioned(
      left: pt.dx - 50,
      top: pt.dy - itemH + (gw * w / 88) * scale - 70, // 向上移动工具栏，避免遮挡家具顶部
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.rotate_right,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                final nextRotation = (pf.rotation + 1) % 4;
                if (_isAreaAvailable(
                  pf.item,
                  pf.r,
                  pf.c,
                  nextRotation,
                  exclude: pf,
                )) {
                  setState(() {
                    pf.rotation = nextRotation;
                  });
                  UserState().savePlacedFurniture(_placedFurniture);
                } else {
                  // 可选：显示提示或震动反馈
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('该方向位置冲突，无法旋转'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _placedFurniture.remove(pf);
                  pf.item.quantity++;
                  _selectedFurniture = null;
                });
                UserState().savePlacedFurniture(_placedFurniture);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 辅助函数：计算网格坐标对应的屏幕像素坐标 (用于工具栏投影)
  Offset _getScreenPoint(
    double i,
    double j,
    double cx,
    double cy,
    double tw,
    double th,
  ) {
    final double u = i / kGridRows;
    final double v = j / kGridCols;
    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    final double x = (i - j) * (tw / 2) * scale;
    final double y = (i + j - (kGridRows + kGridCols) / 2) * (th / 2) * scale;

    // 考虑网格本身的旋转 (kGridRotationDegree)
    final double rad = kGridRotationDegree * math.pi / 180;
    final double rotatedX = x * math.cos(rad) - y * math.sin(rad);
    final double rotatedY = x * math.sin(rad) + y * math.cos(rad);

    return Offset(cx + rotatedX, cy + rotatedY);
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

  Widget _buildFurnitureTray() {
    final categories =
        defaultFurnitureItems.map((e) => e.category).toSet().toList();
    final subCategories = defaultFurnitureItems
        .where((e) => e.category == _selectedCategory)
        .map((e) => e.subCategory)
        .toSet()
        .toList();

    final filteredItems = _availableItems.where((item) {
      bool matchCat = item.category == _selectedCategory;
      bool matchSub =
          _selectedSubCategory == null || item.subCategory == _selectedSubCategory;
      return matchCat && matchSub;
    }).toList();

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(-10, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Row(
          children: [
            // 一级分类侧边栏
            Container(
              width: 65,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                border: Border(right: BorderSide(color: Colors.white10)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      _selectedSubCategory = null;
                    }),
                    child: Container(
                      height: 70,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? const Border(
                                right:
                                    BorderSide(color: Colors.blueAccent, width: 3),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(cat),
                            color: isSelected ? Colors.blueAccent : Colors.white24,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white30,
                              fontSize: 10,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 右侧内容区
            Expanded(
              child: Column(
                children: [
                  // 二级分类选择器
                  if (subCategories.length > 1)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: subCategories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final subCat = isAll ? '全部' : subCategories[index - 1];
                          final isSelected = isAll
                              ? _selectedSubCategory == null
                              : subCat == _selectedSubCategory;

                          return Center(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedSubCategory = isAll ? null : subCat;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blueAccent.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blueAccent.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Text(
                                  subCat,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        isSelected ? Colors.white : Colors.white38,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  // 物品网格
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildFurnitureCard(filteredItems[index]);
                      },
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '厨房':
        return Icons.kitchen;
      case '卧室':
        return Icons.bed;
      case '客厅':
        return Icons.chair;
      case '装饰':
        return Icons.palette;
      default:
        return Icons.category;
    }
  }

  Widget _buildFurnitureCard(FurnitureItem item) {
    final bool isOutOfStock = item.quantity <= 0;
    return Draggable<FurnitureItem>(
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => setState(() {
        _draggingItem = item;
        _draggingRotation = 0;
      }),
      data: item,
      maxSimultaneousDrags: isOutOfStock ? 0 : 1,
      feedback: const SizedBox.shrink(),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCardContent(item)),
      child: Opacity(
        opacity: isOutOfStock ? 0.4 : 1.0,
        child: _buildCardContent(item),
      ),
    );
  }

  Widget _buildCardContent(FurnitureItem item) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AspectRatio(
                    aspectRatio: item.intrinsicWidth / item.intrinsicHeight,
                    child: FurnitureSprite(item: item),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.quantity > 0 ? Colors.blueAccent : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _handleTap(Offset localPos, double fullWidth, double fullHeight) {
    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * _getGridCenterYFactor(context);

    setState(() {
      // 1. 优先进行视觉区域命中测试 (从前到后遍历家具)
      // 在等距投影中，Row + Col 越大的家具在视觉上越靠前
      final foregroundOrderItems = List<PlacedFurniture>.from(_placedFurniture)
        ..sort((a, b) => (b.r + b.c).compareTo(a.r + a.c));

      PlacedFurniture? visualHit;
      for (var pf in foregroundOrderItems) {
        final rect = _getFurnitureRect(
          pf,
          fullWidth,
          fullHeight,
          centerX,
          centerY,
        );
        if (rect.contains(localPos)) {
          visualHit = pf;
          break;
        }
      }

      if (visualHit != null) {
        _selectedFurniture = visualHit;
        _selectedCell = null;
        return;
      }

      // 2. 如果视觉测试未中，尝试精确的网格地板测试
      final cell = _hitTestGrid(localPos, fullWidth, fullHeight);
      if (cell != null) {
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
              return cell.$1 >= pf.r &&
                  cell.$1 < pf.r + gw &&
                  cell.$2 >= pf.c &&
                  cell.$2 < pf.c + gh;
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

  // 辅助函数：计算家具在屏幕上的视觉矩形 (逻辑与 IsometricGridPainter._drawFurniture 保持同步)
  Rect _getFurnitureRect(
    PlacedFurniture pf,
    double w,
    double h,
    double centerX,
    double centerY,
  ) {
    int gw = pf.item.gridW;
    int gh = pf.item.gridH;
    if (pf.rotation % 2 != 0) {
      gw = pf.item.gridH;
      gh = pf.item.gridW;
    }

    final pt = _getScreenPoint(
      pf.r + gw / 2.0,
      pf.c + gh / 2.0,
      centerX,
      centerY,
      w / 22,
      w / 44,
    );

    final double u = (pf.r + gw / 2.0) / kGridRows;
    final double v = (pf.c + gh / 2.0) / kGridCols;
    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    final double itemW = (w / 22) * gw * scale * 0.8;
    final double spriteH =
        itemW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);

    return Rect.fromLTWH(
      pt.dx - itemW / 2,
      pt.dy - spriteH + (gw * w / 88) * scale,
      itemW,
      spriteH,
    );
  }

  (int, int)? _hitTestGrid(Offset localPos, double w, double h) {
    final double centerX = w / 2;
    final double centerY = h * _getGridCenterYFactor(context);

    (int, int)? bestCell;
    double minDistanceSq = double.infinity;

    // 遍历所有格子，找到中心点距离点击位置最近的格子
    // 对于 20x20 的小网格，这种暴力搜索在性能上完全可以接受且最为准确
    // 这种方法天然适配任何复杂的 Taper (变形) 逻辑，无需复杂的数学逆变换
    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kGridCols; c++) {
        final pt = _getScreenPoint(
          r + 0.5,
          c + 0.5,
          centerX,
          centerY,
          w / 22,
          w / 44,
        );

        final double dx = localPos.dx - pt.dx;
        final double dy = localPos.dy - pt.dy;
        final double distSq = dx * dx + dy * dy;

        if (distSq < minDistanceSq) {
          minDistanceSq = distSq;
          bestCell = (r, c);
        }
      }
    }

    // 容错范围：如果距离最近的格子中心超过 100 像素（在 w=2000 的场景下），说明点在外面
    if (minDistanceSq > 150 * 150) return null;

    if (bestCell != null && isCellExcluded(bestCell.$1, bestCell.$2))
      return null;

    return bestCell;
  }

  bool _isAreaAvailable(
    FurnitureItem item,
    int r,
    int c,
    int rotation, {
    PlacedFurniture? exclude,
  }) {
    int gw = item.gridW;
    int gh = item.gridH;
    if (rotation % 2 != 0) {
      gw = item.gridH;
      gh = item.gridW;
    }

    // 1. 检查边界
    if (r < 0 || c < 0 || r + gw > kGridRows || c + gh > kGridCols)
      return false;

    // 2. 检查屏蔽区域
    for (int i = r; i < r + gw; i++) {
      for (int j = c; j < c + gh; j++) {
        if (isCellExcluded(i, j)) return false;
      }
    }

    // 3. 检查与其他家具冲突
    for (final pf in _placedFurniture) {
      if (pf == exclude) continue;

      int pgw = pf.item.gridW;
      int pgh = pf.item.gridH;
      if (pf.rotation % 2 != 0) {
        pgw = pf.item.gridH;
        pgh = pf.item.gridW;
      }

      // 矩形重叠检测
      if (r < pf.r + pgw && r + gw > pf.r && c < pf.c + pgh && c + gh > pf.c) {
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
