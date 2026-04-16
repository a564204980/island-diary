import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/constants/legal_text.dart';

class AboutIslandPage extends StatelessWidget {
  const AboutIslandPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F3F5),
      body: Stack(
        children: [
          // 1. 沉浸式流光背景
          Positioned.fill(
            child: AboutHeroBackground(isNight: isNight),
          ),

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

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, isNight),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroSection(isNight),
                        const SizedBox(height: 48),
                        _buildStoryCard(isNight),
                        const SizedBox(height: 24),
                        _buildFeaturesGrid(isNight),
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
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isNight) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isNight ? Colors.white : Colors.black87,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      floating: true,
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
            color: (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
              const Icon(Icons.auto_awesome, color: Color(0xFFCE93D8), size: 18),
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

  Widget _buildFeaturesGrid(bool isNight) {
    final features = [
      {'icon': Icons.edit_note_rounded, 'title': '随心记录', 'color': const Color(0xFF81C784)},
      {'icon': Icons.format_paint_rounded, 'title': '岛屿装扮', 'color': const Color(0xFFFFB74D)},
      {'icon': Icons.emoji_events_rounded, 'title': '成就收集', 'color': const Color(0xFFFF7043)},
      {'icon': Icons.security_rounded, 'title': '安全守护', 'color': const Color(0xFF64B5F6)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _glassDecoration(isNight),
          child: Row(
            children: [
              Icon(f['icon'] as IconData, color: f['color'] as Color, size: 20),
              const SizedBox(width: 12),
              Text(
                f['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 800.ms);
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

class _AboutHeroBackgroundState extends State<AboutHeroBackground> with SingleTickerProviderStateMixin {
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
        final baseColor = widget.isNight ? const Color(0xFF0F0F1A) : const Color(0xFFE6F3F5);
        return Stack(
          children: [
            Container(color: baseColor),
            _buildBlurOrb(
              color: const Color(0xFF7E57C2).withValues(alpha: widget.isNight ? 0.4 : 0.15),
              offset: Offset(
                math.sin(t * 2 * math.pi) * 0.4 + 0.5,
                math.cos(t * 1.5 * math.pi) * 0.3 + 0.4,
              ),
              size: 1.5,
            ),
            _buildBlurOrb(
              color: const Color(0xFFCE93D8).withValues(alpha: widget.isNight ? 0.3 : 0.1),
              offset: Offset(
                math.cos(t * 1.8 * math.pi) * 0.5 + 0.5,
                math.sin(t * 2.2 * math.pi) * 0.4 + 0.6,
              ),
              size: 1.8,
            ),
            _buildBlurOrb(
              color: const Color(0xFF42A5F5).withValues(alpha: widget.isNight ? 0.2 : 0.1),
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

  Widget _buildBlurOrb({required Color color, required Offset offset, required double size}) {
    return Align(
      alignment: Alignment(offset.dx * 2 - 1, offset.dy * 2 - 1),
      child: Container(
        width: 400 * size,
        height: 400 * size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
