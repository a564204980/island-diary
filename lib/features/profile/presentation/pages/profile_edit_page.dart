import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:intl/intl.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('资料已保存'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
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
          // 装饰性的光晕，仅在初始化后显示
          if (_isInitialized)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7B5C2E).withValues(alpha: isNight ? 0.1 : 0.05),
                      const Color(0xFF7B5C2E).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms),

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
                      _buildTextField(
                        label: '昵称',
                        controller: _nameController,
                        hint: '起一个好听的名字',
                        isNight: isNight,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
                      ),
                      _buildTextField(
                        label: '简介',
                        controller: _bioController,
                        hint: '向岛民们介绍一下自己吧',
                        isNight: isNight,
                        maxLines: 3,
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 20),
                  
                  _buildEditSection(
                    title: '个人属性',
                    isNight: isNight,
                    children: [
                      _buildPickerItem(
                        label: '性别',
                        value: _getGenderText(_selectedGender),
                        icon: _getGenderIcon(_selectedGender),
                        isNight: isNight,
                        onTap: () => _showGenderPicker(context, isNight),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
                      ),
                      _buildPickerItem(
                        label: '生日',
                        value: _selectedBirthday == null 
                            ? '未设置' 
                            : DateFormat('yyyy年MM月dd日').format(_selectedBirthday!),
                        icon: Icons.cake_rounded,
                        isNight: isNight,
                        onTap: () => _showBirthdayPicker(context, isNight),
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

  Widget _buildEditSection({required String title, required List<Widget> children, required bool isNight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white38 : Colors.black38,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isNight,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isNight ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: isNight ? Colors.white : const Color(0xFF1F2937),
            fontFamily: 'LXGWWenKai',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isNight ? Colors.white24 : Colors.black12,
              fontSize: 15,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerItem({
    required String label,
    required String value,
    required IconData icon,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: isNight ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isNight ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isNight ? Colors.white : const Color(0xFF1F2937),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: isNight ? Colors.white24 : Colors.black12),
        ],
      ),
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

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male': return '男';
      case 'female': return '女';
      default: return '保密';
    }
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'male': return Icons.male_rounded;
      case 'female': return Icons.female_rounded;
      default: return Icons.lock_outline_rounded;
    }
  }
}
