import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/plugins/plugin_manager.dart';
import '../../../../../core/plugins/island_plugin.dart';
import 'plugin_detail_page.dart';

class PluginStorePage extends StatefulWidget {
  const PluginStorePage({super.key});

  @override
  State<PluginStorePage> createState() => _PluginStorePageState();
}

class _PluginStorePageState extends State<PluginStorePage> {
  final PluginManager _pm = PluginManager.instance;
  List<IslandPlugin> _availablePlugins = [];
  bool _isLoading = true;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
    _pm.addListener(_onPluginStateChanged);
  }

  @override
  void dispose() {
    _pm.removeListener(_onPluginStateChanged);
    super.dispose();
  }

  void _onPluginStateChanged() {
    setState(() {});
  }

  Future<void> _loadPlugins() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _availablePlugins = _pm.getAllAvailablePlugins();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isNight ? const Color(0xFF0F111A) : const Color(0xFFF8F9FA);
    final textColor = isNight ? Colors.white : const Color(0xFF1A1D24);
    final secondaryTextColor = isNight ? Colors.white70 : const Color(0xFF6B7280);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 底部发光光晕 (Ambient Blobs)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF818CF8).withValues(alpha: isNight ? 0.15 : 0.25), // 浅紫蓝
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.1, duration: 4.seconds, curve: Curves.easeInOutSine),
          
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF472B6).withValues(alpha: isNight ? 0.1 : 0.2), // 粉色
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.1, end: 1.0, duration: 5.seconds, curve: Curves.easeInOutSine)
           .slideX(begin: 0, end: 0.05, duration: 6.seconds, curve: Curves.easeInOutSine),

          Positioned(
            top: 300,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: isNight ? 0.1 : 0.2), // 天蓝
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .slideY(begin: 0, end: 0.1, duration: 5.seconds, curve: Curves.easeInOutSine),

          // 底层大范围的高斯模糊，让色块呈现散开的光斑感
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 实际内容
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          '发现你的\n专属组件',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: 1,
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      ),
                    ),
                    

                    // 过滤标签
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        child: SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildFilterChip('精选推荐', 0, isNight),
                              const SizedBox(width: 12),
                              _buildFilterChip('相机特效', 1, isNight),
                              const SizedBox(width: 12),
                              _buildFilterChip('效率工具', 2, isNight),
                            ],
                          ).animate().fadeIn(delay: 100.ms),
                        ),
                      ),
                    ),
                    
                    // 横向轮播大图 (Featured)
                    if (_availablePlugins.isNotEmpty)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _availablePlugins.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _navigateToDetail(_availablePlugins[index], index),
                                child: _buildFeaturedCard(_availablePlugins[index], index, isNight),
                              );
                            },
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                        ),
                      ),
                    
                    // 列表小标题
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '全部组件',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '查看全部',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms),
                      ),
                    ),
                    
                    // 纵向列表 (List)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final plugin = _availablePlugins[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: GestureDetector(
                              onTap: () => _navigateToDetail(plugin, index),
                              child: _buildListCard(plugin, isNight, textColor, secondaryTextColor)
                                  .animate()
                                  .fadeIn(delay: (300 + index * 100).ms)
                                  .slideY(begin: 0.1, end: 0),
                            ),
                          );
                        },
                        childCount: _availablePlugins.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 60)),
                  ],
                ),
        ],
      ),
    );
  }

  void _navigateToDetail(IslandPlugin plugin, int index) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
    ];
    final gradient = gradients[index % gradients.length];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PluginDetailPage(plugin: plugin, headerGradient: gradient),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isNight) {
    final isSelected = _selectedFilterIndex == index;
    final glassColor = isNight ? Colors.white : Colors.white;
    final textColor = isNight ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? glassColor.withValues(alpha: 0.8) : glassColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: glassColor.withValues(alpha: isSelected ? 0.8 : 0.2),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? (isNight ? Colors.black : Colors.white) : textColor.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(IslandPlugin plugin, int index, bool isNight) {
    final glassBg = isNight ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2);
    final borderColor = isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5);
    final textColor = isNight ? Colors.white : Colors.black87;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ]
          ),
          child: Stack(
            children: [
              // 装饰性渐变发光球
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == 0 ? Colors.blueAccent.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  index == 0 ? Icons.camera_rounded : Icons.dynamic_feed_rounded,
                  size: 140,
                  color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '精选推荐',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plugin.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plugin.description,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(IslandPlugin plugin, bool isNight, Color textColor, Color secondaryColor) {
    final bool isInstalled = _pm.isPluginInstalled(plugin.pluginId);
    final bool isActive = _pm.isPluginActive(plugin.pluginId);
    
    final glassBg = isNight ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.25);
    final borderColor = isNight ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6);
    final iconBgColor = isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/app_icon.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: isNight ? Colors.white70 : Colors.black87,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plugin.description,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(plugin, isInstalled, isActive, isNight),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IslandPlugin plugin, bool isInstalled, bool isActive, bool isNight) {
    final getBgColor = isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08);
    final primaryBgColor = isNight ? Colors.white : Colors.black87;
    
    String label;
    Color color;
    Color bgColor;

    if (!isInstalled) {
      label = '获取';
      color = isNight ? Colors.white : Colors.black87;
      bgColor = getBgColor;
    } else if (isActive) {
      label = '已启用';
      color = isNight ? Colors.white54 : Colors.black54;
      bgColor = isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    } else {
      label = '启用组件';
      color = isNight ? Colors.black : Colors.white;
      bgColor = primaryBgColor;
    }

    return GestureDetector(
      onTap: () {
        if (!isInstalled) {
          _pm.installPlugin(plugin.pluginId);
        } else if (isActive) {
          _pm.disablePlugin(plugin.pluginId);
        } else {
          _pm.enablePlugin(plugin.pluginId);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
