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
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:island_diary/shared/widgets/top_toast.dart';

part 'export/parts/export_canvas.dart';
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
  final FocusNode _inlineFocusNode = FocusNode();
  int _activeTabIndex = 0; // 0:页面, 1:背景, 2:添加, 3:属性, 4:图层, 5:导出
  bool _isPanelExpanded = false; // 面板是否展开，默认收起
  int _focusedPageIndex = 0; // 当前选中的/聚焦的页面
  int _pageTabIdx = 0; // 页面面板子Tab页签：0纸张尺寸，1我的模板
  bool _isZoomScaleInitialized = false; // 是否已经根据容器尺寸初始化了缩放比例
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
          if (!_elements[idx].isLocked) {
            _activeTabIndex = 3; // 自动切换到“属性”面板
          }
        }
        _isPanelExpanded = true;
      } else {
        _isPanelExpanded = false;
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

  Timer? _nudgeTimer;

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _transformationController.removeListener(_onViewportChanged);
    _transformationController.dispose();
    _matrixAnimationController?.dispose();
    _textEditorController.dispose();
    _inlineFocusNode.dispose();
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
  Future<bool> _saveCurrentTemplate(String name) async {
    try {
      final template = ExportTemplateModel(
        name: name,
        pageSize: _pageSize,
        margin: _margin,
        pageBgSettings: _pageBgSettings,
        elements: _elements,
        createdAt: DateTime.now().toIso8601String(),
      );

      final dir = await _templatesDir;
      final file = File('${dir.path}/$name.json');
      
      final jsonStr = json.encode(template.toMap());
      await file.writeAsString(jsonStr);
      
      await _loadLocalTemplates();
      return true;
    } catch (e) {
      debugPrint('保存模板失败: $e');
      return false;
    }
  }

  // 删除某个本地模板文件
  Future<void> _deleteTemplate(ExportTemplateModel template) async {
    try {
      final dir = await _templatesDir;
      final file = File('${dir.path}/${template.name}.json');
      if (await file.exists()) {
        await file.delete();
      }
      await _loadLocalTemplates();
    } catch (e) {
      debugPrint('删除模板失败: $e');
    }
  }

  // 套用模板：一键重置当前编辑状态
  void _applyTemplate(ExportTemplateModel template) {
    _saveToHistory();
    updateState(() {
      _pageSize = template.pageSize;
      _margin.left = template.margin.left;
      _margin.right = template.margin.right;
      _margin.top = template.margin.top;
      _margin.bottom = template.margin.bottom;
      
      _pageBgSettings.clear();
      template.pageBgSettings.forEach((k, v) {
        _pageBgSettings[k] = v.copy();
      });

      _elements = template.elements.map((e) => e.copy()).toList();
      _selectedElementId = null;
      _editingElementId = null;
      
      _undoStack.clear();
      _redoStack.clear();
      
      _focusedPageIndex = 0;
    });

    _isZoomScaleInitialized = false;
    _recenterCanvas();

    showTopToast(
      context,
      '已套用模板 "${template.name}"',
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF5A3E28),
    );
  }

  Future<void> _handleSaveTemplate({bool exitAfterSave = false}) async {
    final controller = TextEditingController(text: _exportSettings.fileName.isNotEmpty ? _exportSettings.fileName : '我的自定义模板');
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 310,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                const Padding(
                  padding: EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Text(
                    '保存为模板',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LXGWWenKai',
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                
                // 输入框
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'LXGWWenKai',
                        color: Color(0xFF2C2C2C),
                      ),
                      decoration: const InputDecoration(
                        hintText: '请输入模板名称...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: 'LXGWWenKai',
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // 分割线
                Container(
                  height: 0.5,
                  color: Colors.black.withValues(alpha: 0.05),
                ),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          if (exitAfterSave) {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            "取消",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5,
                      height: 48,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          Navigator.pop(dialogContext); // 关掉输入弹窗
                          final success = await _saveCurrentTemplate(name);
                          if (!mounted) return;
                          if (success) {
                            showTopToast(
                              context,
                              '模板 "$name" 保存成功！',
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF10B981),
                            );
                            if (exitAfterSave) {
                              Navigator.pop(context); // 退出编辑器页面
                            }
                          } else {
                            showTopToast(
                              context,
                              '模板保存失败，请重试',
                              icon: Icons.error_outline_rounded,
                              iconColor: Colors.red,
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            "确定",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA68565),
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

  void _saveTemplateAndExit() {
    _handleSaveTemplate(exitAfterSave: true);
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
    _initialCanvasStateJson = _getCanvasStateJson();
    _transformationController.addListener(_onViewportChanged);
    _loadLocalTemplates();
  }

  // 初始化默认放入一些精美的占位元素，基于用户日记，起点和宽度与页边距联动
  void _initDefaultElements() {
    _elements = [];
    _pageBgSettings.clear();
    if (widget.diaries.isEmpty) return;

    double currentY = _margin.top;
    final double availableWidth = _canvasWidth - _margin.left - _margin.right;
    const double spacing = 8.0;

    // 辅助方法：分页检查
    double checkPagination(double targetY, double itemHeight) {
      int pageIndex = (targetY / _canvasHeight).floor();
      double pageBottom = (pageIndex + 1) * _canvasHeight - _margin.bottom;
      if (targetY + itemHeight > pageBottom) {
        return (pageIndex + 1) * _canvasHeight + _margin.top;
      }
      return targetY;
    }

    // 辅助方法：将正文切分成独立的句子，保留句末标点符号及处理换行
    List<String> splitIntoSentences(String text) {
      if (text.isEmpty) return [];
      // 正则：匹配遇到标点（。？！；）或者换行符（\n）进行断句并保留标点
      final RegExp regExp = RegExp(r'[^。？！;\n]+[。？！;\n]?');
      final Iterable<Match> matches = regExp.allMatches(text);
      
      List<String> result = [];
      for (final match in matches) {
        final s = match.group(0)?.trim() ?? '';
        if (s.isNotEmpty) {
          result.add(s);
        }
      }
      if (result.isEmpty) {
        result.add(text);
      }
      return result;
    }

    for (int diaryIdx = 0; diaryIdx < widget.diaries.length; diaryIdx++) {
      final diary = widget.diaries[diaryIdx];
      final dt = diary.dateTime;
      final inkColor = DiaryUtils.getInkColor(diary.paperStyle, false);

      // 如果不是第一篇日记，默认另起一页排版（每一篇日记独占新的一页开始）
      if (diaryIdx > 0) {
        int currentPageIndex = (currentY / _canvasHeight).floor();
        currentY = (currentPageIndex + 1) * _canvasHeight + _margin.top;
      }
      final int startPageIndex = (currentY / _canvasHeight).floor();

      // 1. 日期天数元素 (Georgia 68)
      final dayElement = ExportElement(
        id: 'diary_date_day_${diary.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        x: _margin.left,
        y: currentY,
        width: 80,
        height: 68,
        content: dt.day.toString(),
        fontSize: 68,
        color: inkColor,
        fontFamily: 'Georgia',
        lineHeight: 1.0,
      );
      _adjustTextElementWidth(dayElement);
      _elements.add(dayElement);

      // 2. 年月文本元素 (LXGWWenKai 14, 带有 alpha 0.6 柔和色彩)
      final yearMonthElement = ExportElement(
        id: 'diary_date_year_month_${diary.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        x: _margin.left + dayElement.width - 4,
        y: currentY + 13,
        width: 150,
        height: 25,
        content: "${dt.year}年${dt.month}月",
        fontSize: 14,
        color: inkColor.withValues(alpha: 0.6),
        fontFamily: 'LXGWWenKai',
        lineHeight: 1.2,
      );
      _adjustTextElementWidth(yearMonthElement);
      _elements.add(yearMonthElement);

      // 3. 星期与具体时刻元素 (LXGWWenKai 16, FontWeight.bold 粗体)
      final weekTimeElement = ExportElement(
        id: 'diary_date_week_time_${diary.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        x: _margin.left + dayElement.width - 4,
        y: currentY + 32,
        width: 180,
        height: 30,
        content: "${["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][dt.weekday - 1]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}",
        fontSize: 16,
        fontWeight: 'bold',
        color: inkColor.withValues(alpha: 0.8),
        fontFamily: 'LXGWWenKai',
        lineHeight: 1.2,
      );
      _adjustTextElementWidth(weekTimeElement);
      _elements.add(weekTimeElement);

      currentY += 70;

      // 4. 将心情、标签、天气、地点作为独立的文本标签元素进行流式排布并计算高度
      final parsed = ParsedTags.parse(diary.tag, diary.moodIndex);
      final mood = kMoods[diary.moodIndex.clamp(0, kMoods.length - 1)];
      final String moodLabel = parsed.customMood ?? mood.label;
      
      final List<String> tagTexts = [];
      final String mascotPath = UserState().selectedMascotType.value;
      String categoryId = '云织';
      if (mascotPath.contains('marshmallow2')) {
        categoryId = '笃守';
      } else if (mascotPath.contains('marshmallow3')) {
        categoryId = '灵犀';
      } else if (mascotPath.contains('marshmallow4')) {
        categoryId = '霜见';
      }

      final moodMap = const {
        '低落': ['低落', '呜呜', '大哭', '委屈'],
        '烦躁': ['烦躁', '生气', '叹气'],
        '疲惫': ['疲惫', '困', '叹气'],
        '惊喜': ['惊喜', '惊讶', '震惊'],
        '平静': ['平静', '好的', '发呆'],
        '焦虑': ['焦虑', '委屈', '生气'],
        '无聊': ['无聊', '无语', '发呆'],
        '期待': ['期待', '比心', '星星', '喜欢'],
      };

      int? matchedPua;
      final category = EmojiMapping.categories.firstWhere((c) => c['id'] == categoryId, orElse: () => EmojiMapping.categories.first);
      final emojis = category['emojis'] as List;

      for (var e in emojis) {
        if (e['name'] == moodLabel) {
          matchedPua = e['pua'] as int;
          break;
        }
      }

      if (matchedPua == null && moodMap.containsKey(moodLabel)) {
        for (var altName in moodMap[moodLabel]!) {
          for (var e in emojis) {
            if (e['name'] == altName) {
              matchedPua = e['pua'] as int;
              break;
            }
          }
          if (matchedPua != null) break;
        }
      }

      if (matchedPua == null) {
        for (var e in emojis) {
          if (e['name'] == '开心') {
            matchedPua = e['pua'] as int;
            break;
          }
        }
      }

      final String moodEmoji = matchedPua != null ? String.fromCharCode(matchedPua) : '😊';
      tagTexts.add("$moodEmoji $moodLabel");
      for (var t in parsed.tags) {
        tagTexts.add("#$t");
      }
      if (diary.weather != null) {
        tagTexts.add("☀️ ${diary.weather} ${diary.temp ?? ''}");
      }
      if (diary.location != null) {
        tagTexts.add("📍 ${diary.location!}");
      }

      double currentTagX = _margin.left;
      double currentTagY = currentY;
      final double maxTagRight = _canvasWidth - _margin.right;

      for (int i = 0; i < tagTexts.length; i++) {
        final String text = tagTexts[i];
        
        final tempElem = ExportElement(
          id: 'temp_tag_${diary.id}_$i',
          type: 'text',
          x: 0,
          y: 0,
          width: 100,
          height: 24,
          content: text,
          fontSize: 11,
          fontWeight: 'bold',
          textAlign: 'center',
          color: const Color(0xFF5E6C6D),
          textBackgroundColor: const Color(0xFF000000),
          textBackgroundBorderRadius: 12.0,
          textBackgroundPadding: 6.0,
          textBackgroundOpacity: 0.04,
        );
        _adjustTextElementWidth(tempElem);
        
        if (currentTagX + tempElem.width > maxTagRight && currentTagX > _margin.left) {
          currentTagX = _margin.left;
          currentTagY += 36;
        }

        _elements.add(
          ExportElement(
            id: 'diary_metadata_tag_${diary.id}_${i}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'text',
            x: currentTagX,
            y: currentTagY,
            width: tempElem.width,
            height: 24,
            content: text,
            fontSize: 11,
            fontWeight: 'bold',
            textAlign: 'center',
            color: const Color(0xFF5E6C6D),
            textBackgroundColor: const Color(0xFF000000),
            textBackgroundBorderRadius: 12.0,
            textBackgroundPadding: 6.0,
            textBackgroundOpacity: 0.04,
          ),
        );

        currentTagX += tempElem.width + 8;
      }

      currentY = tagTexts.isEmpty ? currentY : (currentTagY + 36);

      final rawContent = diary.content;

      final List<String> sentences = splitIntoSentences(rawContent);

      for (int i = 0; i < sentences.length; i++) {
        final sentence = sentences[i];
        final sentenceElement = ExportElement(
          id: 'diary_content_${diary.id}_$i',
          type: 'text',
          x: _margin.left,
          y: currentY,
          width: availableWidth,
          height: 30,
          content: sentence,
          fontSize: 15,
          color: Colors.black87,
        );

        final sStyle = TextStyle(
          fontSize: sentenceElement.fontSize,
          fontFamily: 'LXGWWenKai',
          height: sentenceElement.lineHeight,
        );
        final sPainter = TextPainter(
          text: TextSpan(text: sentenceElement.content, style: sStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: availableWidth);

        sentenceElement.height = sPainter.height;

        // 检查分页定位
        currentY = checkPagination(currentY, sentenceElement.height);
        sentenceElement.y = currentY;
        _elements.add(sentenceElement);

        // 每句话留 12 像素的段落句间距
        currentY += sentenceElement.height + 12;
      }

      // 6. 解析日记的 blocks 数据并计算图片坐标
      final List<DiaryBlock> diaryBlocks = diary.blocks.map((b) => DiaryBlock.fromMap(b)).toList();
      final List<DiaryBlock> processedBlocks = ImageGroupBlock.preprocess(
        diaryBlocks,
        isMixedLayout: true,
        isImageGrid: true,
      );

      for (var block in processedBlocks) {
        if (block is ImageBlock) {
          final double h = availableWidth / 1.5;
          currentY = checkPagination(currentY, h);
          _elements.add(
            ExportElement(
              id: 'diary_image_${diary.id}_${block.id}',
              type: 'image',
              x: _margin.left,
              y: currentY,
              width: availableWidth,
              height: h,
              content: block.file.path,
              borderRadius: 16.0,
            ),
          );
          currentY += h + 8.0;
        } else if (block is ImageGroupBlock) {
          final images = block.images;
          int index = 0;
          while (index < images.length) {
            final chunk = images.sublist(index, (index + 5).clamp(0, images.length));
            final n = chunk.length;
            if (n == 1) {
              final double h = availableWidth / 1.5;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: availableWidth,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else if (n == 2) {
              final double colW = (availableWidth - spacing) / 2;
              final double h = colW / 0.75;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: colW,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + colW + spacing,
                  y: currentY,
                  width: colW,
                  height: h,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else if (n == 3) {
              final double h = availableWidth / 1.2;
              final double leftW = (availableWidth - spacing) * 2 / 3;
              final double rightW = (availableWidth - spacing) / 3;
              final double rightH = (h - spacing) / 2;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: leftW,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY,
                  width: rightW,
                  height: rightH,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[2].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + rightH + spacing,
                  width: rightW,
                  height: rightH,
                  content: chunk[2].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else if (n == 4) {
              final double h = availableWidth / 1.1;
              final double leftW = (availableWidth - spacing) * 2 / 3;
              final double rightW = (availableWidth - spacing) / 3;
              final double rightH = (h - 2 * spacing) / 3;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: leftW,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY,
                  width: rightW,
                  height: rightH,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[2].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + rightH + spacing,
                  width: rightW,
                  height: rightH,
                  content: chunk[2].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[3].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + 2 * (rightH + spacing),
                  width: rightW,
                  height: rightH,
                  content: chunk[3].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else { // n == 5
              final double topH = availableWidth / 1.1;
              final double bottomH = availableWidth / 3.0;
              final double leftW = (availableWidth - spacing) * 2 / 3;
              final double rightW = (availableWidth - spacing) / 3;
              final double rightH = (topH - 2 * spacing) / 3;
              
              currentY = checkPagination(currentY, topH);
              
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: leftW,
                  height: topH,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY,
                  width: rightW,
                  height: rightH,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[2].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + rightH + spacing,
                  width: rightW,
                  height: rightH,
                  content: chunk[2].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[3].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + 2 * (rightH + spacing),
                  width: rightW,
                  height: rightH,
                  content: chunk[3].file.path,
                  borderRadius: 16.0,
                ),
              );
              
              currentY += topH + spacing;
              
              currentY = checkPagination(currentY, bottomH);
              
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[4].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: availableWidth,
                  height: bottomH,
                  content: chunk[4].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += bottomH;
            }
            index += 5;
            if (index < images.length) {
              currentY += 8.0;
            }
          }
          currentY += 8.0;
        }
      }

      final int endPageIndex = (currentY / _canvasHeight).floor();
      for (int pIdx = startPageIndex; pIdx <= endPageIndex; pIdx++) {
        final String paperBg = DiaryUtils.getPaperBackgroundPath(diary.paperStyle, false);
        final Color paperColor = DiaryUtils.getPaperBaseColor(diary.paperStyle, false);
        _pageBgSettings.putIfAbsent(
          pIdx,
          () => ExportBackgroundSettings(
            color: paperColor,
            imagePath: paperBg.isNotEmpty ? paperBg : null,
            opacity: 1.0,
            x: 0.0,
            y: 0.0,
            scale: 1.0,
            cropRatio: null,
          ),
        );
      }
    }

    // 针对短文本元素自适应测量实际文字宽度以紧贴文本内容
    for (var element in _elements) {
      if (element.type == 'text' && !element.id.contains('diary_content_') && !element.id.contains('diary_metadata_tag_')) {
        _adjustTextElementWidth(element);
      }
    }
  }

  // 根据当前滑动的页边距，动态同步更新系统默认排版元素的位置和宽度
  void _updateElementsMargin() {
    setState(() {
      _initDefaultElements();
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
    setState(() {
      _undoStack.add(_elements.map((e) => e.copy()).toList());
      _redoStack.clear();
    });
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

  double get pageGap => 20.0;

  int get _pageCount {
    double maxY = 0;
    for (var element in _elements) {
      if (element.isVisible) {
        final double bottom = element.y + element.height;
        if (bottom > maxY) {
          maxY = bottom;
        }
      }
    }
    final double contentHeightLimit = _canvasHeight - _margin.bottom;
    if (maxY <= contentHeightLimit) return 1;
    int maxPage = (maxY / _canvasHeight).floor();
    final double pageOffset = maxY % _canvasHeight;
    if (pageOffset > contentHeightLimit) {
      maxPage += 1;
    }
    return (maxPage + 1).clamp(1, 10);
  }

  double get _totalCanvasHeight {
    final int count = _pageCount;
    return _canvasHeight * count + (count - 1) * pageGap;
  }

  double getScreenY(double y) {
    final int pageIndex = y ~/ _canvasHeight;
    final double yInPage = y % _canvasHeight;
    return pageIndex * (_canvasHeight + pageGap) + yInPage;
  }

  double getLayoutY(double screenY) {
    final int pageIndex = screenY ~/ (_canvasHeight + pageGap);
    final double yInPage = screenY % (_canvasHeight + pageGap);
    final double clampedYInPage = yInPage.clamp(0.0, _canvasHeight);
    return pageIndex * _canvasHeight + clampedYInPage;
  }

  void _onViewportChanged() {
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0) return;
    
    final double translationY = matrix.getTranslation().y;
    final double screenCenterY = constraints.maxHeight / 2;
    final double layoutCenterY = (screenCenterY - translationY) / scale;
    
    final double pageHeightWithGap = _canvasHeight + pageGap;
    if (pageHeightWithGap <= 0) return;
    
    int newPageIndex = (layoutCenterY / pageHeightWithGap).floor();
    newPageIndex = newPageIndex.clamp(0, _pageCount - 1);
    
    if (newPageIndex != _focusedPageIndex) {
      updateState(() {
        _focusedPageIndex = newPageIndex;
      });
    }
  }

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
    // 额外留出 16dp 容错间距与文本背景的 padding
    final double paddingOffset = (element.textBackgroundColor != null) ? (element.textBackgroundPadding * 2) : 0.0;
    element.width = (textPainter.width + 16.0 + paddingOffset).clamp(50.0, _canvasWidth - _margin.left - _margin.right);
  }

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
                              color: Color(0xFF8A6C5C),
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


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _initialCanvasStateJson == _getCanvasStateJson(),
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
                          clipBehavior: Clip.none,
                          constrained: false, // 解锁视口高度约束，使 A4/A5 纸张恢复其原本真实的物理比例
                          boundaryMargin: const EdgeInsets.all(800.0), // 留出充足的边界以供拖拽
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: _canvasWidth,
                              child: RepaintBoundary(
                                key: _canvasBoundaryKey,
                                child: _buildCanvas(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 2. 浮动悬浮工具栏 (定位在配置面板上方)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                bottom: (_isPanelExpanded ? 220 : 0) + 68 + MediaQuery.of(context).padding.bottom + 12,
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
      ),
    );
  }
}
