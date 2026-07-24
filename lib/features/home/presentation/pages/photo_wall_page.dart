import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/shared/widgets/island_dialog.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/pages/photo_wall_detail_page.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/collection_box_card.dart';
import 'package:island_diary/shared/widgets/island_page_background.dart';
import 'package:island_diary/shared/animations/cupertino_slide_page_route.dart';

/// “照片墙集合”网格主页面
class PhotoWallPage extends StatefulWidget {
  final bool isNight;
  final String themeId;

  const PhotoWallPage({
    super.key,
    required this.isNight,
    required this.themeId,
  });

  @override
  State<PhotoWallPage> createState() => _PhotoWallPageState();
}

class _PhotoWallPageState extends State<PhotoWallPage> {
  static const String _storageKey = 'photo_wall_collections_v2';
  final List<PhotoWallCollection> _collections = [];
  bool _isLoading = true;

  static const List<String> _presetPhotos = [
    'assets/images/home_card/me_day.jpg',
    'assets/images/home_card/me_night.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  /// 过滤并保留真正存在的有效照片路径
  List<String> _filterValidPhotoPaths(List<String> paths) {
    final List<String> valid = [];
    for (var path in paths) {
      if (path.startsWith('assets/')) {
        valid.add(path);
      } else {
        if (File(path).existsSync()) {
          valid.add(path);
        }
      }
    }
    return valid;
  }

  /// 加载照片墙集合列表
  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);

    // 收集用户日记中的真实图片路径
    final List<String> userDiaryPhotos = [];
    final savedDiaries = UserState().savedDiaries.value;
    for (var diary in savedDiaries) {
      for (var block in diary.blocks) {
        if (block['type'] == 'image' && block['path'] != null) {
          final pathStr = block['path'].toString();
          if (pathStr.startsWith('assets/')) {
            userDiaryPhotos.add(pathStr);
          } else if (File(pathStr).existsSync()) {
            userDiaryPhotos.add(pathStr);
          }
        }
      }
    }

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List list = json.decode(rawJson);
        _collections.clear();
        for (var item in list) {
          final col = PhotoWallCollection.fromMap(item);
          final validPaths = _filterValidPhotoPaths(col.photoPaths);
          if (validPaths.isNotEmpty) {
            _collections.add(col.copyWith(photoPaths: validPaths));
          }
        }
      } catch (_) {
        _initDefaultCollections(userDiaryPhotos);
      }
    } else {
      _initDefaultCollections(userDiaryPhotos);
    }

    // 若过滤后无任何有效集合且有日记照片，则重新生成日记照片集合
    if (_collections.isEmpty && userDiaryPhotos.isNotEmpty) {
      _initDefaultCollections(userDiaryPhotos);
    }

    await _saveCollections();
    setState(() => _isLoading = false);
  }

  /// 初始化默认照片墙集合框（仅当存在真实照片时才包含）
  void _initDefaultCollections(List<String> userPhotos) {
    _collections.clear();

    final validUserPhotos = _filterValidPhotoPaths(userPhotos);

    if (validUserPhotos.isNotEmpty) {
      _collections.add(
        PhotoWallCollection(
          id: 'col_daily',
          title: '拾光·日记记录',
          description: '随手记下的生活片段',
          photoPaths: validUserPhotos,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
      );
    }

    _saveCollections();
  }

  /// 保存照片墙集合
  Future<void> _saveCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = json.encode(_collections.map((c) => c.toMap()).toList());
    await prefs.setString(_storageKey, rawJson);
  }

  /// 创建新照片墙集合
  void _showCreateCollectionDialog() {
    final TextEditingController titleController = TextEditingController();

    IslandDialog.show(
      context,
      title: '新建照片墙集合',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '为您的写真相册框起一个治愈的名字：',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '如：7月海岛度假、浪漫晚霞...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      confirmText: '创建集合',
      cancelText: '取消',
      onConfirm: () async {
        final title = titleController.text.trim();
        if (title.isEmpty) {
          showTopToast(context, '请输入集合名称');
          return;
        }

        final newCol = PhotoWallCollection(
          id: 'col_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          photoPaths: [],
          createdAt: DateTime.now(),
        );

        setState(() {
          _collections.insert(0, newCol);
        });
        await _saveCollections();

        if (mounted) {
          _openCollectionDetail(newCol);
        }
      },
    );
  }

  /// 删除照片墙集合
  void _deleteCollection(PhotoWallCollection col) {
    IslandDialog.show(
      context,
      title: '删除照片墙集合',
      contentText: '确定要删除「${col.title}」集合吗？里面的照片记录不会影响日记原有图片。',
      confirmText: '删除',
      cancelText: '取消',
      onConfirm: () async {
        setState(() {
          _collections.removeWhere((c) => c.id == col.id);
        });
        await _saveCollections();
      },
    );
  }

  /// 重命名集合
  void _renameCollection(PhotoWallCollection col) {
    final titleController = TextEditingController(text: col.title);

    IslandDialog.show(
      context,
      title: '修改集合名称',
      content: TextField(
        controller: titleController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '请输入新名称',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      confirmText: '保存',
      cancelText: '取消',
      onConfirm: () async {
        final newTitle = titleController.text.trim();
        if (newTitle.isNotEmpty) {
          final index = _collections.indexWhere((c) => c.id == col.id);
          if (index != -1) {
            setState(() {
              _collections[index] = _collections[index].copyWith(title: newTitle);
            });
            await _saveCollections();
          }
        }
      },
    );
  }


  /// 进入某个照片墙集合详情
  void _openCollectionDetail(PhotoWallCollection col) async {
    final updatedCol = await Navigator.of(context).push<PhotoWallCollection>(
      CupertinoSlidePageRoute(
        page: PhotoWallDetailPage(
          collection: col,
          isNight: widget.isNight,
        ),
      ),
    );

    if (updatedCol != null) {
      final idx = _collections.indexWhere((c) => c.id == updatedCol.id);
      if (idx != -1) {
        setState(() {
          _collections[idx] = updatedCol;
        });
        _saveCollections();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isNight;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "照片墙集合",
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: const [],
          ),
          body: Stack(
            children: [
              // 0. 全屏透光渐变海岛背景组件
              const Positioned.fill(
                child: IslandPageBackground(),
              ),

          // 1. 主体网格区
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top + kToolbarHeight - 6,
                          ),
                        ),
                        SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.58,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _collections.length) {
                                // 最后一个网格框：新建集合入口按钮框
                                return _buildCreateCollectionCard(isDark, textColor);
                              }
                              final col = _collections[index];
                              return CollectionBoxCard(
                                collection: col,
                                isDark: isDark,
                                textColor: textColor,
                                presetPhotos: _presetPhotos,
                                onTap: () => _openCollectionDetail(col),
                                onRename: () => _renameCollection(col),
                                onDelete: () => _deleteCollection(col),
                              );
                            },
                            childCount: _collections.length + 1,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 新建集合透光晶莹玻璃卡片 (Translucent Frosted Glass Slot Card)
  Widget _buildCreateCollectionCard(bool isDark, Color textColor) {
    return BouncingButton(
      onTap: _showCreateCollectionDialog,
      scaleFactor: 1.04,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.60),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 28,
                    color: isDark ? Colors.lightBlueAccent : const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "新建照片墙集合",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "创建专属主题相册",
                  style: TextStyle(
                    fontSize: 10.5,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
