import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/profile/presentation/pages/diary_book_detail_page.dart';
import 'package:island_diary/features/profile/presentation/pages/diary_book_edit_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class DiaryBooksPage extends StatefulWidget {
  const DiaryBooksPage({super.key});

  @override
  State<DiaryBooksPage> createState() => _DiaryBooksPageState();
}

class _DiaryBooksPageState extends State<DiaryBooksPage> {
  final List<int> _presetColors = [
    0xFF64B5F6, // 天空蓝
    0xFF81C784, // 薄荷绿
    0xFFFFB74D, // 暖阳橙
    0xFFBA68C8, // 薰衣草紫
    0xFFF06292, // 珊瑚粉
  ];

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF13131F) : const Color(0xFFFDFCF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isNight ? Colors.white70 : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '岁月成书',
          style: TextStyle(
            color: isNight ? Colors.white : Colors.black87,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: isNight ? Colors.white70 : Colors.black87,
              size: 28,
            ),
            onPressed: () => _showCreateBookDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<DiaryBook>>(
        valueListenable: UserState().savedBooks,
        builder: (context, books, _) {
          return ValueListenableBuilder<List<dynamic>>(
            valueListenable: UserState().savedDiaries,
            builder: (context, diaries, _) {
              if (books.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books_rounded,
                        size: 60,
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '还没有日记本',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: isNight ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角的「+」按钮\n创建属于自己的第一本日记',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          fontFamily: fontFamily,
                          color: isNight ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.70, // 修改比例以匹配图2中更修长的真实书本比例
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  // 计算属于该日记本的日记数量
                  final int count = diaries.where((d) => d.bookId == book.id).length;
                  
                  // 获取属于该日记本的所有日记，按时间排序找到最早的记录时间
                  final bookDiaries = diaries.where((d) => d.bookId == book.id).toList();
                  bookDiaries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                  final String dateStr = bookDiaries.isNotEmpty
                      ? DateFormat('yyyy/MM/dd').format(bookDiaries.first.dateTime)
                      : '2024/11/26'; // 无记录时使用默认或图示示例日期

                  return _buildBookCard(context, book, count, dateStr, isNight, fontFamily);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    DiaryBook book,
    int count,
    String dateStr,
    bool isNight,
    String fontFamily,
  ) {
    final bookColor = Color(book.coverColorValue);
    final bool hasCustomCover = book.customCoverPath != null && File(book.customCoverPath!).existsSync();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryBookDetailPage(book: book),
          ),
        );
      },
      onLongPress: () {
        _showBookOptionsSheet(context, book);
      },
      child: Stack(
        children: [
          // 1. 纸张厚度（底层白边）
          Positioned(
            left: 6,
            top: 2,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isNight ? const Color(0xFFC0C0C0) : const Color(0xFFF4F1EA), // 纸张色
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border.all(color: isNight ? Colors.black38 : Colors.black12, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.3 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 0.5, color: Colors.black12, margin: const EdgeInsets.only(right: 3)),
                  Container(width: 0.5, color: Colors.black12, margin: const EdgeInsets.only(right: 3)),
                ],
              ),
            ),
          ),
          
          // 2. 书脊与硬皮封面
          Positioned(
            left: 0,
            top: 0,
            right: 6,
            bottom: 4, // 露出底部纸张
            child: Container(
              decoration: BoxDecoration(
                color: hasCustomCover ? Colors.transparent : bookColor.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                image: hasCustomCover
                    ? DecorationImage(
                        image: FileImage(File(book.customCoverPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 莫兰迪滤镜
                    if (!hasCustomCover)
                      Container(
                        color: isNight ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.15),
                      ),
                    
                    // 保留底部深色遮罩保证文字清晰可见
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 书脊阴影过渡
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 书脊边缘高光
                    Positioned(
                      left: 1,
                      top: 0,
                      bottom: 0,
                      width: 1,
                      child: Container(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    // 书皮内部翻折沟槽
                    Positioned(
                      left: 14,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 底部左下角元数据与标题
                    Positioned(
                      left: 20, // 稍微避开左侧书脊
                      bottom: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '始记于 $dateStr',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            book.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: fontFamily,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 右上角“更多”操作按钮
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showBookOptionsSheet(context, book),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  void _showCreateBookDialog(BuildContext context, {DiaryBook? editingBook}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DiaryBookEditPage(editingBook: editingBook),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteBook(BuildContext context, DiaryBook book) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DeleteBookConfirm',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isNight
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFFCFBF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 16, left: 24, right: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "确认删除日记本",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isNight
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF2C2C2C),
                            fontFamily: fontFamily,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "确定要删除《${book.name}》吗？\n删除日记本不会删除其中的日记。",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: isNight
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFF8E8E93),
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 0.5,
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              "保留",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isNight ? Colors.white54 : const Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        height: 50,
                        color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            await UserState().deleteBook(book.id);
                            navigator.pop();
                          },
                          borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              "确认删除",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD35D5D),
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
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isNight,
    required String fontFamily,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive 
                    ? const Color(0xFFC47B7B) 
                    : (isNight ? Colors.white54 : const Color(0xFF8E8E93)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: fontFamily,
                    color: isDestructive
                        ? const Color(0xFFC47B7B)
                        : (isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookOptionsSheet(BuildContext context, DiaryBook book) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return DiaryBottomSheet(
          paperStyle: 'default',
          showDragHandle: true,
          isDiary: false,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              _buildMenuOption(
                icon: Icons.edit_note_rounded,
                title: '重命名日记本',
                iconColor: const Color(0xFFD4A373),
                isNight: isNight,
                fontFamily: fontFamily,
                onTap: () {
                  Navigator.pop(context);
                  _showCreateBookDialog(context, editingBook: book);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              _buildMenuOption(
                icon: Icons.image_outlined,
                title: '设置自定义封面',
                iconColor: const Color(0xFFD4A373),
                isNight: isNight,
                fontFamily: fontFamily,
                onTap: () {
                  Navigator.pop(context);
                  _showCoverPicker(context, book);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              _buildMenuOption(
                icon: Icons.delete_outline_rounded,
                title: '删除日记本',
                iconColor: Colors.redAccent,
                isNight: isNight,
                fontFamily: fontFamily,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteBook(context, book);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<String?> _compressAndSaveCoverHelper(String originPath, String bookId) async {
    try {
      final bytes = await File(originPath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final img.Image resized;
      if (image.width > 300) {
        resized = img.copyResize(image, width: 300);
      } else {
        resized = image;
      }

      final compressedBytes = img.encodeJpg(resized, quality: 75);
      final docDir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${docDir.path}/custom_covers');
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      final newPath = '${coverDir.path}/cover_${bookId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(newPath).writeAsBytes(compressedBytes);
      return newPath;
    } catch (e) {
      debugPrint("封面压缩保存失败: $e");
      return null;
    }
  }

  void _showCoverPickerHelper(BuildContext context, String bookId, Function(String) onCoverSaved) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return DiaryBottomSheet(
          paperStyle: 'default',
          showDragHandle: true,
          isDiary: false,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Text(
                    '设置自定义封面',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final List<AssetEntity>? result = await AssetPicker.pickAssets(
                    context,
                    pickerConfig: AssetPickerConfig(
                      maxAssets: 1,
                      requestType: RequestType.image,
                      filterOptions: FilterOptionGroup(containsLivePhotos: true),
                    ),
                  );
                  if (result != null && result.isNotEmpty) {
                    final file = await result.first.file;
                    if (file != null) {
                      final path = await _compressAndSaveCoverHelper(file.path, bookId);
                      if (path != null) {
                        onCoverSaved(path);
                      }
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '从相册挑选',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    final path = await _compressAndSaveCoverHelper(photo.path, bookId);
                    if (path != null) {
                      onCoverSaved(path);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '拍摄新照片',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCoverPicker(BuildContext context, DiaryBook book) {
    _showCoverPickerHelper(context, book.id, (path) async {
      if (book.customCoverPath != null) {
        final oldFile = File(book.customCoverPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      final updated = book.copyWith(customCoverPath: path);
      await UserState().updateBook(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('封面设置成功 ✨')),
        );
      }
    });
  }
}
