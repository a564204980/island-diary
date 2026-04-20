import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/constants/legal_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/services/backup_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserState().themeMode,
      builder: (context, _) {
        final isNight = UserState().isNight;
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // 1. 动态渐变背景
              _buildBackground(isNight),
              
              // 2. 内容层
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 自定义标题栏
                    SliverToBoxAdapter(
                      child: _buildHeader(context, isNight).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                    ),
                    
                    // 偏好与数据
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '偏好与数据',
                        isNight: isNight,
                        children: [
                          _buildPremiumTile(
                            context,
                            '加密导出',
                            Icons.ios_share_rounded,
                            const Color(0xFF10B981),
                            isNight,
                            onTap: () async {
                              final success = await BackupService.exportData();
                              if (!context.mounted) return;
                              if (success) {
                                _showToast(context, '回忆已成功打包并准备导出');
                              } else {
                                _showToast(context, '导出失败，请检查权限设置');
                              }
                            },
                          ),
                          _buildDivider(isNight),
                          _buildPremiumTile(
                            context,
                            '回忆导入',
                            Icons.system_update_alt_rounded,
                            const Color(0xFF0EA5E9),
                            isNight,
                            onTap: () => _handleImport(context, isNight),
                          ),
                          _buildDivider(isNight),
                          _buildPremiumTile(
                            context,
                            '恢复购买',
                            Icons.shopping_cart_checkout_rounded,
                            const Color(0xFF3B82F6),
                            isNight,
                            onTap: () => _showActionDialog(context, '恢复购买', '正在连接 App Store，验证您的偏好设置与订阅记录...', isNight, isRestore: true),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    
                    // 支持与反馈
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '支持与反馈',
                        isNight: isNight,
                        children: [
                          _buildPremiumTile(
                            context,
                            '去评分',
                            Icons.star_outline_rounded,
                            const Color(0xFFF59E0B),
                            isNight,
                            onTap: () => _showActionDialog(context, '去评分', '岛屿计划离不开您的支持，我们将带您前往 App Store 留下宝贵的评价。', isNight),
                          ),
                          _buildDivider(isNight),
                          _buildPremiumTile(
                            context,
                            '意见反馈',
                            Icons.chat_bubble_outline_rounded,
                            const Color(0xFFEC4899),
                            isNight,
                            onTap: () => _showLegalDialog(context, '意见反馈', LegalText.feedbackInfo, isNight),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 法律条款
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '法律条款',
                        isNight: isNight,
                        children: [
                          _buildPremiumTile(
                            context,
                            '隐私政策',
                            Icons.privacy_tip_outlined,
                            const Color(0xFF6366F1),
                            isNight,
                            onTap: () => _showLegalDialog(context, '隐私政策', LegalText.privacyPolicy, isNight),
                          ),
                          _buildDivider(isNight),
                          _buildPremiumTile(
                            context,
                            '用户协议',
                            Icons.gavel_rounded,
                            const Color(0xFF94A3B8),
                            isNight,
                            onTap: () => _showLegalDialog(context, '用户协议', LegalText.userAgreement, isNight),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 实验室
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: '实验室',
                        isNight: isNight,
                        children: [
                          _buildPremiumTile(
                            context,
                            '调试：一键解锁',
                            Icons.bug_report_rounded,
                            const Color(0xFF8B5CF6),
                            isNight,
                            onTap: () {
                              UserState().unlockAllForTesting();
                              _showToast(context, '已触发全量解锁测试模式');
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(bool isNight) {
    return Container(
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F3F5), // 同步“我的”页面背景
      ),
      child: Stack(
        children: [
          if (isNight) ...[
            // 夜晚模式保留动态星云以增加质感
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 50, duration: 4.seconds),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEC4899).withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(begin: 0, end: 30, duration: 3.seconds),
            ),
          ],
          // 白天模式保持纯正，不再添加额外装饰球，确保与“我的”页完全一致
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isNight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.centerLeft,
              color: Colors.transparent, // 确保点击区域
              child: Icon(
                Icons.arrow_back_ios_new_rounded, 
                size: 22, 
                color: isNight ? Colors.white : const Color(0xFF1F2937)
              ),
            ),
          ),
          const Expanded(
            child: Text(
              '系统设置',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'LXGWWenKai',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 40), // 占位保持居中
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, required bool isNight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'LXGWWenKai',
                color: isNight ? Colors.white38 : Colors.black38,
                letterSpacing: 1,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95), // 提高一点不透明度，在背景更亮时保持清晰
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(children: children),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTile(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color accentColor,
    bool isNight, 
    {required VoidCallback onTap}
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isNight ? Colors.white : Colors.black87,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded, 
                size: 14, 
                color: isNight ? Colors.white24 : Colors.black26
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDivider(bool isNight) {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1, 
        thickness: 0.8, 
        color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleImport(BuildContext context, bool isNight) {
    _showActionDialog(
      context, 
      '回忆导入', 
      '警告：导入操作将使用备份文件覆盖当前岛屿上的所有回忆、成就与偏好。此操作不可撤销，请确保备份文件来源可靠。', 
      isNight,
      onConfirm: () async {
        final result = await BackupService.importData();
        if (!context.mounted) return;
        if (result == 'SUCCESS') {
          _showToast(context, '回忆已成功找回，岛屿状态已重置');
        } else if (result == 'INVALID_SIGNATURE' || result == 'INVALID_FORMAT') {
          _showToast(context, '文件校验未通过：非法的加密晶体');
        } else if (result == 'PASSWORD_ERROR') {
          _showToast(context, '解密失败：备份密码不正确');
        } else if (result == 'FAILED') {
          _showToast(context, '导入失败，请确保文件未损坏');
        }
      },
    );
  }

  void _showActionDialog(BuildContext context, String title, String content, bool isNight, {bool isRestore = false, VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        bool isLoading = onConfirm == null; // 仅在展示类对话框中开启初始加载
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
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isNight ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900, 
                          color: isNight ? Colors.white : const Color(0xFF1A1A1A),
                          fontFamily: 'LXGWWenKai',
                        )
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 24),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2)),
                            strokeWidth: 2.5,
                          ),
                        ),
                      Text(
                        onConfirm != null 
                          ? content 
                          : (isLoading ? content : (isRestore ? '您的所有权益（VIP等级、专属饰品）已成功恢复。' : '正在为您跳转至商店...')),
                        style: TextStyle(
                          color: isNight ? Colors.white70 : Colors.black54, 
                          fontSize: 15, 
                          height: 1.6,
                          fontFamily: 'LXGWWenKai'
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (onConfirm != null)
                        Row(
                          children: [
                            Expanded(
                              child: _buildCrystalButton(
                                context, 
                                '取消', 
                                isNight, 
                                onPressed: () => Navigator.pop(context)
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCrystalButton(
                                context, 
                                '确认执行', 
                                isNight, 
                                onPressed: () {
                                  Navigator.pop(context);
                                  onConfirm();
                                }
                              ),
                            ),
                          ],
                        )
                      else if (!isLoading)
                        _buildCrystalButton(
                          context, 
                          '好', 
                          isNight, 
                          onPressed: () => Navigator.pop(context)
                        ),
                    ],
                  ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: isNight ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 内容区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title, 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          color: isNight ? Colors.white : const Color(0xFF1A1A1A), 
                          fontWeight: FontWeight.w900, 
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 1.2,
                        )
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 2.5,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: isNight ? Colors.white70 : Colors.black87, 
                              height: 1.8, 
                              fontSize: 14.5, 
                              fontFamily: 'LXGWWenKai',
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildCrystalButton(
                        context, 
                        '好', 
                        isNight, 
                        onPressed: () => Navigator.pop(context)
                      ),
                    ],
                  ),
                ),
                // 右上角关闭键
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded, 
                      color: isNight ? Colors.white38 : Colors.black26, 
                      size: 24
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }

  Widget _buildCrystalButton(BuildContext context, String label, bool isNight, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          border: Border.all(
            color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }
}
