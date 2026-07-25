import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/shared/widgets/island_dialog.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/pages/photo_wall_detail_page.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/collection_box_card.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall_card.dart';
import 'package:island_diary/features/home/presentation/services/photo_wall_image_cache.dart';
import 'package:island_diary/shared/widgets/island_page_background.dart';

/// “照片墙集合”网格主页面
class PhotoWallPage extends StatefulWidget {
  final bool isNight;
  final String themeId;

  const PhotoWallPage({
    super.key,
    required this.isNight,
    required this.themeId,
  });

  /// 导航前提前预热：同步加载集合数据 + 图片字节进内存缓存，消除进入列表页时的白屏
  /// 由外部在 Navigator.push 前调用，因此定义在公开类上
  static Future<void> prewarmCache() async {
    // 如果静态缓存已存在，只需补充预热图片字节即可
    if (_PhotoWallPageState._staticCollectionsCache != null &&
        _PhotoWallPageState._staticCollectionsCache!.isNotEmpty) {
      final List<String> allPaths = [];
      for (var col in _PhotoWallPageState._staticCollectionsCache!) {
        allPaths.addAll(col.photoPaths);
      }
      PhotoWallImageCache.preloadSync(allPaths);
      return;
    }

    // 静态缓存为空时，从磁盘读取并填充
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_PhotoWallPageState._storageKey);
      if (rawJson == null || rawJson.isEmpty) return;

      final List rawList = json.decode(rawJson);
      final List<PhotoWallCollection> cols = [];
      for (var item in rawList) {
        Map<String, dynamic>? map;
        if (item is Map) {
          map = Map<String, dynamic>.from(item);
        } else if (item is String) {
          try {
            final decoded = json.decode(item);
            if (decoded is Map) map = Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
        if (map != null) cols.add(PhotoWallCollection.fromMap(map));
      }

      if (cols.isEmpty) return;

      _PhotoWallPageState._staticCollectionsCache = cols;

      // 同步预热所有集合的图片字节
      final List<String> allPaths = [];
      for (var col in cols) {
        allPaths.addAll(col.photoPaths);
      }
      PhotoWallImageCache.preloadSync(allPaths);
    } catch (_) {}
  }

  @override
  State<PhotoWallPage> createState() => _PhotoWallPageState();
}

class _PhotoWallPageState extends State<PhotoWallPage> {
  static const String _storageKey = 'photo_wall_collections_v2';
  static List<PhotoWallCollection>? _staticCollectionsCache;
  final List<PhotoWallCollection> _collections = [];
  bool _isLoading = true;

  static const List<String> _presetPhotos = [
    'assets/images/home_card/me_day.jpg',
    'assets/images/home_card/me_night.jpg',
  ];

  @override
  void initState() {
    super.initState();
    if (_staticCollectionsCache != null && _staticCollectionsCache!.isNotEmpty) {
      _collections.addAll(_staticCollectionsCache!);
      _isLoading = false;
    }
    _loadCollections();
  }

  /// 过滤并补充有效照片路径（无效或已被清理的本地图片自动用预设写真补位，消除死白框）
  List<String> _filterValidPhotoPaths(List<String> paths) {
    const fallbackBgs = [
      'assets/images/home_card/me_day.jpg',
      'assets/images/home_card/me_night.jpg',
      'assets/images/emoji/modules_bg/4.png',
      'assets/images/emoji/modules_bg/5.png',
      'assets/images/emoji/modules_bg/6.png',
      'assets/images/emoji/modules_bg/7.png',
      'assets/images/emoji/modules_bg/8.png',
      'assets/images/emoji/modules_bg/9.png',
      'assets/images/emoji/modules_bg/10.png',
      'assets/images/emoji/modules_bg/11.png',
      'assets/images/emoji/modules_bg/12.png',
    ];

    final List<String> result = [];
    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (path.startsWith('assets/')) {
        result.add(path);
      } else if (File(path).existsSync()) {
        result.add(path);
      } else {
        result.add(fallbackBgs[i.abs() % fallbackBgs.length]);
      }
    }
    return result;
  }

  /// 加载照片墙集合列表
  Future<void> _loadCollections() async {
    if (_collections.isEmpty) {
      setState(() => _isLoading = true);
    }
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

    final List<PhotoWallCollection> loadedCols = [];
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List rawList = json.decode(rawJson);
        for (var item in rawList) {
          Map<String, dynamic>? map;
          if (item is Map) {
            map = Map<String, dynamic>.from(item);
          } else if (item is String) {
            try {
              final decoded = json.decode(item);
              if (decoded is Map) map = Map<String, dynamic>.from(decoded);
            } catch (_) {}
          }
          if (map != null) {
            var col = PhotoWallCollection.fromMap(map);
            if (col.coverImagePath != null &&
                col.coverImagePath!.isNotEmpty &&
                !col.coverImagePath!.endsWith('_v4.png')) {
              try {
                final oldF = File(col.coverImagePath!);
                if (oldF.existsSync()) oldF.deleteSync();
              } catch (_) {}
              col = col.copyWith(coverImagePath: '');
            }
            final validPaths = _filterValidPhotoPaths(col.photoPaths);
            loadedCols.add(col.copyWith(photoPaths: validPaths));
          }
        }
      } catch (_) {
        _initDefaultCollections(userDiaryPhotos);
        return;
      }
    } else {
      _initDefaultCollections(userDiaryPhotos);
      return;
    }

    if (loadedCols.isNotEmpty) {
      final hasActive = loadedCols.any((c) => c.isActive);
      if (!hasActive) {
        loadedCols[0] = loadedCols[0].copyWith(isActive: true);
      }
      _collections.clear();
      _collections.addAll(loadedCols);
    }

    // 预载入全量照片解包字节到内存缓存中，防止图片解码闪落
    final List<String> allPhotosToPreload = [];
    for (var col in _collections) {
      allPhotosToPreload.addAll(col.photoPaths);
    }
    PhotoWallImageCache.preload(allPhotosToPreload);

    _staticCollectionsCache = List.from(_collections);
    await _saveCollections();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 切换首页展示的激活照片墙集合 (保持卡片原地不动，不弹出 Toast 消息提醒)
  void _setActiveCollection(PhotoWallCollection target) async {
    HapticFeedback.mediumImpact();
    setState(() {
      for (int i = 0; i < _collections.length; i++) {
        final isCurrentTarget = _collections[i].id == target.id;
        _collections[i] = _collections[i].copyWith(isActive: isCurrentTarget);
      }
    });
    await _saveCollections();
  }

  /// 初始化默认照片墙集合框（仅当存在真实照片时才包含）
  void _initDefaultCollections(List<String> userPhotos) {
    _collections.clear();

    final validUserPhotos = _filterValidPhotoPaths(userPhotos);

    _collections.add(
      PhotoWallCollection(
        id: 'col_daily',
        title: '拾光·日记记录',
        description: '随手记下的生活片段',
        photoPaths: validUserPhotos,
        createdAt: DateTime.now(),
        isDefault: true,
        isActive: true,
      ),
    );

    _saveCollections();
  }

  /// 保存照片墙集合
  Future<void> _saveCollections() async {
    _staticCollectionsCache = List.from(_collections);
    final prefs = await SharedPreferences.getInstance();
    final rawJson = json.encode(_collections.map((c) => c.toMap()).toList());
    await prefs.setString(_storageKey, rawJson);

    if (_collections.isNotEmpty) {
      final activeCol = _collections.firstWhere(
        (c) => c.isActive,
        orElse: () => _collections.first,
      );
      PhotoWallCard.updateStaticCache(activeCol);
    }
  }

  /// 创建新照片墙集合
  void _showCreateCollectionDialog() {
    final TextEditingController titleController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    IslandDialog.show(
      context,
      title: '新建照片墙集合',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '为您的写真相册框起一个治愈的名字：',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF8D827A),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            autofocus: true,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'LXGWWenKai',
              color: isDark ? Colors.white : const Color(0xFF3E2723),
            ),
            decoration: InputDecoration(
              hintText: '如：7月海岛度假、浪漫晚霞...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFFA89F91),
                fontSize: 13,
                fontFamily: 'LXGWWenKai',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEDF2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
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
          _collections.add(newCol);
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    IslandDialog.show(
      context,
      title: '修改集合名称',
      content: TextField(
        controller: titleController,
        autofocus: true,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'LXGWWenKai',
          color: isDark ? Colors.white : const Color(0xFF3E2723),
        ),
        decoration: InputDecoration(
          hintText: '请输入新名称',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFFA89F91),
            fontSize: 13,
            fontFamily: 'LXGWWenKai',
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFEDF2F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
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


  /// 进入某个照片墙集合详情 (顺滑快速转场，瞬间隐藏列表页)
  void _openCollectionDetail(PhotoWallCollection col) async {
    await Navigator.of(context).push<PhotoWallCollection>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 120), // 加快退出速度，杜绝残影
        pageBuilder: (context, animation, secondaryAnimation) => PhotoWallDetailPage(
          collection: col,
          isNight: widget.isNight,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            // 退出时改用 easeOut 或线性，使透明度迅速下降，避免虚影滞留
            reverseCurve: Curves.easeOut,
          );
          return FadeTransition(
            opacity: curvedAnim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
              child: child,
            ),
          );
        },
      ),
    );

    if (mounted) {
      _loadCollections();
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: BouncingButton(
                  onTap: _showCreateCollectionDialog,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.60),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: textColor,
                      size: 22,
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

          // 1. 主体网格区
          Positioned.fill(
            child: _isLoading
                ? const SizedBox.shrink() // 加载中透明占位（背景可透出，避免纯白转圈）
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
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
                              return CollectionBoxCard(
                                collection: _collections[index],
                                isDark: isDark,
                                textColor: textColor,
                                presetPhotos: _presetPhotos,
                                onTap: () => _openCollectionDetail(_collections[index]),
                                onRename: () => _renameCollection(_collections[index]),
                                onDelete: () => _deleteCollection(_collections[index]),
                                onSetActive: () => _setActiveCollection(_collections[index]),
                              );
                            },
                            childCount: _collections.length,
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

}
