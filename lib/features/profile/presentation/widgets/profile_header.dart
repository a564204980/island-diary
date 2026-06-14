import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/life_line_switcher_sheet.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:island_diary/features/profile/presentation/pages/settings_page.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image_picker/image_picker.dart';

class ProfileHeader extends StatelessWidget {
  final bool isNight;
  final bool isVip;

  const ProfileHeader({super.key, required this.isNight, required this.isVip});

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
            Expanded(child: _buildInfoSection(context, userState, isNight)),
          ],
        ),
        const SizedBox(height: 20),
        // 3. 标签与按钮组区域
        _buildTagAndActionsSection(context, userState, isNight, isVip),
      ],
    );
  }

  Widget _buildAvatarSection(
    BuildContext context,
    UserState userState,
    bool isNight,
  ) {
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
                      color: isNight
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.9),
                      border: Border.all(
                        color: const Color(
                          0xFF818CF8,
                        ).withValues(alpha: isNight ? 0.7 : 0.55),
                        width: 4.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFA855F7,
                          ).withValues(alpha: isNight ? 0.3 : 0.18),
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
                                  ? const Color(
                                      0xFF818CF8,
                                    ).withValues(alpha: 0.3)
                                  : const Color(
                                      0xFF818CF8,
                                    ).withValues(alpha: 0.2),
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
                          color: isNight
                              ? const Color(0xFF0D1B2A)
                              : const Color(0xFFE6F3F5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFA855F7,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(delay: 100.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    UserState userState,
    bool isNight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: ValueListenableBuilder<String>(
                      valueListenable: userState.userName,
                      builder: (context, name, _) {
                        return Text(
                          name.isEmpty ? '海岛新居民' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isNight ? Colors.white : const Color(0xFF1F2937),
                            fontFamily: _getFontFamily(),
                            letterSpacing: 1.5,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showLifeLineSwitcher(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.alt_route_rounded,
                        size: 16,
                        color: isNight ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildActionIcon(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              icon: Icons.settings_outlined,
              isNight: isNight,
            ),
          ],
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
                fontFamily: _getFontFamily(),
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildTagAndActionsSection(
    BuildContext context,
    UserState userState,
    bool isNight,
    bool isVip,
  ) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: userState.selectedTitles,
      builder: (context, titles, _) {
        final List<Widget> tagWidgets = [];

        // 1. 添加称号标签
        if (titles.isEmpty) {
          tagWidgets.add(
            _buildTagItem(
              isVip ? '岛屿永久居民' : '岛屿普通居民',
              null,
              isNight,
            ),
          );
        } else {
          tagWidgets.addAll(titles.map((title) {
            final tier = MascotAchievement.allAchievements
                .where((a) => a.rewardTitle == title)
                .firstOrNull
                ?.titleTier;
            return _buildTagItem(title, tier, isNight);
          }));
        }

        return SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: tagWidgets,
                ),
              ),
              const SizedBox(width: 16),
              _buildActionIcon(
                onTap: () => _navigateToEditProfile(context, isNight),
                label: '编辑资料', // 保留编辑资料的文字，渲染为胶囊药丸形状
                icon: Icons.edit_outlined,
                isNight: isNight,
              ),
            ],
          ),
        );
      },
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
                color: const Color(
                  0xFF818CF8,
                ).withValues(alpha: isNight ? 0.3 : 0.2),
                width: 0.8,
              )
            : null,
        boxShadow: tier != null
            ? [
                BoxShadow(
                  color: tier.color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
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
              fontFamily: _getFontFamily(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required VoidCallback onTap,
    String? label, // 引入 label 选项，提供对胶囊和圆形的自适应支持
    required IconData icon,
    required bool isNight,
  }) {
    final String themeId = UserState().selectedIslandThemeId.value;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isNight) {
      bgColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white12;
      textColor = Colors.white70;
    } else {
      if (themeId == 'lego') {
        bgColor = const Color(0xFFFFFBEB); // 奶油温润黄背景
        borderColor = const Color(0xFFFDE68A); // 金色琥珀细描边
        textColor = const Color(0xFF4E3629); // 精准复古炭褐深巧克力色（图2同款质感咖啡褐）
      } else if (themeId == 'cotton_candy') {
        bgColor = const Color(0xFFF5F3FF); // 浅粉紫底色
        borderColor = const Color(0xFFDDD6FE); // 梦幻淡紫边框
        textColor = const Color(0xFF7C3AED); // 棉花糖经典皇家紫
      } else {
        bgColor = Colors.black.withValues(alpha: 0.03);
        borderColor = Colors.black.withValues(alpha: 0.05);
        textColor = const Color(0xFF4B5563); // 经典高级岩石灰
      }
    }

    final bool hasLabel = label != null && label.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: hasLabel
            ? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ) // 有文字时：加宽的胶囊样式
            : const EdgeInsets.all(9), // 无文字时：精美微缩圆圈包裹，完全对齐完美对称圆形
        decoration: BoxDecoration(
          color: bgColor,
          shape: hasLabel ? BoxShape.rectangle : BoxShape.circle, // 自适应形状
          borderRadius: hasLabel ? BorderRadius.circular(20) : null,
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isNight
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF78350F).withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16, // 图标稍大一点，确保饱满清晰
              color: textColor,
            ),
            if (hasLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontFamily: _getFontFamily(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context, bool isNight) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileEditPage(),
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
      showDragHandle: false,
      builder: (context) => DiaryBottomSheet(
        paperStyle: 'default',
        showDragHandle: true,
        isDiary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '修改头像',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: _getFontFamily(),
              ),
            ),
            const SizedBox(height: 8),
            _buildPickerOption(
              context,
              icon: Icons.photo_library_rounded,
              label: '从相册选择',
              isNight: isNight,
              onTap: () async {
                Navigator.pop(context);
                final List<AssetEntity>? result = await AssetPicker.pickAssets(
                  context,
                  pickerConfig: const AssetPickerConfig(
                    maxAssets: 1,
                    requestType: RequestType.image,
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  final file = await result.first.file;
                  if (file != null) userState.setCustomAvatarPath(file.path);
                }
              },
            ),
            _buildPickerOption(
              context,
              icon: Icons.camera_alt_rounded,
              label: '拍照',
              isNight: isNight,
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (photo != null) userState.setCustomAvatarPath(photo.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isNight,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isNight ? Colors.white70 : Colors.black54),
      title: Text(
        label,
        style: TextStyle(
          color: isNight ? Colors.white : Colors.black87,
          fontFamily: _getFontFamily(),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLifeLineSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => const LifeLineSwitcherSheet(),
    );
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}
