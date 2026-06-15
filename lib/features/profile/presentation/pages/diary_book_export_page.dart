import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:island_diary/features/profile/presentation/pages/export/widgets/exporting_dialog.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/profile/presentation/pages/export/models/export_models.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_radar_chart.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_trend_chart.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_weekly_chart.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_palette_chart.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_mood_flow_chart.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_heatmap_chart.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/redbook_asset_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/image_group_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

part 'export/parts/export_canvas.dart';
part 'export/parts/export_panels.dart';


// --- 主页面实现 ---

class DiaryBookExportPage extends StatefulWidget {
  final DiaryBook book;
  final List<DiaryEntry> diaries;

  const DiaryBookExportPage({
    super.key,
    required this.book,
    required this.diaries,
  });

  @override
  State<DiaryBookExportPage> createState() => _DiaryBookExportPageState();
}

class _DiaryBookExportPageState extends State<DiaryBookExportPage> with TickerProviderStateMixin {
  void updateState(VoidCallback fn) => mounted ? setState(fn) : fn();

  // 核心设计状态
  ExportPageSize _pageSize = ExportPageSize.presets[0];
  bool _isLandscape = false; // 是否横向
  final ExportPageMargin _margin = ExportPageMargin();
  final ExportBackgroundSettings _bgSettings = ExportBackgroundSettings();
  List<ExportElement> _elements = [];
  final ExportSettings _exportSettings = ExportSettings();

  // 历史栈，用于撤销/重做
  final List<List<ExportElement>> _undoStack = [];
  final List<List<ExportElement>> _redoStack = [];

  // 编辑交互状态
  String? _selectedElementId;
  String? _editingElementId;
  String? _activeHandle;
  final FocusNode _inlineFocusNode = FocusNode();
  int _activeTabIndex = 0; // 0:页面, 1:背景, 2:添加, 3:属性, 4:图层, 5:导出
  bool _isZoomScaleInitialized = false; // 是否已经根据容器尺寸初始化了缩放比例
  final TransformationController _transformationController = TransformationController();

  // 图表预渲染用 GlobalKey（Offstage + RepaintBoundary 截图）
  final GlobalKey _chartKeyRadar    = GlobalKey();
  final GlobalKey _chartKeyTrend    = GlobalKey();
  final GlobalKey _chartKeyWeekly   = GlobalKey();
  final GlobalKey _chartKeyPalette  = GlobalKey();
  final GlobalKey _chartKeyMoodFlow = GlobalKey();
  final GlobalKey _chartKeyHeatmap  = GlobalKey();

  // 临时挂载的待截图图表组件
  Widget? _capturingChartWidget;

  AnimationController? _matrixAnimationController;
  Animation<Matrix4>? _matrixAnimation;
  BoxConstraints? _lastConstraints;
  late TextEditingController _textEditorController;

  void _animateMatrixTo(Matrix4 targetMatrix) {
    _matrixAnimationController?.dispose();
    _matrixAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    
    final Matrix4 startMatrix = _transformationController.value;
    
    _matrixAnimation = Matrix4Tween(
      begin: startMatrix,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _matrixAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(() {
        _transformationController.value = _matrixAnimation!.value;
      });
      
    _matrixAnimationController!.forward();
  }

  void _recenterCanvas({bool animate = true}) {
    final constraints = _lastConstraints;
    if (constraints == null) return;
    
    const padding = 32.0;
    final targetWidth = constraints.maxWidth - padding;
    final scale = targetWidth / _canvasWidth;
    
    final dx = (constraints.maxWidth - _canvasWidth * scale) / 2;
    final dy = 16.0;
    
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
      
    if (animate) {
      _animateMatrixTo(targetMatrix);
    } else {
      _transformationController.value = targetMatrix;
    }
  }

  void _selectElement(String? id) {
    setState(() {
      if (_editingElementId != null) {
        _inlineFocusNode.unfocus();
        _editingElementId = null;
      }
      _selectedElementId = id;
      if (id != null) {
        final idx = _elements.indexWhere((e) => e.id == id);
        if (idx != -1) {
          _textEditorController.text = _elements[idx].content;
        }
      }
    });
  }

  void _showImageEditDialog(ExportElement element) {
    final controller = TextEditingController(text: element.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('编辑图片链接', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '图片链接 (URL)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _saveToHistory();
              setState(() {
                element.content = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _matrixAnimationController?.dispose();
    _textEditorController.dispose();
    _inlineFocusNode.dispose();
    super.dispose();
  }



  @override
  void initState() {
    super.initState();
    _textEditorController = TextEditingController();
    _inlineFocusNode.addListener(() {
      if (!_inlineFocusNode.hasFocus) {
        setState(() {
          _editingElementId = null;
        });
      }
    });
    _exportSettings.fileName = '${widget.book.name}_导出';
    _initDefaultElements();
  }

  // 初始化默认放入一些精美的占位元素，基于用户日记，起点和宽度与页边距联动
  void _initDefaultElements() {
    _elements = [
      ExportElement(
        id: 'title',
        type: 'text',
        x: _margin.left,
        y: _margin.top + 20,
        width: 250.0,
        height: 60,
        content: widget.book.name,
        fontSize: 28,
        color: const Color(0xFF2C3E50),
      ),
      ExportElement(
        id: 'subtitle',
        type: 'text',
        x: _margin.left,
        y: _margin.top + 80,
        width: 280.0,
        height: 35,
        content: '—— 属于我的海岛生活日记书',
        fontSize: 16,
        color: Colors.grey[600]!,
      ),
      ExportElement(
        id: 'divider',
        type: 'line',
        x: _margin.left,
        y: _margin.top + 120,
        width: _canvasWidth - _margin.left - _margin.right,
        height: 2,
        content: 'solid',
        color: const Color(0xFFBDC3C7),
      ),
    ];

    // 如果有日记，把第一篇日记的内容精简放上去，并自动把日记内的插图也加载进来
    if (widget.diaries.isNotEmpty) {
      final firstDiary = widget.diaries.first;
      final firstTitle = firstDiary.title;
      _elements.add(
        ExportElement(
          id: 'diary_title',
          type: 'text',
          x: _margin.left,
          y: _margin.top + 160,
          width: 200.0,
          height: 40,
          content: (firstTitle != null && firstTitle.isNotEmpty)
              ? firstTitle
              : '第一章：启程的岛屿',
          fontSize: 20,
          color: const Color(0xFF34495E),
        ),
      );
      
      final firstContent = firstDiary.content;
      _elements.add(
        ExportElement(
          id: 'diary_content',
          type: 'text',
          x: _margin.left,
          y: _margin.top + 210,
          width: _canvasWidth - _margin.left - _margin.right,
          height: 250,
          content: firstContent.isNotEmpty
              ? (firstContent.length > 250 
                  ? '${firstContent.substring(0, 250)}...' 
                  : firstContent)
              : '今天天气晴朗，微风徐徐。小岛的清晨总是如此宁静，蔚蓝的海浪轻轻拍打着沙滩。我漫步在林间小道上，呼吸着新鲜空气，仿佛所有的烦恼都随风消逝了...',
          fontSize: 15,
          color: Colors.black87,
        ),
      );

      // 解析日记的 blocks 数据
      final List<DiaryBlock> diaryBlocks = firstDiary.blocks.map((b) => DiaryBlock.fromMap(b)).toList();
      double currentY = _margin.top + 480;
      double currentX = _margin.left;
      final double availableWidth = _canvasWidth - _margin.left - _margin.right;
      final double colWidth = (availableWidth - 16) / 2; // 双列排版，间距 16

      for (var block in diaryBlocks) {
        if (block is ImageBlock) {
          _elements.add(
            ExportElement(
              id: 'diary_image_${block.id}',
              type: 'image',
              x: currentX,
              y: currentY,
              width: colWidth,
              height: colWidth,
              content: block.file.path,
            ),
          );
          if (currentX == _margin.left) {
            currentX = _margin.left + colWidth + 16;
          } else {
            currentX = _margin.left;
            currentY += colWidth + 16;
          }
        } else if (block is ImageGroupBlock) {
          for (var img in block.images) {
            _elements.add(
              ExportElement(
                id: 'diary_image_${img.id}',
                type: 'image',
                x: currentX,
                y: currentY,
                width: colWidth,
                height: colWidth,
                content: img.file.path,
              ),
            );
            if (currentX == _margin.left) {
              currentX = _margin.left + colWidth + 16;
            } else {
              currentX = _margin.left;
              currentY += colWidth + 16;
            }
          }
        }
      }
    }

    // 针对短文本元素自适应测量实际文字宽度以紧贴文本内容
    for (var element in _elements) {
      if (element.type == 'text' && element.id != 'diary_content') {
        _adjustTextElementWidth(element);
      }
    }
  }

  // 根据当前滑动的页边距，动态同步更新系统默认排版元素的位置和宽度
  void _updateElementsMargin() {
    setState(() {
      for (var element in _elements) {
        // 联动 X 坐标与宽度
        if (element.id == 'divider' || element.id == 'diary_content') {
          element.x = _margin.left;
          element.width = (_canvasWidth - _margin.left - _margin.right).clamp(50.0, _canvasWidth);
        } else if (element.id == 'title' ||
            element.id == 'subtitle' ||
            element.id == 'diary_title') {
          element.x = _margin.left;
          final maxAllowedWidth = _canvasWidth - _margin.left - _margin.right;
          if (element.width > maxAllowedWidth) {
            element.width = maxAllowedWidth.clamp(50.0, _canvasWidth);
          }
        }

        // 联动 Y 坐标
        if (element.id == 'title') {
          element.y = _margin.top + 20;
        } else if (element.id == 'subtitle') {
          element.y = _margin.top + 80;
        } else if (element.id == 'divider') {
          element.y = _margin.top + 120;
        } else if (element.id == 'diary_title') {
          element.y = _margin.top + 160;
        } else if (element.id == 'diary_content') {
          element.y = _margin.top + 210;
        }
      }
    });
  }

  // 放大或缩小预览画面矩阵
  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double newScale = (currentScale * factor).clamp(0.2, 3.0);
    final double finalFactor = newScale / currentScale;
    setState(() {
      _transformationController.value = matrix..scaleByDouble(finalFactor, finalFactor, 1.0, 1.0);
    });
  }

  // 保存历史状态用于撤销
  void _saveToHistory() {
    _undoStack.add(_elements.map((e) => e.copy()).toList());
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _redoStack.add(_elements.map((e) => e.copy()).toList());
        _elements = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(_elements.map((e) => e.copy()).toList());
        _elements = _redoStack.removeLast();
      });
    }
  }

  // 获取当前编辑画布的实际像素宽度和高度，与印刷纸张尺寸规格动态绑定
  double get _canvasWidth => _isLandscape ? _pageSize.height : _pageSize.width;
  double get _canvasHeight => _isLandscape ? _pageSize.width : _pageSize.height;

  // 截图某个预渲染图表，返回临时文件路径
  Future<String?> _captureChart(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('图表截图失败: $e');
      return null;
    }
  }

  void _adjustTextElementWidth(ExportElement element) {
    if (element.type != 'text') return;
    final textStyle = TextStyle(
      fontSize: element.fontSize,
      fontFamily: element.fontFamily == '系统内置' ? 'LXGWWenKai' : element.fontFamily,
      fontWeight: element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: element.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      letterSpacing: element.letterSpacing,
      height: element.lineHeight,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: element.content, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _canvasWidth - _margin.left - _margin.right);
    // 额外留出 16dp 容错间距
    element.width = (textPainter.width + 16.0).clamp(50.0, _canvasWidth - _margin.left - _margin.right);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5A3E28), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '导出设计器',
          style: TextStyle(
            color: Color(0xFF5A3E28),
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'LXGWWenKai',
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设计模板保存成功！', style: TextStyle(fontFamily: 'LXGWWenKai')),
                  backgroundColor: Color(0xFF5A3E28),
                ),
              );
            },
            child: const Text(
              '保存模板',
              style: TextStyle(
                color: Color(0xFF8A6C5C),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6E5540), Color(0xFF4A3423)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A3423).withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showExportDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Text(
                        '导出 PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 离屏预渲染区：将待截图的图表 Widget 动态渲染到真实 RenderTree 中并置于屏幕外以确保 Paint 执行，避免 !debugNeedsPaint 错误
          if (_capturingChartWidget != null)
            Positioned(
              left: -9999,
              top: -9999,
              child: _capturingChartWidget!,
            ),
          Stack(
            children: [
              // 1. 画布及浮动手势工具区域
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _selectElement(null);
                  },
                  child: Container(
                    color: const Color(0xFFEAE7E4),
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _lastConstraints = constraints;
                        if (!_isZoomScaleInitialized) {
                          // 自动计算初始最佳充满宽度比例，留出左右各 16dp 的边距（共 32dp）
                          const padding = 32.0;
                          final targetWidth = constraints.maxWidth - padding;
                          final scale = targetWidth / _canvasWidth;
                          
                          // 动态计算平移量，实现水平和垂直的绝对居中对齐
                          final dx = (constraints.maxWidth - _canvasWidth * scale) / 2;
                          final dy = 16.0;
                          
                          // 初始化 TransformationController 矩阵值（带平移补偿）
                          _transformationController.value = Matrix4.identity()
                            ..translateByDouble(dx, dy, 0.0, 1.0)
                            ..scaleByDouble(scale, scale, 1.0, 1.0);
                          _isZoomScaleInitialized = true;
                        }

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.1,
                          maxScale: 3.0,
                          constrained: false, // 解锁视口高度约束，使 A4/A5 纸张恢复其原本真实的物理比例
                          boundaryMargin: const EdgeInsets.all(800.0), // 留出充足的边界以供拖拽
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                              width: _canvasWidth,
                              height: _canvasHeight,
                              child: _buildCanvas(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 2. 浮动悬浮工具栏 (定位在配置面板上方)
              Positioned(
                bottom: 220 + 68 + MediaQuery.of(context).padding.bottom + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildQuickToolbar(),
                ),
              ),
              // 3. 底部配置面板区 (层叠覆盖在最上层)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomPanel(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
