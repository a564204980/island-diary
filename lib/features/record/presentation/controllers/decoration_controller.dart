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
  // --- 鏍稿績瀹跺叿鏁版嵁 ---
  final List<PlacedFurniture> _placedFurniture = [];
  List<PlacedFurniture> get placedFurniture =>
      List.unmodifiable(_placedFurniture);

  late List<FurnitureItem> _availableItems;
  List<FurnitureItem> get availableItems => _availableItems;

  String selectedCategory = '鍘ㄦ埧';
  String? selectedSubCategory;

  // --- 浜や簰涓庨€夋嫨鐘舵€?---
  (int, int)? selectedCell;
  (int, int)? ghostCell;
  FurnitureItem? draggingItem;
  int draggingRotation = 0;
  double ghostZ = 0.0;
  PlacedFurniture? selectedFurniture;

  // 杩炶疮鎷栨嫿鐩稿叧
  bool isLongPressDragging = false;
  PlacedFurniture? originalFurnitureData;
  PlacedFurniture? draggingOriginalPF;

  // 鏋滃喕寮硅烦鍔ㄧ敾鐩稿叧
  AnimationController? _bounceController;
  Animation<double>? _bounceAnimation;
  PlacedFurniture? bouncingFurniture;
  double get bounceScale => _bounceAnimation?.value ?? 1.0;

  // --- 鍦烘櫙鎺у埗 ---
  double currentScale = 0.4;
  Offset sceneOffset = const Offset(-120, 0);
  bool isInteracting = false;
  bool showGrid = true;
  bool isCapturingSnapshot = false;
  bool isInitializing = true;
  double loadingProgress = 0.0;

  // --- 澧欓潰棰滆壊鎺у埗 ---
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
      );
    }).toList();

    // 鍔犺浇宸蹭繚瀛樼殑瀹跺叿甯冨眬
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

    // 棰勫姞杞藉繀闇€璧勬簮
    _preloadAssets(context);
  }

  Future<void> _preloadAssets(BuildContext context) async {
    isInitializing = true;
    loadingProgress = 0.0;
    notifyListeners();

    // 1. 纭畾闇€瑕佷紭鍏堝姞杞界殑璧勬簮锛堝凡鎽嗘斁鐨勫鍏?+ 褰撳墠鍒嗙被鐨勫墠鍑犱釜锛?
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

    // 鎸夐『搴忛€愪釜鍔犺浇璧勬簮锛屽噺灏戝唴瀛樺嘲鍊煎苟璁╄繘搴︽洿鏂版洿骞虫粦
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

      // 缁?UI 绾跨▼鍠樻伅鐨勬満浼氾紝纭繚杩涘害鏉℃枃瀛楄兘娓叉煋鍑烘潵
      await Future.delayed(Duration.zero);
    }

    // 棰濆鐨勫皬寤惰繜纭繚 UI 骞虫粦杩囨浮
    await Future.delayed(const Duration(milliseconds: 300));
    // 鍔犺浇澧欓潰棰滆壊
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

  // --- 鏍稿績涓氬姟閫昏緫 ---

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

  double dragZOffset = 0.0; // 璁板綍鎷栨嫿寮€濮嬫椂鎵嬫寚涓庣墿鍝佸簳搴х殑 Z 杞村亸绉?

  void updateDragPosition(
    Offset localPos,
    IsometricCoordinateConverter converter, {
    bool isFirstFrame = false,
  }) {
    if (draggingItem == null) return;

    if (draggingItem!.isWall) {
      // 绛夎酱娴嬪潗鏍囩郴涓紝宸﹀(XZ闈?r杞?鍦ㄨ瑙変笂浣嶄簬灞忓箷鍙充晶锛屽彸澧?YZ闈?c杞?鍦ㄨ瑙変笂浣嶄簬灞忓箷宸︿晶
      // 鍥犳鎵嬫寚鍦ㄥ睆骞曞彸渚?> centerX)鏃舵墠鏄?preferLeft
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

      // 濡傛灉鏄涓€甯э紙鍒氭姄璧凤級锛屽垵濮嬪寲鍋忕Щ閲?
      if (isFirstFrame) {
        dragZOffset = ghostZ - touchZ;
      }

      final double maxAllowedZ = (kWallGridHeight - draggingItem!.gridH)
          .toDouble();
      ghostZ = (touchZ + dragZOffset).clamp(0.0, maxAllowedZ).roundToDouble();

      final int gw = draggingItem!.gridW;
      (int, int) centeredCell = useLeftWall
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
        int gw = draggingRotation % 2 == 0
            ? draggingItem!.gridW
            : draggingItem!.gridH;
        int gh = draggingRotation % 2 == 0
            ? draggingItem!.gridH
            : draggingItem!.gridW;
        final centeredCell = (
          (cell.$1 - (gw / 2).floor()).clamp(0, kGridRows - gw),
          (cell.$2 - (gh / 2).floor()).clamp(0, kGridCols - gh),
        );
        // --- 闈犲瀹跺叿鍔ㄦ€侀珮搴﹀惛闄勯€昏緫 (鏁版嵁椹卞姩) ---
        double targetZ = 0.0;

        // 鍙湁楗板搧銆佽蒋瑁呫€佺泦鏍界瓑瑁呴グ绫荤墿浠惰Е鍙戞閫昏緫
        bool isDecoration =
            draggingItem!.category == '瑁呴グ' ||
            draggingItem!.subCategory == '杞' ||
            draggingItem!.subCategory == '楗板搧' ||
            draggingItem!.subCategory == '鐩嗘牻';

        if (isDecoration) {
          double foundSurfaceZ = 0.0;
          for (final pf in _placedFurniture) {
            // 蹇界暐鍦版澘銆佸澹佷互鍙婅嚜韬?
            if (pf.item.isFloor || pf.item.isWall || pf == draggingOriginalPF)
              continue;

            int pgw = pf.rotation % 2 == 0 ? pf.item.gridW : pf.item.gridH;
            int pgh = pf.rotation % 2 == 0 ? pf.item.gridH : pf.item.gridW;

            // 纰版挒妫€娴嬶細褰撳墠鐗╁搧鏍兼槸鍚﹀湪瀹跺叿鍗犱綅鍐?
            if (centeredCell.$1 < pf.r + pgw &&
                centeredCell.$1 + gw > pf.r &&
                centeredCell.$2 < pf.c + pgh &&
                centeredCell.$2 + gh > pf.c) {
              // 鍏抽敭鍒ゆ柇锛氳瀹跺叿鏄惁闈犲 (r=0 鎴?c=0)
              if (pf.r == 0 || pf.c == 0) {
                // 浠庨厤缃〃涓幏鍙栬瀹跺叿鐨勮〃闈㈤珮搴?
                final height = _furnitureSurfaceHeights[pf.item.id] ?? 0.0;
                if (height > foundSurfaceZ) {
                  foundSurfaceZ = height;
                }
              }
            }
          }
          targetZ = foundSurfaceZ;
        }

        double oldZ = ghostZ;
        ghostZ = targetZ;

        if (centeredCell != ghostCell) {
          ghostCell = centeredCell;
          isInteracting = true;
          notifyListeners();
        } else if (targetZ != oldZ) {
          // 濡傛灉浣嶇疆娌″彉浣嗛珮搴﹀彉浜嗭紙杩涘叆/绂诲紑涓嶅悓楂樺害瀹跺叿鍖哄煙锛夛紝涔熻閫氱煡閲嶇粯
          notifyListeners();
        }
      }
    }
  }

  // --- 瀹跺叿琛ㄩ潰楂樺害閰嶇疆琛?---
  static const Map<String, double> _furnitureSurfaceHeights = {
    'cabinet_1': 4.0, // 姗辨煖
    'table_1': 2.2, // 妗屽瓙 1
    'table_2': 2.2, // 妗屽瓙 2
    'table_3': 1.8, // 妗屽瓙 3 (杈冪煯)
    'sofa_1': 1.2, // 娌欏彂
    'sofa_2': 1.2,
    'sofa_3': 1.2,
    'sofa_4': 1.2,
    'bookcase_1': 3.0, // 涔︽煖鍙伴潰
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

    // 瑙﹀彂鏋滃喕寮硅烦鍚搁檮鍔ㄧ敾
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

    // 鑾峰彇褰撳墠鍗犲湴瀹介珮 (鐢?isAreaAvailable 鍐呴儴閫昏緫鎺ㄥ鍑?
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

    // 鑾峰彇鏃嬭浆鍚庣殑鍗犲湴瀹介珮
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
      // 澧欓潰鎸備欢锛氬垏鎹㈠闈㈤€昏緫
      // Rotation index: 0(宸?, 1(鍙?, 2(宸?鑳?, 3(鍙?鑳?
      if (oldRotation % 2 == 0 && nextRotation % 2 != 0) {
        // 浠庡乏澧欏彉鍙冲: (r, 0) -> (0, r)
        nr = 0;
        nc = pf.r;
      } else if (oldRotation % 2 != 0 && nextRotation % 2 == 0) {
        // 浠庡彸澧欏彉宸﹀: (0, c) -> (c, 0)
        nr = pf.c;
        nc = 0;
      }
    } else {
      // 鍦伴潰鐗╁搧锛氬熀浜庨噸蹇冪殑鏃嬭浆閫昏緫
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
    // 1. 灏嗘墍鏈夌幇鏈夌殑鍦版澘褰掕繕搴撳瓨
    for (var pf in _placedFurniture.where((pf) => pf.item.isFloor)) {
      pf.item.quantity++;
    }
    // 2. 绉婚櫎鎵€鏈夊湴鏉?
    _placedFurniture.removeWhere((pf) => pf.item.isFloor);

    // 3. 璁＄畻閾烘弧闇€瑕佺殑琛屽垪鏁?
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
        // 濡傛灉姝ｅ湪鏀剧疆鐨勬槸鍦版锛岃€屽鏂规槸鏅€氬鍏凤紙闈炲湴鏉裤€侀潪鍦版锛夛紝鍒欒烦杩囩鎾?
        if (item.subCategory == '鍦版' &&
            !pf.item.isFloor &&
            pf.item.subCategory != '鍦版') {
          continue;
        }
        // 濡傛灉瀵规柟鏄湴姣紝鑰屾垜浠瑕佹斁缃殑鏄櫘閫氬鍏凤紝涔熻烦杩囨娴嬶紝璁╁湴姣竴鐩村彲浠ヨ鍘嬬潃
        if (pf.item.subCategory == '鍦版' &&
            !item.isFloor &&
            item.subCategory != '鍦版') {
          continue;
        }

        // [淇] 濡傛灉鏀剧殑鏄€滈グ鍝?瑁呴グ鈥濇垨鈥滆蒋瑁呪€濓紝鍒欏厑璁镐笌闄ゅ湴鏉垮鐨勪换浣曞鍏凤紙鍖呮嫭鍏朵粬楗板搧锛夐噸鍙?
        bool isDecorator = item.category == '瑁呴グ' || item.subCategory == '杞';
        bool isExistingDecorator =
            pf.item.category == '瑁呴グ' || pf.item.subCategory == '杞';

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
        // 1. 鍩虹鍒嗙被浼樺厛绾э細澧欓潰 > 鍦伴潰 (瀹跺叿/瑁呴グ) > 鍦版澘
        if (a.item.isWall != b.item.isWall) return a.item.isWall ? -1 : 1;
        if (a.item.isFloor != b.item.isFloor) return a.item.isFloor ? 1 : -1;

        // 2. 杞/楗板搧锛堥€氬父鍦ㄤ笂鏂癸級鍏锋湁鏇撮珮鐐瑰嚮浼樺厛绾?
        bool aIsSoft = a.item.subCategory == '杞' || a.item.category == '瑁呴グ';
        bool bIsSoft = b.item.subCategory == '杞' || b.item.category == '瑁呴グ';
        if (aIsSoft != bIsSoft) return aIsSoft ? -1 : 1;

        // 3. 鏍稿績鎺掑簭锛氱敱杩戝強杩?(Front-to-Back)
        // 鍦ㄧ瓑杞翠晶鎶曞奖涓紝r+c 杈冨ぇ浠ｈ〃鐗╀綋鏇撮潬杩戣瀵熻€咃紝搴斾紭鍏堟娴?
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;

        // 濡傛灉 a 涓ユ牸鍦?b 鐨勫墠鏂癸紝鍒?a 浼樺厛
        if (a.r >= b.r + gwB || a.c >= b.c + ghB) return -1;
        // 濡傛灉 b 涓ユ牸鍦?a 鐨勫墠鏂癸紝鍒?b 浼樺厛
        if (b.r >= a.r + gwA || b.c >= a.c + ghA) return 1;

        // 4. 閲嶅彔鎯呭喌涓嬬殑缁嗚妭鍒ゅ畾 (楂樺害銆佷綅缃?
        // 濡傛灉鍦ㄥ悓涓€鏍兼垨閲嶅彔锛孼 杞达紙楂樺害锛夊ぇ鐨勪紭鍏?
        if (a.z != b.z) return b.z.compareTo(a.z);

        // 鏈€鍚庢牴鎹綉鏍间腑蹇冩繁搴﹂檷搴忔帓鍒?
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
        final bool isFlipped = pf.rotation == 1; // 鏃嬭浆 1 娆′唬琛?180 搴︾炕杞?
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
          // 鐭╁舰鍖哄煙鍐咃紝杩涗竴姝ユ娴嬪儚绱犻€忔槑搴?
          final double dx = localPos.dx - rect.left;
          final double dy = localPos.dy - rect.top;

          // 1. 鐢ㄧ煩褰㈠疄闄呭昂瀵镐笌 intrinsic 灏哄鐨勬瘮渚嬫潵鏄犲皠锛?
          //    涓嶈兘鐢?visualScale 闄わ紝鍥犱负 rect 鐨勫疄闄呭楂樼敱 estimateVisualWidth
          //    鎺ㄥ锛堝彈 tw銆乬ridW銆乬ridH銆乼aper 褰卞搷锛夛紝涓?intrinsicWidth * visualScale 涓嶇瓑銆?
          double ix = dx * pf.item.intrinsicWidth / rect.width;
          double iy = dy * pf.item.intrinsicHeight / rect.height;

          // 2. 澶勭悊闀滃儚鍙嶈浆锛坮otation==1 鏃跺浘鍍忔按骞崇炕杞級
          if (isFlipped) {
            ix = pf.item.intrinsicWidth - ix;
          }

          // 3. 鏄犲皠鍒板浘鐗囩湡瀹炲垎杈ㄧ巼
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
            // 濡傛灉鍥剧墖杩樻病鍔犺浇瀹岋紝鍥為€€鍒扮煩褰㈡娴?
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
