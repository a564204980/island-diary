import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:island_diary/core/widgets/island_floating_bottom_bar.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/photo_board_canvas.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/photo_wall_settings_sheet.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/wall_layout_mode.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall_card.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/redbook_asset_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:island_diary/shared/widgets/island_dialog.dart';
import 'package:island_diary/shared/widgets/island_page_background.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/features/home/presentation/services/photo_wall_storage_service.dart';

/// 展板详情与自由缩影手帐编辑页面 (PhotoWallDetailPage)
class PhotoWallDetailPage extends StatefulWidget {
  final PhotoWallCollection collection;
  final bool isNight;

  const PhotoWallDetailPage({
    super.key,
    required this.collection,
    required this.isNight,
  });

  @override
  State<PhotoWallDetailPage> createState() => _PhotoWallDetailPageState();
}

class _PhotoWallDetailPageState extends State<PhotoWallDetailPage> {
  late PhotoWallCollection _collection;
  late WallLayoutMode _layoutMode;
  bool _showWashiTape = true;
  bool _isEditing = true;

  final Map<String, Offset> _photoCustomPositions = {};
  final Map<String, double> _photoCustomAngles = {};
  final Map<String, double> _photoCustomScales = {};
  final GlobalKey _canvasBoundaryKey = GlobalKey();
  final GlobalKey<PhotoBoardCanvasState> _canvasKey = GlobalKey<PhotoBoardCanvasState>();

  final List<String> _photoIds = [];

  static const List<String> _presetPhotos = [
    'assets/images/icons/mood1.png',
    'assets/images/icons/mood2.png',
    'assets/images/icons/mood3.png',
    'assets/images/icons/mood4.png',
    'assets/images/icons/mood5.png',
  ];

  late int _randomSeed;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
    _layoutMode = WallLayoutModeX.fromString(_collection.layoutMode ?? 'scatter');
    _randomSeed = _collection.id.hashCode.abs();
    _syncPhotoIds();
    _loadCustomPositions();
  }

  void _syncPhotoIds() {
    _photoIds.clear();
    for (int i = 0; i < _collection.photoPaths.length; i++) {
      _photoIds.add('photo_$i');
    }
  }

  void _loadCustomPositions() {
    if (_collection.customPositions != null) {
      _collection.customPositions!.forEach((key, val) {
        if (val.length >= 2) {
          _photoCustomPositions[key] = Offset(val[0], val[1]);
        }
      });
    }
    if (_collection.customAngles != null) {
      _photoCustomAngles.addAll(_collection.customAngles!);
    }
    if (_collection.customScales != null) {
      _photoCustomScales.addAll(_collection.customScales!);
    }
  }

  Future<void> _saveCollectionState() async {
    final posMap = <String, List<double>>{};
    _photoCustomPositions.forEach((k, v) {
      posMap[k] = [v.dx, v.dy];
    });

    final updated = _collection.copyWith(
      layoutMode: _layoutMode.name,
      customPositions: posMap,
      customAngles: Map.from(_photoCustomAngles),
      customScales: Map.from(_photoCustomScales),
    );

    _collection = updated;

    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('photo_wall_collections_v2');
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> rawList = jsonDecode(rawJson);
        final List<Map<String, dynamic>> list = [];
        for (var item in rawList) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item));
          } else if (item is String) {
            try {
              final decoded = jsonDecode(item);
              if (decoded is Map) {
                list.add(Map<String, dynamic>.from(decoded));
              }
            } catch (_) {}
          }
        }

        final index = list.indexWhere((item) => item['id'] == updated.id);
        if (index != -1) {
          list[index] = updated.toMap();
          await prefs.setString('photo_wall_collections_v2', jsonEncode(list));
          PhotoWallCard.updateStaticCache(updated);
        }
      } catch (e) {
        debugPrint("保存照片墙状态失败: $e");
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final List<AssetEntity>? result = await RedBookAssetPicker.pick(
        context,
        maxAssets: 9,
        requestType: RequestType.image,
      );
      if (result != null && result.isNotEmpty) {
        final List<String> rawPaths = [];
        for (var asset in result) {
          final file = await asset.file;
          if (file != null) {
            rawPaths.add(file.path);
          }
        }

        if (rawPaths.isNotEmpty) {
          final addedPaths = await PhotoWallStorageService.savePhotosToPermanentStorage(rawPaths);
          final newPaths = List<String>.from(_collection.photoPaths)..addAll(addedPaths);
          final existingCount = _photoIds.length;

          setState(() {
            _collection = _collection.copyWith(
              photoPaths: newPaths,
              layoutMode: 'scatter',
            );
            _layoutMode = WallLayoutMode.scatter;

            final rand = math.Random();
            const cols = 3;
            const maxRows = 3;

            for (int i = 0; i < addedPaths.length; i++) {
              final newId = 'photo_${_photoIds.length}';
              _photoIds.add(newId);

              final totalIndex = existingCount + i;
              final colIndex = totalIndex % cols;
              final rowIndex = (totalIndex ~/ cols) % maxRows;

              final double baseX = 18.0 + colIndex * 88.0;
              final double baseY = 24.0 + rowIndex * 115.0;
              final double randomX = (rand.nextDouble() - 0.5) * 36.0;
              final double randomY = (rand.nextDouble() - 0.5) * 36.0;

              final double finalX = (baseX + randomX).clamp(10.0, 210.0);
              final double finalY = (baseY + randomY).clamp(14.0, 350.0);

              final double randomAngle = (rand.nextDouble() - 0.5) * 0.44;

              _photoCustomPositions[newId] = Offset(finalX, finalY);
              _photoCustomAngles[newId] = randomAngle;
              _photoCustomScales[newId] = 1.0;
            }
          });

          await _saveCollectionState();
          if (mounted) {
            showTopToast(context, "📸 成功钉入 ${addedPaths.length} 张照片", icon: Icons.push_pin_rounded);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showTopToast(context, "选图失败: $e");
      }
    }
  }

  void _removePhoto(String photoId) {
    final index = _photoIds.indexOf(photoId);
    if (index != -1) {
      setState(() {
        _collection.photoPaths.removeAt(index);
        _photoIds.removeAt(index);
        _photoCustomPositions.remove(photoId);
        _photoCustomAngles.remove(photoId);
        _photoCustomScales.remove(photoId);
      });
      _saveCollectionState();
    }
  }

  void _clearAllPhotos() {
    if (_collection.photoPaths.isEmpty) {
      showTopToast(context, '展板已经是空的啦');
      return;
    }

    IslandDialog.show(
      context,
      title: '清空展板照片',
      content: const Text(
        '确定要清空展板上的所有照片吗？清空后可以重新添加写真。',
        style: TextStyle(fontSize: 14),
      ),
      confirmText: '确认清空',
      onConfirm: () {
        setState(() {
          _collection = _collection.copyWith(photoPaths: []);
          _photoIds.clear();
          _photoCustomPositions.clear();
          _photoCustomAngles.clear();
          _photoCustomScales.clear();
        });
        _saveCollectionState();
        showTopToast(context, '🧹 已清空展板所有照片', icon: Icons.cleaning_services_rounded);
      },
    );
  }

  void _showPhotoPreviewDialog(String path, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _buildPhotoWidget(path, index),
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
                    _saveCollectionState();
                    Navigator.of(dialogCtx).pop();
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
                  onTap: () => Navigator.of(dialogCtx).pop(),
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

  Widget _buildPhotoWidget(String path, int seed, {double? height}) {
    final double h = height ?? double.infinity;
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        height: h,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          _presetPhotos[seed.abs() % _presetPhotos.length],
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
          _presetPhotos[seed.abs() % _presetPhotos.length],
          fit: BoxFit.cover,
          height: h,
          width: double.infinity,
        ),
      );
    }
    return Image.asset(
      _presetPhotos[seed.abs() % _presetPhotos.length],
      fit: BoxFit.cover,
      height: h,
      width: double.infinity,
    );
  }

  void _openSettingsSheet() {
    PhotoWallSettingsSheet.show(
      context,
      isNight: widget.isNight,
      showWashiTape: _showWashiTape,
      onShowWashiTapeChanged: (val) {
        setState(() {
          _showWashiTape = val;
        });
      },
      onResetLayout: () {
        setState(() {
          _photoCustomPositions.clear();
          _photoCustomScales.clear();
          _photoCustomAngles.clear();
        });
        _saveCollectionState();
      },
    );
  }

  void _safeExitDetailPage() {
    _canvasKey.currentState?.clearSelection();
    if (_isEditing) {
      setState(() => _isEditing = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(_collection);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isNight;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _canvasKey.currentState?.clearSelection();
        if (_isEditing) {
          setState(() => _isEditing = false);
        }
        if (didPop) return;
        Navigator.of(context).pop(_collection);
      },
      child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
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
              onPressed: _safeExitDetailPage,
            ),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            "照片墙编辑",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: BouncingButton(
                onTap: _clearAllPhotos,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                        color: textColor.withValues(alpha: 0.85),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '清空',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // 0. 全屏透光渐变海岛背景组件
            const Positioned.fill(
              child: IslandPageBackground(),
            ),

            // 1. 中央实体展板相框区
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;
                  const boardMarginH = 16.0;
                  final boardMarginTop =
                      MediaQuery.of(context).padding.top + kToolbarHeight - 38.0;
                  const double boardAspectRatio = 0.58;

                  final boardWidth = screenW - boardMarginH * 2;
                  final boardHeight = boardWidth / boardAspectRatio;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: boardMarginH,
                        right: boardMarginH,
                        top: boardMarginTop,
                      ),
                      child: SizedBox(
                        width: boardWidth,
                        height: boardHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. 玻璃质感底座容器 (背景层)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                  child: Container(
                                    padding: const EdgeInsets.all(7.0),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.22)
                                            : Colors.white.withValues(alpha: 0.50),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: isDark ? 0.35 : 0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.12)
                                            : Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 2. 照片展板画布区 (允许照片无阻挡跨越屏幕左右边界)
                            Positioned(
                              left: 7.0,
                              top: 7.0,
                              right: 7.0,
                              bottom: 7.0,
                              child: PhotoBoardCanvas(
                                key: _canvasKey,
                                isEditing: _isEditing,
                                canvasBoundaryKey: _canvasBoundaryKey,
                                collection: _collection,
                                layoutMode: _layoutMode,
                                showWashiTape: _showWashiTape,
                                isDark: isDark,
                                boardWidth: boardWidth - 14.0,
                                boardHeight: boardHeight - 14.0,
                                photoIds: _photoIds,
                                photoCustomPositions: _photoCustomPositions,
                                photoCustomAngles: _photoCustomAngles,
                                photoCustomScales: _photoCustomScales,
                                randomSeed: _randomSeed,
                                presetPhotos: _presetPhotos,
                                onPreviewPhoto: _showPhotoPreviewDialog,
                                onRemovePhoto: _removePhoto,
                                onStateChanged: _saveCollectionState,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. 引入公共悬浮胶囊底部菜单组件 (IslandFloatingBottomBar)
            IslandFloatingBottomBar(
              isDark: isDark,
              offset: Offset.zero,
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
                  icon: _layoutMode == WallLayoutMode.scatter
                      ? Icons.style_rounded
                      : Icons.grid_view_rounded,
                  color: textColor,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _canvasKey.currentState?.clearSelection();
                    setState(() {
                      _layoutMode = _layoutMode == WallLayoutMode.scatter
                          ? WallLayoutMode.treemap
                          : WallLayoutMode.scatter;
                      _saveCollectionState();
                    });
                  },
                  tooltip:
                      _layoutMode == WallLayoutMode.scatter ? "二叉切分" : "手帐散落",
                  width: 36,
                  iconSize: 22,
                ),
                const SizedBox(width: 24),
                IslandFloatingBottomBarItem(
                  icon: Icons.tune_rounded,
                  color: textColor,
                  onTap: _openSettingsSheet,
                  tooltip: "展板设置",
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
}
