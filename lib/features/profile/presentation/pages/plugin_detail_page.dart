import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/plugins/plugin_manager.dart';
import '../../../../../core/plugins/island_plugin.dart';

class PluginDetailPage extends StatefulWidget {
  final IslandPlugin plugin;
  final Gradient? headerGradient;

  const PluginDetailPage({
    super.key,
    required this.plugin,
    this.headerGradient,
  });

  @override
  State<PluginDetailPage> createState() => _PluginDetailPageState();
}

class _PluginDetailPageState extends State<PluginDetailPage> {
  final PluginManager _pm = PluginManager.instance;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Timer? _downloadTimer;

  @override
  void initState() {
    super.initState();
    _pm.addListener(_onPluginStateChanged);
  }

  @override
  void dispose() {
    _downloadTimer?.cancel();
    _pm.removeListener(_onPluginStateChanged);
    super.dispose();
  }

  void _onPluginStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isNight ? const Color(0xFF0F111A) : const Color(0xFFF8F9FA);
    final textColor = isNight ? Colors.white : const Color(0xFF1A1D24);
    final secondaryTextColor = isNight ? Colors.white70 : const Color(0xFF6B7280);

    final bool isInstalled = _pm.isPluginInstalled(widget.plugin.pluginId);
    final bool isActive = _pm.isPluginActive(widget.plugin.pluginId);

    // 默认渐变色（如果没有传）
    final fallbackGradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部大图区域
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: widget.headerGradient ?? fallbackGradient,
              ),
              child: Stack(
                children: [
                  // 背景点缀图标
                  Positioned(
                    right: -40,
                    bottom: -20,
                    child: Icon(
                      Icons.extension_rounded,
                      size: 240,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
            
            // 详情内容区域
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题与收藏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.plugin.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 28,
                      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  // 评分与标签信息
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'T',
                          style: TextStyle(
                            color: isNight ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '版本 ${widget.plugin.version} - 官方组件',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // 描述标题
                  Text(
                    'Description',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 12),
                  
                  // 描述正文
                  Text(
                    widget.plugin.description * 3, // 重复几次让文案看起来丰富一些
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 120), // 为底部悬浮按钮留出空间
                ],
              ),
            ),
          ],
        ),
      ),
      // 底部悬浮操作栏
      bottomSheet: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 16),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.8),
              blurRadius: 20,
              spreadRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildMainActionButton(isInstalled, isActive, isNight),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: isNight ? const Color(0xFF232530) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.ios_share_rounded,
                  color: textColor,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(bool isInstalled, bool isActive, bool isNight) {
    // 参考图2：紫色主题按钮
    final primaryColor = const Color(0xFF8B5CF6);
    
    if (_isDownloading) {
      // 下载进度条状态
      return Container(
        key: const ValueKey('downloading_progress'),
        height: 56,
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // 进度填充层
              FractionallySizedBox(
                widthFactor: _downloadProgress,
                heightFactor: 1.0,
                child: Container(
                  color: primaryColor.withValues(alpha: 0.8),
                ),
              ),
              // 文字层
              Center(
                child: Text(
                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isNight ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String label;
    Color bgColor;
    Color textColor;

    if (!isInstalled) {
      label = '获取 / 安装';
      bgColor = primaryColor;
      textColor = Colors.white;
    } else if (isActive) {
      label = '停用组件';
      bgColor = isNight ? const Color(0xFF232530) : const Color(0xFFE5E7EB);
      textColor = isNight ? Colors.white : Colors.black;
    } else {
      label = '启用组件';
      bgColor = primaryColor;
      textColor = Colors.white;
    }

    return GestureDetector(
      key: const ValueKey('action_button'),
      onTap: () {
        if (!isInstalled) {
          _startFakeDownload();
        } else if (isActive) {
          _pm.disablePlugin(widget.plugin.pluginId);
        } else {
          _pm.enablePlugin(widget.plugin.pluginId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _startFakeDownload() {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _downloadTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _downloadProgress += 0.02; // 每次加 2%，大概 2.5 秒下完
        if (_downloadProgress >= 1.0) {
          _downloadProgress = 1.0;
          timer.cancel();
          _pm.installPlugin(widget.plugin.pluginId).then((_) {
            if (mounted) {
              setState(() {
                _isDownloading = false;
              });
            }
          });
        }
      });
    });
  }
}
