import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, mode, child) {
        final bool isNight = UserState().isNight;
        
        return Stack(
          children: [
            // 背景模糊
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. 头像与昵称
                    _buildProfileHeader(isNight),
                    const SizedBox(height: 48),
                    
                    // 2. 主题切换卡片
                    _buildThemeCard(context, mode, isNight),
                    const SizedBox(height: 24),
                    
                    // 3. 其他设置占位
                    _buildSettingsCard('关于小岛', Icons.info_outline, isNight),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isNight) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFF176).withOpacity(0.6),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFF176).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/emoji/weixiao.png'),
              fit: BoxFit.cover,
            ),
          ),
        ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          UserState().userName.value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isNight ? Colors.white : const Color(0xFF3E2723),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, String currentMode, bool isNight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNight ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFF176).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: isNight ? const Color(0xFFFFE082) : const Color(0xFF7B5C2E),
              ),
              const SizedBox(width: 12),
              Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildThemeOptions(currentMode, isNight),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(String currentMode, bool isNight) {
    final List<Map<String, dynamic>> options = [
      {'label': '日间', 'mode': 'light', 'icon': Icons.wb_sunny_outlined},
      {'label': '夜间', 'mode': 'dark', 'icon': Icons.nightlight_outlined},
      {'label': '自动', 'mode': 'auto', 'icon': Icons.auto_awesome_outlined},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((opt) {
        final bool isSelected = currentMode == opt['mode'];
        return Expanded(
          child: GestureDetector(
            onTap: () => UserState().setThemeMode(opt['mode']),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isNight ? const Color(0xFFFFE082).withOpacity(0.3) : const Color(0xFFFFE082).withOpacity(0.5))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFF176) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    opt['icon'],
                    size: 20,
                    color: isSelected
                        ? (isNight ? Colors.white : const Color(0xFF3E2723))
                        : (isNight ? Colors.white54 : Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isNight ? Colors.white : const Color(0xFF3E2723))
                          : (isNight ? Colors.white54 : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, bool isNight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isNight ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isNight ? Colors.white70 : const Color(0xFF7B5C2E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isNight ? Colors.white : const Color(0xFF3E2723),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: isNight ? Colors.white30 : Colors.black26,
          ),
        ],
      ),
    );
  }
}
