import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'diary_photo_preview_page.dart';
import 'diary_editor_page.dart';

enum PhotoViewMode { grid, list }

enum PhotoSortOrder { latest, oldest }

/// 时光画廊：沉浸式照片墙视图
class DiaryPhotoWallPage extends StatefulWidget {
  const DiaryPhotoWallPage({super.key});

  @override
  State<DiaryPhotoWallPage> createState() => _DiaryPhotoWallPageState();
}

class _DiaryPhotoWallPageState extends State<DiaryPhotoWallPage> {
  PhotoViewMode _viewMode = PhotoViewMode.grid;
  PhotoSortOrder _sortOrder = PhotoSortOrder.latest;

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final bgColor = isNight ? const Color(0xFF13131F) : const Color(0xFFF7F2E9);
    final accentColor = const Color(0xFFD4A373);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ValueListenableBuilder<List<DiaryEntry>>(
          valueListenable: UserState().savedDiaries,
          builder: (context, diaries, _) {
            final List<_PhotoItem> photoItems = [];
            for (var diary in diaries) {
              for (var block in diary.blocks) {
                if (block['type'] == 'image') {
                  photoItems.add(_PhotoItem(
                    diary: diary,
                    imagePath: block['path'],
                  ));
                }
              }
            }

            if (_sortOrder == PhotoSortOrder.latest) {
              photoItems.sort((a, b) => b.diary.dateTime.compareTo(a.diary.dateTime));
            } else {
              photoItems.sort((a, b) => a.diary.dateTime.compareTo(b.diary.dateTime));
            }

            final List<Widget> slivers = [];

            // 1. 标题栏
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: isNight ? Colors.white : Colors.black87,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "时光画廊",
                            style: TextStyle(
                              color: isNight ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              fontFamily: 'LXGWWenKai',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: Text(
                          "记录生活，珍藏美好瞬间",
                          style: TextStyle(
                            color: isNight ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // 2. 工具栏
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildViewToggleBtn(PhotoViewMode.grid, Icons.grid_view_rounded, isNight, accentColor),
                            _buildViewToggleBtn(PhotoViewMode.list, Icons.view_list_rounded, isNight, accentColor),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PhotoSortOrder>(
                            value: _sortOrder,
                            icon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(Icons.unfold_more_rounded, size: 16, color: isNight ? Colors.white38 : Colors.black38),
                            ),
                            dropdownColor: isNight ? const Color(0xFF1E1E2C) : Colors.white,
                            borderRadius: BorderRadius.circular(20), // 重点：让菜单也变圆润
                            elevation: 8,
                            style: TextStyle(
                              fontSize: 13,
                              color: isNight ? Colors.white70 : Colors.black87,
                              fontFamily: 'LXGWWenKai',
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (val) {
                              if (val != null) setState(() => _sortOrder = val);
                            },
                            items: [
                              DropdownMenuItem(
                                value: PhotoSortOrder.latest, 
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(_sortOrder == PhotoSortOrder.latest ? "最新在前 · ✓" : "最新在前"),
                                )
                              ),
                              DropdownMenuItem(
                                value: PhotoSortOrder.oldest, 
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(_sortOrder == PhotoSortOrder.oldest ? "最早在前 · ✓" : "最早在前"),
                                )
                              ),
                            ],
                            selectedItemBuilder: (context) {
                              return [
                                const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("最新在前"))),
                                const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("最早在前"))),
                              ];
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // 3. 内容区
            if (photoItems.isEmpty) {
              slivers.add(_buildEmptyState(isNight));
            } else {
              if (_viewMode == PhotoViewMode.grid) {
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _GalleryCard(
                          item: photoItems[index],
                          index: index,
                          totalCount: photoItems.length,
                          isNight: isNight,
                          accentColor: accentColor,
                        ),
                        childCount: photoItems.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85, 
                      ),
                    ),
                  ),
                );
              } else {
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GalleryCard(
                            item: photoItems[index],
                            index: index,
                            totalCount: photoItems.length,
                            isNight: isNight,
                            accentColor: accentColor,
                            isHorizontal: true,
                          ),
                        ),
                        childCount: photoItems.length,
                      ),
                    ),
                  ),
                );
              }

              // 4. 统计
              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Center(
                      child: Text(
                        "共 ${photoItems.length} 张照片",
                        style: TextStyle(
                          color: isNight ? Colors.white24 : Colors.black26,
                          fontSize: 13,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: slivers,
            );
          },
        ),
      ),
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentColor,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openNewDiary,
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNewDiary() async {
    final draft = UserState().diaryDraft.value;
    if (draft != null) {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditorPage(
            moodIndex: draft.moodIndex,
            intensity: draft.intensity,
            tag: draft.tag,
          ),
        ),
      );
      return;
    }

    // 直接进入编辑器 (默认：平静心情)
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const DiaryEditorPage(moodIndex: 4, intensity: 6),
      ),
    );
  }

  Widget _buildViewToggleBtn(PhotoViewMode mode, IconData icon, bool isNight, Color accentColor) {
    final bool isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? (isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive && !isNight
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? accentColor : (isNight ? Colors.white30 : Colors.black26),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isNight) {
    return SliverToBoxAdapter(
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: isNight ? Colors.white10 : Colors.black12),
            const SizedBox(height: 16),
            Text("还没有留下照片记忆呢...", style: TextStyle(
              color: isNight ? Colors.white24 : Colors.black26,
              fontFamily: 'LXGWWenKai',
            )),
          ],
        ),
      ),
    );
  }
}

class _PhotoItem {
  final DiaryEntry diary;
  final String imagePath;
  _PhotoItem({required this.diary, required this.imagePath});
}

class _GalleryCard extends StatelessWidget {
  final _PhotoItem item;
  final int index;
  final int totalCount;
  final bool isNight;
  final Color accentColor;
  final bool isHorizontal;

  const _GalleryCard({
    required this.item,
    required this.index,
    required this.totalCount,
    required this.isNight,
    required this.accentColor,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = "${item.diary.dateTime.month}月${item.diary.dateTime.day}日";
    final weekday = DiaryUtils.getWeekdayChinese(item.diary.dateTime.weekday);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryPhotoPreviewPage(
              entry: item.diary,
              imagePath: item.imagePath,
            ),
          ),
        );
      },
      child: Container(
        height: isHorizontal ? 120 : 230,
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF212831) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNight ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. 照片背景
            Positioned.fill(
              child: Hero(
                tag: 'photo_${item.diary.id}_${item.imagePath}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DiaryUtils.buildImage(item.imagePath, fit: BoxFit.cover),
                ),
              ),
            ),
            
            // 2. 底部渐变蒙层
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // 3. 底部信息
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                      Text(
                        weekday,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => UserState().toggleLike(item.diary.id),
                    child: Icon(
                      item.diary.isLiked ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: item.diary.isLiked ? accentColor : Colors.white38,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
