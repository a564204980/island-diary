import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class AboutIslandPage extends StatelessWidget {
  const AboutIslandPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Stack(
      children: [
        // 1. 全屏艺术背景
        Positioned.fill(child: AboutHeroBackground(isNight: isNight)),

        // 2. 静态浅色/深色透明遮罩层
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: isNight
                  ? const Color(0xFF0D1B2A).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),

        // 3. 页面主体（Scaffold 保持透明背景，限制 CustomScrollView 视口）
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: _buildStandardAppBar(context, isNight),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildHeroSection(isNight),
                          const SizedBox(height: 48),
                          _buildStoryCard(isNight),
                          const SizedBox(height: 32),
                          _buildManualSection(
                            isNight: isNight,
                            index: 0,
                            icon: Icons.edit_note_rounded,
                            title: '随心记录',
                            color: const Color(0xFF81C784),
                            content:
                                '记录生活从未如此简单：\n'
                                '• 点击底部菜单栏上的「小软」即可开始写作。\n'
                                '• 选择今日心情标签，让记录更有温度。\n'
                                '• 支持插入多张精美照片，定格精彩瞬间。\n'
                                '• 所有内容存储在本地，保护您的隐私。',
                          ),
                          const SizedBox(height: 16),
                          _buildManualSection(
                            isNight: isNight,
                            index: 1,
                            icon: Icons.format_paint_rounded,
                            title: '小软的衣帽间',
                            color: const Color(0xFFFFB74D),
                            content:
                                '打造独一无二的私人领地：\n'
                                '• 在「小软的衣帽间」内，为您的守护灵挑选并更换绝版外观。\n'
                                '• 想要更别致？点击预览左下角的「更换背景」即可切换小岛氛围。\n'
                                '• 稀有装扮可以通过日常记录或后续更新解锁。',
                          ),
                          const SizedBox(height: 16),
                          _buildManualSection(
                            isNight: isNight,
                            index: 2,
                            icon: Icons.security_rounded,
                            title: '安全守护',
                            color: const Color(0xFF64B5F6),
                            content:
                                '保护您的心灵秘密：\n'
                                '• 进入「安全中心」开启应用锁或手势密码保护隐私。\n'
                                '• 全文加密存储，无需担心数据泄露。\n'
                                '• 温馨提示：由于数据不上传云端，请务必开启系统级的备份功能。',
                          ),
                          const SizedBox(height: 60),
                          _buildFooter(isNight),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildStandardAppBar(BuildContext context, bool isNight) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isNight ? Colors.white70 : Colors.black87,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '关于小岛',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontFamily: 'LXGWWenKai',
          color: isNight ? Colors.white : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isNight) {
    return Column(
      children: [
        const SizedBox(height: 24),

        Text(
          '岛屿日记',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'Douyin',
            color: isNight ? Colors.white : const Color(0xFF1A1A1A),
            letterSpacing: 2,
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (isNight
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isNight ? Colors.white38 : Colors.black38,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStoryCard(bool isNight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _glassDecoration(isNight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFCE93D8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '我们的故事',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white : Colors.black87,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '在这个喧嚣的世界里，我们每个人都值得拥有一座属于自己的宁静小岛。这里没有评判，没有压力，只有你最真实的自我。不论是琐碎的日常，还是心底的秘密，岛屿日记都会为你温柔珍藏。',
            style: TextStyle(
              fontSize: 14,
              height: 1.8,
              color: isNight ? Colors.white70 : Colors.black54,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildManualSection({
    required bool isNight,
    required int index,
    required IconData icon,
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _glassDecoration(isNight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white : Colors.black87,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 2.0,
                  color: isNight ? Colors.white70 : Colors.black54,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (600 + index * 100).ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildFooter(bool isNight) {
    return Column(
      children: [
        Text(
          'Made with Love for Dreamers',
          style: TextStyle(
            fontSize: 12,
            color: isNight ? Colors.white24 : Colors.black26,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 Island Diary Team',
          style: TextStyle(
            fontSize: 10,
            color: isNight ? Colors.white12 : Colors.black12,
          ),
        ),
      ],
    );
  }

  BoxDecoration _glassDecoration(bool isNight) {
    return BoxDecoration(
      color: isNight
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isNight
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}

class AboutHeroBackground extends StatelessWidget {
  final bool isNight;
  const AboutHeroBackground({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    final baseColor = isNight
        ? const Color(0xFF0D1B2A)
        : const Color(0xFFE6F3F5);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNight
              ? [
                  baseColor,
                  const Color(0xFF1B263B),
                  const Color(0xFF0D1B2A),
                ]
              : [
                  baseColor,
                  const Color(0xFFD0E8EC),
                  const Color(0xFFE6F3F5),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: _buildStaticOrb(
              color: isNight
                  ? const Color(0xFF7E57C2).withValues(alpha: 0.15)
                  : const Color(0xFFCE93D8).withValues(alpha: 0.22),
              size: 350,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildStaticOrb(
              color: isNight
                  ? const Color(0xFF42A5F5).withValues(alpha: 0.12)
                  : const Color(0xFF80DEEA).withValues(alpha: 0.22),
              size: 300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticOrb({
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
