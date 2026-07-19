import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/features/record/presentation/pages/camera_edit/camera_edit_overlay.dart';
import 'package:island_diary/core/theme/app_colors.dart';

// ── 数据模型 ────────────────────────────────────────────────────────────────

abstract class GalleryItem {}

class PhotoItem extends GalleryItem {
  final AssetEntity asset;
  PhotoItem(this.asset);
}

class MonthCardItem extends GalleryItem {
  final String title;
  final String subtitle;
  final Color bgColor;
  MonthCardItem(this.title, this.subtitle, this.bgColor);
}

// ── 瀑布流相册画廊 ───────────────────────────────────────────────────────────

/// 联动相机取景器动画的相册瀑布流组件。
/// [animation] 由父级 _unfoldCurvedAnimation 驱动，控制列表随取景器展开/收起的联动偏移。
/// [viewfinderHeight] 取景器完全展开后的高度，用于计算列表的起始偏移量。
class WaterfallAlbumGallery extends StatefulWidget {
  final Animation<double>? animation;
  final double? viewfinderHeight;
  final VoidCallback? onCancel;

  const WaterfallAlbumGallery({
    super.key,
    this.animation,
    this.viewfinderHeight,
    this.onCancel,
  });

  @override
  State<WaterfallAlbumGallery> createState() => _WaterfallAlbumGalleryState();
}

class _WaterfallAlbumGalleryState extends State<WaterfallAlbumGallery> {
  List<GalleryItem> _items = [];
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  bool _isLoading = true;
  bool _isShowingAlbumList = false;

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
  }

  Future<void> _loadGalleryData() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final FilterOptionGroup filterOptionGroup = FilterOptionGroup(
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false,
        ),
      ],
    );

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common, // 支持图片和视频
      hasAll: true,
      filterOption: filterOptionGroup,
    );

    if (paths.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _albums = paths;
      _currentAlbum ??= paths.first;
    });

    final List<AssetEntity> entities =
        await _currentAlbum!.getAssetListPaged(page: 0, size: 30);

    final List<GalleryItem> newItems = [];
    int? lastMonth;

    final List<Color> monthColors = [
      const Color(0xFFC5B8A5),
      const Color(0xFF788394),
      const Color(0xFF9E928A),
      const Color(0xFF8BA59B),
    ];
    int colorIndex = 0;

    for (var entity in entities) {
      final date = entity.createDateTime;
      if (lastMonth != date.month) {
        lastMonth = date.month;
        final monthStr = '${date.year}年${date.month}月';
        final monthEnStr = _getMonthZh(date.month);
        newItems.add(MonthCardItem(
          monthStr,
          monthEnStr,
          monthColors[colorIndex % monthColors.length],
        ));
        colorIndex++;
      }
      newItems.add(PhotoItem(entity));
    }

    if (mounted) {
      setState(() {
        _items = newItems;
        _isLoading = false;
      });
    }
  }

  String _getMonthZh(int month) {
    const months = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final galleryItems = Stack(
          children: [
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: colors.textSecondary),
              )
            else if (_isShowingAlbumList)
              _buildAlbumList()
            else
              MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                padding: EdgeInsets.only(
                  top: 11.0 + 37.0 + 24.0, // 初始位置位于胶囊下方 gap(24) 处
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 80, // 增加底部边距，避免被导航栏遮挡
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  if (item is MonthCardItem) {
                    return _buildMonthCard(item);
                  } else if (item is PhotoItem) {
                    return _buildPhotoCard(item);
                  }
                  return const SizedBox();
                },
              ),
            // 悬浮底部菜单导航栏 (图2样式：胶囊形状、毛玻璃)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: _buildBottomNavigationBar(context),
            ),
          ],
        );

    if (widget.animation == null || widget.viewfinderHeight == null) {
      return Container(
        color: colors.cardBackground,
        child: galleryItems,
      );
    }

    return Container(
      color: colors.cardBackground, // 静态铺满屏幕的纯色背景
      child: AnimatedBuilder(
        animation: widget.animation!,
        builder: (context, child) {
        final t = widget.animation!.value;

        final startTop = 11.0;
        final endTop = MediaQuery.of(context).padding.top + 70;
        final currentTop = lerpDouble(startTop, endTop, t)!;

        final startHeight = 37.0;
        final endHeight = widget.viewfinderHeight!;
        final currentHeight = lerpDouble(startHeight, endHeight, t)!;

        final viewfinderBottom = currentTop + currentHeight;
        final capsuleBottom = 11.0 + 37.0; // 48.0

        // 当 t=0 时，translateY = 0，让容器铺满屏幕，照片可以穿越胶囊底部
        // 当 t=1 时，translateY 把照片推到取景器下方
        final translateY = viewfinderBottom - capsuleBottom;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: child,
        );
      },
      child: galleryItems,
    ));
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              // 增加不透明度，使用更深的颜色
              color: const Color(0xFF2C2C2C).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // 胶囊根据内容紧凑
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 取消按钮 -> 返回图标
                GestureDetector(
                  onTap: () {
                    if (widget.onCancel != null) {
                      widget.onCancel!();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // 拆分为两个图标：照片 / 相册
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 照片图标 (点击回到全部照片/退出相册列表)
                    GestureDetector(
                      onTap: () {
                        if (_isShowingAlbumList || (_albums.isNotEmpty && _currentAlbum?.id != _albums.first.id)) {
                          setState(() {
                            _isShowingAlbumList = false;
                            if (_albums.isNotEmpty) {
                              _currentAlbum = _albums.first;
                            }
                            _isLoading = true;
                          });
                          _loadGalleryData();
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.image_rounded,
                          color: (!_isShowingAlbumList && _currentAlbum?.id == _albums.firstOrNull?.id) ? Colors.white : Colors.white54,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 相册图标 (点击打开相册分类列表)
                    GestureDetector(
                      onTap: () {
                        if (!_isShowingAlbumList) {
                          setState(() {
                            _isShowingAlbumList = true;
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.photo_library_rounded,
                          color: _isShowingAlbumList ? Colors.white : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateAlbumName(String name) {
    if (name == 'Recent' || name == 'Recent_Added') return '全部照片';
    if (name == 'Pictures') return '图片';
    if (name == 'Download') return '下载';
    if (name == 'Camera') return '相机';
    if (name == 'Screenshots') return '截图';
    if (name == 'Screenrecords' || name == 'Screen Recording') return '屏幕录制';
    if (name == 'Video' || name == 'Videos' || name == 'Movies') return '视频';
    if (name == 'WeiXin') return '微信';
    return name;
  }

  Widget _buildAlbumList() {
    return GridView.builder(
      padding: EdgeInsets.only(
        top: 11.0 + 37.0 + 24.0, // 与瀑布流一致的顶部留白
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 一排三个
        mainAxisSpacing: 24,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75, // 控制封面(正方形)和下方文字的高度比例
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        final displayName = _translateAlbumName(album.name);
        return _buildAlbumListItem(album, displayName);
      },
    );
  }

  Widget _buildAlbumListItem(AssetPathEntity album, String displayName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentAlbum = album;
          _isShowingAlbumList = false;
          _isLoading = true;
        });
        _loadGalleryData();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 相册封面缩略图 (正方形大图)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FutureBuilder<List<AssetEntity>>(
                future: album.getAssetListPaged(page: 0, size: 1),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final asset = snapshot.data!.first;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AssetEntityImage(
                            asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(300),
                            thumbnailFormat: ThumbnailFormat.jpeg,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.photo_album, color: Colors.white54),
                          ),
                          // 视频图标
                          if (asset.type == AssetType.video)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Icon(Icons.videocam_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                            ),
                        ],
                      ),
                    );
                  }
                  return const Icon(Icons.photo_album, color: Colors.white54);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 相册名称
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColorsExtension.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // 数量
          FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snapshot) {
              return Text(
                '${snapshot.data ?? 0}',
                style: TextStyle(
                  color: AppColorsExtension.of(context).textSecondary,
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(MonthCardItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(PhotoItem item) {
    double ratio = 1.0;
    if (item.asset.width > 0 && item.asset.height > 0) {
      ratio = item.asset.width / item.asset.height;
    }

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        try {
          final file = await item.asset.file;
          if (file != null && mounted) {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                reverseTransitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Scaffold(
                    backgroundColor: Colors.black,
                    body: CameraEditOverlay(
                      heroTag: 'gallery_photo_${item.asset.id}',
                      isFromAlbum: true,
                      capturedRawPath: file.path,
                      initialRatio: '4:3',
                      initialWatermarkStyle: 'none',
                      initialFilter: 'none',
                      initialAdjustParams: const {
                        'exposure': 0.0,
                        'highlights': 0.0,
                        'shadows': 0.0,
                        'brightness': 0.0,
                        'contrast': 0.0,
                        'whites': 0.0,
                        'blacks': 0.0,
                        'saturation': 0.0,
                        'vibrance': 0.0,
                        'temp': 0.0,
                        'sharpness': 0.0,
                        'fade': 0.0,
                      },
                      initialMattingMode: 'none',
                      onReTake: () => Navigator.pop(context),
                      onConfirm: (editedPath, mattedPath) {
                        Navigator.pop(context, {
                          'editedPath': editedPath,
                          'mattedPath': mattedPath,
                        });
                      },
                    ),
                  );
                },
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );

            if (result != null && mounted) {
              Navigator.pop(context, result);
            }
          } else if (file == null && mounted) {
            showTopToast(context, '无法获取图片，可能还在云端或已被删除');
          }
        } catch (e) {
          debugPrint('获取相册图片失败: $e');
          if (mounted) {
            showTopToast(context, '无法获取图片，可能还在云端或已被删除');
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: ratio,
            child: Hero(
              tag: 'gallery_photo_${item.asset.id}',
              child: AssetEntityImage(
                item.asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(250),
                thumbnailFormat: ThumbnailFormat.jpeg,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image, color: Colors.white54),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
