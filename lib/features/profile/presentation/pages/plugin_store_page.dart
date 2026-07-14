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
      body: _isLoading
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
                            child: _buildFeaturedCard(_availablePlugins[index], index),
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
    );
  }

  void _navigateToDetail(IslandPlugin plugin, int index) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
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
    // 选中状态颜色：参考原图的亮紫色/蓝色
    final selectedColor = isNight ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED);
    final unselectedBg = isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    final unselectedBorder = isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : unselectedBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isNight ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(IslandPlugin plugin, int index) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
    ];
    final gradient = gradients[index % gradients.length];
    final tagColor = index == 0 ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
      ),
      child: Stack(
        children: [
          // 模拟图片底纹图标
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              index == 0 ? Icons.camera_rounded : Icons.dynamic_feed_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.15),
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
                    color: tagColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '热门推荐',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plugin.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plugin.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
    );
  }

  Widget _buildListCard(IslandPlugin plugin, bool isNight, Color textColor, Color secondaryColor) {
    final bool isInstalled = _pm.isPluginInstalled(plugin.pluginId);
    final bool isActive = _pm.isPluginActive(plugin.pluginId);
    
    // 参考图中圆角矩形图片
    final iconBgColor = isNight ? const Color(0xFF232530) : const Color(0xFFE5E7EB);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/app_icon.png'), // 降级图标，如果没有会显示底色
              fit: BoxFit.cover,
              opacity: 0.3, // 暗化处理
            ),
          ),
          child: Icon(
            Icons.camera_alt_rounded,
            color: isNight ? Colors.white54 : Colors.black54,
            size: 28,
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
              const SizedBox(height: 10),
              _buildActionButton(plugin, isInstalled, isActive, isNight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IslandPlugin plugin, bool isInstalled, bool isActive, bool isNight) {
    final btnBgColor = isNight ? const Color(0xFF1E212B) : const Color(0xFFE5E7EB);
    final activeBgColor = isNight ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : const Color(0xFF7C3AED).withValues(alpha: 0.1);
    
    String label;
    Color color;
    Color bgColor;

    if (!isInstalled) {
      label = '获取 / 安装';
      color = isNight ? Colors.white : Colors.black;
      bgColor = btnBgColor;
    } else if (isActive) {
      label = '已启用';
      color = isNight ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
      bgColor = activeBgColor;
    } else {
      label = '启用组件';
      color = isNight ? Colors.white : Colors.white;
      bgColor = isNight ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED);
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
