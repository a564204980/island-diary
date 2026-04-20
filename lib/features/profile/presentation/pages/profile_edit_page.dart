import 'dart:ui';
import 'package:flutter/material.dart';
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SafeArea(
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
    DateTime initialDate = _selectedBirthday ?? DateTime(2000, 1, 1);
    int currentYear = initialDate.year;
    int currentMonth = initialDate.month;
    int currentDay = initialDate.day;

    final List<int> years = List.generate(DateTime.now().year - 1950 + 1, (i) => 1950 + i);
    final List<int> months = List.generate(12, (i) => i + 1);

    final yearController = FixedExtentScrollController(initialItem: years.indexOf(currentYear));
    final monthController = FixedExtentScrollController(initialItem: currentMonth - 1);
    final dayController = FixedExtentScrollController(initialItem: currentDay - 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
          if (currentDay > daysInMonth) currentDay = daysInMonth;
          final List<int> days = List.generate(daysInMonth, (i) => i + 1);

          String getMetadataText() {
            final now = DateTime.now();
            int age = now.year - currentYear;
            if (now.month < currentMonth || (now.month == currentMonth && now.day < currentDay)) {
              age--;
            }
            final signs = ['摩羯座', '水瓶座', '双鱼座', '白羊座', '金牛座', '双子座', '巨蟹座', '狮子座', '处女座', '天秤座', '天蝎座', '射手座'];
            final cutoff = [19, 18, 20, 19, 20, 20, 22, 22, 22, 22, 21, 21];
            int index = currentMonth - (currentDay <= cutoff[currentMonth - 1] ? 1 : 0);
            if (index < 0) index = 11;
            if (index >= 12) index = 0;
            return '${currentYear}年 · $age岁 · ${signs[index]}';
          }

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: isNight ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: isNight ? Colors.white10 : Colors.white, width: 1.5)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 38, height: 4.5, decoration: BoxDecoration(color: isNight ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2.25))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: Text('取消', style: TextStyle(color: isNight ? Colors.white38 : Colors.black38, fontSize: 15, fontFamily: 'LXGWWenKai'))
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('选择生日', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isNight ? Colors.white : Colors.black87, fontFamily: 'LXGWWenKai')),
                            const SizedBox(height: 6),
                            Text(
                              getMetadataText(),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF29B6E0), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedBirthday = DateTime(currentYear, currentMonth, currentDay));
                            Navigator.pop(context);
                          },
                          child: const Text('确定', style: TextStyle(color: Color(0xFF29B6E0), fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'LXGWWenKai')),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.05), Colors.black, Colors.black, Colors.black.withValues(alpha: 0.05)],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF29B6E0).withValues(alpha: 0.15), width: 1),
                            ),
                          ),
                          Row(
                            children: [
                              _buildStarTrailWheel(years, yearController, (val) {
                                setPickerState(() => currentYear = years[val]);
                              }, isNight, flex: 3, suffix: '年'),
                              _buildStarTrailWheel(months, monthController, (val) {
                                setPickerState(() => currentMonth = months[val]);
                              }, isNight, flex: 2, suffix: '月'),
                              _buildStarTrailWheel(days, dayController, (val) {
                                setPickerState(() => currentDay = days[val]);
                              }, isNight, flex: 2, suffix: '日'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarTrailWheel(List<int> items, FixedExtentScrollController controller, ValueChanged<int> onChanged, bool isNight, {required int flex, required String suffix}) {
    return Expanded(
      flex: flex,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        perspective: 0.005,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index >= items.length) return null;
            return Center(
              child: Text(
                '${items[index]}$suffix',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isNight ? Colors.white : Colors.black87,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            );
          },
          childCount: items.length,
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
