import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../pages/decoration_page_constants.dart';
import '../../data/services/furniture_db_service.dart';
import '../widgets/furniture_sprite.dart';

class DecorationController extends ChangeNotifier {
  // --- 核心家具数据 ---
  final List<PlacedFurniture> _placedFurniture = [];
  List<PlacedFurniture> get placedFurniture =>
      List.unmodifiable(_placedFurniture);

  List<FurnitureItem> _availableItems = [];
  List<FurnitureItem> get availableItems => _availableItems;

  String selectedCategory = '家具';
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

  // 点击放置的最近一次预览物品（再次点击时先移除）
  PlacedFurniture? _lastClickPlaced;

  // 果冻弹跳动画相关
  AnimationController? _bounceController;
  Animation<double>? _bounceAnimation;
  PlacedFurniture? bouncingFurniture;
  double get bounceScale => _bounceAnimation?.value ?? 1.0;

  // --- 场景控制 ---
  double currentScale = 0.5;
  Offset sceneOffset = const Offset(-120, 0);
  bool isInteracting = false;
  bool showGrid = false;
  bool isCapturingSnapshot = false;
  bool isInitializing = true;
  double loadingProgress = 0.0;

  // --- 场景背景控制 ---
  Color wallColorLeft = const Color(0xFFDEDCCE);
  Color wallColorRight = const Color(0xFFDEDCCE);
  WallPattern wallPattern = WallPattern.none;
  FloorPattern floorPattern = FloorPattern.none;
  Color floorColor = const Color(0xFFF1EBD1);

  Future<void> init(BuildContext context, {TickerProvider? vsync}) async {
    isInitializing = true;
    loadingProgress = 0.0;
    notifyListeners();

    if (vsync != null && _bounceController == null) {
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

    _availableItems = FurnitureDbService.getAllItems();

    // 过滤掉本地被删除了的资源文件，防止抛出 AssetNotFound 异常并显示空白卡片
    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final Set<String> assets = manifest.listAssets().toSet();
      _availableItems = _availableItems.where((item) {
        return assets.contains(item.imagePath);
      }).toList();
    } catch (e) {
      debugPrint('Failed to filter missing assets using AssetManifest: $e');
    }

    // 加载已保存的家具布局
    final saved = UserState().placedFurniture.value;
    if (saved.isNotEmpty) {
      final Set<String> floorDeductedIds = {};
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
          if (masterItem.isFloor) {
            if (!floorDeductedIds.contains(masterItem.id)) {
              masterItem.quantity--;
              floorDeductedIds.add(masterItem.id);
            }
          } else {
            masterItem.quantity--;
          }
        }
      }
    }

    // 加载已保存的墙面与地板样式
    wallColorLeft = UserState().wallColorLeft.value;
    wallColorRight = UserState().wallColorRight.value;
    wallPattern = WallPattern.values[UserState().wallPattern.value.clamp(0, WallPattern.values.length - 1)];
    floorColor = UserState().floorColor.value;
    floorPattern = FloorPattern.values[UserState().floorPattern.value.clamp(0, FloorPattern.values.length - 1)];

    // 预加载必需资源
    await _preloadAssets(context);
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
      if (!context.mounted) return;
      final item = _availableItems.firstWhere((it) => it.id == id);
      try {
        await FurnitureSprite.precacheItem(item, context);
        if (!context.mounted) return;
      } catch (e) {
        debugPrint('Preloading error for $id: $e');
      }
      loadedCount++;
      loadingProgress = loadedCount / totalToLoad;
      notifyListeners();

      // 给 UI 线程喘息的机会，并稍微拉长节奏，确保进度条和文字能被看清
      await Future.delayed(const Duration(milliseconds: 60));
      if (!context.mounted) return;
    }

    // 额外的平滑延迟，避免加载过快导致的闪烁
    await Future.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    // 加载墙面颜色官方推荐色
    wallColorLeft = UserState().wallColorLeft.value;
    wallColorRight = UserState().wallColorRight.value;
    wallPattern =
        WallPattern.values[UserState().wallPattern.value.clamp(
          0,
          WallPattern.values.length - 1,
        )];
    floorColor = UserState().floorColor.value;
    floorPattern =
        FloorPattern.values[UserState().floorPattern.value.clamp(
          0,
          FloorPattern.values.length - 1,
        )];

    isInitializing = false;
    notifyListeners();
  }

  void setWallColor(bool isLeft, Color color) {
    if (isLeft) {
      wallColorLeft = color;
    } else {
      wallColorRight = color;
    }
    UserState().saveSceneColors(wallColorLeft, wallColorRight, floorColor);
    notifyListeners();
  }

  void setFloorColor(Color color) {
    floorColor = color;
    UserState().saveSceneColors(wallColorLeft, wallColorRight, floorColor);
    notifyListeners();
  }

  void setFloorPattern(FloorPattern pattern) {
    floorPattern = pattern;
    UserState().saveFloorPattern(pattern.index);
    notifyListeners();
  }

  void setWallPattern(WallPattern pattern) {
    wallPattern = pattern;
    UserState().saveWallPattern(pattern.index);
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

  int dyeVersion = 0; // 用于强制触发重绘的版本号

  void updatePlacedFurnitureVariant(
    PlacedFurniture pf,
    FurnitureColorVariant variant,
  ) {
    final index = _placedFurniture.indexOf(pf);
    if (index != -1) {
      // 1. 先更新模型数据
      final updatedPF = pf.copyWith(
        item: pf.item.copyWith(imagePath: variant.imagePath),
      );
      _placedFurniture[index] = updatedPF;

      // 如果是地板类物品，同步更新场景的 floorColor
      if (pf.item.isFloor) {
        setFloorColor(variant.color);
      }

      // 增加版本号以触发重绘
      dyeVersion++;

      if (selectedFurniture == pf) {
        selectedFurniture = updatedPF;
      }
      notifyListeners(); // 第一次通知：数据已变

      // 2. 预加载新贴图，加载完成后再次触发重绘确保显示
      final image = AssetImage(variant.imagePath);
      final stream = image.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          // 将图片存入缓存池
          SpritePainter.cacheImage(variant.imagePath, info.image);
          // 图片准备好了，第二次通知：强制场景重绘以显示新贴图
          notifyListeners();
        }),
      );
    }
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

  void startDragging(FurnitureItem item, {PlacedFurniture? originalPF}) {
    draggingItem = item;
    draggingOriginalPF = originalPF;
    ghostCell = null;
    ghostZ = originalPF?.z ?? 0.0;
    draggingRotation = originalPF?.rotation ?? 0;
    isInteracting = true;
    notifyListeners();
  }

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

      // 计算当前手指点对应的 Z 高度 (0~max)
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

      final double maxAllowedZ = math.max(
        0.0,
        (kWallGridHeight - draggingItem!.gridH).toDouble(),
      );
      final double oldZ = ghostZ;
      ghostZ = (touchZ + dragZOffset).clamp(0.0, maxAllowedZ).roundToDouble();

      final int gw = draggingItem!.gridW;
      (int, int) centeredCell = useLeftWall
          ? ((wallCell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw), 0)
          : (0, (wallCell.$2 - (gw / 2).floor()).clamp(0, kGridCols - gw));

      if (centeredCell != ghostCell ||
          draggingRotation != targetRotation ||
          ghostZ != oldZ) {
        ghostCell = centeredCell;
        draggingRotation = targetRotation;
        isInteracting = true;
        notifyListeners();
      }
    } else {
      // --- 改进后的探测逻辑：支持由于高度视差导致的地面投影点溢出探测 ---
      
      // 1. 尝试探测所有家具的表面高度
      double targetZ = 0.0;
      if (draggingItem!.canStack) {
        double foundSurfaceZ = 0.0;
        for (final pf in _placedFurniture) {
          if (pf.item.isFloor || pf.item.isWall || pf == draggingOriginalPF) {
            continue;
          }

          if (pf.item.surfaceHeight != null) {
            final double height = pf.item.surfaceHeight!;
            final cellAtHeight = converter.getGridCell(localPos, z: height);

            if (cellAtHeight != null) {
              int pgw = pf.rotation % 2 == 0 ? pf.item.gridW : pf.item.gridH;
              int pgh = pf.rotation % 2 == 0 ? pf.item.gridH : pf.item.gridW;

              if (cellAtHeight.$1 >= pf.r &&
                  cellAtHeight.$1 < pf.r + pgw &&
                  cellAtHeight.$2 >= pf.c &&
                  cellAtHeight.$2 < pf.c + pgh) {
                if (height > foundSurfaceZ) {
                  foundSurfaceZ = height;
                }
              }
            }
          }
        }
        targetZ = foundSurfaceZ;
      }

      // 2. 根据最终高度计算投影网格
      var cellZ = converter.getGridCell(localPos, z: targetZ);
      
      // 3. 如果带高度的探测失效（例如点击了完全不在网格内的区域），尝试保底地面探测
      if (cellZ == null && targetZ > 0) {
        cellZ = converter.getGridCell(localPos, z: 0.0);
      }

      if (cellZ != null) {
        if (isCellExcluded(cellZ.$1, cellZ.$2)) return;

        int gw = draggingRotation % 2 == 0 ? draggingItem!.gridW : draggingItem!.gridH;
        int gh = draggingRotation % 2 == 0 ? draggingItem!.gridH : draggingItem!.gridW;

        // 应用高度补偿和边界限制
        final centeredCell = (
          (cellZ.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
          (cellZ.$2 - (gh / 2).floor()).clamp(0, kGridCols - gh),
        );

        double oldZ = ghostZ;
        ghostZ = targetZ;

        if (centeredCell != ghostCell || targetZ != oldZ) {
          ghostCell = centeredCell;
          isInteracting = true;
          notifyListeners();
        }
      }
    }
  }



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

  void addFurniture(FurnitureItem item) {
    if (item.quantity <= 0) return;

    // 若上一次点击放置的物品还未被移动/删除，先移除它
    final bool allowsSelfOverlap =
        item.canStack && item.surfaceHeight != null;

    if (!allowsSelfOverlap && _lastClickPlaced != null &&
        _placedFurniture.contains(_lastClickPlaced)) {
      _placedFurniture.remove(_lastClickPlaced);
      _lastClickPlaced!.item.quantity++;
    }
    _lastClickPlaced = null;

    if (item.subCategory == '墙纸') {
      if (item.id.contains('stripes_pink')) {
        setWallPattern(WallPattern.stripes);
      } else if (item.id.contains('stripes_lavender')) {
        setWallPattern(WallPattern.lavenderStripes);
      } else if (item.id.contains('dual_color')) {
        setWallPattern(WallPattern.dualColor);
      } else if (item.id.contains('solid_sand')) {
        setWallColor(true, const Color(0xFFE7CBA2));
        setWallColor(false, const Color(0xFFE7CBA2));
        setWallPattern(WallPattern.none);
      } else if (item.id.contains('wainscoting')) {
        setWallPattern(WallPattern.wainscoting);
        // 设置配套的藕粉色基调
        setWallColor(true, const Color(0xFFBC8B91));
        setWallColor(false, const Color(0xFFBC8B91));
      } else if (item.id.contains('clouds')) {
        setWallPattern(WallPattern.clouds);
        setWallColor(true, const Color(0xFFC2DFFF));
        setWallColor(false, const Color(0xFFC2DFFF));
      } else if (item.id.contains('pink_gradient')) {
        setWallPattern(WallPattern.pinkGradient);
      } else if (item.id.contains('gradient')) {
        setWallPattern(WallPattern.gradient);
      } else if (item.id.contains('sparkle')) {
        setWallPattern(WallPattern.sparkle);
      } else if (item.id.contains('melting_drips')) {
        setWallPattern(WallPattern.meltingDrips);
      } else if (item.id.contains('green_hills')) {
        setWallPattern(WallPattern.greenHills);
      } else if (item.id.contains('vintage_floral')) {
        setWallPattern(WallPattern.vintageFloral);
        // 设置底色为浅青绿
        setWallColor(true, const Color(0xFFE2EBD5));
        setWallColor(false, const Color(0xFFE2EBD5));
      } else if (item.id.contains('ivy_skirting')) {
        setWallPattern(WallPattern.ivySkirting);
        // 设置底色为淡米黄
        setWallColor(true, const Color(0xFFF7F5E4));
        setWallColor(false, const Color(0xFFF7F5E4));
      } else if (item.id.contains('sakura')) {
        setWallPattern(WallPattern.sakura);
        // 设置底色为柔和粉色
        setWallColor(true, const Color(0xFFFDE8E9));
        setWallColor(false, const Color(0xFFFDE8E9));
      } else if (item.id.contains('green_wood_panels')) {
        setWallPattern(WallPattern.greenWoodPanels);
        // 设置清新的淡绿底色
        setWallColor(true, const Color(0xFFC5DEC1));
        setWallColor(false, const Color(0xFFC5DEC1));
      } else {
        setWallPattern(WallPattern.none);
      }
      return;
    }

    if (item.subCategory == '地板') {
      if (item.id.contains('triple_herringbone')) {
        // 1. 清除所有现有的图片地板并归还库存
        _clearExistingFloorsToInventory();
        // 2. 设置特定的底色
        if (item.id.contains('mint')) {
          setFloorColor(const Color(0xFFB9DCC8));
        } else if (item.id.contains('sage')) {
          setFloorColor(const Color(0xFFA8B49F));
        }
        // 3. 设置代码纹理
        setFloorPattern(FloorPattern.tripleHerringbone);
      } else if (item.id.contains('herringbone')) {
        _clearExistingFloorsToInventory();
        setFloorPattern(FloorPattern.herringbone);
      } else if (item.id.contains('random_wood')) {
        _clearExistingFloorsToInventory();
        setFloorPattern(FloorPattern.randomWood);
      } else if (item.id.contains('plaid')) {
        _clearExistingFloorsToInventory();
        setFloorPattern(FloorPattern.plaid);
      } else if (item.id.contains('harlequin')) {
        _clearExistingFloorsToInventory();
        setFloorPattern(FloorPattern.harlequin);
      } else if (item.id.contains('terrazzo')) {
        _clearExistingFloorsToInventory();
        setFloorPattern(FloorPattern.terrazzo);
        setFloorColor(const Color(0xFFCED4BC)); // 匹配图片的浅绿色基底
      } else {
        // 如果是普通地板图层，则重置代码生成的纹理并自动铺满
        setFloorPattern(FloorPattern.none);
        handleFillAll(item);
      }
      return;
    }

    int r = (kGridRows / 2).floor();
    int c = (kGridCols / 2).floor();
    if (item.isWall) {
      r = (kGridRows / 2).floor();
      c = 0;
    }

    placeFurniture(item, r: r, c: c, z: 0, rotation: 0);
    // 记录本次点击放置的引用
    _lastClickPlaced = selectedFurniture;
  }

  void deleteFurniture(PlacedFurniture pf) {
    if (pf.item.isFloor) {
      // 地板作为整体处理：如果是删除最后一块同类地板，才归还 1 个库存
      final otherSameFloors = _placedFurniture.where((item) => item != pf && item.item.id == pf.item.id);
      if (otherSameFloors.isEmpty) {
        pf.item.quantity++;
      }
    } else {
      pf.item.quantity++;
    }
    _placedFurniture.remove(pf);
    selectedFurniture = null;
    UserState().savePlacedFurniture(_placedFurniture);
    notifyListeners();
  }

  void rotateFurniture(IsometricCoordinateConverter converter) {
    if (selectedFurniture == null) return;
    final pf = selectedFurniture!;
    final int oldRotation = pf.rotation;
    final int nextRotation = (oldRotation + 1) % 4;

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
    _lastClickPlaced = null; // 拖拽完成后清除点击预览引用
    isInteracting = false;
  }

  void clearAll() {
    // 按 ID 归还库存，确保地板类只归还 1 个
    final Set<String> returnedIds = {};
    for (var pf in _placedFurniture) {
      if (pf.item.isFloor) {
        if (!returnedIds.contains(pf.item.id)) {
          pf.item.quantity++;
          returnedIds.add(pf.item.id);
        }
      } else {
        pf.item.quantity++;
      }
    }
    _placedFurniture.clear();
    selectedFurniture = null;
    selectedCell = null;
    UserState().savePlacedFurniture(_placedFurniture);
    notifyListeners();
  }

  void handleFillAll(FurnitureItem item) {
    // 1. 将所有现有的地板归还库存（作为整体归还 1 个）
    _clearExistingFloorsToInventory();

    // 2. 移除所有地板 (已经在 _clearExistingFloorsToInventory 处理了，但为了严谨这里保留 removeWhere)
    _placedFurniture.removeWhere((pf) => pf.item.isFloor);

    // 3. 计算铺满需要的行列数
    final int rows = (kGridRows / item.gridW).ceil();
    final int cols = (kGridCols / item.gridH).ceil();

    // 4. 批量添加（不论库存，强行铺满）
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final int r = (i * item.gridW).toInt();
        final int jCol = (j * item.gridH).toInt();
        _placedFurniture.add(
          PlacedFurniture(item: item, r: r, c: jCol, rotation: 0),
        );
      }
    }
    // 整体消耗 1 个
    item.quantity--;

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

    if (r < 0 || c < 0 || r + gw > kGridRows || c + gh > kGridCols) {
      return false;
    }

    if (isWall && z + item.gridH > kWallGridHeight) {
      return false;
    }

    for (int i = r; i < r + gw; i++) {
      for (int j = c; j < c + gh; j++) {
        if (isCellExcluded(i, j)) {
          return false;
        }
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

        // [修正] 如果放的是“可叠放”物品，则允许与具有表面高度的家具重叠
        bool isDecorator = item.canStack;
        bool isExistingSurface = pf.item.surfaceHeight != null;

        if ((isDecorator && isExistingSurface) ||
            (item.surfaceHeight != null && pf.item.canStack)) {
          continue;
        }

        // 兼容原有的装饰类允许重叠逻辑
        bool isExistingDecorator = pf.item.canStack;
        if ((isDecorator && !pf.item.isFloor) ||
            (isExistingDecorator && !item.isFloor)) {
          continue;
        }

        if (z < pf.z + pf.item.gridH && z + item.gridH > pf.z) {
          return false;
        }
      }
    }
    return true;
  }

  PlacedFurniture? findVisualHit(
    Offset localPos,
    IsometricCoordinateConverter converter,
  ) {
    final sorted =
        List<PlacedFurniture>.from(
          _placedFurniture.where((pf) => !pf.item.isFloor),
        )..sort((a, b) {
          // 1. 基础分类优先级：墙面 > 地面 (家具/装饰) > 地板
          if (a.item.isWall != b.item.isWall) return a.item.isWall ? -1 : 1;
          if (a.item.isFloor != b.item.isFloor) return a.item.isFloor ? 1 : -1;

          // 2. 软装/饰品（通常在上方）具有更高点击优先级
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
          // 如果 b 严格在 a 的前方，则 b 优先
          if (b.r >= a.r + gwA || b.c >= a.c + ghA) return 1;

          // 4. 重叠情况下的细节判定 (高度、位置)
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
          isCarpet: pf.item.subCategory == '地毯',
        );

        if (rect.contains(localPos)) {
          // 矩形区域内，进一步检测像素透明度
          final double dx = localPos.dx - rect.left;
          final double dy = localPos.dy - rect.top;

          // 1. 用矩形实际尺寸与 intrinsic 尺寸的比例来映射：
          //    避免除零
          if (rect.width == 0 || rect.height == 0) continue;

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

  /// 私有方法：清理当前场景中的所有地板并正确归还库存数量（整体归还逻辑）
  void _clearExistingFloorsToInventory() {
    final existingFloors =
        _placedFurniture.where((pf) => pf.item.isFloor).toList();
    if (existingFloors.isEmpty) return;

    final Set<String> returnedIds = {};
    for (var pf in existingFloors) {
      if (!returnedIds.contains(pf.item.id)) {
        pf.item.quantity++;
        returnedIds.add(pf.item.id);
      }
    }
    _placedFurniture.removeWhere((pf) => pf.item.isFloor);
  }
}
