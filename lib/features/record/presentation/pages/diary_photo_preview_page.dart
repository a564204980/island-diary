import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 照片沉浸预览页面 (沉浸式布局，功能全收纳至顶部右侧方块按钮)
class DiaryPhotoPreviewPage extends StatefulWidget {
  final DiaryEntry entry;
  final String imagePath; // 点击进入时的初始图片

  const DiaryPhotoPreviewPage({
    super.key,
    required this.entry,
    required this.imagePath,
  });

  @override
  State<DiaryPhotoPreviewPage> createState() => _DiaryPhotoPreviewPageState();
}

class _DiaryPhotoPreviewPageState extends State<DiaryPhotoPreviewPage> {
  late List<String> _diaryImages;
  late PageController _pageController;
  int _currentPage = 0;
  bool _showUI = false;

  @override
  void initState() {
    super.initState();
    _diaryImages = widget.entry.blocks
        .where((b) => b['type'] == 'image')
        .map((b) => b['path'] as String)
        .toList();
    
    _currentPage = _diaryImages.indexOf(widget.imagePath);
    if (_currentPage == -1) _currentPage = 0;
    
    _pageController = PageController(initialPage: _currentPage);

    // 延迟显示 UI 元素，等待 Hero 动画完成
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _showUI = true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final bgColor = isNight ? const Color(0xFF13131F) : const Color(0xFFF7F2E9);
    final panelBgColor = isNight 
        ? const Color(0xFF212831).withValues(alpha: 0.5) 
        : const Color(0xFFFFFBF7);
    final textColor = isNight ? Colors.white : Colors.black87;
    final subTextColor = isNight ? Colors.white.withValues(alpha: 0.5) : Colors.black45;
    final accentColor = const Color(0xFFD4A373);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. 页头标题 (含返回键 & 右侧方块功能键)
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildHeader(context, isNight, textColor, accentColor),
            ),
            
            // 1. 可滚动区域
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // 照片展示区
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 400,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _diaryImages.length,
                                onPageChanged: (index) => setState(() => _currentPage = index),
                                itemBuilder: (context, index) {
                                  return Hero(
                                    tag: index == _currentPage 
                                        ? 'photo_${widget.entry.id}_${_diaryImages[index]}'
                                        : 'photo_page_$index',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: DiaryUtils.buildImage(
                                        _diaryImages[index],
                                        width: MediaQuery.of(context).size.width - 32,
                                        height: 400,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // 页码指示器
                            if (_diaryImages.length > 1)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: AnimatedOpacity(
                                  opacity: _showUI ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      "${_currentPage + 1}/${_diaryImages.length}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 内容区块
                    AnimatedOpacity(
                      opacity: _showUI ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // 2. 日期与天气
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${widget.entry.dateTime.month}月${widget.entry.dateTime.day}日",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'LXGWWenKai',
                                      ),
                                    ),
                                    Text(
                                      DiaryUtils.getWeekdayChinese(widget.entry.dateTime.weekday),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 15,
                                        fontFamily: 'LXGWWenKai',
                                      ),
                                    ),
                                  ],
                                ),
                                _buildWeatherTag(widget.entry.weather ?? "晴天", isNight, accentColor),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 3. 正文记录
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              widget.entry.content.isEmpty ? "这一刻，只想静静记录..." : widget.entry.content,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.8),
                                fontSize: 16,
                                height: 1.6,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 4. 元数据面板
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: panelBgColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: !isNight ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _buildMetaItem(Icons.calendar_today_rounded, "拍摄时间", 
                                        "${widget.entry.dateTime.year}/${widget.entry.dateTime.month.toString().padLeft(2,'0')}/${widget.entry.dateTime.day.toString().padLeft(2,'0')}\n${widget.entry.dateTime.hour.toString().padLeft(2,'0')}:${widget.entry.dateTime.minute.toString().padLeft(2,'0')}", isNight, textColor, accentColor),
                                      _buildMetaItem(Icons.location_on_rounded, "拍摄地点", widget.entry.location ?? "未知地点\n暂无坐标", isNight, textColor, accentColor),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      _buildMetaItem(Icons.smartphone_rounded, "设备", "iPhone 15\nPro", isNight, textColor, accentColor),
                                      _buildMetaItem(Icons.local_offer_rounded, "标签", widget.entry.tag ?? "无标签\n记录生活", isNight, textColor, accentColor),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 5. 快捷输入区
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: panelBgColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: !isNight ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit_note_rounded, color: accentColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "给这张照片添加记录...",
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.25),
                                      fontSize: 14,
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isNight, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：返回 & 标题
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 24),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "时光画廊",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "记录生活，珍藏美好瞬间",
                  style: TextStyle(
                    color: isNight ? Colors.white54 : Colors.black45,
                    fontSize: 16,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),
          // 右侧：圆形功能区 (参考截图)
          ValueListenableBuilder<List<DiaryEntry>>(
            valueListenable: UserState().savedDiaries,
            builder: (context, diaries, _) {
              final entry = diaries.firstWhere((e) => e.id == widget.entry.id, orElse: () => widget.entry);
              final bool isLiked = entry.isLiked;
              
              return Row(
                children: [
                  _buildCircleBtn(
                    isLiked ? Icons.star_rounded : Icons.star_outline_rounded, 
                    () => UserState().toggleLike(widget.entry.id), 
                    isNight, 
                    accentColor
                  ),
                  const SizedBox(width: 8),
                  _buildCircleBtn(Icons.ios_share_rounded, () {}, isNight, accentColor),
                  const SizedBox(width: 8),
                  _buildMoreBtn(isNight, accentColor, textColor),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap, bool isNight, Color accentColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 22),
      ),
    );
  }

  Widget _buildMoreBtn(bool isNight, Color accentColor, Color textColor) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: isNight ? const Color(0xFF2C2C3E) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz_rounded, color: accentColor, size: 22),
      ),
      onSelected: (value) {
        // 根据 value 处理不同逻辑
      },
      itemBuilder: (context) => [
        _buildPopupItem('edit', Icons.edit_rounded, "编辑照片", textColor, accentColor),
        _buildPopupItem('tag', Icons.local_offer_rounded, "添加标签", textColor, accentColor),
        _buildPopupItem('cover', Icons.photo_rounded, "设为封面", textColor, accentColor),
        _buildPopupItem('copy', Icons.copy_all_rounded, "复制到相册", textColor, accentColor),
        const PopupMenuDivider(height: 1),
        _buildPopupItem('export', Icons.download_rounded, "导出照片", textColor, accentColor),
        _buildPopupItem('print', Icons.print_rounded, "打印照片", textColor, accentColor),
        const PopupMenuDivider(height: 1),
        _buildPopupItem('delete', Icons.delete_outline_rounded, "删除照片", Colors.redAccent, Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String title, Color textColor, Color iconColor) {
    return PopupMenuItem(
      value: value,
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: iconColor.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 14),
          Text(
            title, 
            style: TextStyle(
              color: textColor, 
              fontSize: 15,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherTag(String weather, bool isNight, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_rounded, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Text(
            weather,
            style: TextStyle(
              color: accentColor, 
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value, bool isNight, Color textColor, Color accentColor) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: isNight ? Colors.white.withValues(alpha: 0.3) : Colors.black38, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: textColor, 
                  fontSize: 13, 
                  height: 1.3,
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
