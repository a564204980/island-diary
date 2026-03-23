import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
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
  PlacedFurniture? _selectedFurniture;
  final List<PlacedFurniture> _placedFurniture = [];
  final List<FurnitureItem> _availableItems = List.from(defaultFurnitureItems);
  final GlobalKey _gridKey = GlobalKey();

  ui.Image? _bgImage;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  void _resolveImageSize() {
    const path = 'assets/images/decoration/furniture/house.png';
    const image = AssetImage(path);
    image.resolve(const ImageConfiguration()).addListener(
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              alignment: Alignment.center,
              width: math.max(w, screenW),
              height: math.max(h, screenH),
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
                          final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          
                          // 统一使用 globalToLocal 获取相对于网格画布的本地坐标
                          final localPos = box.globalToLocal(details.offset);
                          
                          // 使用 DragAnchor.pointer 后，localPos 已经是手指位置
                          // 我们只需要一个极小的偏移（如 10 像素）来确保手指不完全挡住选中框中心点即可，甚至可以为 0
                          final correctedPos = Offset(localPos.dx, localPos.dy + 10); 
                          
                          final cell = _hitTestGrid(correctedPos, w, h);
                          if (cell != _ghostCell) {
                            setState(() {
                              _ghostCell = cell;
                            });
                          }
                        },
                        onAccept: (item) {
                          if (_ghostCell != null && item.quantity > 0) {
                            setState(() {
                              _placedFurniture.add(
                                PlacedFurniture(
                                  item: item,
                                  r: _ghostCell!.$1,
                                  c: _ghostCell!.$2,
                                ),
                              );
                              item.quantity--;
                              _ghostCell = null;
                            });
                          }
                        },
                        onLeave: (data) => setState(() => _ghostCell = null),
                        builder: (context, candidateData, rejectedData) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) => _handleTap(details.localPosition, w, h), // localPosition 已经是本地的
                            child: CustomPaint(
                              painter: IsometricGridPainter(
                                rows: kGridRows,
                                cols: kGridCols,
                                fullWidth: w,
                                fullHeight: h,
                                selectedCell: _selectedCell,
                                placedItems: _placedFurniture,
                                selectedFurniture: _selectedFurniture,
                                ghostItem: candidateData.isNotEmpty
                                    ? (candidateData.first!, _ghostCell)
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFurnitureTray(),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragOverlay(double w, double h) {
    final pf = _selectedFurniture!;
    final centerX = w / 2;
    final centerY = h * kGridCenterYFactor;

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
    final double scale = 1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    final double itemW = (w / 22) * gw * scale;
    final double spriteH = itemW * (1072 / 605);
    final double overlayH = spriteH + 60; // 稍微多一点区域以便点击到顶部

    return Positioned(
      left: pt.dx - itemW / 2,
      top: pt.dy - overlayH + 40,
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
            pf.item.quantity++;
            _placedFurniture.remove(pf);
            _selectedFurniture = null;
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
    final centerY = h * kGridCenterYFactor;
    
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
    final double scale = 1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;
    final double itemW = (w / 22) * gw * scale;
    final double itemH = itemW * (1072 / 605) + (gw * w / 44) * scale;

    return Positioned(
      left: pt.dx - 50,
      top: pt.dy - itemH - 20, // 物品顶部再往上一点
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
              icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  pf.rotation = (pf.rotation + 1) % 4;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () {
                setState(() {
                  _placedFurniture.remove(pf);
                  pf.item.quantity++;
                  _selectedFurniture = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // 辅助函数：计算网格坐标对应的屏幕像素坐标 (用于工具栏投影)
  Offset _getScreenPoint(double i, double j, double cx, double cy, double tw, double th) {
    final double u = i / kGridRows;
    final double v = j / kGridCols;
    final double scale = 1.0 +
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

  Widget _buildFurnitureTray() {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final item = _availableItems[index];
          return _buildFurnitureCard(item);
        },
      ),
    );
  }

  Widget _buildFurnitureCard(FurnitureItem item) {
    final bool isOutOfStock = item.quantity <= 0;
    return Draggable<FurnitureItem>(
      dragAnchorStrategy: pointerDragAnchorStrategy, // 确保 details.offset 指向手指
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
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
                    )
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

  void _handleTap(Offset localPos, double fullWidth, double h) {
    final cell = _hitTestGrid(localPos, fullWidth, h);
    setState(() {
      if (cell != null) {
        // 查找是否点击了家具
        final clickedFurniture = _placedFurniture.cast<PlacedFurniture?>().firstWhere(
          (pf) {
            if (pf == null) return false;
            // 简单判定：点击坐标是否在家具占用的矩形范围内
            // 考虑旋转后的 gridW/gridH
            int gw = pf.item.gridW;
            int gh = pf.item.gridH;
            if (pf.rotation % 2 != 0) {
              gw = pf.item.gridH;
              gh = pf.item.gridW;
            }
            return cell.$1 >= pf.r && cell.$1 < pf.r + gw && 
                   cell.$2 >= pf.c && cell.$2 < pf.c + gh;
          },
          orElse: () => null,
        );

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

  (int, int)? _hitTestGrid(Offset localPos, double w, double h) {
    final double centerX = w / 2;
    final double centerY = h * kGridCenterYFactor;
    
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

    if (bestCell != null && isCellExcluded(bestCell.$1, bestCell.$2)) return null;

    return bestCell;
  }
}
