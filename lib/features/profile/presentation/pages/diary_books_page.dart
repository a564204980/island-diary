import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/profile/presentation/pages/diary_book_detail_page.dart';
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
                return const Center(child: CircularProgressIndicator());
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 22,
                  mainAxisSpacing: 28,
                  childAspectRatio: 0.48,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  // 计算属于该日记本的日记数量
                  final int count = diaries.where((d) => d.bookId == book.id).length;

                  return _buildBookCard(context, book, count, isNight, fontFamily);
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
    bool isNight,
    String fontFamily,
  ) {
    final bookColor = Color(book.coverColorValue);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryBookDetailPage(book: book),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                // 3D 阴影底层
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isNight
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(4, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                // 精美的封面主体
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: (book.customCoverPath == null || !File(book.customCoverPath!).existsSync())
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                bookColor,
                                bookColor.withValues(alpha: 0.75),
                              ],
                            )
                          : null,
                      image: (book.customCoverPath != null && File(book.customCoverPath!).existsSync())
                          ? DecorationImage(
                              image: FileImage(File(book.customCoverPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 书脊装饰线条
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // 细条阴影线模拟折页
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        // 铁圈活页装订效果
                        Positioned(
                          left: -10,
                          top: 10,
                          bottom: 10,
                          width: 14,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (i) {
                              return Container(
                                width: 12,
                                height: 5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 1.5,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFEEEEEE),
                                      Color(0xFFB0B0B0),
                                      Color(0xFF666666),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // 书脊内部更深的色条，营造3D深度感
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 4,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        // 书名与徽标
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const Spacer(),
                                Text(
                                  book.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (book.description.isNotEmpty)
                                  Text(
                                    book.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 8.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 底部信息与管理按钮
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white70 : Colors.black87,
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$count 篇记录',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isNight ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (book.id != 'default')
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: isNight ? Colors.white38 : Colors.black45,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showBookOptionsSheet(context, book),
                  ),
                )
              else
                const SizedBox(
                  width: 24,
                  height: 24,
                ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  void _showCreateBookDialog(BuildContext context, {DiaryBook? editingBook}) {
    final nameCtrl = TextEditingController(text: editingBook?.name ?? '');
    final descCtrl = TextEditingController(text: editingBook?.description ?? '');
    int selectedColorValue = editingBook?.coverColorValue ?? _presetColors[UserState().savedBooks.value.length % _presetColors.length];
    final String bookId = editingBook?.id ?? const Uuid().v4();
    String? tempCoverPath = editingBook?.customCoverPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final bool isNight = UserState().isNight;
        final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
            ? 'SweiFistLeg'
            : 'LXGWWenKai';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: DiaryBottomSheet(
                paperStyle: 'default',
                showDragHandle: true,
                isDiary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      editingBook == null ? '新建日记本' : '编辑日记本',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: fontFamily,
                        color: isNight ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      maxLength: 12,
                      decoration: InputDecoration(
                        hintText: '起个温暖的书名吧...',
                        counterText: '',
                        filled: true,
                        fillColor: isNight
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF7F5F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: isNight ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLength: 30,
                      decoration: InputDecoration(
                        hintText: '简介/寄语（选填）',
                        counterText: '',
                        filled: true,
                        fillColor: isNight
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF7F5F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: isNight ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '书籍封面图',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: fontFamily),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        _showCoverPickerHelper(context, bookId, (path) {
                          setModalState(() {
                            tempCoverPath = path;
                          });
                        });
                      },
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: isNight
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNight
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: tempCoverPath == null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFD4A373), size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    '上传封面图 (选填)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: fontFamily,
                                      color: isNight ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(tempCoverPath!),
                                        width: 54,
                                        height: 74,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '已选择封面图',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: fontFamily,
                                        fontWeight: FontWeight.w600,
                                        color: isNight ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setModalState(() {
                                        tempCoverPath = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                    label: Text(
                                      '删除',
                                      style: TextStyle(fontSize: 12, fontFamily: fontFamily, color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A373),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('书名不能为空名哦')),
                          );
                          return;
                        }
                        if (editingBook == null) {
                          final newBook = DiaryBook(
                            id: bookId,
                            name: name,
                            description: descCtrl.text.trim(),
                            coverColorValue: selectedColorValue,
                            customCoverPath: tempCoverPath,
                          );
                          await UserState().createBook(newBook);
                        } else {
                          final updated = editingBook.copyWith(
                            name: name,
                            description: descCtrl.text.trim(),
                            coverColorValue: selectedColorValue,
                            customCoverPath: tempCoverPath,
                          );
                          await UserState().updateBook(updated);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        editingBook == null ? '创建' : '保存',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: isNight ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '确认删除日记本',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '确定要删除《${book.name}》吗？删除日记本不会删除其中的日记。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: fontFamily,
                      color: isNight ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isNight
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                              color: isNight ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await UserState().deleteBook(book.id);
                            navigator.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '确认删除',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDestructive ? Colors.redAccent : iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: fontFamily,
                    color: isDestructive
                        ? Colors.redAccent
                        : (isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937)),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isNight ? Colors.white30 : Colors.black38,
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
              Text(
                '设置自定义封面',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                  color: isNight ? Colors.white70 : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuOption(
                icon: Icons.photo_library_rounded,
                title: '从相册选择',
                iconColor: const Color(0xFFD4A373),
                isNight: isNight,
                fontFamily: fontFamily,
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
                icon: Icons.camera_alt_rounded,
                title: '拍照',
                iconColor: const Color(0xFFD4A373),
                isNight: isNight,
                fontFamily: fontFamily,
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
              ),
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
