import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../pages/decoration_page_constants.dart';
import '../../data/furniture_data.dart';
import '../widgets/furniture_sprite.dart';

class DecorationController extends ChangeNotifier {
  // --- 核心家具数据 ---
  final List<PlacedFurniture> _placedFurniture = [];
  List<PlacedFurniture> get placedFurniture => List.unmodifiable(_placedFurniture);
  
  late List<FurnitureItem> _availableItems;
  List<FurnitureItem> get availableItems => _availableItems;

  String selectedCategory = '厨房';
  String? selectedSubCategory;

  // --- 交互与选择状态 ---
  (int, int)? selectedCell;
  (int, int)? ghostCell;
  FurnitureItem? draggingItem; 
  int draggingRotation = 0;
  double ghostZ = 0.0; 
  PlacedFurniture? selectedFurniture;
  
  // 连贯拖拽相关
  bool isLongPressDragging = false;
  PlacedFurniture? originalFurnitureData;
  PlacedFurniture? draggingOriginalPF; 

  // --- 场景控制 ---
  double currentScale = 0.6;
  Offset sceneOffset = const Offset(-120, 0);
  bool isInteracting = false; 
  bool showGrid = true;
  bool isCapturingSnapshot = false;

  void init(BuildContext context) {
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
            z: sf.z,
            rotation: sf.rotation,
          ));
          masterItem.quantity--;
        }
      }
    }

    // 预加载所有家具素材
    for (final item in _availableItems) {
      FurnitureSprite.precacheItem(item, context).then((_) {
        notifyListeners();
      });
    }
  }

  // --- 核心业务逻辑 ---

  void selectCell((int, int)? cell) {
    selectedCell = cell;
    selectedFurniture = null;
    notifyListeners();
  }

  void selectFurniture(PlacedFurniture? pf) {
    selectedFurniture = pf;
    selectedCell = null;
    notifyListeners();
  }

  void setCategory(String cat) {
    selectedCategory = cat;
    selectedSubCategory = null;
    notifyListeners();
  }

  void setSubCategory(String? sub) {
    selectedSubCategory = sub;
    notifyListeners();
  }

  double dragZOffset = 0.0; // 记录拖拽开始时手指与物品底座的 Z 轴偏移

  void updateDragPosition(Offset localPos, IsometricCoordinateConverter converter, {bool isFirstFrame = false}) {
    if (draggingItem == null) return;

    if (draggingItem!.isWall) {
      final bool preferLeft = localPos.dx >= converter.centerX;
      final wallCell = converter.getWallCell(localPos, preferLeftWall: preferLeft);
      final int targetRotation = preferLeft ? 0 : 1;
      
      // 计算当前手势点对应的 Z 高度 (0~max)
      final double touchZ = converter.getWallZ(
        localPos,
        r: preferLeft ? wallCell.$1.toDouble() : 0,
        c: preferLeft ? 0 : wallCell.$2.toDouble(),
        maxZ: kWallGridHeight.toDouble(),
      );

      // 如果是第一帧（刚抓起），初始化偏移量
      if (isFirstFrame) {
        dragZOffset = ghostZ - touchZ;
      }

      final double maxAllowedZ = (kWallGridHeight - draggingItem!.gridH).toDouble();
      ghostZ = (touchZ + dragZOffset).clamp(0.0, maxAllowedZ).roundToDouble();

      final int gw = draggingItem!.gridW;
      (int, int) centeredCell = preferLeft 
          ? ((wallCell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw), 0)
          : (0, (wallCell.$2 - (gw / 2).floor()).clamp(0, kGridCols - gw));

      if (centeredCell != ghostCell || draggingRotation != targetRotation) {
        ghostCell = centeredCell;
        draggingRotation = targetRotation;
        isInteracting = true;
        notifyListeners();
      }
    } else {
      var cell = converter.getGridCell(localPos);
      if (cell != null && isCellExcluded(cell.$1, cell.$2)) cell = null;
      if (cell != null) {
        int gw = draggingRotation % 2 == 0 ? draggingItem!.gridW : draggingItem!.gridH;
        int gh = draggingRotation % 2 == 0 ? draggingItem!.gridH : draggingItem!.gridW;
        final centeredCell = (
          (cell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
          (cell.$2 - (gh / 2).floor()).clamp(0, kGridCols - gh),
        );
        if (centeredCell != ghostCell) {
          ghostCell = centeredCell;
          isInteracting = true;
          notifyListeners();
        }
      }
    }
  }

  void placeFurniture(FurnitureItem item, {required int r, required int c, required double z, required int rotation}) {
    final newPf = PlacedFurniture(
      item: item,
      r: r,
      c: c,
      z: z,
      rotation: rotation,
    );

    if (draggingOriginalPF != null) {
      _placedFurniture.remove(draggingOriginalPF);
    } else {
      item.quantity--;
    }

    _placedFurniture.add(newPf);
    selectedFurniture = newPf;
    _cleanupDragState();
    UserState().savePlacedFurniture(_placedFurniture);
    notifyListeners();
  }

  void deleteFurniture(PlacedFurniture pf) {
    _placedFurniture.remove(pf);
    pf.item.quantity++;
    selectedFurniture = null;
    UserState().savePlacedFurniture(_placedFurniture);
    notifyListeners();
  }

  void rotateFurniture(IsometricCoordinateConverter converter) {
    if (selectedFurniture == null) return;
    final pf = selectedFurniture!;
    final int oldRotation = pf.rotation;
    final int nextRotation = (oldRotation + 1) % 2;

    // 获取当前占地宽高 (由 isAreaAvailable 内部逻辑推导出)
    int gw = pf.item.gridW;
    int gh = pf.item.isWall ? 1 : pf.item.gridH;
    if (oldRotation % 2 != 0) {
      if (pf.item.isWall) {
        gw = 1; gh = pf.item.gridW;
      } else {
        gw = pf.item.gridH; gh = pf.item.gridW;
      }
    }

    // 获取旋转后的占地宽高
    int ngw = pf.item.gridW;
    int ngh = pf.item.isWall ? 1 : pf.item.gridH;
    if (nextRotation % 2 != 0) {
      if (pf.item.isWall) {
        ngw = 1; ngh = pf.item.gridW;
      } else {
        ngw = pf.item.gridH; ngh = pf.item.gridW;
      }
    }

    int nr = pf.r;
    int nc = pf.c;

    if (pf.item.isWall) {
      // 墙面挂件：切换墙面逻辑
      // Rotation index: 0(左), 1(右), 2(左-背), 3(右-背)
      if (oldRotation % 2 == 0 && nextRotation % 2 != 0) {
        // 从左墙变右墙: (r, 0) -> (0, r)
        nr = 0; nc = pf.r;
      } else if (oldRotation % 2 != 0 && nextRotation % 2 == 0) {
        // 从右墙变左墙: (0, c) -> (c, 0)
        nr = pf.c; nc = 0;
      }
    } else {
      // 地面物品：基于重心的旋转逻辑
      nr = pf.r + (gw - ngw) ~/ 2;
      nc = pf.c + (gh - ngh) ~/ 2;
    }

    if (isAreaAvailable(pf.item, nr, nc, nextRotation, converter, exclude: pf, z: pf.z)) {
      pf.r = nr;
      pf.c = nc;
      pf.rotation = nextRotation;
      UserState().savePlacedFurniture(_placedFurniture);
      notifyListeners();
    }
  }

  void cancelDragging() {
    _cleanupDragState();
    notifyListeners();
  }

  void _cleanupDragState() {
    isLongPressDragging = false;
    draggingItem = null;
    ghostCell = null;
    originalFurnitureData = null;
    draggingOriginalPF = null;
    isInteracting = false;
  }

  void clearAll() {
    for (var pf in _placedFurniture) {
      pf.item.quantity++;
    }
    _placedFurniture.clear();
    selectedFurniture = null;
    selectedCell = null;
    UserState().savePlacedFurniture(_placedFurniture);
    notifyListeners();
  }

  void handleFillAll(FurnitureItem item) {
    // 1. 将所有现有的地板归还库存
    for (var pf in _placedFurniture.where((pf) => pf.item.isFloor)) {
      pf.item.quantity++;
    }
    // 2. 移除所有地板
    _placedFurniture.removeWhere((pf) => pf.item.isFloor);

    // 3. 计算铺满需要的行列数
    final int rows = (kGridRows / item.gridW).ceil();
    final int cols = (kGridCols / item.gridH).ceil();

    // 4. 批量添加
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (item.quantity > 0) {
          final int r = (i * item.gridW).toInt();
          final int jCol = (j * item.gridH).toInt();
          _placedFurniture.add(PlacedFurniture(
            item: item,
            r: r,
            c: jCol,
            rotation: 0,
          ));
          item.quantity--;
        }
      }
    }
    UserState().savePlacedFurniture(_placedFurniture);
    notifyListeners();
  }

  bool isAreaAvailable(
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

    if (r < 0 || c < 0 || r + gw > kGridRows || c + gh > kGridCols) return false;

    if (isWall && z + item.gridH > kWallGridHeight) return false;

    for (int i = r; i < r + gw; i++) {
      for (int j = c; j < c + gh; j++) {
        if (isCellExcluded(i, j)) return false;
      }
    }

    bool isFloor = item.isFloor;
    for (final pf in _placedFurniture) {
      if (pf == exclude) continue;
      if (isFloor != pf.item.isFloor || isWall != pf.item.isWall) continue;

      int pgw = pf.item.gridW;
      int pgh = pf.item.isWall ? 1 : pf.item.gridH;
      if (pf.rotation % 2 != 0) {
        if (pf.item.isWall) { pgw = 1; pgh = pf.item.gridW; }
        else { pgw = pf.item.gridH; pgh = pf.item.gridW; }
      }

      if (r < pf.r + pgw && r + gw > pf.r && c < pf.c + pgh && c + gh > pf.c) {
        if (z < pf.z + pf.item.gridH && z + item.gridH > pf.z) return false;
      }
    }
    return true;
  }

  PlacedFurniture? findVisualHit(Offset localPos, IsometricCoordinateConverter converter) {
    final sorted = List<PlacedFurniture>.from(_placedFurniture)..sort((a, b) {
      if (a.item.category == '地板' || b.item.category == '地板') return a.item.category == '地板' ? 1 : -1;
      int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
      int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
      int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
      int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;
      if (b.r + gwB <= a.r || b.c + ghB <= a.c) return -1;
      if (a.r + gwA <= b.r || a.c + ghA <= b.c) return 1;
      return (b.r + b.c).compareTo(a.r + a.c);
    });

    for (var pf in sorted) {
      if (pf.item.isWall) {
        final double h = pf.item.gridH.toDouble();
        final double l = pf.item.gridW.toDouble();
        List<Offset> pts = pf.rotation % 2 == 0
          ? [converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), pf.z + h), 
             converter.getScreenPoint(pf.r + l, pf.c.toDouble(), pf.z + h), 
             converter.getScreenPoint(pf.r + l, pf.c.toDouble(), pf.z), 
             converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), pf.z)]
          : [converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), pf.z + h), 
             converter.getScreenPoint(pf.r.toDouble(), pf.c + l, pf.z + h), 
             converter.getScreenPoint(pf.r.toDouble(), pf.c + l, pf.z), 
             converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), pf.z)];
        if ((Path()..addPolygon(pts, true)).contains(localPos)) return pf;
      } else {
        int gw = pf.rotation % 2 == 0 ? pf.item.gridW : pf.item.gridH;
        int gh = pf.rotation % 2 == 0 ? pf.item.gridH : pf.item.gridW;
        final bool isBack = pf.rotation == 1 || pf.rotation == 2;
        final rect = converter.getFurnitureRect(
          r: pf.r, c: pf.c, gw: gw, gh: gh,
          visualScale: isBack ? (pf.item.backVisualScale ?? pf.item.visualScale) : pf.item.visualScale,
          visualOffset: isBack ? (pf.item.backVisualOffset ?? pf.item.visualOffset) : pf.item.visualOffset,
          intrinsicWidth: pf.item.intrinsicWidth, intrinsicHeight: pf.item.intrinsicHeight, z: pf.z
        );
        if (rect.contains(localPos)) return pf;
      }
    }
    return null;
  }
  
  void toggleGrid() {
    showGrid = !showGrid;
    notifyListeners();
  }

  void updateInteracting(bool value) {
    isInteracting = value;
    notifyListeners();
  }

  void updateCapturing(bool value) {
    isCapturingSnapshot = value;
    notifyListeners();
  }

  void updateSceneOffset(Offset delta) {
    sceneOffset += delta;
    notifyListeners();
  }
}
