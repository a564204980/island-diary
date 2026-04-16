import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image_picker/image_picker.dart';

class ProfileHeader extends StatelessWidget {
  final bool isNight;
  final bool isVip;

  const ProfileHeader({
    super.key,
    required this.isNight,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 头像区域 (左侧)
            _buildAvatarSection(context, userState, isNight),
            const SizedBox(width: 24),
            // 2. 资料区域 (右侧)
            Expanded(
              child: _buildInfoSection(context, userState, isNight),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 3. 标签与按钮组区域
        _buildTagAndActionsSection(context, userState, isNight, isVip),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context, UserState userState, bool isNight) {
    return ValueListenableBuilder<String?>(
      valueListenable: userState.customAvatarPath,
      builder: (context, path, _) {
        return GestureDetector(
          onTap: () => _showAvatarPicker(context, isNight),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 头像容器
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.9),
                  border: Border.all(
                    color: const Color(0xFF818CF8).withValues(alpha: isNight ? 0.7 : 0.55),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: isNight ? 0.3 : 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: path != null
                      ? DecorationImage(
                          image: FileImage(File(path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: path == null
                    ? Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: isNight
                              ? const Color(0xFF818CF8).withValues(alpha: 0.3)
                              : const Color(0xFF818CF8).withValues(alpha: 0.2),
                        ),
                      )
                    : null,
              ),
              // 编辑浮层图标
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF818CF8), Color(0xFFA855F7)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F3F5),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, UserState userState, bool isNight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(
          valueListenable: userState.userName,
          builder: (context, name, _) {
            return Text(
              name.isEmpty ? '海岛新居民' : name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isNight ? Colors.white : const Color(0xFF1F2937),
                fontFamily: 'LXGWWenKai',
                letterSpacing: 1.5,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: userState.userBio,
          builder: (context, bio, _) {
            return Text(
              bio.isEmpty ? '在这个岛屿，记录每一个值得纪念的瞬间...' : bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isNight ? Colors.white38 : Colors.black38,
                fontFamily: 'LXGWWenKai',
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildTagAndActionsSection(BuildContext context, UserState userState, bool isNight, bool isVip) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 称号标签展示区
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: userState.selectedTitles,
            builder: (context, titles, _) {
              if (titles.isEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTagItem(isVip ? '岛屿永久居民' : '岛屿普通居民', null, isNight),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: titles.map((title) {
                  final tier = MascotAchievement.allAchievements
                      .where((a) => a.rewardTitle == title)
                      .firstOrNull?.titleTier;
                  return _buildTagItem(title, tier, isNight);
                }).toList(),
              );
            },
          ),
        ),
        // 按钮组
        Row(
          children: [
            _buildActionIcon(
              onTap: () => _navigateToEditProfile(context, isNight),
              label: '编辑资料',
              isNight: isNight,
            ),
            const SizedBox(width: 8),
            _buildActionIcon(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置功能开发中...'))),
              icon: Icons.settings_outlined,
              isNight: isNight,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTagItem(String displayTitle, TitleTier? tier, bool isNight) {
    return Container(
      // 与“编辑资料”按钮高度一致 (vertical: 6)
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: tier?.cardGradient,
        color: tier == null
            ? const Color(0xFF818CF8).withValues(alpha: isNight ? 0.12 : 0.08)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: tier == null
            ? Border.all(
                color: const Color(0xFF818CF8).withValues(alpha: isNight ? 0.3 : 0.2),
                width: 0.8,
              )
            : null,
        boxShadow: tier != null
            ? [BoxShadow(color: tier.color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier?.badge ?? Icons.workspace_premium_rounded,
            size: 13,
            color: tier != null ? Colors.white : const Color(0xFF818CF8),
          ),
          const SizedBox(width: 4),
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: tier != null ? Colors.white : const Color(0xFF818CF8),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({required VoidCallback onTap, String? label, IconData? icon, required bool isNight}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isNight ? Colors.white24 : Colors.black12, width: 0.6),
        ),
        child: label != null
            ? Text(label, style: TextStyle(fontSize: 12, color: isNight ? Colors.white70 : Colors.black54, fontFamily: 'LXGWWenKai'))
            : Icon(icon, size: 18, color: isNight ? Colors.white70 : Colors.black54),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context, bool isNight) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileEditPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, bool isNight) {
    final userState = UserState();
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
            const Text('修改头像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'LXGWWenKai')),
            const SizedBox(height: 24),
            _buildPickerOption(context, icon: Icons.photo_library_rounded, label: '从相册选择', isNight: isNight, onTap: () async {
              Navigator.pop(context);
              final List<AssetEntity>? result = await AssetPicker.pickAssets(context, pickerConfig: const AssetPickerConfig(maxAssets: 1, requestType: RequestType.image));
              if (result != null && result.isNotEmpty) {
                final file = await result.first.file;
                if (file != null) userState.setCustomAvatarPath(file.path);
              }
            }),
            _buildPickerOption(context, icon: Icons.camera_alt_rounded, label: '拍照', isNight: isNight, onTap: () async {
              Navigator.pop(context);
              final ImagePicker picker = ImagePicker();
              final XFile? photo = await picker.pickImage(source: ImageSource.camera);
              if (photo != null) userState.setCustomAvatarPath(photo.path);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, required bool isNight}) {
    return ListTile(
      leading: Icon(icon, color: isNight ? Colors.white70 : Colors.black54),
      title: Text(label, style: TextStyle(color: isNight ? Colors.white : Colors.black87, fontFamily: 'LXGWWenKai')),
      onTap: onTap,
    );
  }
}
