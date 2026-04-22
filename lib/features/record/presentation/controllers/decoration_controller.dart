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
  List<PlacedFurniture> get placedFurniture =>
      List.unmodifiable(_placedFurniture);

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

  // 果冻弹跳动画相关
  AnimationController? _bounceController;
  Animation<double>? _bounceAnimation;
  PlacedFurniture? bouncingFurniture;
  double get bounceScale => _bounceAnimation?.value ?? 1.0;

  // --- 场景控制 ---
  double currentScale = 0.5;
  Offset sceneOffset = const Offset(-120, 0);
  bool isInteracting = false;
  bool showGrid = true;
  bool isCapturingSnapshot = false;
  bool isInitializing = true;
  double loadingProgress = 0.0;

  // --- 墙面颜色控制 ---
  Color wallColorLeft = const Color(0xFFDEDCCE);
  Color wallColorRight = const Color(0xFFDEDCCE);

  void init(BuildContext context, {TickerProvider? vsync}) {
    if (vsync != null) {
      _bounceController =
          AnimationController(
            vsync: vsync,
            duration: const Duration(milliseconds: 600),
          )..addListener(() {
            notifyListeners();
          });

      _bounceAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _bounceController!, curve: Curves.elasticOut),
      );
    }

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
        flippedVisualScale: item.flippedVisualScale,
        flippedVisualOffset: item.flippedVisualOffset,
        flippedVisualRotationX: item.flippedVisualRotationX,
        flippedVisualRotationY: item.flippedVisualRotationY,
        flippedVisualRotationZ: item.flippedVisualRotationZ,
        flippedVisualPivot: item.flippedVisualPivot,
        toolbarOffset: item.toolbarOffset,
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
          _placedFurniture.add(
            PlacedFurniture(
              item: masterItem,
              r: sf.r,
              c: sf.c,
              z: sf.z,
              rotation: sf.rotation,
            ),
          );
          masterItem.quantity--;
        }
      }
    }

    // 预加载必需资源
    _preloadAssets(context);
  }

  Future<void> _preloadAssets(BuildContext context) async {
    isInitializing = true;
    loadingProgress = 0.0;
    notifyListeners();

    // 1. 确定需要优先加载的资源（已摆放的家具 + 当前分类的前几个）
    final Set<String> itemsToPreload = {};
    for (var pf in _placedFurniture) {
      itemsToPreload.add(pf.item.id);
    }

    final currentCategoryItems = _availableItems
        .where((it) => it.category == selectedCategory)
        .take(10);
    for (var it in currentCategoryItems) {
      itemsToPreload.add(it.id);
    }

    if (itemsToPreload.isEmpty) {
      isInitializing = false;
      loadingProgress = 1.0;
      notifyListeners();
      return;
    }

    int loadedCount = 0;
    final totalToLoad = itemsToPreload.length;

    // 按顺序逐个加载资源，减少内存峰值并让进度更新更平滑
    for (final id in itemsToPreload) {
      final item = _availableItems.firstWhere((it) => it.id == id);
      try {
        await FurnitureSprite.precacheItem(item, context);
      } catch (e) {
        debugPrint('Preloading error for $id: $e');
      }
      loadedCount++;
      loadingProgress = loadedCount / totalToLoad;
      notifyListeners();

      // 给 UI 线程喘息的机会，确保进度条文字能渲染出来
      await Future.delayed(Duration.zero);
    }

    // 棰濆鐨勫皬寤惰繜纭繚 UI 骞虫粦杩囨浮
    await Future.delayed(const Duration(milliseconds: 300));
    // 加载墙面颜色官方推荐色
    wallColorLeft = UserState().wallColorLeft.value;
    wallColorRight = UserState().wallColorRight.value;

    isInitializing = false;
    notifyListeners();
  }

  void setWallColor(bool isLeft, Color color) {
    if (isLeft) {
      wallColorLeft = color;
    } else {
      wallColorRight = color;
    }
    UserState().saveWallColors(wallColorLeft, wallColorRight);
    notifyListeners();
  }

  @override
  void dispose() {
    _bounceController?.dispose();
    super.dispose();
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

  void updateDragPosition(
    Offset localPos,
    IsometricCoordinateConverter converter, {
    bool isFirstFrame = false,
  }) {
    if (draggingItem == null) return;

    if (draggingItem!.isWall) {
      // 等轴测坐标系中，左墙(XZ面, r轴) 在视觉上位于屏幕右侧，右墙(YZ面, c轴) 在视觉上位于屏幕左侧
      // 因此手指在屏幕右侧 (> centerX) 时才是 preferLeft
      final bool preferLeft = localPos.dx > converter.centerX;

      final bool useLeftWall = preferLeft;
      final int targetRotation = useLeftWall ? 0 : 1;

      final wallCell = converter.getWallCell(
        localPos,
        preferLeftWall: useLeftWall,
      );

      // 璁＄畻褰撳墠鎵嬪娍鐐瑰搴旂殑 Z 楂樺害 (0~max)
      final double touchZ = converter.getWallZ(
        localPos,
        r: useLeftWall ? wallCell.$1.toDouble() : 0,
        c: useLeftWall ? 0 : wallCell.$2.toDouble(),
        maxZ: kWallGridHeight.toDouble(),
      );

      // 如果是第一帧（刚抓起），初始化偏移量
      if (isFirstFrame) {
        dragZOffset = ghostZ - touchZ;
      }

      final double maxAllowedZ = (kWallGridHeight - draggingItem!.gridH)
          .toDouble();
      final double oldZ = ghostZ;
      ghostZ = (touchZ + dragZOffset).clamp(0.0, maxAllowedZ).roundToDouble();

      final int gw = draggingItem!.gridW;
      (int, int) centeredCell = useLeftWall
          ? ((wallCell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw), 0)
          : (0, (wallCell.$2 - (gw / 2).floor()).clamp(0, kGridCols - gw));

      if (centeredCell != ghostCell || draggingRotation != targetRotation || ghostZ != oldZ) {
        ghostCell = centeredCell;
        draggingRotation = targetRotation;
        isInteracting = true;
        notifyListeners();
      }
    } else {
      // 1. 获取稳定、不受高度影响的基础控制网格(光标直射地面)，以此作为承托面侦测依据，绝对消除边缘跨层抖动。
      var cell0 = converter.getGridCell(localPos, z: 0.0);
      if (cell0 != null && isCellExcluded(cell0.$1, cell0.$2)) cell0 = null;
      
      if (cell0 != null) {
        int gw = draggingRotation % 2 == 0
            ? draggingItem!.gridW
            : draggingItem!.gridH;
        int gh = draggingRotation % 2 == 0
            ? draggingItem!.gridH
            : draggingItem!.gridW;
            
        final centeredCell0 = (
          (cell0.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
          (cell0.$2 - (gh / 2).floor()).clamp(0, kGridCols - gh),
        );
        
        // --- 靠墙/高台家具动态高度吸附逻辑 ---
        double targetZ = 0.0;
        bool isDecoration =
            draggingItem!.category == '装饰' ||
            draggingItem!.subCategory == '软装' ||
            draggingItem!.subCategory == '饰品' ||
            draggingItem!.subCategory == '盆栽';

        if (isDecoration) {
          double foundSurfaceZ = 0.0;
          for (final pf in _placedFurniture) {
            if (pf.item.isFloor || pf.item.isWall || pf == draggingOriginalPF)
              continue;

            int pgw = pf.rotation % 2 == 0 ? pf.item.gridW : pf.item.gridH;
            int pgh = pf.rotation % 2 == 0 ? pf.item.gridH : pf.item.gridW;

            // 碰撞检测使用基础探测网格：只要光标下方实际有支持面，无论最终视觉偏多少都视作落在桌上
            if (centeredCell0.$1 < pf.r + pgw &&
                centeredCell0.$1 + gw > pf.r &&
                centeredCell0.$2 < pf.c + pgh &&
                centeredCell0.$2 + gh > pf.c) {
              final height = _furnitureSurfaceHeights[pf.item.id] ?? 0.0;
              if (height > foundSurfaceZ) {
                foundSurfaceZ = height;
              }
            }
          }
          targetZ = foundSurfaceZ;
        }

        double oldZ = ghostZ;
        ghostZ = targetZ;

        // 2. 根据确定的 targetZ 逆向求出带有视差补偿的最终摆放网格，确保高空画出来的物块在其对应绝对坐标上与手指无任何偏移
        var cellZ = converter.getGridCell(localPos, z: targetZ);
        if (cellZ != null && isCellExcluded(cellZ.$1, cellZ.$2)) cellZ = null;
        var finalCell = cellZ ?? cell0; // 若悬空补偿导致超出室内，使用基础退回

        final centeredCell = (
          (finalCell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
          (finalCell.$2 - (gh / 2).floor()).clamp(0, kGridCols - gh),
        );

        if (centeredCell != ghostCell) {
          ghostCell = centeredCell;
          isInteracting = true;
          notifyListeners();
        } else if (targetZ != oldZ) {
          // 如果位置没变但高度变了（进入/离开不同高度家具区域），也要通知重绘
          notifyListeners();
        }
      }
    }
  }

  // --- 家具表面高度配置表 ---
  static const Map<String, double> _furnitureSurfaceHeights = {
    'cabinet_1': 4.0, // 橱柜
    'cabinet_2': 4.0, // 奶酪色拼色地柜
    'cabinet_3': 4.0, // 奶酪色拼色转角地柜
    'table_1': 2.2, // 桌子 1
    'table_2': 2.2, // 桌子 2
    'table_3': 1.8, // 桌子 3 (较矮)
    'sofa_1': 1.2, // 沙发
    'sofa_2': 1.2,
    'sofa_3': 1.2,
    'sofa_4': 1.2,
    'bookcase_1': 3.0, // 书柜台面
  };

  void placeFurniture(
    FurnitureItem item, {
    required int r,
    required int c,
    required double z,
    required int rotation,
  }) {
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

    // 触发果冻弹跳吸附动画
    bouncingFurniture = newPf;
    _bounceController?.forward(from: 0.0);

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
        gw = 1;
        gh = pf.item.gridW;
      } else {
        gw = pf.item.gridH;
        gh = pf.item.gridW;
      }
    }

    // 获取旋转后的占地宽高
    int ngw = pf.item.gridW;
    int ngh = pf.item.isWall ? 1 : pf.item.gridH;
    if (nextRotation % 2 != 0) {
      if (pf.item.isWall) {
        ngw = 1;
        ngh = pf.item.gridW;
      } else {
        ngw = pf.item.gridH;
        ngh = pf.item.gridW;
      }
    }

    int nr = pf.r;
    int nc = pf.c;

    if (pf.item.isWall) {
      // 墙面挂件：切换墙面逻辑
      // Rotation index: 0(左), 1(右), 2(左后), 3(右后)
      if (oldRotation % 2 == 0 && nextRotation % 2 != 0) {
        // 从左墙变右墙: (r, 0) -> (0, r)
        nr = 0;
        nc = pf.r;
      } else if (oldRotation % 2 != 0 && nextRotation % 2 == 0) {
        // 从右墙变左墙: (0, c) -> (c, 0)
        nr = pf.c;
        nc = 0;
      }
    } else {
      // 地面物品：基于重心的旋转逻辑
      nr = pf.r + (gw - ngw) ~/ 2;
      nc = pf.c + (gh - ngh) ~/ 2;
    }

    if (isAreaAvailable(
      pf.item,
      nr,
      nc,
      nextRotation,
      converter,
      exclude: pf,
      z: pf.z,
    )) {
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

    // 4. 鎵归噺娣诲姞
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (item.quantity > 0) {
          final int r = (i * item.gridW).toInt();
          final int jCol = (j * item.gridH).toInt();
          _placedFurniture.add(
            PlacedFurniture(item: item, r: r, c: jCol, rotation: 0),
          );
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
        gw = 1;
        gh = item.gridW;
      } else {
        gw = item.gridH;
        gh = item.gridW;
      }
    }

    if (r < 0 || c < 0 || r + gw > kGridRows || c + gh > kGridCols)
      return false;

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
        if (pf.item.isWall) {
          pgw = 1;
          pgh = pf.item.gridW;
        } else {
          pgw = pf.item.gridH;
          pgh = pf.item.gridW;
        }
      }

      if (r < pf.r + pgw && r + gw > pf.r && c < pf.c + pgh && c + gh > pf.c) {
        // 如果正在放置的是地毯，而对方是普通家具（非地板、非地毯），则跳过碰撞检测
        if (item.subCategory == '地毯' &&
            !pf.item.isFloor &&
            pf.item.subCategory != '地毯') {
          continue;
        }
        // 如果对方是地毯，而我们正要放置的是普通家具，也跳过检测，让地毯一直可以被压着
        if (pf.item.subCategory == '地毯' &&
            !item.isFloor &&
            item.subCategory != '地毯') {
          continue;
        }

        // [修正] 如果放的是“饰品/装饰”或“软装”，则允许与除地板外的任何家具（包括其他饰品）重叠
        bool isDecorator = item.category == '装饰' || item.subCategory == '软装';
        bool isExistingDecorator =
            pf.item.category == '装饰' || pf.item.subCategory == '软装';

        if ((isDecorator && !pf.item.isFloor) ||
            (isExistingDecorator && !item.isFloor)) {
          continue;
        }

        if (z < pf.z + pf.item.gridH && z + item.gridH > pf.z) return false;
      }
    }
    return true;
  }

  PlacedFurniture? findVisualHit(
    Offset localPos,
    IsometricCoordinateConverter converter,
  ) {
    final sorted = List<PlacedFurniture>.from(_placedFurniture)
      ..sort((a, b) {
        // 1. 基础分类优先级：墙面 > 地面 (家具/装饰) > 地板
        if (a.item.isWall != b.item.isWall) return a.item.isWall ? -1 : 1;
        if (a.item.isFloor != b.item.isFloor) return a.item.isFloor ? 1 : -1;

        // 2. 杞/楗板搧锛堥€氬父鍦ㄤ笂鏂癸級鍏锋湁鏇撮珮鐐瑰嚮浼樺厛绾?
        bool aIsSoft = a.item.subCategory == '软装' || a.item.category == '装饰';
        bool bIsSoft = b.item.subCategory == '软装' || b.item.category == '装饰';
        if (aIsSoft != bIsSoft) return aIsSoft ? -1 : 1;

        // 3. 核心排序：由近及远 (Front-to-Back)
        // 在等轴测投影中，r+c 较大代表物体更靠近观察者，应优先检测
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;

        // 如果 a 严格在 b 的前方，则 a 优先
        if (a.r >= b.r + gwB || a.c >= b.c + ghB) return -1;
        // 濡傛灉 b 涓ユ牸鍦?a 鐨勫墠鏂癸紝鍒?b 浼樺厛
        if (b.r >= a.r + gwA || b.c >= a.c + ghA) return 1;

        // 4. 閲嶅彔鎯呭喌涓嬬殑缁嗚妭鍒ゅ畾 (楂樺害銆佷綅缃?
        // 如果在同一格或重叠，Z 轴（高度）大的优先
        if (a.z != b.z) return b.z.compareTo(a.z);

        // 最后根据网格中心深度降序排列
        return (b.r + b.c).compareTo(a.r + a.c);
      });

    for (var pf in sorted) {
      if (pf.item.isWall) {
        final double h = pf.item.gridH.toDouble();
        final double l = pf.item.gridW.toDouble();
        List<Offset> pts = pf.rotation % 2 == 0
            ? [
                converter.getScreenPoint(
                  pf.r.toDouble(),
                  pf.c.toDouble(),
                  pf.z + h,
                ),
                converter.getScreenPoint(pf.r + l, pf.c.toDouble(), pf.z + h),
                converter.getScreenPoint(pf.r + l, pf.c.toDouble(), pf.z),
                converter.getScreenPoint(
                  pf.r.toDouble(),
                  pf.c.toDouble(),
                  pf.z,
                ),
              ]
            : [
                converter.getScreenPoint(
                  pf.r.toDouble(),
                  pf.c.toDouble(),
                  pf.z + h,
                ),
                converter.getScreenPoint(pf.r.toDouble(), pf.c + l, pf.z + h),
                converter.getScreenPoint(pf.r.toDouble(), pf.c + l, pf.z),
                converter.getScreenPoint(
                  pf.r.toDouble(),
                  pf.c.toDouble(),
                  pf.z,
                ),
              ];
        if ((Path()..addPolygon(pts, true)).contains(localPos)) return pf;
      } else {
        int gw = pf.rotation % 2 == 0 ? pf.item.gridW : pf.item.gridH;
        int gh = pf.rotation % 2 == 0 ? pf.item.gridH : pf.item.gridW;
        final bool isFlipped = pf.rotation == 1; // 旋转 1 次代表 180 度翻转
        final double visualScale = isFlipped
            ? (pf.item.flippedVisualScale ?? pf.item.visualScale)
            : pf.item.visualScale;
        final Offset visualOffset = isFlipped
            ? (pf.item.flippedVisualOffset ?? pf.item.visualOffset)
            : pf.item.visualOffset;

        final rect = converter.getFurnitureRect(
          r: pf.r,
          c: pf.c,
          gw: gw,
          gh: gh,
          visualScale: visualScale,
          visualOffset: visualOffset,
          intrinsicWidth: pf.item.intrinsicWidth,
          intrinsicHeight: pf.item.intrinsicHeight,
          z: pf.z,
        );

        if (rect.contains(localPos)) {
          // 矩形区域内，进一步检测像素透明度官方推荐色
          final double dx = localPos.dx - rect.left;
          final double dy = localPos.dy - rect.top;

          // 1. 用矩形实际尺寸与 intrinsic 尺寸的比例来映射：
          //    不能用 visualScale 除，因为 rect 的实际宽高由 estimateVisualWidth
          //    推导（受 tw、gridW、gridH、taper 影响），与 intrinsicWidth * visualScale 不等。
          double ix = dx * pf.item.intrinsicWidth / rect.width;
          double iy = dy * pf.item.intrinsicHeight / rect.height;

          // 2. 处理镜像反转（rotation==1 时图像水平翻转）
          if (isFlipped) {
            ix = pf.item.intrinsicWidth - ix;
          }

          // 3. 映射到图片真实分辨率
          final img = SpritePainter.getImage(pf.item.imagePath);
          if (img != null) {
            final double sx = pf.item.spriteRect.left * img.width;
            final double sy = pf.item.spriteRect.top * img.height;
            final double sw = pf.item.spriteRect.width * img.width;
            final double sh = pf.item.spriteRect.height * img.height;

            final int px = (sx + ix / pf.item.intrinsicWidth * sw)
                .round()
                .clamp(0, img.width - 1);
            final int py = (sy + iy / pf.item.intrinsicHeight * sh)
                .round()
                .clamp(0, img.height - 1);

            if (SpritePainter.getAlphaAt(pf.item.imagePath, px, py) > 20) {
              return pf;
            }
          } else {
            // 如果图片还没加载完，回退到矩形检测
            return pf;
          }
        }
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
