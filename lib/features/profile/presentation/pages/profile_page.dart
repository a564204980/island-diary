import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/pages/vip_benefits_page.dart';
import 'package:island_diary/features/profile/presentation/pages/mascot_decoration_page.dart';
import 'package:island_diary/features/profile/presentation/pages/security_center_page.dart';
import 'package:island_diary/features/profile/presentation/pages/achievement_page.dart';
import 'package:island_diary/features/profile/presentation/pages/about_island_page.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _checkBirthday();
  }

  Future<void> _checkBirthday() async {
    final userState = UserState();
    final hasGift = await userState.checkAndClaimBirthdayGift();
    if (hasGift && mounted) {
      _showBirthdayCelebration(context);
    }
  }

  void _showBirthdayCelebration(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cake_rounded, size: 80, color: Color(0xFF7B5C2E))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
                  .rotate(begin: -0.1, end: 0.1),
              const SizedBox(height: 24),
              const Text(
                '生日快乐！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'LXGWWenKai',
                  decoration: TextDecoration.none,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              const Text(
                '您的岛屿专属礼物已存入成就系统',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'LXGWWenKai',
                  decoration: TextDecoration.none,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B5C2E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    '收下礼物',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'LXGWWenKai',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).scale(),
            ],
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.themeMode,
        userState.isVip,
        userState.userName,
        userState.selectedMascotDecoration,
        userState.customAvatarPath,
      ]),
      builder: (context, child) {
        final bool isNight = userState.isNight;
        final bool isVip = userState.isVip.value;
        final String name = userState.userName.value;

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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 20),
                  // 1. 头部区域
                  _buildProfileHeader(context, name, isVip, isNight),
                  const SizedBox(height: 32),

                  // 2. VIP 会员特权卡片
                  _buildVipMembershipCard(context, isVip, isNight),
                  const SizedBox(height: 24),

                  // 3. 功能矩阵 (Bento Style)
                  _buildBentoMenu(context, isNight),

                  const SizedBox(height: 32),
                  // 4. 底部信息
                  Center(
                    child: Text(
                      '岛屿日记 · 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.white24 : Colors.black26,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, bool isVip, bool isNight) {
    final userState = UserState();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 上层区域：头像与基本信息 (姓名 + 简介)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 头像区
              Stack(
                alignment: Alignment.center,
                children: [
                  // 主头像容器
                  GestureDetector(
                    onTap: () => _showAvatarPicker(context, isNight),
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isNight ? const Color(0xFF1E293B) : Colors.white,
                        border: Border.all(
                          color: isVip
                              ? const Color(0xFFFFF176)
                              : (isNight ? Colors.white10 : Colors.white),
                          width: 4.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isNight ? 0.4 : 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Center(
                          child: userState.customAvatarPath.value != null && userState.customAvatarPath.value!.isNotEmpty
                              ? Image.file(
                                  File(userState.customAvatarPath.value!),
                                  fit: BoxFit.cover,
                                  width: 92,
                                  height: 92,
                                )
                              : StaticSprite(
                                  assetPath: 'assets/images/emoji/marshmallow.png',
                                  decorationPath: userState.selectedMascotDecoration.value,
                                  size: 80,
                                ),
                        ),
                      ),
                    ),
                  ),
                  // 相机图标
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isVip ? const Color(0xFFFFF176) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isVip ? Colors.white : Colors.black12,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 11,
                        color: isVip ? const Color(0xFF7B5C2E) : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),

              const SizedBox(width: 20),

              // 昵称与简介
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: isNight ? Colors.white : const Color(0xFF333333),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: userState.userBio,
                      builder: (context, bio, _) {
                        return GestureDetector(
                          onTap: () {
                            final isNight = UserState().isNight;
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
                          },
                          child: Text(
                            bio.isNotEmpty ? bio : '点击编辑资料，写下你的岛屿简介',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isNight ? Colors.white38 : Colors.black38,
                              fontFamily: 'LXGWWenKai',
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. 下层区域：称号标签 (左) 与按钮组 (右)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 称号标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isNight 
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isVip 
                        ? const Color(0xFFFFF176).withValues(alpha: 0.5) 
                        : (isNight ? Colors.white10 : Colors.black12),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVip ? Icons.verified_user_rounded : Icons.person_pin_circle_rounded,
                      size: 10,
                      color: isVip ? const Color(0xFF7B5C2E) : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVip ? '岛屿永久居民' : '普通居民',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isVip 
                            ? (isNight ? const Color(0xFFFFCC80) : const Color(0xFF7B5C2E))
                            : (isNight ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),

              // 按钮组
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final isNight = UserState().isNight;
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
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNight ? Colors.white24 : Colors.black12,
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        '编辑资料',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF333333),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('设置功能开发中...')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNight ? Colors.white24 : Colors.black12,
                          width: 0.6,
                        ),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: isNight ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
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
            const Text(
              '修改头像',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildPickerOption(
              context,
              icon: Icons.photo_library_rounded,
              label: '从相册选择',
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
                  if (file != null) {
                    userState.setCustomAvatarPath(file.path);
                  }
                }
              },
              isNight: isNight,
            ),
            _buildPickerOption(
              context,
              icon: Icons.camera_alt_rounded,
              label: '拍照',
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  userState.setCustomAvatarPath(photo.path);
                }
              },
              isNight: isNight,
            ),
            const SizedBox(height: 16),
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
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.redAccent : (isNight ? Colors.white70 : Colors.black54)),
      title: Text(
        label,
        style: TextStyle(
          color: isDanger ? Colors.redAccent : (isNight ? Colors.white : Colors.black87),
          fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildVipMembershipCard(
    BuildContext context,
    bool isVip,
    bool isNight,
  ) {
    return Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: !isVip ? Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6),
            ) : null,
            boxShadow: [
              BoxShadow(
                color: isVip
                    ? const Color(0xFFAB47BC).withValues(alpha: 0.3)
                    : (isNight
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFFB0BEC5).withValues(alpha: 0.2)),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 极光渐变背景
                Positioned.fill(
                  child: AnimatedGradient(isVip: isVip, isNight: isNight),
                ),

                // 内容
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVip ? '星光计划 · 已激活' : '星光计划 · 永久居民',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isVip
                                      ? Colors.white
                                      : (isNight
                                            ? Colors.white
                                            : const Color(0xFF3E2723)),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                isVip ? '您的岛屿正沐浴在永恒星光中' : '让每一份心情都拥有流光溢彩的家',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isVip
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : (isNight
                                            ? Colors.white38
                                            : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            isVip ? Icons.workspace_premium : Icons.stars,
                            color: isVip
                                ? const Color(0xFFFFF176)
                                : (isNight ? Colors.white24 : Colors.black12),
                            size: 32,
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VipBenefitsPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isVip
                                ? Colors.white.withValues(alpha: 0.2)
                                : (isNight
                                      ? Colors.white
                                      : const Color(0xFF3E2723)),
                            borderRadius: BorderRadius.circular(16),
                            border: isVip
                                ? Border.all(color: Colors.white30)
                                : null,
                          ),
                          child: Text(
                            isVip ? '查看专属权益' : '立即入驻',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isVip
                                  ? Colors.white
                                  : (isNight
                                        ? const Color(0xFF3E2723)
                                        : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic, delay: 300.ms)
        .fadeIn(delay: 300.ms);
  }

  Widget _buildBentoMenu(BuildContext context, bool isNight) {
    return Column(
      children: [
        // 第一排 Bento
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildThemeBento(isNight)),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final isNight = UserState().isNight;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: true, // 保持不透明以覆盖底层
                        barrierColor: isNight
                            ? Colors.black
                            : const Color(0xFFFDFCF7),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const SecurityCenterPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                  child: _buildQuickActionBento(
                    title: '岛屿安全',
                    icon: Icons.lock_outline,
                    color: const Color(0xFF81C784),
                    isNight: isNight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 第二排 Bento
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final isNight = UserState().isNight;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: true,
                        barrierColor: isNight
                            ? Colors.black
                            : const Color(0xFFFDFCF7),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const MascotDecorationPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _buildQuickActionBento(
                    title: '小软装扮',
                    icon: Icons.auto_fix_high_rounded,
                    color: const Color(0xFFFFB74D),
                    isNight: isNight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionBento(
                  title: '回忆导出',
                  icon: Icons.ios_share,
                  color: const Color(0xFF64B5F6),
                  isNight: isNight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 第三排 Bento
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final isNight = UserState().isNight;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: true,
                        barrierColor: isNight
                            ? Colors.black
                            : const Color(0xFFFDFCF7),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AchievementPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _buildQuickActionBento(
                    title: '岛屿成就',
                    icon: Icons.emoji_events_outlined,
                    color: const Color(0xFFFF7043),
                    isNight: isNight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final isNight = UserState().isNight;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: true,
                        barrierColor: isNight ? Colors.black : const Color(0xFFFDFCF7),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AboutIslandPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  child: _buildQuickActionBento(
                    title: '关于小岛',
                    icon: Icons.info_outline,
                    color: const Color(0xFFBA68C8),
                    isNight: isNight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildThemeBento(bool isNight) {
    final mode = UserState().themeMode.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _bentoDecoration(isNight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 16,
                color: isNight ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 6),
              Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildThemeOptions(mode, isNight),
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
        return GestureDetector(
          onTap: () => UserState().setThemeMode(opt['mode']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isNight
                        ? const Color(0xFFFFF176).withValues(alpha: 0.15)
                        : const Color(0xFFFFF176).withValues(alpha: 0.3))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFF176).withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              opt['icon'] as IconData,
              size: 18,
              color: isSelected
                  ? (isNight
                        ? const Color(0xFFFFF176)
                        : const Color(0xFF7B5C2E))
                  : (isNight ? Colors.white24 : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionBento({
    required String title,
    required IconData icon,
    required Color color,
    required bool isNight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _bentoDecoration(isNight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _bentoDecoration(bool isNight) {
    return BoxDecoration(
      color: isNight
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isNight
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.9),
      ),
      boxShadow: [
        BoxShadow(
          color: isNight
              ? Colors.black.withValues(alpha: 0.3)
              : const Color(0xFFB0BEC5).withValues(alpha: 0.2), // 柔和偏蓝灰投影
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

/// 动感渐变背景
class AnimatedGradient extends StatefulWidget {
  final bool isVip;
  final bool isNight;
  const AnimatedGradient({
    super.key,
    required this.isVip,
    required this.isNight,
  });

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isVip
                  ? [
                      const Color(0xFFCE93D8),
                      const Color(0xFF7E57C2),
                      const Color(0xFF42A5F5),
                    ]
                  : (widget.isNight
                        ? [const Color(0xFF37474F), const Color(0xFF263238)]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.8),
                          ]),
              stops: widget.isVip
                  ? [
                      0.0,
                      0.5 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                      1.0,
                    ]
                  : null, // 非 VIP 状态下不使用动态 stop
            ),
          ),
        );
      },
    );
  }
}
