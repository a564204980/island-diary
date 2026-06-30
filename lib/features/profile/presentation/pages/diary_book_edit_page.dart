import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/shared/widgets/custom_color_picker_sheet.dart';

// 预设书籍封面颜色 (扩展为13个经典的莫兰迪低饱和度高级配色)
final List<int> _presetColors = [
  0xFF8BA3B5, // 雾霾蓝
  0xFF8F9E8B, // 苔藓绿
  0xFFC0A9BD, // 丁香紫
  0xFFC9A297, // 浅烟粉
  0xFF5A6B5C, // 深野绿
  0xFF4E5E70, // 暮色蓝
  0xFF8C6B50, // 摩卡棕
  0xFFA3B899, // 灰绿竹
  0xFFD2C5B5, // 杏仁灰
  0xFFBCAAA4, // 陶土粉
  0xFF90A4AE, // 蓝石灰
  0xFFB0BEC5, // 灰雨燕
  0xFFA59385, // 砂岩褐
];

final List<String> _presetColorNames = [
  '雾霾蓝',
  '苔藓绿',
  '丁香紫',
  '浅烟粉',
  '深野绿',
  '暮色蓝',
  '摩卡棕',
  '灰绿竹',
  '杏仁灰',
  '陶土粉',
  '蓝石灰',
  '灰雨燕',
  '砂岩褐',
];

class DiaryBookEditPage extends StatefulWidget {
  final DiaryBook? editingBook;

  const DiaryBookEditPage({super.key, this.editingBook});

  @override
  State<DiaryBookEditPage> createState() => _DiaryBookEditPageState();
}

class _DiaryBookEditPageState extends State<DiaryBookEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late int _selectedColorValue;
  late String _bookId;
  String? _tempCoverPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.editingBook?.name ?? '');
    _descCtrl = TextEditingController(text: widget.editingBook?.description ?? '');
    _bookId = widget.editingBook?.id ?? const Uuid().v4();
    _tempCoverPath = widget.editingBook?.customCoverPath;

    // 默认选取颜色
    if (widget.editingBook != null) {
      _selectedColorValue = widget.editingBook!.coverColorValue;
    } else {
      _selectedColorValue = _presetColors[UserState().savedBooks.value.length % _presetColors.length];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // 辅助选择照片方法
  Future<void> _pickImage() async {
    try {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
        ),
      );
      if (result == null || result.isEmpty) return;

      final file = await result.first.file;
      if (file == null) return;

      // 复制到应用本地目录防止临时文件被清理
      final appDir = await getApplicationDocumentsDirectory();
      final coverDir = Directory(p.join(appDir.path, 'custom_covers'));
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      final ext = p.extension(file.path);
      final newPath = p.join(coverDir.path, '${_bookId}_cover$ext');
      final newFile = await File(file.path).copy(newPath);

      setState(() {
        _tempCoverPath = newFile.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择封面失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    final Color bookColor = Color(_selectedColorValue);

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF13131F) : const Color(0xFFFDFCF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isNight ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editingBook == null ? '新建日记本' : '修改日记本',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            color: isNight ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    // 1. 所见即所得的“微缩拟物书籍封面预览”
                    Center(
                      child: _buildBookPreview(bookColor, isNight),
                    ),
                    const SizedBox(height: 36),

                    // 2. 书名输入框
                    _buildInputField(
                      controller: _nameCtrl,
                      hintText: '起个温暖的书名吧...',
                      maxLength: 12,
                      fontFamily: fontFamily,
                      isNight: isNight,
                    ),
                    const SizedBox(height: 24),

                    // 3. 简介输入框
                    _buildInputField(
                      controller: _descCtrl,
                      hintText: '简介 / 寄语（选填）',
                      maxLength: 30,
                      fontFamily: fontFamily,
                      isNight: isNight,
                    ),
                    const SizedBox(height: 36),

                    // 4. 颜色色块选择区
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '选择封面色系',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontFamily,
                            color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                          ),
                        ),
                        if (_tempCoverPath == null)
                          Text(
                            _presetColorNames[_presetColors.indexOf(_selectedColorValue)],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: fontFamily,
                              color: isNight ? Colors.white38 : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildColorSelector(isNight, fontFamily),
                    const SizedBox(height: 36),

                    // 5. 更多选项（照片封面）
                    Text(
                      '个性化照片封面',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: fontFamily,
                        color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPhotoSelector(isNight, fontFamily),
                  ],
                ),
              ),
            ),

            // 底部悬浮确认大按钮
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
              child: GestureDetector(
                onTap: _onSave,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA68565),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA68565).withValues(alpha: isNight ? 0.15 : 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.editingBook == null ? '确认创建' : '保存修改',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.white,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 绘制拟物化预览书籍
  Widget _buildBookPreview(Color bookColor, bool isNight) {
    final bool hasCustomCover = _tempCoverPath != null && File(_tempCoverPath!).existsSync();
    Color displayColor = hasCustomCover ? Colors.transparent : bookColor.withValues(alpha: 0.9);

    return SizedBox(
      width: 100,
      height: 136,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 书页侧边纸张效果 (书页侧面缝隙)
          Positioned(
            right: 0,
            top: 4,
            bottom: 4,
            width: 8,
            child: Container(
              decoration: BoxDecoration(
                color: isNight ? const Color(0xFFC0C0C0) : const Color(0xFFF4F1EA),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: isNight ? Colors.black38 : Colors.black12,
                  width: 0.5,
                ),
              ),
            ),
          ),
          
          // 2. 书脊与封面卡层
          Positioned(
            left: 0,
            right: 4,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.35 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 自定义图片
                    if (hasCustomCover)
                      Image.file(
                        File(_tempCoverPath!),
                        fit: BoxFit.cover,
                      ),
                    
                    // 柔和环境滤镜
                    if (!hasCustomCover)
                      Container(
                        color: isNight ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.1),
                      ),

                    // 书脊阴影过度
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    // 书皮翻折凹槽线
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 提取公用输入框样式
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required int maxLength,
    required String fontFamily,
    required bool isNight,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        counterText: '',
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isNight ? Colors.white54 : const Color(0xFFA68565),
            width: 1.5,
          ),
        ),
      ),
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        color: isNight ? Colors.white : Colors.black87,
      ),
    );
  }

  // 挑选色块 精致呼吸感圆色板 (一行7个)
  Widget _buildColorSelector(bool isNight, String fontFamily) {
    final List<int> row1Colors = _presetColors.sublist(0, 7);
    final List<int> row2Colors = _presetColors.sublist(7, 13);

    Widget buildColorRow(List<int> colors) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: colors.map((colorVal) {
          final bool isSelected = _selectedColorValue == colorVal && _tempCoverPath == null;
          final Color displayColor = Color(colorVal);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColorValue = colorVal;
                _tempCoverPath = null; // 切换色系自动取消照片封面
              });
            },
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isNight ? Colors.white.withValues(alpha: 0.8) : const Color(0xFFA68565))
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 26 : 28,
                height: isSelected ? 26 : 28,
                decoration: BoxDecoration(
                  color: displayColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: displayColor.computeLuminance() > 0.9
                        ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08))
                        : Colors.transparent,
                    width: 0.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: displayColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: displayColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        buildColorRow(row1Colors),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ...row2Colors.map((colorVal) {
              final bool isSelected = _selectedColorValue == colorVal && _tempCoverPath == null;
              final Color displayColor = Color(colorVal);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorValue = colorVal;
                    _tempCoverPath = null; // 切换色系自动取消照片封面
                  });
                },
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isNight ? Colors.white.withValues(alpha: 0.8) : const Color(0xFFA68565))
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 26 : 28,
                    height: isSelected ? 26 : 28,
                    decoration: BoxDecoration(
                      color: displayColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: displayColor.computeLuminance() > 0.9
                            ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08))
                            : Colors.transparent,
                        width: 0.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: displayColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: displayColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
            _buildCustomColorItem(isNight),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomColorItem(bool isNight) {
    return GestureDetector(
      onTap: () {
        showCustomColorPickerBottomSheet(
          context,
          initialColor: Color(_selectedColorValue),
          title: '自定义封面颜色',
          onColorSelected: (color) {
            setState(() {
              _selectedColorValue = color.toARGB32();
              _tempCoverPath = null;
            });
          },
        );
      },
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(
            color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
        child: Icon(
          Icons.colorize_rounded,
          color: const Color(0xFFA68565),
          size: 16,
        ),
      ),
    );
  }

  // 自定义封面挑选组件
  Widget _buildPhotoSelector(bool isNight, String fontFamily) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _tempCoverPath == null ? Icons.photo_library_outlined : Icons.check_circle_rounded,
              color: _tempCoverPath == null
                  ? (isNight ? Colors.white30 : Colors.black38)
                  : const Color(0xFFA68565),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tempCoverPath == null ? '上传自定义图片作为封面' : '已成功选定照片封面',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 13,
                  color: _tempCoverPath == null
                      ? (isNight ? Colors.white38 : Colors.black45)
                      : (isNight ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
            if (_tempCoverPath != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _tempCoverPath = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '清除',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 保存数据
  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书名不能为空名哦')),
      );
      return;
    }

    if (widget.editingBook == null) {
      final newBook = DiaryBook(
        id: _bookId,
        name: name,
        description: _descCtrl.text.trim(),
        coverColorValue: _selectedColorValue,
        customCoverPath: _tempCoverPath,
      );
      await UserState().createBook(newBook);
    } else {
      final updated = widget.editingBook!.copyWith(
        name: name,
        description: _descCtrl.text.trim(),
        coverColorValue: _selectedColorValue,
        customCoverPath: _tempCoverPath,
      );
      await UserState().updateBook(updated);
    }
    if (!mounted) return;
    
    showTopToast(
      context,
      widget.editingBook == null ? '日记本创建成功' : '日记本修改成功',
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF10B981),
    );
    
    Navigator.pop(context);
  }
}
