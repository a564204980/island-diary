import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
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
import 'package:island_diary/shared/widgets/custom_color_picker_sheet.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:island_diary/shared/widgets/top_toast.dart';

part 'export/parts/export_elements_logic.dart';
part 'export/parts/export_template_logic.dart';
part 'export/parts/export_history_logic.dart';
part 'export/parts/export_layout_logic.dart';
part 'export/parts/export_canvas.dart';
part 'export/parts/export_canvas_bg_layer.dart';
part 'export/parts/export_canvas_gesture.dart';
part 'export/parts/export_canvas_render.dart';
part 'export/parts/export_canvas_toolbar.dart';
part 'export/parts/export_panels.dart';
part 'export/parts/export_panel_page.dart';
part 'export/parts/export_panel_background.dart';
part 'export/parts/export_panel_add.dart';
part 'export/parts/export_panel_properties.dart';
part 'export/parts/export_panel_layers.dart';
part 'export/parts/export_panel_export.dart';


// --- 主页面实现 ---

class RichTextEditingController extends TextEditingController {
  final InlineSpan Function(String text, TextStyle style) buildRichTextSpan;

  RichTextEditingController({
    super.text,
    required this.buildRichTextSpan,
  });

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    return buildRichTextSpan(text, style ?? const TextStyle()) as TextSpan;
  }
}

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
  Widget? _canvasSubtreeCache;
  final ValueNotifier<int> _canvasRefreshTrigger = ValueNotifier<int>(0);
  List<Widget>? _cachedBackgroundWidgets;

  // 专门用于通知「选中元素 + 面板展开」变化，避免 setState 全量重建
  final ValueNotifier<String?> _selectionNotifier = ValueNotifier<String?>(null);
  // 面板展开状态通知器（isPanelExpanded + activeTabIndex打包通知）
  final ValueNotifier<(bool, int)> _panelStateNotifier = ValueNotifier<(bool, int)>((false, 0));

  void updateState(VoidCallback fn) {
    fn();
    _canvasRefreshTrigger.value++;
    Future.microtask(() {
      if (mounted) {
        _selectionNotifier.value = _selectedElementId; // 通知属性面板刷新
        _panelStateNotifier.value = (_isPanelExpanded, _activeTabIndex);
      }
    });
    if (mounted) setState(() {});
  }

  void updateCanvasState(VoidCallback fn) {
    fn();
    _canvasRefreshTrigger.value++;
    // 通知属性面板刷新XY坐标
    Future.microtask(() {
      if (mounted) {
        _selectionNotifier.value = _selectedElementId;
      }
    });
  }

  void updateStateAndBackground(VoidCallback fn) {
    fn();
    _cachedBackgroundWidgets = null;
    _canvasRefreshTrigger.value++;
    if (mounted) setState(() {});
  }

  // 核心设计状态
  ExportPageSize _pageSize = ExportPageSize.presets[0];
  bool _isLandscape = false; // 是否横向
  final ExportPageMargin _margin = ExportPageMargin();
  final Map<int, ExportBackgroundSettings> _pageBgSettings = {};
  ExportBackgroundSettings get _bgSettings => getBgSettingsForPage(_focusedPageIndex);

  ExportBackgroundSettings getBgSettingsForPage(int pageIndex) {
    return _pageBgSettings.putIfAbsent(pageIndex, () => ExportBackgroundSettings());
  }
  List<ExportElement> _elements = [];
  final ExportSettings _exportSettings = ExportSettings();

  // 历史栈，用于撤销/重做
  final List<List<ExportElement>> _undoStack = [];
  final List<List<ExportElement>> _redoStack = [];

  // 编辑交互状态
  String? _selectedElementId;
  String? _editingElementId;
  String? _activeHandle;
  double _dragX = 0.0;
  double _dragY = 0.0;
  final List<double> _vGuidelines = [];
  final List<double> _hGuidelines = [];
  final FocusNode _inlineFocusNode = FocusNode();
  int _activeTabIndex = 0; // 0:页面, 1:背景, 2:添加, 3:属性, 4:图层, 5:导出
  bool _isPanelExpanded = false; // 面板是否展开，默认收起
  int _focusedPageIndex = 0; // 当前选中的/聚焦的页面
  int _pageTabIdx = 0; // 页面面板子Tab页签：0纸张尺寸，1我的模板
  bool _isInitializing = true; // 是否正在异步排版大量日记
  bool _isZoomScaleInitialized = false; // 是否已经根据容器尺寸初始化了缩放比例
  double? _initialScale; // 新增：记录初始设定的完美铺满屏幕时的 scale
  final TransformationController _transformationController = TransformationController();

  // 图表预渲染用 GlobalKey（Offstage + RepaintBoundary 截图）
  final GlobalKey _chartKeyRadar    = GlobalKey();
  final GlobalKey _chartKeyTrend    = GlobalKey();
  final GlobalKey _chartKeyWeekly   = GlobalKey();
  final GlobalKey _chartKeyPalette  = GlobalKey();
  final GlobalKey _chartKeyMoodFlow = GlobalKey();
  final GlobalKey _chartKeyHeatmap  = GlobalKey();

  // 画布截图用 GlobalKey
  final GlobalKey _canvasBoundaryKey = GlobalKey();

  // 当前画布视口的剔除渲染边界缓冲框
  Rect _currentCullingRect = Rect.zero;

  // 临时挂载的待截图图表组件
  Widget? _capturingChartWidget;

  String _initialCanvasStateJson = '';

  String _getCanvasStateJson() {
    final elementsMap = _elements.map((e) => e.toMap()).toList();
    final bgSettingsMap = _pageBgSettings.map((k, v) => MapEntry(k.toString(), v.toMap()));
    final state = {
      'pageSize': _pageSize.toMap(),
      'isLandscape': _isLandscape,
      'margin': _margin.toMap(),
      'pageBgSettings': bgSettingsMap,
      'elements': elementsMap,
    };
    return json.encode(state);
  }

  AnimationController? _matrixAnimationController;
  Animation<Matrix4>? _matrixAnimation;

  AnimationController? _alignAnimationController;
  Animation<Matrix4>? _alignAnimation;
  
  BoxConstraints? _lastConstraints;
  late TextEditingController _textEditorController;



  void _navigateToPage(int pageIndex) {
    updateState(() {
      _focusedPageIndex = pageIndex;
    });
    
    final constraints = _lastConstraints;
    if (constraints == null) return;
    
    const padding = 32.0;
    final targetWidth = constraints.maxWidth - padding;
    final scale = targetWidth / _canvasWidth;
    
    final dx = (constraints.maxWidth - _canvasWidth * scale) / 2;
    final dy = 16.0 - pageIndex * (_canvasHeight + pageGap) * scale;
    
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
      
    _animateMatrixTo(targetMatrix);
  }


  void _selectElement(String? id) {
    if (_editingElementId != null) {
      _inlineFocusNode.unfocus();
      _editingElementId = null;
    }
    _selectedElementId = id;
    if (id != null) {
      final idx = _elements.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _textEditorController.text = _elements[idx].content;
        if (!_elements[idx].isLocked) {
          _activeTabIndex = 3; // 自动切换到"属性"面板
        }
      }
      _isPanelExpanded = true;
    } else {
      _isPanelExpanded = false;
    }
    // 使用微任务延迟更新，避免在当前同步调用栈中触发 setState，从而防止 "widget tree locked" 异常
    Future.microtask(() {
      if (mounted) {
        _selectionNotifier.value = id;
        _panelStateNotifier.value = (_isPanelExpanded, _activeTabIndex);
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
              updateState(() {
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

  Timer? _nudgeTimer;

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _transformationController.removeListener(_onViewportChanged);
    _transformationController.dispose();
    _matrixAnimationController?.dispose();
    _alignAnimationController?.dispose();
    _textEditorController.dispose();
    _inlineFocusNode.dispose();
    // Do not dispose ValueNotifiers to prevent crash during child widget unmount
    super.dispose();
  }



  // 模板本地持久化状态
  List<ExportTemplateModel> _savedTemplates = [];
  bool _isLoadingTemplates = false;

  Future<Directory> get _templatesDir async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/pdf_templates');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // 从本地 pdf_templates 目录加载所有模板
  Future<void> _loadLocalTemplates() async {
    updateState(() {
      _isLoadingTemplates = true;
    });
    try {
      final dir = await _templatesDir;
      final files = dir.listSync();
      final List<ExportTemplateModel> loaded = [];
      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final content = await file.readAsString();
          final Map<String, dynamic> map = json.decode(content) as Map<String, dynamic>;
          loaded.add(ExportTemplateModel.fromMap(map));
        }
      }
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      updateState(() {
        _savedTemplates = loaded;
      });
    } catch (e) {
      debugPrint('加载本地模板失败: $e');
    } finally {
      updateState(() {
        _isLoadingTemplates = false;
      });
    }
  }

  // 将当前画布快照写入本地 json 文件中

  // 套用模板：一键重置当前编辑状态


  @override
  void initState() {
    super.initState();
    _textEditorController = RichTextEditingController(buildRichTextSpan: _buildRichTextSpan);
    _inlineFocusNode.addListener(() {
      if (!_inlineFocusNode.hasFocus) {
        updateState(() {
          _editingElementId = null;
        });
      }
    });
    _exportSettings.fileName = '${widget.book.name}_导出';
    
    _transformationController.addListener(_onViewportChanged);
    _loadLocalTemplates();

    // 延迟解析海量日记，让新页面的转场动画顺滑无阻
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 留出 350ms 等待 MaterialPageRoute 动画完全展开
      await Future.delayed(const Duration(milliseconds: 350));
      _initDefaultElements();
      if (!mounted) return;
      updateState(() {
        _isInitializing = false;
        _initialCanvasStateJson = _getCanvasStateJson();
      });
    });
  }

  // 初始化默认放入一些精美的占位元素，基于用户日记，起点和宽度与页边距联动

  // 根据当前滑动的页边距，动态同步更新系统默认排版元素的位置和宽度

  // 放大或缩小预览画面矩阵

  // 保存历史状态用于撤销



  double get _totalCanvasHeight {
    final int count = _pageCount;
    return _canvasHeight * count + (count - 1) * pageGap;
  }




  // 交互结束时：若处于未放大状态但发生偏航，触发果冻回弹式磁吸居中


  void _handleBackPress() {
    if (_initialCanvasStateJson == _getCanvasStateJson()) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Text(
                    '是否将本次设计保存为模板？',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                      fontFamily: 'LXGWWenKai',
                      height: 1.4,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // 关弹窗
                          Navigator.pop(this.context); // 退出页面
                        },
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            '丢弃',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // 关弹窗
                          _saveTemplateAndExit();
                        },
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            '保存模板',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A3E28),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _getCanvasSubtree() {
    if (_canvasSubtreeCache != null) return _canvasSubtreeCache!;
    _canvasSubtreeCache = Positioned.fill(
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
                _initialScale = scale;
                
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
                onInteractionEnd: _onInteractionEnd, // 新增：松手时自动磁吸回弹
                minScale: 0.1,
                maxScale: 3.0,
                clipBehavior: Clip.none,
                constrained: false, // 解锁视口高度约束，使 A4/A5 纸张恢复其原本真实的物理比例
                boundaryMargin: const EdgeInsets.all(double.infinity), // 解除边界限制，允许超长画布自由平移和定位
                interactionEndFrictionCoefficient: 0.00005, // 增加阻尼感，使滑动更加平稳厚重
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: _canvasWidth,
                    child: RepaintBoundary(
                      key: _canvasBoundaryKey,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _canvasRefreshTrigger,
                        builder: (context, _, _) => _buildCanvas(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    return _canvasSubtreeCache!;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAE7E4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C2C2C), size: 18),
            onPressed: _handleBackPress,
          ),
          title: const Text(
            'PDF 编辑器',
            style: TextStyle(
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.bold,
              fontSize: 17,
              fontFamily: 'LXGWWenKai',
            ),
          ),
          centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _handleSaveTemplate(),
            child: const Text(
              '保存模板',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),

        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFA68565)),
                  SizedBox(height: 16),
                  Text(
                    '正在将您的日记排版成书...',
                    style: TextStyle(
                      color: Color(0xFFA68565),
                      fontFamily: 'LXGWWenKai',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
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
              _getCanvasSubtree(),
              // 2. 浮动悬浮工具栏 + 底部面板：监听 _panelStateNotifier，选中时无需 setState
              ValueListenableBuilder<(bool, int)>(
                valueListenable: _panelStateNotifier,
                builder: (context, panelState, _) {
                  final isPanelExpanded = panelState.$1;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        bottom: (isPanelExpanded ? 220 : 0) + 68 + MediaQuery.of(context).padding.bottom + 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _buildQuickToolbar(),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBottomPanel(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
