import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/constants/legal_text.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/shared/widgets/prop_obtained/prop_obtained_popup.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserState().themeMode,
      builder: (context, _) {
        final isNight = UserState().isNight;
        
        return Stack(
          children: [
            // 1. 艺术渐变与慢速漂浮光晕背景
            _buildBackground(isNight),
            
            // 2. 页面主体（Scaffold 保持透明背景，内容不穿透 AppBar）
            Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: false,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
                title: Text(
                  '系统设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isNight ? Colors.white : const Color(0xFF1F2937),
                    fontFamily: _getFontFamily(),
                    letterSpacing: 2,
                  ),
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: isNight ? Colors.white70 : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    

                    // 支持与反馈
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '支持与反馈',
                        subtitle: '为我们评分，提供改进意见',
                        isNight: isNight,
                        children: [
                          _SettingsTile(
                            title: '去评分',
                            icon: Icons.star_outline_rounded,
                            accentColor: const Color(0xFFF59E0B),
                            isNight: isNight,
                            onTap: () => _showActionDialog(
                              context, 
                              '去评分', 
                              '岛屿计划离不开您的支持，我们将带您前往商店留下宝贵的评价 ⭐', 
                              isNight
                            ),
                          ),
                          _buildDivider(isNight),
                          _SettingsTile(
                            title: '意见反馈',
                            icon: Icons.chat_bubble_outline_rounded,
                            accentColor: const Color(0xFFEC4899),
                            isNight: isNight,
                            onTap: () => _showLegalDialog(context, '意见反馈', LegalText.feedbackInfo, isNight),
                          ),
                          _buildDivider(isNight),
                          _SettingsTile(
                            title: '清理缓存',
                            icon: Icons.cleaning_services_rounded,
                            accentColor: const Color(0xFF10B981),
                            isNight: isNight,
                            onTap: () => _showClearCacheDialog(context, isNight),
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 法律条款
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '法律条款',
                        subtitle: '数据安全保护与服务条款',
                        isNight: isNight,
                        children: [
                          _SettingsTile(
                            title: '隐私政策',
                            icon: Icons.privacy_tip_outlined,
                            accentColor: const Color(0xFF6366F1),
                            isNight: isNight,
                            onTap: () => _showLegalDialog(context, '隐私政策', LegalText.privacyPolicy, isNight),
                          ),
                          _buildDivider(isNight),
                          _SettingsTile(
                            title: '用户协议',
                            icon: Icons.gavel_rounded,
                            accentColor: const Color(0xFF94A3B8),
                            isNight: isNight,
                            onTap: () => _showLegalDialog(context, '用户协议', LegalText.userAgreement, isNight),
                          ),
                        ],
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 实验室
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '实验室',
                        subtitle: '专为开发者或测试人员准备的功能',
                        isNight: isNight,
                        children: [
                          _SettingsTile(
                            title: '调试：一键解锁',
                            icon: Icons.bug_report_rounded,
                            accentColor: const Color(0xFF8B5CF6),
                            isNight: isNight,
                            onTap: () {
                              UserState().unlockAllForTesting();
                              _showToast(
                                context,
                                '已触发全量解锁测试模式 ⚡',
                                icon: Icons.offline_bolt_rounded,
                                iconColor: const Color(0xFFFBBF24),
                              );
                            },
                          ),
                          _buildDivider(isNight),
                          _SettingsTile(
                            title: '调试：生成测试日记 (100条)',
                            icon: Icons.playlist_add_rounded,
                            accentColor: const Color(0xFF10B981),
                            isNight: isNight,
                            onTap: () async {
                              await UserState().generateMockDiaries();
                              if (context.mounted) {
                                _showToast(
                                  context,
                                  '已成功生成 100 条测试数据 📅',
                                  icon: Icons.check_circle_rounded,
                                  iconColor: const Color(0xFF10B981),
                                );
                              }
                            },
                          ),
                          _buildDivider(isNight),
                          ValueListenableBuilder<bool>(
                            valueListenable: UserState().showPropObtainedPopup,
                            builder: (context, value, _) {
                              return _SettingsTile(
                                title: '启用获得道具弹窗',
                                icon: Icons.celebration_rounded,
                                accentColor: const Color(0xFFF59E0B),
                                isNight: isNight,
                                trailing: Switch(
                                  value: value,
                                  activeThumbColor: isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2),
                                  onChanged: (val) {
                                    UserState().setShowPropObtainedPopup(val);
                                  },
                                ),
                                onTap: () {
                                  UserState().setShowPropObtainedPopup(!value);
                                },
                              );
                            },
                          ),
                          _buildDivider(isNight),
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              UserState().isImageCompressEnabled,
                              UserState().imageCompressQuality,
                            ]),
                            builder: (context, _) {
                              final enabled = UserState().isImageCompressEnabled.value;
                              final quality = UserState().imageCompressQuality.value;
                              return Column(
                                children: [
                                  _SettingsTile(
                                    title: '上传前自动压缩图片',
                                    icon: Icons.image_aspect_ratio_rounded,
                                    accentColor: const Color(0xFF6366F1),
                                    isNight: isNight,
                                    trailing: Switch(
                                      value: enabled,
                                      activeThumbColor: isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2),
                                      onChanged: (val) {
                                        UserState().setImageCompressEnabled(val);
                                      },
                                    ),
                                    onTap: () {
                                      UserState().setImageCompressEnabled(!enabled);
                                    },
                                  ),
                                  if (enabled) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(68, 4, 20, 12),
                                      child: Row(
                                        children: [
                                          Text(
                                            '压缩质量比例: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isNight ? Colors.white38 : Colors.black45,
                                              fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
                                            ),
                                          ),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderThemeData(
                                                trackHeight: 2,
                                                activeTrackColor: isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2),
                                                inactiveTrackColor: (isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2)).withValues(alpha: 0.15),
                                                thumbColor: isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2),
                                                overlayColor: (isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2)).withValues(alpha: 0.1),
                                              ),
                                              child: Slider(
                                                value: quality.toDouble(),
                                                min: 30,
                                                max: 100,
                                                divisions: 70,
                                                onChanged: (val) {
                                                  UserState().setImageCompressQuality(val.round());
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$quality%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2),
                                              fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          _buildDivider(isNight),
                          _SettingsTile(
                            title: '调试：触发获得道具弹窗',
                            icon: Icons.animation_rounded,
                            accentColor: const Color(0xFFEC4899),
                            isNight: isNight,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => DiaryBottomSheet(
                                  paperStyle: 'default',
                                  showDragHandle: true,
                                  isDiary: false,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '选择测试道具类型',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isNight ? Colors.white : const Color(0xFF5A3E28),
                                          fontFamily: 'LXGWWenKai',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ...[
                                        ('随机帽子/头饰', MascotDecorationCategory.hat),
                                        ('随机发型', MascotDecorationCategory.hair),
                                        ('随机眼镜', MascotDecorationCategory.glasses),
                                        ('随机耳饰', MascotDecorationCategory.face),
                                        ('随机高阶饰品 (全部)', null),
                                      ].map((item) {
                                        return ListTile(
                                          title: Text(
                                            item.$1,
                                            style: TextStyle(
                                              fontFamily: 'LXGWWenKai',
                                              fontSize: 14,
                                              color: isNight ? Colors.white70 : const Color(0xFF5A3E28),
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: isNight ? Colors.white30 : const Color(0xFF8A7A6E),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            final decos = MascotDecoration.allDecorations;
                                            List<MascotDecoration> filtered;
                                            if (item.$2 == null) {
                                              filtered = decos.where((d) => d.rarity == MascotRarity.legendary || d.rarity == MascotRarity.epic).toList();
                                            } else {
                                              filtered = decos.where((d) => d.category == item.$2).toList();
                                            }
                                            if (filtered.isEmpty) {
                                              _showToast(context, '该分类下无可用饰品数据 😢');
                                              return;
                                            }
                                            final randomDeco = filtered[math.Random().nextInt(filtered.length)];
                                            showPropObtainedPopup(context, randomDeco);
                                          },
                                        );
                                      }),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 危险区域
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '危险区域',
                        subtitle: '涉及永久删除数据的高危操作',
                        isNight: isNight,
                        children: [
                          _SettingsTile(
                            title: '抹除所有回忆',
                            icon: Icons.delete_forever_rounded,
                            accentColor: const Color(0xFFEF4444),
                            isNight: isNight,
                            onTap: () {
                              _showActionDialog(
                                context,
                                '抹除所有回忆',
                                '警告：此操作将永久删除该岛屿上的所有回忆、房间布局及偏好设置。执行后将无法找回。',
                                isNight,
                                onConfirm: () async {
                                  await UserState().factoryReset();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const OnboardingPage()),
                                      (route) => false,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }

  Widget _buildBackground(bool isNight) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNight
              ? [
                  const Color(0xFF0F172A),
                  const Color(0xFF0D1B2A),
                  const Color(0xFF1E1E38),
                ]
              : [
                  const Color(0xFFF9F6F0),
                  const Color(0xFFEAF4F4),
                  const Color(0xFFE6EBE0),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isNight
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : const Color(0xFFA5F3FC).withValues(alpha: 0.3),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isNight
                        ? const Color(0xFFEC4899).withValues(alpha: 0.1)
                        : const Color(0xFFFBCFE8).withValues(alpha: 0.25),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSection({
    required String title, 
    required String subtitle, 
    required List<Widget> children, 
    required bool isNight
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: _getFontFamily(),
                        color: isNight ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF374151),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isNight ? Colors.white30 : Colors.black38,
                        fontFamily: _getFontFamily(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isNight ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isNight) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1, 
        thickness: 0.8, 
        color: isNight ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)
      ),
    );
  }

  void _showToast(BuildContext context, String message, {IconData icon = Icons.info_outline_rounded, Color? iconColor}) {
    showTopToast(
      context,
      message,
      icon: icon,
      iconColor: iconColor,
    );
  }

  void _showActionDialog(
    BuildContext context, 
    String title, 
    String content, 
    bool isNight, 
    {bool isRestore = false, VoidCallback? onConfirm}
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        bool isLoading = onConfirm == null; 
        return StatefulBuilder(
          builder: (context, setState) {
            if (onConfirm == null) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted && isLoading) {
                  setState(() => isLoading = false);
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isNight ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900, 
                          color: isNight ? Colors.white : const Color(0xFF1A1A1A),
                          fontFamily: _getFontFamily(),
                        )
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 2,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2)
                            ),
                            strokeWidth: 2.5,
                          ),
                        ),
                      Text(
                        onConfirm != null 
                          ? content 
                          : (isLoading ? content : (isRestore ? '您的所有权益（VIP等级、专属饰品）已成功恢复。' : '已为您跳转至对应页面。')),
                        style: TextStyle(
                          color: isNight ? Colors.white70 : Colors.black87, 
                          fontSize: 14, 
                          height: 1.6,
                          fontFamily: _getFontFamily()
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      if (onConfirm != null)
                        Row(
                          children: [
                            Expanded(
                              child: _SettingsDialogBtn(
                                label: '取消', 
                                isNight: isNight, 
                                isDanger: false,
                                onPressed: () => Navigator.pop(context)
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SettingsDialogBtn(
                                label: '确认执行', 
                                isNight: isNight, 
                                isDanger: true,
                                onPressed: () {
                                  Navigator.pop(context);
                                  onConfirm();
                                }
                              ),
                            ),
                          ],
                        )
                      else if (!isLoading)
                        _SettingsDialogBtn(
                          label: '好', 
                          isNight: isNight, 
                          isDanger: false,
                          onPressed: () => Navigator.pop(context)
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content, bool isNight) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: isNight ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title, 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: isNight ? Colors.white : const Color(0xFF1A1A1A), 
                          fontWeight: FontWeight.w900, 
                          fontFamily: _getFontFamily(),
                          letterSpacing: 1.2,
                        )
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 2,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: isNight ? Colors.white70 : Colors.black87, 
                              height: 1.7, 
                              fontSize: 14, 
                              fontFamily: _getFontFamily(),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SettingsDialogBtn(
                        label: '我知道了', 
                        isNight: isNight, 
                        isDanger: false,
                        onPressed: () => Navigator.pop(context)
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded, 
                      color: isNight ? Colors.white38 : Colors.black26, 
                      size: 22
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<double> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = 0;
      if (await tempDir.exists()) {
        final list = tempDir.listSync(recursive: true);
        for (var file in list) {
          if (file is io.File) {
            totalSize += await file.length();
          }
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _clearCacheDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final list = tempDir.listSync(recursive: true);
        for (var file in list) {
          if (file is io.File) {
            await file.delete();
          } else if (file is io.Directory) {
            try {
              await file.delete(recursive: true);
            } catch (_) {}
          }
        }
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      debugPrint("清理缓存出错: $e");
    }
  }

  void _showClearCacheDialog(BuildContext context, bool isNight) async {
    // 异步计算当前缓存大小
    final double sizeInBytes = await _calculateCacheSize();
    final double sizeInMb = sizeInBytes / (1024 * 1024);

    if (!context.mounted) return;

    _showActionDialog(
      context,
      '清理缓存',
      '当前临时缓存大小为 ${sizeInMb.toStringAsFixed(2)} MB。\n清理缓存后，下载的临时图片及浏览记录将会被清除，写过的日记内容不会受到任何影响。',
      isNight,
      onConfirm: () async {
        await _clearCacheDirectory();
        if (context.mounted) {
          _showToast(
            context,
            '缓存清理成功 ✨',
            icon: Icons.cleaning_services_rounded,
            iconColor: const Color(0xFF10B981),
          );
        }
      },
    );
  }
}

// ============== 下方为私有按压微动效组件与精致的水晶弹窗按钮 ==============

class _SettingsTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final bool isNight;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.isNight,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // 渐变叶片/花瓣形状的图标容器背景
    final iconBgDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          widget.accentColor.withValues(alpha: 0.2),
          widget.accentColor.withValues(alpha: 0.06),
        ],
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
        topRight: Radius.circular(6),
        bottomLeft: Radius.circular(6),
      ),
      border: Border.all(
        color: widget.accentColor.withValues(alpha: 0.12),
        width: 1,
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0),
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.isNight ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02))
              : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: iconBgDecoration,
                child: Icon(
                  widget.icon, 
                  size: 19, 
                  color: widget.accentColor
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937),
                  fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
                ),
              ),
              const Spacer(),
              widget.trailing ?? Icon(
                Icons.arrow_forward_ios_rounded, 
                size: 13, 
                color: widget.isNight ? Colors.white24 : Colors.black26
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDialogBtn extends StatefulWidget {
  final String label;
  final bool isNight;
  final bool isDanger;
  final VoidCallback onPressed;

  const _SettingsDialogBtn({
    required this.label,
    required this.isNight,
    required this.isDanger,
    required this.onPressed,
  });

  @override
  State<_SettingsDialogBtn> createState() => _SettingsDialogBtnState();
}

class _SettingsDialogBtnState extends State<_SettingsDialogBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDanger 
        ? const Color(0xFFEF4444) 
        : (widget.isNight ? const Color(0xFF818CF8) : const Color(0xFF7E57C2));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 危险操作与常规操作按钮的渐变色板
          gradient: widget.isDanger
              ? const LinearGradient(
                  colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                )
              : LinearGradient(
                  colors: widget.isNight
                      ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                      : [const Color(0xFF9333EA), const Color(0xFF7E57C2)],
                ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: _isPressed ? 0.15 : 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
            fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
          ),
        ),
      ),
    );
  }
}
