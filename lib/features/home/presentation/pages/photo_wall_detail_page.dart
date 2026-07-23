import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/redbook_asset_picker.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/wall_background_painter.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/treemap_splitter.dart';
import 'package:island_diary/core/widgets/island_floating_bottom_bar.dart';
import 'package:island_diary/core/services/wind_service.dart';
import 'package:island_diary/shared/animations/wind_dissolve_effect.dart';

/// 照片墙集合详情页 (中央实体展板相框样式，对齐图2)
class PhotoWallDetailPage extends StatefulWidget {
  final PhotoWallCollection collection;
  final bool isNight;
  final WallTheme currentTheme;

  const PhotoWallDetailPage({
    super.key,
    required this.collection,
    required this.isNight,
    required this.currentTheme,
  });

  @override
  State<PhotoWallDetailPage> createState() => _PhotoWallDetailPageState();
}

class _ActiveWindDissolveEffect {
  final String id;
  final Offset position;
  final Size size;
  final double angle;
  final WindMode windMode;

  _ActiveWindDissolveEffect({
    required this.id,
    required this.position,
    required this.size,
    required this.angle,
    required this.windMode,
  });
}

class _PhotoWallDetailPageState extends State<PhotoWallDetailPage> {
  late PhotoWallCollection _collection;
  WallLayoutMode _layoutMode = WallLayoutMode.scatter;
  int _randomSeed = 42;
  bool _isPureViewMode = false;
  String? _selectedPhotoId;
  int _nextId = 0;
  late List<String> _photoIds;
  String _generateId() => 'photo_${_nextId++}';
  Offset? _dragStartPos;
  final Map<String, Offset> _photoCustomPositions = {};
  final Map<String, double> _photoCustomScales = {};
  final Map<String, double> _photoCustomAngles = {};
  final List<_ActiveWindDissolveEffect> _activeDissolves = [];

  static const List<String> _presetPhotos = [
    'assets/images/home_card/me_day.jpg',
    'assets/images/home_card/me_night.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
    _photoIds = List.generate(_collection.photoPaths.length, (_) => _generateId());

    // 恢复先前保存的布局模式
    if (_collection.layoutMode == 'treemap') {
      _layoutMode = WallLayoutMode.treemap;
    } else if (_collection.layoutMode == 'scatter') {
      _layoutMode = WallLayoutMode.scatter;
    }

    // 恢复先前保存的照片手帐散落坐标
    if (_collection.customPositions != null) {
      _collection.customPositions!.forEach((id, list) {
        if (list.length >= 2) {
          _photoCustomPositions[id] = Offset(list[0], list[1]);
        }
      });
    }

    // 恢复先前保存的照片缩放比例
    if (_collection.customScales != null) {
      _photoCustomScales.addAll(_collection.customScales!);
    }

    // 恢复先前保存的照片旋转角度
    if (_collection.customAngles != null) {
      _photoCustomAngles.addAll(_collection.customAngles!);
    }
  }

  /// 将当前所有排版位置、旋转角度、缩放、图层顺序与布局模式同步写回 _collection
  void _saveCollectionState() {
    final posMap = <String, List<double>>{};
    _photoCustomPositions.forEach((id, pos) {
      posMap[id] = [pos.dx, pos.dy];
    });

    _collection = _collection.copyWith(
      photoPaths: List.from(_collection.photoPaths),
      customPositions: posMap,
      customScales: Map.from(_photoCustomScales),
      customAngles: Map.from(_photoCustomAngles),
      layoutMode: _layoutMode == WallLayoutMode.scatter ? 'scatter' : 'treemap',
    );
  }

  /// 选中照片（保持现有层级顺序不变）
  void _selectPhoto(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPhotoId = id;
    });
  }

  /// 构建精致图层气泡菜单项 (包含马卡龙 Icon 徽章 + 右侧图层阶梯标)
  Widget _buildLayerMenuItem({
    required IconData icon,
    required String label,
    required String badgeText,
    required bool enabled,
    required Color activeBgColor,
    required Color activeIconColor,
  }) {
    final bgColor = enabled ? activeBgColor : const Color(0xFFF8FAFC);
    final iconColor = enabled ? activeIconColor : Colors.grey.shade400;
    final textColor = enabled ? const Color(0xFF1E293B) : Colors.grey.shade400;
    final badgeBgColor = enabled ? activeBgColor.withValues(alpha: 0.7) : const Color(0xFFF1F5F9);
    final badgeTextColor = enabled ? activeIconColor : Colors.grey.shade400;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 15,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 弹出精准跟随按钮物理位置的图层切换气泡菜单（移至置顶 / 上移一层 / 下移一层 / 移至置底）
  void _showLayerMenu(BuildContext buttonContext, String id) async {
    HapticFeedback.selectionClick();
    final index = _photoIds.indexOf(id);
    if (index == -1) return;
    final total = _photoIds.length;
    if (total <= 1) return;

    final RenderBox? buttonBox = buttonContext.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlay == null) return;

    // 精准实时换算 44x44 图层按钮在全屏上的物理 Bounds，并将菜单锚点偏移至图标正下方 6px 处（避开覆盖图标）
    final Rect buttonRect = buttonBox.localToGlobal(Offset.zero, ancestor: overlay) & buttonBox.size;

    const double menuWidth = 168.0;
    final double menuLeft = buttonRect.left.clamp(12.0, overlay.size.width - menuWidth - 12.0);

    final Rect targetRect = Rect.fromLTWH(
      menuLeft,
      buttonRect.bottom + 6.0,
      buttonRect.width,
      buttonRect.height,
    );

    final isTop = (index == total - 1);
    final isBottom = (index == 0);

    final selected = await showMenu<String>(
      context: buttonContext,
      position: RelativeRect.fromRect(
        targetRect,
        Offset.zero & overlay.size,
      ),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.98),
      items: [
        PopupMenuItem<String>(
          value: 'front',
          enabled: !isTop,
          child: _buildLayerMenuItem(
            icon: Icons.flip_to_front_rounded,
            label: '移至置顶',
            badgeText: 'TOP',
            enabled: !isTop,
            activeBgColor: const Color(0xFFEEF2FF), // 薰衣草紫柔光框
            activeIconColor: const Color(0xFF4F46E5),
          ),
        ),
        PopupMenuItem<String>(
          value: 'forward',
          enabled: !isTop,
          child: _buildLayerMenuItem(
            icon: Icons.arrow_upward_rounded,
            label: '上移一层',
            badgeText: '+1',
            enabled: !isTop,
            activeBgColor: const Color(0xFFECFDF5), // 薄荷绿柔光框
            activeIconColor: const Color(0xFF059669),
          ),
        ),
        PopupMenuItem<String>(
          value: 'backward',
          enabled: !isBottom,
          child: _buildLayerMenuItem(
            icon: Icons.arrow_downward_rounded,
            label: '下移一层',
            badgeText: '-1',
            enabled: !isBottom,
            activeBgColor: const Color(0xFFFFF7ED), // 暖橙色柔光框
            activeIconColor: const Color(0xFFEA580C),
          ),
        ),
        PopupMenuItem<String>(
          value: 'back',
          enabled: !isBottom,
          child: _buildLayerMenuItem(
            icon: Icons.flip_to_back_rounded,
            label: '移至置底',
            badgeText: 'BOT',
            enabled: !isBottom,
            activeBgColor: const Color(0xFFF1F5F9), // 燕麦灰柔光框
            activeIconColor: const Color(0xFF64748B),
          ),
        ),
      ],
    );

    if (selected != null) {
      _applyLayerAction(id, selected);
    }
  }

  /// 执行精准图层位置调整
  void _applyLayerAction(String id, String action) {
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _photoIds.indexOf(id);
      if (index == -1) return;
      final total = _photoIds.length;

      final p = _collection.photoPaths.removeAt(index);
      final removedId = _photoIds.removeAt(index);

      switch (action) {
        case 'front':
          _collection.photoPaths.add(p);
          _photoIds.add(removedId);
          break;
        case 'forward':
          final newIndex = (index + 1).clamp(0, total - 1);
          _collection.photoPaths.insert(newIndex, p);
          _photoIds.insert(newIndex, removedId);
          break;
        case 'backward':
          final newIndex = (index - 1).clamp(0, total - 1);
          _collection.photoPaths.insert(newIndex, p);
          _photoIds.insert(newIndex, removedId);
          break;
        case 'back':
          _collection.photoPaths.insert(0, p);
          _photoIds.insert(0, removedId);
          break;
      }
      _saveCollectionState();
    });
  }

  /// 顺时针旋转照片
  void _rotatePhoto(String id, double initialAngle) {
    HapticFeedback.selectionClick();
    setState(() {
      final currentAngle = _photoCustomAngles[id] ?? initialAngle;
      _photoCustomAngles[id] = currentAngle + (math.pi / 12);
      _saveCollectionState();
    });
  }

  /// 循环缩放照片卡片 (0.8x -> 1.0x -> 1.25x -> 1.5x)
  void _scalePhoto(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      final currentScale = _photoCustomScales[id] ?? 1.0;
      if (currentScale < 0.9) {
        _photoCustomScales[id] = 1.0;
      } else if (currentScale < 1.1) {
        _photoCustomScales[id] = 1.25;
      } else if (currentScale < 1.3) {
        _photoCustomScales[id] = 1.5;
      } else {
        _photoCustomScales[id] = 0.8;
      }
      _saveCollectionState();
    });
  }

  /// 移除照片 (带有随风消逝粒子特效)
  void _removePhoto(String id, {Size? cardSize}) {
    HapticFeedback.lightImpact();

    final currentPos = _photoCustomPositions[id] ?? Offset.zero;
    final currentAngle = _photoCustomAngles[id] ?? 0.0;
    final currentWindMode = WindService.currentWind.value;
    final size = cardSize ?? const Size(80, 92);

    setState(() {
      _activeDissolves.add(
        _ActiveWindDissolveEffect(
          id: id,
          position: currentPos,
          size: size,
          angle: currentAngle,
          windMode: currentWindMode,
        ),
      );

      final index = _photoIds.indexOf(id);
      if (index != -1) {
        _collection.photoPaths.removeAt(index);
        _photoIds.removeAt(index);
        if (_selectedPhotoId == id) {
          _selectedPhotoId = null;
        }
        _photoCustomPositions.remove(id);
        _photoCustomScales.remove(id);
        _photoCustomAngles.remove(id);
      }
      _saveCollectionState();
    });
  }

  /// 向此集合钉入照片 (调用公共 RedBookAssetPicker 相册组件)
  Future<void> _pickPhoto() async {
    try {
      final List<AssetEntity>? results = await RedBookAssetPicker.pick(
        context,
        maxAssets: 9,
        requestType: RequestType.image,
      );
      if (results != null && results.isNotEmpty) {
        final List<String> newPaths = [];
        for (var entity in results) {
          final file = await entity.file;
          if (file != null) {
            newPaths.add(file.path);
          }
        }
        if (newPaths.isNotEmpty) {
          final newIds = List<String>.generate(newPaths.length, (_) => _generateId());
          final updatedPhotos = List<String>.from(_collection.photoPaths)
            ..insertAll(0, newPaths);
          final updatedIds = List<String>.from(_photoIds)
            ..insertAll(0, newIds);
          setState(() {
            _collection = _collection.copyWith(photoPaths: updatedPhotos);
            _photoIds = updatedIds;
            _randomSeed += 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showTopToast(context, '无法打开相册，请重试');
      }
    }
  }

  /// 预览放大写真照片
  void _previewPhoto(String path, int index) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPhotoWidget(path, index, height: 360),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_collection.title} #${index + 1}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        "海岛记忆 · 珍藏",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BouncingButton(
                  onTap: () {
                    final newPhotos = List<String>.from(_collection.photoPaths)..removeAt(index);
                    setState(() {
                      _collection = _collection.copyWith(photoPaths: newPhotos);
                      _photoIds.removeAt(index);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text("移除照片", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BouncingButton(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Text(
                      "关闭预览",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String path, int index, {double? height}) {
    final double h = height ?? double.infinity;
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        height: h,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          _presetPhotos[index % _presetPhotos.length],
          fit: BoxFit.cover,
          height: h,
          width: double.infinity,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        height: h,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          _presetPhotos[index % _presetPhotos.length],
          fit: BoxFit.cover,
          height: h,
          width: double.infinity,
        ),
      );
    }
    return Image.asset(
      _presetPhotos[index % _presetPhotos.length],
      fit: BoxFit.cover,
      height: h,
      width: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = (widget.currentTheme == WallTheme.darkPaper);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveCollectionState();
        Navigator.of(context).pop(_collection);
      },
      child: Scaffold(
        backgroundColor: widget.currentTheme.bgColor,
        extendBodyBehindAppBar: false,
        appBar: _isPureViewMode
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textColor,
                    size: 20,
                  ),
                  onPressed: () {
                    _saveCollectionState();
                    Navigator.of(context).pop(_collection);
                  },
                ),
                title: Text(
                  _collection.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        body: Stack(
          children: [
            // 1. 全屏工作台背景 (点阵/木纹底纹 Canvas)
            Positioned.fill(
              child: CustomPaint(
                painter: WallBackgroundPainter(theme: widget.currentTheme),
              ),
            ),

            // 2. 中央实体展板相框区 (对齐图2：深色/手帐画板相框约束)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_isPureViewMode) {
                    setState(() => _isPureViewMode = false);
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = constraints.maxWidth;

                    // 中央胡桃木画板边距与确切长宽比 (精确映射比例：宽:高 = 0.58，即高 = 宽 / 0.58)
                    const boardMarginH = 16.0;
                    const boardMarginTop = 6.0;
                    const double boardAspectRatio = 0.58;

                    final boardWidth = screenW - boardMarginH * 2;
                    final boardHeight = boardWidth / boardAspectRatio;

                    return Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: boardMarginH,
                          right: boardMarginH,
                          top: boardMarginTop,
                        ),
                        child: Container(
                          width: boardWidth,
                          height: boardHeight,
                          padding: const EdgeInsets.all(14.0), // 14px 宽幅立体加粗胡桃木外框
                          decoration: BoxDecoration(
                            // 复古胡桃木实木外框（深咖啡木色）
                            color: isDark
                                ? const Color(0xFF291A10)
                                : const Color(0xFF4A2E1B),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3D2314)
                                  : const Color(0xFF382012),
                              width: 2.0,
                            ),
                            boxShadow: [
                              // 实木相框落地重度弥散落地影
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.30),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Container(
                            // 软木/燕麦手帐衬布板 (Cork Board Canvas)
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1610)
                                  : const Color(0xFFE8D5C4), // 暖燕麦/软木纸纹衬底
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFD4C2B0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                // 内凹沉降微阴影
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: _buildConstrainingBoardContent(
                                boardWidth - 28.0,
                                boardHeight - 28.0,
                                isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. 引入公共悬浮胶囊底部菜单组件 (IslandFloatingBottomBar)
            IslandFloatingBottomBar(
              isDark: isDark,
              offset: _isPureViewMode ? const Offset(0, 2.5) : Offset.zero,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                IslandFloatingBottomBarItem(
                  icon: Icons.add_a_photo_rounded,
                  color: textColor,
                  onTap: _pickPhoto,
                  tooltip: "钉入照片",
                  width: 36,
                  iconSize: 22,
                ),
                const SizedBox(width: 24),
                IslandFloatingBottomBarItem(
                  icon: Icons.dashboard_customize_rounded,
                  color: textColor,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _layoutMode = _layoutMode == WallLayoutMode.scatter
                          ? WallLayoutMode.treemap
                          : WallLayoutMode.scatter;
                      _saveCollectionState();
                    });
                  },
                  tooltip: _layoutMode == WallLayoutMode.scatter ? "二叉切分" : "手帐散落",
                  width: 36,
                  iconSize: 22,
                ),
                const SizedBox(width: 24),
                IslandFloatingBottomBarItem(
                  icon: Icons.casino_rounded,
                  color: textColor,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _randomSeed = math.Random().nextInt(10000);
                      _photoCustomPositions.clear();
                      _photoCustomScales.clear();
                      _photoCustomAngles.clear();
                      _saveCollectionState();
                    });
                  },
                  tooltip: "随机重排",
                  width: 36,
                  iconSize: 22,
                ),
                const SizedBox(width: 24),
                IslandFloatingBottomBarItem(
                  icon: Icons.fullscreen_rounded,
                  color: textColor,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isPureViewMode = true);
                  },
                  tooltip: "纯享",
                  width: 36,
                  iconSize: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 在相框内部约束渲染照片 (对齐图2 Moodboard 相框内约束)
  Widget _buildConstrainingBoardContent(double boardWidth, double boardHeight, bool isDark) {
    if (_collection.photoPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 40,
              color: isDark ? Colors.amber.shade200.withValues(alpha: 0.4) : const Color(0xFF78350F).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              "暂无写真照片",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF522B14),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "点击下方「钉入照片」放入画框",
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : const Color(0xFF78350F).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_layoutMode == WallLayoutMode.treemap) {
      final count = _collection.photoPaths.length;
      final bounds = Rect.fromLTWH(6, 6, boardWidth - 12, boardHeight - 12);
      final indices = List.generate(count, (i) => i);
      final leaves = TreemapSplitter.computeLeaves(bounds, indices, _randomSeed);

      return SizedBox(
        height: boardHeight,
        width: boardWidth,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: leaves.map((leaf) {
            final path = _collection.photoPaths[leaf.index];
            const gap = 3.0;
            final cardRect = leaf.rect.deflate(gap);

            return Positioned(
              left: cardRect.left,
              top: cardRect.top,
              width: cardRect.width,
              height: cardRect.height,
              child: BouncingButton(
                onTap: () => _previewPhoto(path, leaf.index),
                scaleFactor: 1.05,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildPhotoWidget(path, leaf.index),
                      ),
                    ),
                    Positioned(
                      top: 1,
                      child: _buildPushPinWidget(leaf.index, false),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // 散落手帐 Moodboard 模 (固定画板物理网格，自适应散落且删除/增改不乱跳)
      final count = _collection.photoPaths.length;
      
      // 使用固定的 3 列 3 行画板参准网格，确保算法步长与物理长宽解耦，不受总卡片数增减影响
      const int cols = 3;
      const int maxRows = 3;

      final maxAvailableW = (boardWidth - 24.0) / cols;
      final cardW = (maxAvailableW * 0.90).clamp(48.0, 96.0);
      final cardH = (cardW * 1.15).clamp(55.0, 110.0);

      final rowStep = (boardHeight - cardH - 24.0) / (maxRows - 1);
      final colStep = (boardWidth - cardW - 24.0) / (cols - 1);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedPhotoId = null),
        child: SizedBox(
          height: boardHeight,
          width: boardWidth,
          child: Stack(
            key: ValueKey(_photoIds.join(',')),
            clipBehavior: Clip.none,
            children: [
              ...List.generate(count, (index) {
              final path = _collection.photoPaths[index];
              final id = _photoIds[index];

              // 若该 ID 尚无保存的散落坐标，则根据稳定规则进行一次性计算并自动缓存锁定
              if (!_photoCustomPositions.containsKey(id)) {
                final rand = math.Random(_randomSeed + id.hashCode);
                final col = id.hashCode.abs() % cols;
                final row = (id.hashCode.abs() ~/ cols) % maxRows;

                final offsetX = (rand.nextDouble() - 0.5) * 12.0;
                final offsetY = (rand.nextDouble() - 0.5) * 12.0;

                final defaultLeft = (12.0 + col * colStep + offsetX).clamp(6.0, boardWidth - cardW - 6.0);
                final defaultTop = (12.0 + row * rowStep + offsetY).clamp(6.0, boardHeight - cardH - 6.0);
                _photoCustomPositions[id] = Offset(defaultLeft, defaultTop);

                final defaultAngle = (rand.nextDouble() - 0.5) * 0.32;
                _photoCustomAngles[id] ??= defaultAngle;
              }

              final currentPos = _photoCustomPositions[id]!;
              final currentAngle = _photoCustomAngles[id] ?? 0.0;
              final userScale = _photoCustomScales[id] ?? 1.0;

              final left = currentPos.dx;
              final top = currentPos.dy;

              final isSelected = _selectedPhotoId == id;

              const double handlePadding = 20.0;

              return Positioned(
                key: ValueKey(id),
                left: left - handlePadding,
                top: top - handlePadding,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (_selectedPhotoId == id) {
                      setState(() => _selectedPhotoId = null);
                    } else {
                      _selectPhoto(id);
                    }
                  },
                  onLongPressStart: (details) {
                    HapticFeedback.heavyImpact();
                    _selectPhoto(id);
                    _dragStartPos = _photoCustomPositions[id] ?? Offset(left, top);
                  },
                  onLongPressMoveUpdate: (details) {
                    if (_selectedPhotoId == id) {
                      final basePos = _dragStartPos ?? Offset(left, top);
                      final double newX = (basePos.dx + details.offsetFromOrigin.dx)
                          .clamp(-cardW * 0.2, boardWidth - cardW * 0.8);
                      final double newY = (basePos.dy + details.offsetFromOrigin.dy)
                          .clamp(-cardH * 0.2, boardHeight - cardH * 0.8);

                      setState(() {
                        _photoCustomPositions[id] = Offset(newX, newY);
                      });
                    }
                  },
                  onLongPressEnd: (_) {
                    _dragStartPos = null;
                    _saveCollectionState();
                  },
                  onLongPressUp: () {
                    _dragStartPos = null;
                    _saveCollectionState();
                  },
                  onPanStart: (details) {
                    _selectPhoto(id);
                    if (!_photoCustomPositions.containsKey(id)) {
                      _photoCustomPositions[id] = Offset(left, top);
                    }
                  },
                  onPanUpdate: (details) {
                    if (_selectedPhotoId == id) {
                      final currentOffset = _photoCustomPositions[id] ?? Offset(left, top);
                      final double newX = (currentOffset.dx + details.delta.dx)
                          .clamp(-cardW * 0.2, boardWidth - cardW * 0.8);
                      final double newY = (currentOffset.dy + details.delta.dy)
                          .clamp(-cardH * 0.2, boardHeight - cardH * 0.8);

                      setState(() {
                        _photoCustomPositions[id] = Offset(newX, newY);
                      });
                    }
                  },
                  onPanEnd: (_) {
                    _saveCollectionState();
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.08 * userScale : 1.0 * userScale,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    child: Transform.rotate(
                      angle: currentAngle,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // Base padding provider so Stack is large enough for hit testing
                          Padding(
                            padding: const EdgeInsets.all(handlePadding),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: cardW,
                              height: cardH,
                              padding: const EdgeInsets.all(4.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? Colors.black.withValues(alpha: 0.45)
                                        : Colors.black38,
                                    blurRadius: isSelected ? 14 : 6,
                                    offset: isSelected ? const Offset(0, 6) : const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.5),
                                child: SizedBox.expand(
                                  child: _buildPhotoWidget(path, index),
                                ),
                              ),
                            ),
                          ),

                          // 顶部钉在展板上的极简小圆钉 (包含拔起与钉入动态物理反馈)
                          Positioned(
                            top: handlePadding + 1,
                            child: _buildPushPinWidget(index, isSelected),
                          ),

                          // 选中状态：在悬浮放大的同时同步显现虚线框与四角调控手柄
                          if (isSelected) ...[
                            // 1. 选中虚线框
                            Positioned(
                              left: handlePadding,
                              top: handlePadding,
                              right: handlePadding,
                              bottom: handlePadding,
                              child: CustomPaint(
                                painter: DashedBorderPainter(
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                            // 2. 左上角：图层管理 (气泡菜单)
                            Positioned(
                              top: handlePadding - 21,
                              left: handlePadding - 21,
                              child: _buildHandleButton(
                                icon: Icons.layers_rounded,
                                onTapWithContext: (btnCtx) => _showLayerMenu(btnCtx, id),
                              ),
                            ),
                            // 3. 左下角：放大缩小 (切换卡片尺寸)
                            Positioned(
                              bottom: handlePadding - 21,
                              left: handlePadding - 21,
                              child: _buildHandleButton(
                                icon: Icons.aspect_ratio_rounded,
                                onTap: () => _scalePhoto(id),
                                onPanUpdate: (details) {
                                  setState(() {
                                    final currentScale = _photoCustomScales[id] ?? 1.0;
                                    // 左下角往外拉(向左dx<0,向下dy>0)为放大
                                    final delta = (details.delta.dy - details.delta.dx) * 0.005;
                                    _photoCustomScales[id] = (currentScale + delta).clamp(0.4, 3.0);
                                  });
                                },
                              ),
                            ),
                            // 4. 右上角：移除/删除照片 (触发随风消逝粒子特效)
                            Positioned(
                              top: handlePadding - 21,
                              right: handlePadding - 21,
                              child: _buildHandleButton(
                                icon: Icons.close_rounded,
                                onTap: () => _removePhoto(id, cardSize: Size(cardW, cardH)),
                              ),
                            ),
                            // 5. 右下角：旋转照片
                            Positioned(
                              bottom: handlePadding - 21,
                              right: handlePadding - 21,
                              child: _buildHandleButton(
                                icon: Icons.rotate_right_rounded,
                                onTap: () => _rotatePhoto(id, currentAngle),
                                onPanUpdate: (details) {
                                  setState(() {
                                    // 根据物理力矩原理：右下角，向下滑动(dy>0)或向左滑动(dx<0)时，产生顺时针旋转(角度增加)
                                    // 因此旋转增量应该正比于 (dy - dx)
                                    _photoCustomAngles[id] = (_photoCustomAngles[id] ?? currentAngle) + (details.delta.dy - details.delta.dx) * 0.008;
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // 渲染随风消逝粒子动画动效层 (读取 WindService 海岛风速)
            ..._activeDissolves.map((dissolve) {
              return Positioned(
                key: ValueKey('dissolve_${dissolve.id}'),
                left: dissolve.position.dx,
                top: dissolve.position.dy,
                child: WindDissolveEffectWidget(
                  position: Offset.zero,
                  size: dissolve.size,
                  angle: dissolve.angle,
                  windMode: dissolve.windMode,
                  onComplete: () {
                    if (mounted) {
                      setState(() {
                        _activeDissolves.removeWhere((d) => d.id == dissolve.id);
                      });
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
    }
  }

  /// 选中卡片调控手柄圆按钮组件 (包含 44x44px 触摸热区与防手势冲突处理)
  Widget _buildHandleButton({
    required IconData icon,
    VoidCallback? onTap,
    void Function(BuildContext context)? onTapWithContext,
    GestureDragUpdateCallback? onPanUpdate,
  }) {
    final Widget buttonWidget = Builder(
      builder: (btnContext) {
        return BouncingButton(
          onTap: () {
            if (onTapWithContext != null) {
              onTapWithContext(btnContext);
            } else if (onTap != null) {
              onTap();
            }
          },
          scaleFactor: 1.18,
          child: Container(
            width: 44,
            height: 44,
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF64748B).withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 14,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (onPanUpdate != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }

  /// 极简治愈系手帐小圆钉组件 (包含拔起与钉入动态物理反馈)
  Widget _buildPushPinWidget(int index, bool isSelected) {
    const pinColors = [
      Color(0xFFFFB7B2), // 马卡龙柔粉
      Color(0xFFB5EAD7), // 薄荷绿
      Color(0xFFFFE5B4), // 奶油暖黄
      Color(0xFFE2D4F0), // 薰衣草浅紫
      Color(0xFFC7CEEA), // 天空柔蓝
    ];
    final color = pinColors[index % pinColors.length];

    return AnimatedScale(
      scale: isSelected ? 1.35 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: isSelected ? Curves.easeOutBack : Curves.bounceOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: isSelected ? Curves.easeOutBack : Curves.bounceOut,
        transform: Matrix4.translationValues(0, isSelected ? -10.0 : 0.0, 0)
          ..rotateZ(isSelected ? -0.12 : 0.0),
        transformAlignment: Alignment.center,
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.15),
              blurRadius: isSelected ? 6 : 2,
              offset: isSelected ? const Offset(0, 5) : const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// 手帐选中虚线框绘制类
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dash = 6.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-3, -3, size.width + 6, size.height + 6),
      const Radius.circular(9),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = math.min(dash, metric.length - distance);
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
