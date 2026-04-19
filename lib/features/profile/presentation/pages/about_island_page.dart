import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class AboutIslandPage extends StatelessWidget {
  const AboutIslandPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Scaffold(
      backgroundColor: isNight
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFE6F3F5),
      // 不再使用 extendBodyBehindAppBar，以确保 AppBar 和 Body 的位置关系完全符合标准
      appBar: _buildStandardAppBar(context, isNight),
      body: Stack(
        children: [
          // 1. 沉浸式流光背景 - 改为 fill，但在 extendBodyBehindAppBar 为 false 时，它只填充 body 区域
          Positioned.fill(child: AboutHeroBackground(isNight: isNight)),

          // 2. 模糊覆盖层
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: isNight
                      ? const Color(0xFF0D1B2A).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),

          Center(
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
                                '• 稀有装扮可以通过达成特定成就免费解锁。',
                          ),
                          const SizedBox(height: 16),
                          _buildManualSection(
                            isNight: isNight,
                            index: 2,
                            icon: Icons.emoji_events_rounded,
                            title: '成就收集',
                            color: const Color(0xFFFF7043),
                            content:
                                '见证您的每一次成长：\n'
                                '• 在「成就墙」查看您的荣誉历程。\n'
                                '• 点击未解锁成就，查看详细的达成要求。\n'
                                '• 达成「白金」等级成就即可获得史诗级装扮奖励。',
                          ),
                          const SizedBox(height: 16),
                          _buildManualSection(
                            isNight: isNight,
                            index: 3,
                            icon: Icons.security_rounded,
                            title: '安全守护',
                            color: const Color(0xFF64B5F6),
                            content:
                                '保护您的心灵秘密：\n'
                                '• 进入「安全中心」开启 FaceID/指纹应用锁。\n'
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
        ],
      ),
    );
  }

  PreferredSizeWidget _buildStandardAppBar(BuildContext context, bool isNight) {
    return AppBar(
      backgroundColor: isNight
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFE6F3F5),
      elevation: 0,
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

class AboutHeroBackground extends StatefulWidget {
  final bool isNight;
  const AboutHeroBackground({super.key, required this.isNight});

  @override
  State<AboutHeroBackground> createState() => _AboutHeroBackgroundState();
}

class _AboutHeroBackgroundState extends State<AboutHeroBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
        final t = _controller.value;
        final baseColor = widget.isNight
            ? const Color(0xFF0F0F1A)
            : const Color(0xFFE6F3F5);
        return Stack(
          children: [
            Container(color: baseColor),
            _buildBlurOrb(
              color: const Color(
                0xFF7E57C2,
              ).withValues(alpha: widget.isNight ? 0.4 : 0.15),
              offset: Offset(
                math.sin(t * 2 * math.pi) * 0.4 + 0.5,
                math.cos(t * 1.5 * math.pi) * 0.3 + 0.4,
              ),
              size: 1.5,
            ),
            _buildBlurOrb(
              color: const Color(
                0xFFCE93D8,
              ).withValues(alpha: widget.isNight ? 0.3 : 0.1),
              offset: Offset(
                math.cos(t * 1.8 * math.pi) * 0.5 + 0.5,
                math.sin(t * 2.2 * math.pi) * 0.4 + 0.6,
              ),
              size: 1.8,
            ),
            _buildBlurOrb(
              color: const Color(
                0xFF42A5F5,
              ).withValues(alpha: widget.isNight ? 0.2 : 0.1),
              offset: Offset(
                math.sin(t * 1.2 * math.pi) * 0.6 + 0.5,
                math.cos(t * 2.5 * math.pi) * 0.5 + 0.5,
              ),
              size: 1.2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurOrb({
    required Color color,
    required Offset offset,
    required double size,
  }) {
    return Align(
      alignment: Alignment(offset.dx * 2 - 1, offset.dy * 2 - 1),
      child: Container(
        width: 400 * size,
        height: 400 * size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
