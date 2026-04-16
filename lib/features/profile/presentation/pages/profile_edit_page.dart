import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/features/profile/presentation/widgets/title_selection_sheet.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  bool _isInitialized = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late String _selectedGender;
  DateTime? _selectedBirthday;

  @override
  void initState() {
    super.initState();
    final userState = UserState();
    _nameController = TextEditingController(text: userState.userName.value);
    _bioController = TextEditingController(text: userState.userBio.value);
    _selectedGender = userState.userGender.value;
    _selectedBirthday = userState.userBirthday.value;

    // 延迟渲染复杂组件，防止切换页面时的白光闪烁
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _isInitialized = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final userState = UserState();
    await userState.setUserName(_nameController.text);
    await userState.setUserBio(_bioController.text);
    await userState.setUserGender(_selectedGender);
    await userState.setUserBirthday(_selectedBirthday);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;
    final Color bgColor = isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F3F5);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '编辑资料',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isNight ? Colors.white : const Color(0xFF1F2937),
            fontFamily: 'LXGWWenKai',
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isNight ? Colors.white70 : Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              '完成',
              style: TextStyle(
                color: const Color(0xFF7B5C2E),
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 背景保持纯净一致

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                if (_isInitialized) ...[
                  _buildEditSection(
                    title: '基础信息',
                    isNight: isNight,
                    children: [
                      _buildRowTextField(
                        label: '昵称',
                        controller: _nameController,
                        hint: '起一个好听的名字',
                        isNight: isNight,
                      ),
                      _buildDivider(isNight),
                      _buildBioField(
                        controller: _bioController,
                        isNight: isNight,
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  _buildEditSection(
                    title: '个人属性',
                    isNight: isNight,
                    children: [
                      _buildPickerItem(
                        label: '性别',
                        value: _getGenderText(_selectedGender),
                        isNight: isNight,
                        onTap: () => _showGenderPicker(context, isNight),
                      ),
                      _buildDivider(isNight),
                      _buildPickerItem(
                        label: '生日',
                        value: _selectedBirthday == null 
                            ? '未设置' 
                            : DateFormat('yyyy年MM月dd日').format(_selectedBirthday!),
                        isNight: isNight,
                        onTap: () => _showBirthdayPicker(context, isNight),
                      ),
                      _buildDivider(isNight),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: userState.selectedTitles,
                        builder: (context, titles, _) {
                          return _buildPickerItem(
                            label: '我的称号',
                            value: titles.isEmpty ? '默认居民' : titles.join('、'),
                            isNight: isNight,
                            onTap: () => _showTitlePicker(context, isNight),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),
                  
                  Text(
                    '设置生日后，在岛屿的每一年生日当天都将收到一份特别的礼物。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isNight ? Colors.white24 : Colors.black26,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isNight) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1, 
        thickness: 0.5, 
        color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
      ),
    );
  }

  Widget _buildRowTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isNight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isNight ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: isNight ? Colors.white60 : Colors.black54,
                fontFamily: 'LXGWWenKai',
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isNight ? Colors.white24 : Colors.black26,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField({
    required TextEditingController controller,
    required bool isNight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '简介',
            style: TextStyle(
               fontSize: 15,
               color: isNight ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 1,
            style: TextStyle(
              fontSize: 15,
              color: isNight ? Colors.white60 : Colors.black54,
              fontFamily: 'LXGWWenKai',
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: '向岛民们介绍一下自己吧...',
              hintStyle: TextStyle(
                color: isNight ? Colors.white24 : Colors.black26,
                fontSize: 15,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerItem({
    required String label,
    required String value,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isNight ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: isNight ? Colors.white60 : Colors.black54,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isNight ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection({required String title, required List<Widget> children, required bool isNight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isNight ? Colors.white54 : Colors.black54,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
            boxShadow: isNight ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showGenderPicker(BuildContext context, bool isNight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择性别', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildGenderOption(context, 'male', '男', Icons.male_rounded, Colors.blue, isNight),
            _buildGenderOption(context, 'female', '女', Icons.female_rounded, Colors.pink, isNight),
            _buildGenderOption(context, 'secret', '保密', Icons.lock_outline_rounded, Colors.grey, isNight),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String value, String label, IconData icon, Color color, bool isNight) {
    final isSelected = _selectedGender == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? color : (isNight ? Colors.white24 : Colors.black26)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? (isNight ? Colors.white : Colors.black) : (isNight ? Colors.white54 : Colors.black54),
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: color, size: 20) : null,
      onTap: () {
        setState(() => _selectedGender = value);
        Navigator.pop(context);
      },
    );
  }

  void _showBirthdayPicker(BuildContext context, bool isNight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                  const Text('选择生日', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      if (_selectedBirthday == null) {
                        setState(() => _selectedBirthday = DateTime(2000, 1, 1));
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: isNight ? Brightness.dark : Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: isNight ? Colors.white : Colors.black,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedBirthday ?? DateTime(2000, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    setState(() => _selectedBirthday = date);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTitlePicker(BuildContext context, bool isNight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TitleSelectionSheet(isNight: isNight),
    );
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male': return '男';
      case 'female': return '女';
      default: return '保密';
    }
  }

}
