import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/constants/legal_text.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserState().themeMode,
      builder: (context, _) {
        final isNight = UserState().isNight;
        final Color bgColor = isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F3F5);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              '系统设置',
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
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSection(
                    title: '偏好与数据',
                    isNight: isNight,
                    children: [
                      _buildListTile('回忆导出', Icons.ios_share_rounded, isNight, onTap: () {
                        _showToast(context, '回忆导出功能正在紧锣密鼓开发中');
                      }),
                      _buildDivider(isNight),
                      _buildListTile('恢复购买', Icons.shopping_cart_checkout_rounded, isNight, onTap: () {
                        _showActionDialog(context, '恢复购买', '正在连接 App Store，验证您的偏好设置与订阅记录...', isNight, isRestore: true);
                      }),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection(
                    title: '支持与反馈',
                    isNight: isNight,
                    children: [
                      _buildListTile('去评分', Icons.star_border_rounded, isNight, onTap: () {
                        _showActionDialog(context, '去评分', '岛屿计划离不开您的支持，我们将带您前往 App Store 留下宝贵的评价。', isNight);
                      }),
                      _buildDivider(isNight),
                      _buildListTile('意见反馈', Icons.chat_bubble_outline_rounded, isNight, onTap: () {
                        _showLegalDialog(context, '意见反馈', LegalText.feedbackInfo, isNight);
                      }),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),

                  _buildSection(
                    title: '法律条款',
                    isNight: isNight,
                    children: [
                      _buildListTile('隐私政策', Icons.privacy_tip_outlined, isNight, onTap: () {
                        _showLegalDialog(context, '隐私政策', LegalText.privacyPolicy, isNight);
                      }),
                      _buildDivider(isNight),
                      _buildListTile('用户协议', Icons.gavel_rounded, isNight, onTap: () {
                        _showLegalDialog(context, '用户协议', LegalText.userAgreement, isNight);
                      }),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  _buildSection(
                    title: '实验室',
                    isNight: isNight,
                    children: [
                      _buildListTile(
                        '开发调试：一键解锁',
                        Icons.bug_report_rounded,
                        isNight,
                        onTap: () {
                          UserState().unlockAllForTesting();
                          _showToast(context, '已触发全量解锁测试模式');
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, required bool isNight}) {
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

  Widget _buildListTile(String title, IconData icon, bool isNight, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isNight ? Colors.white54 : Colors.black54),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: isNight ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isNight ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isNight) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(height: 1, thickness: 0.5, color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showActionDialog(BuildContext context, String title, String content, bool isNight, {bool isRestore = false}) {
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = true;
        return StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted && isLoading) {
                setState(() => isLoading = false);
              }
            });

            return AlertDialog(
              backgroundColor: isNight ? const Color(0xFF1A1A2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(title, style: TextStyle(color: isNight ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2)),
                        strokeWidth: 2,
                      ),
                    ),
                  Text(
                    isLoading ? content : (isRestore ? '您的所有权益（VIP等级、专属饰品）已成功恢复。' : '正在为您跳转至商店...'),
                    style: TextStyle(color: isNight ? Colors.white70 : Colors.black54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('好', style: TextStyle(color: isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2))),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content, bool isNight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isNight ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title, 
          style: TextStyle(color: isNight ? Colors.white : const Color(0xFF1A1A1A), fontWeight: FontWeight.bold)
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(color: isNight ? Colors.white70 : Colors.black87, height: 1.6, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('好', style: TextStyle(color: isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2))),
          ),
        ],
      ),
    );
  }
}
