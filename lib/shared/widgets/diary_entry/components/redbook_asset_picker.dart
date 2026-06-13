import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:island_diary/core/state/user_state.dart';

class RedBookAssetPicker extends StatefulWidget {
  final int maxAssets;
  final RequestType requestType;

  const RedBookAssetPicker({
    super.key,
    this.maxAssets = 1,
    this.requestType = RequestType.common,
  });

  static Future<List<AssetEntity>?> pick(
    BuildContext context, {
    int maxAssets = 1,
    RequestType requestType = RequestType.common,
  }) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      PhotoManager.openSetting();
      return null;
    }
    if (!context.mounted) return null;
    return Navigator.push<List<AssetEntity>>(
      context,
      MaterialPageRoute(
        builder: (context) => RedBookAssetPicker(
          maxAssets: maxAssets,
          requestType: requestType,
        ),
      ),
    );
  }

  @override
  State<RedBookAssetPicker> createState() => _RedBookAssetPickerState();
}

class _RedBookAssetPickerState extends State<RedBookAssetPicker> with SingleTickerProviderStateMixin {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _allAssets = [];
  List<AssetEntity> _filteredAssets = [];
  final List<AssetEntity> _selectedAssets = [];

  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 80;
  bool _hasMore = true;

  final List<String> _tabs = ['全部', '视频', '照片', '实况图'];
  int _currentTabIdx = 0;
  bool _isAlbumDropdownOpen = false;

  bool _isLoadingHuaweiLive = false;
  List<AssetEntity> _huaweiLiveAssets = [];

  Future<void> _loadHuaweiLiveAssets() async {
    if (_huaweiLiveAssets.isNotEmpty || _isLoadingHuaweiLive) return;
    setState(() => _isLoadingHuaweiLive = true);
    try {
      final List<dynamic>? ids = await const MethodChannel('com.example.island_diary/huawei_motion_photo')
          .invokeMethod('getHuaweiMotionPhotoIds');
      if (ids != null && ids.isNotEmpty) {
        final List<AssetEntity> temp = [];
        for (final id in ids) {
          final entity = await AssetEntity.fromId(id.toString());
          if (entity != null) {
            temp.add(entity);
          }
        }
        setState(() {
          _huaweiLiveAssets = temp;
        });
      }
    } catch (e) {
      debugPrint("Failed to load Huawei live photos: $e");
    } finally {
      setState(() => _isLoadingHuaweiLive = false);
      _filterAssets();
    }
  }

  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIdx = _tabController.index;
        _filterAssets();
      });
    });
    _scrollController.addListener(_onScroll);
    _loadAlbums();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: widget.requestType,
        filterOption: FilterOptionGroup(
          containsLivePhotos: true,
          onlyLivePhotos: false,
        ),
      );
      if (paths.isNotEmpty) {
        setState(() {
          _albums = paths;
          _selectedAlbum = paths.first;
        });
        await _loadAssets(replace: true);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to load albums: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssets({bool replace = false}) async {
    if (_selectedAlbum == null) return;
    setState(() => _isLoading = true);
    try {
      if (replace) {
        _currentPage = 0;
        _allAssets.clear();
        _hasMore = true;
      }
      final List<AssetEntity> list = await _selectedAlbum!.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _allAssets.addAll(list);
          _currentPage++;
          if (list.length < _pageSize) {
            _hasMore = false;
          }
        }
        _filterAssets();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load assets: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterAssets() {
    if (_currentTabIdx == 0) {
      // 全部
      _filteredAssets = List.from(_allAssets);
    } else if (_currentTabIdx == 1) {
      // 视频
      _filteredAssets = _allAssets.where((e) => e.type == AssetType.video).toList();
    } else if (_currentTabIdx == 2) {
      // 照片
      _filteredAssets = _allAssets.where((e) => e.type == AssetType.image).toList();
    } else if (_currentTabIdx == 3) {
      // 实况图 (Live Photo)
      final isAndroid = Theme.of(context).platform == TargetPlatform.android;
      if (isAndroid) {
        _filteredAssets = _huaweiLiveAssets;
        _loadHuaweiLiveAssets();
      } else {
        _filteredAssets = _allAssets.where((e) => e.isLivePhoto).toList();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadAssets();
      }
    }
  }

  void _toggleSelect(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        if (widget.maxAssets == 1) {
          _selectedAssets.clear();
          _selectedAssets.add(asset);
        } else if (_selectedAssets.length < widget.maxAssets) {
          _selectedAssets.add(asset);
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  Widget _buildTopBar(String fontFamily) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF121212),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧关闭
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          // 中间相册选择下拉
          GestureDetector(
            onTap: () {
              setState(() {
                _isAlbumDropdownOpen = !_isAlbumDropdownOpen;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedAlbum?.name ?? '相册',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isAlbumDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
          // 右侧确定按钮
          GestureDetector(
            onTap: () {
              if (_selectedAssets.isNotEmpty) {
                Navigator.pop(context, _selectedAssets);
              } else {
                // 如果没有选择任何照片，默认返回关闭
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedAssets.isNotEmpty
                    ? const Color(0xFFFF2442) // 小红书经典红
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedAssets.isNotEmpty
                    ? "确定(${_selectedAssets.length})"
                    : "草稿箱",
                style: TextStyle(
                  color: _selectedAssets.isNotEmpty ? Colors.white : Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(String fontFamily) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.only(bottom: 8),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
        indicator: const FixedWidthUnderlineTabIndicator(
          width: 16,
          height: 3,
          color: Color(0xFFFF2442),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: fontFamily),
        unselectedLabelStyle: TextStyle(fontSize: 15, fontFamily: fontFamily),
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildMediaGrid(String fontFamily) {
    if (_filteredAssets.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          '无媒体资源',
          style: TextStyle(color: Colors.white38, fontSize: 16, fontFamily: fontFamily),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(1.5),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: _filteredAssets.length,
      itemBuilder: (context, index) {
        final asset = _filteredAssets[index];
        final isSelected = _selectedAssets.contains(asset);
        final selectIndex = _selectedAssets.indexOf(asset) + 1;

        return GestureDetector(
          onTap: () => _toggleSelect(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 缩略图
              AssetEntityImage(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(200),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
              // 左下角：视频时长 或 实况图图标
              if (asset.type == AssetType.video)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        _formatDuration(asset.videoDuration),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                )
              else if (asset.isLivePhoto)
                const Positioned(
                  left: 6,
                  bottom: 6,
                  child: Icon(
                    Icons.lens_blur_rounded, // 类似于小红书/iOS Live Photo 的同心圆/虚化圆圈图标
                    color: Colors.white,
                    size: 16,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              // 右上角：选择圈圈
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _toggleSelect(asset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      color: isSelected ? const Color(0xFFFF2442) : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Text(
                            widget.maxAssets == 1 ? "✓" : "$selectIndex",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumDropdown(String fontFamily) {
    return Positioned(
      top: 56,
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: [
          // 暗色透明背景，点击关闭下拉
          GestureDetector(
            onTap: () => setState(() => _isAlbumDropdownOpen = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          // 相册列表内容
          Container(
            color: const Color(0xFF1A1A1A),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _albums.length,
              itemBuilder: (context, index) {
                final album = _albums[index];
                final isSelected = _selectedAlbum == album;
                return FutureBuilder<int>(
                  future: album.assetCountAsync,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: album.name.isNotEmpty
                            ? FutureBuilder<List<AssetEntity>>(
                                future: album.getAssetListRange(start: 0, end: 1),
                                builder: (context, shot) {
                                  if (shot.hasData && shot.data!.isNotEmpty) {
                                    return AssetEntityImage(
                                      shot.data!.first,
                                      isOriginal: false,
                                      thumbnailSize: const ThumbnailSize.square(100),
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Icon(Icons.image, color: Colors.white24);
                                },
                              )
                            : const Icon(Icons.image, color: Colors.white24),
                      ),
                      title: Text(
                        album.name,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFFF2442) : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                          fontFamily: fontFamily,
                        ),
                      ),
                      subtitle: Text(
                        '$count 张',
                        style: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: fontFamily),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: Color(0xFFFF2442))
                          : null,
                      onTap: () async {
                        setState(() {
                          _selectedAlbum = album;
                          _isAlbumDropdownOpen = false;
                          _isLoading = true;
                        });
                        await _loadAssets(replace: true);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(fontFamily),
                _buildTabBar(fontFamily),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMediaGrid(fontFamily),
                      if (_isLoading && _allAssets.isEmpty)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2442)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isAlbumDropdownOpen) _buildAlbumDropdown(fontFamily),
          ],
        ),
      ),
    );
  }
}

class FixedWidthUnderlineTabIndicator extends Decoration {
  final double width;
  final double height;
  final Color color;

  const FixedWidthUnderlineTabIndicator({
    this.width = 16,
    this.height = 3,
    this.color = const Color(0xFFFF2442),
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedWidthUnderlinePainter(this, onChanged);
  }
}

class _FixedWidthUnderlinePainter extends BoxPainter {
  final FixedWidthUnderlineTabIndicator decoration;

  _FixedWidthUnderlinePainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final double centerX = rect.left + rect.width / 2;
    final double bottomY = rect.bottom;
    
    final Paint paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;
      
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - decoration.width / 2, 
        bottomY - decoration.height, 
        decoration.width, 
        decoration.height
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rrect, paint);
  }
}
