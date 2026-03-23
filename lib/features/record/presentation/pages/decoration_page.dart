import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../../domain/models/furniture.dart';
import '../../domain/models/furniture_data.dart';
import '../widgets/furniture_panel.dart';

class DecorationPage extends StatefulWidget {
  const DecorationPage({super.key});

  @override
  State<DecorationPage> createState() => _DecorationPageState();
}

class _DecorationPageState extends State<DecorationPage> {
  late ScrollController _scrollController;
  double _aspectRatio = 1.0;
  int? _selectedCol;
  int? _selectedRow;

  // 所有可用的家具项
  final List<FurnitureItem> _availableItems = FurnitureData.defaultItems;

  // 场景中已放置的家具
  final List<FurnitureInstance> _placedFurniture = [];

  // 拖拽相关状态
  bool _isPanelOpen = false;
  FurnitureInstance? _draggingInstance;
  Offset? _dragOffset;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _resolveImageSize();
    _loadFurnitureImages();

    // 默认在场景中放一个床作为初始演示
    _placedFurniture.add(FurnitureInstance(
      item: _availableItems.first,
      col: 10,
      row: 5,
    ));

    // 进入装修模式时强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 默认居中滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent / 2,
        );
      }
    });
  }

  Future<void> _loadFurnitureImages() async {
    for (var item in _availableItems) {
      item.image = await _loadUiImage(item.imagePath);
    }
    if (mounted) setState(() {});
  }

  Future<ui.Image> _loadUiImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _resolveImageSize() {
    const path = 'assets/images/decoration/furniture/house.png';
    final stream = const AssetImage(path).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _aspectRatio = info.image.width / info.image.height;
          });
        }
      }),
    );
  }

  Map<String, int>? _getGridFromPosition(Offset pos, Size size) {
    final layout = PerspectiveLayout(size);
    final yLines = layout.yLines;

    if (pos.dy < yLines.first || pos.dy > yLines.last) return null;

    // 1. 确定行
    int rowIdx = -1;
    for (int j = 0; j < yLines.length - 1; j++) {
      if (pos.dy >= yLines[j] && pos.dy < yLines[j + 1]) {
        rowIdx = j;
        break;
      }
    }
    if (rowIdx == -1) return null;

    // 2. 确定列
    final double t = layout.getTForY(pos.dy);
    final double tBack = layout.tBack;
    final double factor = (1.0 - t) / (1.0 - tBack);
    final double vpX = layout.vpX;

    double i;
    i = 38 * ((pos.dx - vpX) / t + vpX) / size.width;

    if (i >= 15) {
      final double C = size.width * 0.0015 * factor;
      final double nominator = pos.dx - vpX * (1 - t) - 14 * C;
      final double denominator = (t * size.width / 38.0) - C;
      if (denominator.abs() > 0.0001) {
        i = nominator / denominator;
      }
    }

    return {'col': (i.floor() - 2), 'row': rowIdx + 1};
  }

  void _handleTap(TapUpDetails details, Size size) {
    final res = _getGridFromPosition(details.localPosition, size);
    if (res == null) return;
    final int col = res['col']!;
    final int row = res['row']!;

    if (_isCellRemoved(col, row)) return;

    if (col >= 1 && col <= 55 && row >= 1 && row <= 10) {
      setState(() {
        if (_selectedCol == col && _selectedRow == row) {
          _selectedCol = null;
          _selectedRow = null;
        } else {
          _selectedCol = col;
          _selectedRow = row;
        }
      });
    }
  }

  Offset _getFurnitureScreenPos(Size size, FurnitureInstance instance) {
    final layout = PerspectiveLayout(size);
    final yLines = layout.yLines;

    final int rEnd = instance.row - 1 + instance.item.gridHeight;
    final double yFront = yLines[rEnd < yLines.length ? rEnd : yLines.length - 1];
    final double tFront = layout.getTForY(yFront);
    
    final int iStart = instance.col + 2;
    final int iEnd = iStart + instance.item.gridWidth;
    
    final double xFL = layout.getGridX(iStart.toDouble(), tFront);
    final double xFR = layout.getGridX(iEnd.toDouble(), tFront);

    return Offset((xFL + xFR) / 2, yFront);
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    final touch = details.localPosition;
    
    // 逆序遍历，这样点中重叠区域时优先选中上层（后添加的）家具
    for (var instance in _placedFurniture.reversed) {
      final pos = _getFurnitureScreenPos(size, instance);
      final double dist = (touch - pos).distance;
      if (dist < 100) {
        final res = _getGridFromPosition(touch, size);
        setState(() {
          _draggingInstance = instance;
          if (res != null) {
            _dragOffset = Offset(
              (res['col']! - instance.col).toDouble(),
              (res['row']! - instance.row).toDouble(),
            );
          } else {
            _dragOffset = Offset.zero;
          }
        });
        return; // 选中一个后立即退出
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_draggingInstance == null) return;

    final res = _getGridFromPosition(details.localPosition, size);
    if (res != null) {
      int targetCol = (res['col'] as int) - (_dragOffset?.dx.toInt() ?? 0);
      int targetRow = (res['row'] as int) - (_dragOffset?.dy.toInt() ?? 0);

      // 限制范围
      targetCol = targetCol.clamp(1, 55 - _draggingInstance!.item.gridWidth + 1);
      targetRow = targetRow.clamp(1, 10 - _draggingInstance!.item.gridHeight + 1);

      if (_draggingInstance!.col != targetCol || _draggingInstance!.row != targetRow) {
        setState(() {
          _draggingInstance!.col = targetCol;
          _draggingInstance!.row = targetRow;
        });
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _draggingInstance = null;
    });
  }

  bool _isCellRemoved(int col, int row) =>
      FloorGridPainter.checkGridRemoved(col, row);

  @override
  void dispose() {
    _scrollController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    const String bgPath = 'assets/images/decoration/furniture/house.png';

    return Scaffold(
      backgroundColor: isNight
          ? const Color(0xFF13131F)
          : const Color(0xFFD2B48C),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double currentScale = 1.4;
                final double h = constraints.maxHeight * currentScale;
                final double fullWidth = h * _aspectRatio;

                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(
                      details,
                      Size(fullWidth, constraints.maxHeight),
                    ),
                    onPanStart: (details) => _handlePanStart(
                      details,
                      Size(fullWidth, constraints.maxHeight),
                    ),
                    onPanUpdate: (details) => _handlePanUpdate(
                      details,
                      Size(fullWidth, constraints.maxHeight),
                    ),
                    onPanEnd: (details) => _handlePanEnd(details),
                    child: Stack(
                      children: [
                        Image.asset(
                          bgPath,
                          height: h,
                          width: fullWidth,
                          fit: BoxFit.cover,
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: FloorGridPainter(
                              selectedCol: _selectedCol,
                              selectedRow: _selectedRow,
                              placedFurniture: _placedFurniture,
                              isDraggingFurniture: _draggingInstance != null,
                              draggingCol: _draggingInstance?.col,
                              draggingRow: _draggingInstance?.row,
                              draggingWidth: _draggingInstance?.item.gridWidth,
                              draggingHeight: _draggingInstance?.item.gridHeight,
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
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => setState(() => _isPanelOpen = !_isPanelOpen),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPanelOpen ? Icons.chevron_right_rounded : Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isPanelOpen)
            FurniturePanel(
              availableItems: _availableItems,
              placedFurniture: _placedFurniture,
              onToggleItem: (item) {
                setState(() {
                  final bool isPlaced = _placedFurniture.any((e) => e.item.id == item.id);
                  if (isPlaced) {
                    _placedFurniture.removeWhere((e) => e.item.id == item.id);
                  } else {
                    _placedFurniture.add(FurnitureInstance(
                      item: item,
                      col: 21,
                      row: 1,
                    ));
                  }
                  _isPanelOpen = false;
                });
              },
            ),
        ],
      ),
    );
  }
}

class FloorGridPainter extends CustomPainter {
  final int? selectedCol;
  final int? selectedRow;
  final List<FurnitureInstance>? placedFurniture;
  final bool isDraggingFurniture;
  final int? draggingCol;
  final int? draggingRow;
  final int? draggingWidth;
  final int? draggingHeight;

  FloorGridPainter({
    this.selectedCol,
    this.selectedRow,
    this.placedFurniture,
    this.isDraggingFurniture = false,
    this.draggingCol,
    this.draggingRow,
    this.draggingWidth,
    this.draggingHeight,
  });

  static bool checkGridRemoved(int col, int row) {
    if (col <= 5 && row <= 5) return true;
    if (row == 6 && col <= 5) return true;
    if (col == 6 && row <= 4) return true;
    if (col == 1 && row >= 7 && row <= 10) return true;
    if (col == 4 && row == 7) return true;
    if (col == 5 && row >= 7 && row <= 8) return true;
    if (col == 25 && row <= 6) return true;
    if (col == 26 && row <= 5) return true;
    if (col == 27 && row <= 4) return true;
    if (col >= 28 && col <= 31 && row <= 3) return true;
    if (col == 29 && row >= 6 && row <= 8) return true;
    if (col == 30 && row >= 4 && row <= 7) return true;
    if (row <= 6 && col >= 31) return true;
    if (row == 7 && col >= 30) return true;
    if (row >= 8 && row <= 9 && col >= 37) return true;
    if (row == 10 && col >= 36) return true;
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final layout = PerspectiveLayout(size);
    final floorPath = _getFloorPath(layout);
    
    canvas.save();
    canvas.clipPath(floorPath);

    // 1. 绘制落点预览
    _drawPlacementPreview(canvas, layout);

    // 2. 绘制网格线
    _drawGridLines(canvas, layout);

    // 3. 绘制坐标标注
    _drawCoordinates(canvas, layout);

    canvas.restore();

    // 4. 绘制家具
    _drawFurniture(canvas, layout);
  }

  void _drawPlacementPreview(Canvas canvas, PerspectiveLayout layout) {
    if (draggingCol != null && draggingRow != null && draggingWidth != null && draggingHeight != null) {
      _drawGridHighlight(canvas, layout, draggingCol!, draggingRow!, draggingWidth!, draggingHeight!);
    } else if (selectedCol != null && selectedRow != null) {
      _drawGridHighlight(canvas, layout, selectedCol!, selectedRow!, 1, 1);
    }
  }

  void _drawGridLines(Canvas canvas, PerspectiveLayout layout) {
    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final yLines = layout.yLines;
    // 纵向线
    for (int i = 3; i <= 55; i++) {
      for (int rowIdx = 0; rowIdx < yLines.length - 1; rowIdx++) {
        final int visibleCol = i - 2;
        final int visibleRow = rowIdx + 1;
        bool shouldDraw = !checkGridRemoved(visibleCol, visibleRow);
        if (!shouldDraw && visibleCol > 1 && !checkGridRemoved(visibleCol - 1, visibleRow)) {
          shouldDraw = true;
        }
        if (shouldDraw) {
          final double yT = yLines[rowIdx];
          final double yB = yLines[rowIdx + 1];
          canvas.drawLine(
            Offset(layout.getGridX(i.toDouble(), layout.getTForY(yT)), yT),
            Offset(layout.getGridX(i.toDouble(), layout.getTForY(yB)), yB),
            gridPaint,
          );
        }
      }
    }
    // 水平线
    for (int rowIdx = 0; rowIdx < yLines.length; rowIdx++) {
      final double y = yLines[rowIdx];
      final double t = layout.getTForY(y);
      for (int i = 3; i < 55; i++) {
        final int visibleCol = i - 2;
        bool shouldDraw = (rowIdx < yLines.length - 1 && !checkGridRemoved(visibleCol, rowIdx + 1)) ||
                         (rowIdx > 0 && !checkGridRemoved(visibleCol, rowIdx));
        if (shouldDraw) {
          canvas.drawLine(
            Offset(layout.getGridX(i.toDouble(), t), y),
            Offset(layout.getGridX((i + 1).toDouble(), t), y),
            gridPaint,
          );
        }
      }
    }
  }

  void _drawCoordinates(Canvas canvas, PerspectiveLayout layout) {
    final textStyle = TextStyle(
      color: Colors.yellowAccent.withOpacity(0.8),
      fontSize: 8,
      fontWeight: FontWeight.bold,
    );
    final yLines = layout.yLines;
    for (int rowIdx = 0; rowIdx < yLines.length - 1; rowIdx++) {
      final double midY = (yLines[rowIdx] + yLines[rowIdx + 1]) / 2;
      final double tMid = layout.getTForY(midY);
      for (int i = 3; i < 55; i++) {
        final int visibleCol = i - 2;
        final int visibleRow = rowIdx + 1;
        if (checkGridRemoved(visibleCol, visibleRow)) continue;
        final double xL = layout.getGridX(i.toDouble(), tMid);
        final double xR = layout.getGridX((i + 1).toDouble(), tMid);
        final tp = TextPainter(
          text: TextSpan(text: '$visibleCol-$visibleRow', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset((xL + xR) / 2 - tp.width / 2, midY - tp.height / 2));
      }
    }
  }

  void _drawFurniture(Canvas canvas, PerspectiveLayout layout) {
    final instances = placedFurniture ?? [];
    for (var instance in instances) {
      final item = instance.item;
      if (item.image == null) continue;
      
      final int iStart = instance.col + 2;
      final int iEnd = iStart + item.gridWidth;
      final int rEnd = instance.row - 1 + item.gridHeight;

      if (rEnd >= 0 && rEnd < layout.yLines.length) {
        final double yFront = layout.yLines[rEnd];
        final double tFront = layout.getTForY(yFront);
        final double xFL = layout.getGridX(iStart.toDouble() + item.offsetX, tFront);
        final double xFR = layout.getGridX(iEnd.toDouble() + item.offsetX, tFront);

        final double drawWidth = (xFR - xFL).abs() * item.widthStretch;
        final double drawHeight = (drawWidth / item.widthStretch) * (item.image!.height / item.image!.width) * item.heightStretch;
        final double opacity = isDraggingFurniture ? 0.7 : 1.0;

        canvas.drawImageRect(
          item.image!,
          Rect.fromLTWH(0, 0, item.image!.width.toDouble(), item.image!.height.toDouble()),
          Rect.fromLTWH((xFL + xFR) / 2 - drawWidth / 2, yFront - drawHeight, drawWidth, drawHeight),
          Paint()..filterQuality = FilterQuality.high..color = Colors.white.withOpacity(opacity),
        );
      }
    }
  }

  void _drawGridHighlight(Canvas canvas, PerspectiveLayout layout, int col, int row, int width, int height) {
    final int iStart = col + 2;
    final int iEnd = iStart + width;
    final int rTIdx = row - 1;
    final int rBIdx = rTIdx + height;

    if (rTIdx >= 0 && rBIdx < layout.yLines.length) {
      final double yT = layout.yLines[rTIdx];
      final double yB = layout.yLines[rBIdx];
      final double tT = layout.getTForY(yT);
      final double tB = layout.getTForY(yB);

      final p1 = Offset(layout.getGridX(iStart.toDouble(), tT), yT);
      final p2 = Offset(layout.getGridX(iEnd.toDouble(), tT), yT);
      final p3 = Offset(layout.getGridX(iEnd.toDouble(), tB), yB);
      final p4 = Offset(layout.getGridX(iStart.toDouble(), tB), yB);

      canvas.drawPath(
        Path()..addPolygon([p1, p2, p3, p4], true),
        Paint()..color = Colors.cyanAccent.withOpacity(0.3)..style = PaintingStyle.fill,
      );
    }
  }

  Path _getFloorPath(PerspectiveLayout layout) {
    final path = Path();
    final size = layout.size;
    final w = size.width;
    final h = size.height;
    final floorTop = layout.yLines[0]; // 这里简化了，直接取 grid 的顶线作为裁剪参考

    path.moveTo(0, h);
    path.lineTo(0, h * 0.92);
    path.lineTo(w * 0.15, h * 0.85);
    path.lineTo(w * 0.15, h * 0.75);
    path.lineTo(w * 0.0, h * 0.70);
    path.lineTo(w * 0.32, floorTop);
    path.lineTo(w * 0.98, floorTop);
    path.lineTo(w * 0.98, h * 0.95);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant FloorGridPainter oldDelegate) {
    try {
      return oldDelegate.selectedCol != selectedCol ||
          oldDelegate.selectedRow != selectedRow ||
          oldDelegate.placedFurniture != placedFurniture ||
          oldDelegate.isDraggingFurniture != isDraggingFurniture ||
          oldDelegate.draggingCol != draggingCol ||
          oldDelegate.draggingRow != draggingRow;
    } catch (_) {
      return true;
    }
  }
}


class PerspectiveLayout {
  final Size size;
  late final double vpX;
  late final double vpY;
  late final double tBack;
  late final List<double> yLines;

  PerspectiveLayout(this.size) {
    vpX = size.width * 0.5;
    vpY = size.height * 0.35;
    
    double currentY = size.height * 0.59;
    double step = (size.height - currentY) * 0.05;
    for (int i = 0; i < 2; i++) {
      currentY += step;
      step *= 1.25;
    }
    tBack = (currentY - vpY) / (size.height - vpY);

    yLines = [];
    double tempY = currentY;
    double tempStep = (size.height - currentY) * 0.032;
    for (int r = 0; r <= 10; r++) {
      yLines.add(tempY);
      tempY += tempStep;
      tempStep *= 1.25;
    }
  }

  double getGridX(double i, double t) {
    double bottomX = size.width * (i / 38);
    double x = vpX + t * (bottomX - vpX);
    if (i >= 15) {
      double factor = (1.0 - t) / (1.0 - tBack);
      x -= (i - 14) * size.width * 0.0015 * factor;
    }
    return x;
  }

  double getTForY(double y) => (y - vpY) / (size.height - vpY);
}
