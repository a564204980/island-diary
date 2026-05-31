part of '../../pages/statistics_page.dart';

extension _BentoMoodPalette on _StatisticsPageState {
  Widget _buildMoodPaletteBento(bool isNight, List<DiaryEntry> allEntries) {
    final now = DateTime.now();
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';

    // 1. 构建本月所有的日记心情色块数据流，按时间从早到晚排序
    final List<_PaletteItem> paletteItems = [];
    for (var e in allEntries) {
      if (e.dateTime.year == now.year && e.dateTime.month == now.month) {
        paletteItems.add(_PaletteItem(
          day: e.dateTime.day,
          entry: e,
          moodIndex: e.moodIndex,
        ));
      }
    }
    paletteItems.sort((a, b) => a.entry.dateTime.compareTo(b.entry.dateTime));

    // 统计计算天数和情绪色
    final int recordDays = paletteItems.map((e) => e.day).toSet().length;
    final Set<int> uniqueMoods = paletteItems.map((e) => e.moodIndex % kMoods.length).toSet();
    final int moodColorCount = uniqueMoods.length;

    // 2. 左侧联动文字选择
    String textToShow;
    if (_selectedPaletteDay != null && _selectedPaletteDay! >= 1000) {
      final int idx = _selectedPaletteDay! - 1000;
      if (idx >= 0 && idx < paletteItems.length) {
        final item = paletteItems[idx];
        final date = item.entry.dateTime;
        final moodLabel = kMoods[item.moodIndex % kMoods.length].label;
        final comment = (item.entry.content.trim().isNotEmpty)
            ? item.entry.content.trim()
            : "写下了这一抹生活色彩。";
        textToShow = "${date.month}月${date.day}日 · ${date.hour}时\n$moodLabel · $comment";
      } else {
        textToShow = "把本月的心情，\n调成一款独一无二的\n灵魂画布。";
      }
    } else {
      textToShow = "把本月的心情，\n调成一款独一无二的\n灵魂画布。";
    }

    Widget rightCanvas = _buildJellyCanvas(
      isNight: isNight,
      isCottonCandy: isCottonCandy,
      paletteItems: paletteItems,
      now: now,
    );

    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上部 Row：左侧详情联动 + 右侧密集马赛克画布
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧占比 32%
              Expanded(
                flex: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 标题行
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '时光调色盘',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isNight
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : (isCottonCandy ? const Color(0xFF5A3E28) : const Color(0xFF5A3E28)),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        GestureDetector(
                          onTap: () {
                            showCupertinoDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('时光调色盘', style: TextStyle(fontFamily: 'LXGWWenKai')),
                                content: const Text(
                                  '这里是属于你的情绪艺术品。系统将你本月记录的每日心情调配成马卡龙果冻色块，并拼贴在一块宽幅抽象画布上。点击色块可查看当日的情感备注。',
                                  style: TextStyle(fontFamily: 'LXGWWenKai'),
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('我知道了', style: TextStyle(fontFamily: 'LXGWWenKai')),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(
                            CupertinoIcons.info_circle,
                            size: 14,
                            color: isNight
                                ? Colors.white24
                                : Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 3. 联动文案
                    SizedBox(
                      height: 60,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          textToShow,
                          key: ValueKey<String>(textToShow),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: isNight
                                ? Colors.white.withValues(alpha: 0.5)
                                : (isCottonCandy ? const Color(0xFF8A6C5C) : Colors.black54),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 右侧密集马赛克画布
              Expanded(
                flex: 68,
                child: Padding(
                  padding: const EdgeInsets.only(top: 28), // 进一步下沉至 28px，完美拉开与标题的距离并优美撑高卡片高度
                  child: AspectRatio(
                    aspectRatio: 2.8, // 提高长宽比，横向展示更多精致果冻格子（约 20 列），大幅度减少/避免滚动
                    child: rightCanvas,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 下部 Row：横跨底部的通栏展示（天数/情绪统计文字 + 试色小圆滴）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 4. 统计天数文字
              Text(
                '$recordDays 天记录 · $moodColorCount 种情绪色',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.3)
                      : (isCottonCandy ? const Color(0xFFB09587) : Colors.black38),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              // 5. 试色小圆滴 Wrap
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: uniqueMoods.map((moodIdx) {
                    return _buildMiniColorDot(moodIdx, isNight, isCottonCandy);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPaletteItemTap(int index) {
    updatePaletteDay(index + 1000);
  }

  // 绘制微缩试色小果冻圆滴
  Widget _buildMiniColorDot(int moodIndex, bool isNight, bool isCottonCandy) {
    final color = _getMoodColor(moodIndex, isNight, isCottonCandy);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(0, 1.2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }

  // 右侧无缝拼贴果冻长卷
  Widget _buildJellyCanvas({
    required bool isNight,
    required bool isCottonCandy,
    required List<_PaletteItem> paletteItems,
    required DateTime now,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        // 固定 7 行，每小格边长等于高度 / 7
        const int rowCount = 7;
        final String themeId = UserState().selectedIslandThemeId.value;
        final double cellSize = themeId == 'lego'
            ? ((height - 7 * 1.2) / rowCount) - 1.5
            : (height / rowCount) - 1.5;

        Widget contentWidget;

        if (paletteItems.isEmpty) {
          // 本月无日记：展示自适应列数 x 7行的半透明灰色马赛克格子底片墙
          final int defaultCols = (width / cellSize).floor().clamp(1, 20);
          final Widget emptyGrid = Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(defaultCols, (colIdx) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rowCount, (rowIdx) {
                  final String themeId = UserState().selectedIslandThemeId.value;
                  final bool isLego = themeId == 'lego';
                  if (isLego) {
                    final Color whiteColor = isNight
                        ? const Color(0xFF2C2F36).withValues(alpha: 0.12)
                        : const Color(0xFFF9F9FB).withValues(alpha: 0.15);
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(0.6),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(1.8),
                        boxShadow: [
                          BoxShadow(
                            color: isNight ? Colors.white.withValues(alpha: 0.01) : Colors.white.withValues(alpha: 0.12),
                            offset: const Offset(-0.8, -0.8),
                            blurRadius: 0.8,
                          ),
                          BoxShadow(
                            color: isNight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
                            offset: const Offset(0.8, 0.8),
                            blurRadius: 0.8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: cellSize * 0.54,
                          height: cellSize * 0.54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: whiteColor,
                            boxShadow: [
                              BoxShadow(
                                color: isNight ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.15),
                                offset: const Offset(-0.8, -0.8),
                                blurRadius: 0.8,
                              ),
                              BoxShadow(
                                color: isNight ? Colors.black.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
                                offset: const Offset(0.8, 0.8),
                                blurRadius: 0.8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: isCottonCandy
                          ? const Color(0xFFFFEDE7).withValues(alpha: 0.45)
                          : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
                      border: Border.all(
                        color: isCottonCandy
                            ? const Color(0xFFF8DDD5).withValues(alpha: 0.35)
                            : (isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)),
                        width: 0.4,
                      ),
                    ),
                  );
                }),
              );
            }),
          );

          contentWidget = Stack(
            children: [
              emptyGrid,
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.paintbrush,
                        size: 15,
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.35)
                            : (isCottonCandy ? const Color(0xFFB09587) : const Color(0xFF8A6C5C).withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '等待你的第一笔心情色彩',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: isNight
                              ? Colors.white.withValues(alpha: 0.4)
                              : (isCottonCandy ? const Color(0xFF9A7A69) : const Color(0xFF7A5A4A).withValues(alpha: 0.7)),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // 本月有日记：无缝拼贴正方形色块列表，垂直固定 7 行，支持横向自由滚动
          final int activeCols = (paletteItems.length / rowCount).ceil();
          // 计算可用宽度下最大能铺满的列数，上限为 20 列，用来填补右侧多余空白防止太空
          final int totalCols = (width / cellSize).floor().clamp(1, 20);
          final int showCols = max(activeCols, totalCols);

          contentWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(showCols, (colIdx) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(rowCount, (rowIdx) {
                    final int itemIdx = colIdx * rowCount + rowIdx;
                    if (itemIdx >= paletteItems.length) {
                      // 填充半透明的灰色/粉色微晶边框网格，保持整体画布无缝铺满且不显得太空
                      final String themeId = UserState().selectedIslandThemeId.value;
                      final bool isLego = themeId == 'lego';
                      if (isLego) {
                        final Color whiteColor = isNight
                            ? const Color(0xFF2C2F36).withValues(alpha: 0.12)
                            : const Color(0xFFF9F9FB).withValues(alpha: 0.15);
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(0.6),
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(1.8),
                            boxShadow: [
                              BoxShadow(
                                color: isNight ? Colors.white.withValues(alpha: 0.01) : Colors.white.withValues(alpha: 0.12),
                                offset: const Offset(-0.8, -0.8),
                                blurRadius: 0.8,
                              ),
                              BoxShadow(
                                color: isNight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
                                offset: const Offset(0.8, 0.8),
                                blurRadius: 0.8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: cellSize * 0.54,
                              height: cellSize * 0.54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: whiteColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: isNight ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.15),
                                    offset: const Offset(-0.8, -0.8),
                                    blurRadius: 0.8,
                                  ),
                                  BoxShadow(
                                    color: isNight ? Colors.black.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
                                    offset: const Offset(0.8, 0.8),
                                    blurRadius: 0.8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: isCottonCandy
                              ? const Color(0xFFFFEDE7).withValues(alpha: 0.45)
                              : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
                          border: Border.all(
                            color: isCottonCandy
                                ? const Color(0xFFF8DDD5).withValues(alpha: 0.35)
                                : (isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)),
                            width: 0.4,
                          ),
                        ),
                      );
                    }

                    final item = paletteItems[itemIdx];
                    final bool isSelected = _selectedPaletteDay == itemIdx + 1000;
                    final color = _getMoodColor(item.moodIndex % kMoods.length, isNight, isCottonCandy);

                    final String themeId = UserState().selectedIslandThemeId.value;
                    final bool isLego = themeId == 'lego';

                    Widget cellWidget;
                    if (isLego) {
                      cellWidget = Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(0.6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(1.8),
                          boxShadow: [
                            BoxShadow(
                              color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.35),
                              offset: const Offset(-0.8, -0.8),
                              blurRadius: 0.8,
                            ),
                            BoxShadow(
                              color: isNight ? Colors.black54 : Colors.black.withValues(alpha: 0.22),
                              offset: const Offset(0.8, 0.8),
                              blurRadius: 0.8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: cellSize * 0.54,
                            height: cellSize * 0.54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                  color: isNight ? Colors.white12 : Colors.white.withValues(alpha: 0.45),
                                  offset: const Offset(-0.8, -0.8),
                                  blurRadius: 0.8,
                                ),
                                BoxShadow(
                                  color: isNight ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.28),
                                  offset: const Offset(0.8, 0.8),
                                  blurRadius: 0.8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      // 3D果冻渲染（直角，无缝贴合）
                      cellWidget = Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              Color.lerp(color, Colors.black, isNight ? 0.12 : 0.08) ?? color,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 晶莹高光层
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: isCottonCandy ? 0.35 : 0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7],
                                ),
                              ),
                            ),
                            // 细微的顶部与左侧立体亮线（拟物化玻璃边沿）
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _InnerBorderPainter(isNight: isNight),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 如果被点选，叠加极具发光描边高亮
                    if (isSelected) {
                      cellWidget = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          cellWidget,
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFF7AAB6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF7AAB6).withValues(alpha: 0.55),
                                    blurRadius: 6,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // 微缩交互弹性反馈
                    return GestureDetector(
                      onTap: () => _onPaletteItemTap(itemIdx),
                      child: cellWidget
                          .animate(
                            target: isSelected ? 1 : 0,
                            autoPlay: false,
                          )
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(0.94, 0.94),
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutBack,
                          )
                          .then()
                          .scale(
                            begin: const Offset(0.94, 0.94),
                            end: const Offset(1.0, 1.0),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                          ),
                    );
                  }),
                );
              }),
            ),
          );
        }

        // 外层视窗用大圆角进行高雅切边裁边，完美融入 Bento
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: contentWidget,
              ),
            ),

            // 悬浮点缀：云朵 A (左中，淡蓝紫)
            Positioned(
              left: width * 0.28,
              top: height * 0.1,
              child: _buildFloatingItem(
                _buildFloatingIcon(
                  icon: CupertinoIcons.cloud_fill,
                  size: 16,
                  gradientColors: const [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                ),
                0,
              ),
            ),

            // 悬浮点缀：云朵 B (最右侧，白色)
            Positioned(
              right: width * 0.04,
              bottom: height * 0.2,
              child: _buildFloatingItem(
                _buildFloatingIcon(
                  icon: CupertinoIcons.cloud_fill,
                  size: 18,
                  gradientColors: const [Colors.white, Color(0xFFFFECEE)],
                ),
                400,
              ),
            ),

            // 悬浮点缀：爱心 (中右偏上)
            Positioned(
              right: width * 0.32,
              top: height * 0.15,
              child: _buildFloatingItem(
                _buildFloatingIcon(
                  icon: CupertinoIcons.heart_fill,
                  size: 12,
                  gradientColors: const [Color(0xFFFFB2A6), Color(0xFFFF8E9B)],
                ),
                800,
              ),
            ),

            // 悬浮点缀：月亮 (右中)
            Positioned(
              right: width * 0.20,
              bottom: height * 0.25,
              child: _buildFloatingItem(
                _buildFloatingIcon(
                  icon: CupertinoIcons.moon_fill,
                  size: 12,
                  gradientColors: const [Color(0xFFF9B7FF), Color(0xFFD9B9E7)],
                ),
                1200,
              ),
            ),

            // 悬浮氛围小星光：右上角（金色）
            Positioned(
              right: -6,
              top: -8,
              child: _buildFloatingItem(
                _buildFloatingIcon(
                  icon: CupertinoIcons.sparkles,
                  size: 12,
                  gradientColors: const [Color(0xFFFFE0A3), Color(0xFFFFD54F)],
                ),
                1600,
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建带有精致白色发光描边的漂浮点缀图标，防止在彩色日记格底色背景上看不清
  Widget _buildFloatingIcon({
    required IconData icon,
    required double size,
    required List<Color> gradientColors,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 底层：稍大 1.0px 的纯白描边图标，辅以 4 个方向的白色微距 Shadow 构造出柔和外发光轮廓
        Icon(
          icon,
          size: size + 1.0,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 1.5, offset: const Offset(-0.6, -0.6)),
            Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 1.5, offset: const Offset(0.6, -0.6)),
            Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 1.5, offset: const Offset(-0.6, 0.6)),
            Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 1.5, offset: const Offset(0.6, 0.6)),
          ],
        ),
        // 顶层：马卡龙渐变色主体图标
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(colors: gradientColors).createShader(bounds),
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ],
    );
  }

  // 悬浮点缀上下漂动动画
  Widget _buildFloatingItem(Widget child, int delayMs) {
    return IgnorePointer(
      child: child
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            delay: Duration(milliseconds: delayMs),
          )
          .moveY(
            begin: -2.0,
            end: 2.0,
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeInOut,
          )
          .then()
          .shimmer(
            duration: const Duration(milliseconds: 3200),
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
    );
  }

  Color _getMoodColor(int moodIndex, bool isNight, bool isCottonCandy) {
    switch (moodIndex % 11) {
      case 0:
        return isCottonCandy ? const Color(0xFFFFB2A6) : const Color(0xFFFF8A80);
      case 1:
        return isCottonCandy ? const Color(0xFFC7E5C7) : const Color(0xFF81C784);
      case 2:
        return isCottonCandy ? const Color(0xFFA9D8EB) : const Color(0xFF64B5F6);
      case 3:
        return isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFE57373);
      case 4:
        return isCottonCandy ? const Color(0xFFD9B9E7) : const Color(0xFFBA68C8);
      case 5:
        return isCottonCandy ? const Color(0xFFFFE0A3) : const Color(0xFFFFD54F);
      case 6:
        return isCottonCandy ? const Color(0xFFF9B7FF) : const Color(0xFFF06292);
      case 7:
        return isCottonCandy ? const Color(0xFFB0BEC5) : const Color(0xFF90A4AE);
      case 8:
        return isCottonCandy ? const Color(0xFFB3E5FC) : const Color(0xFF4FC3F7);
      case 9:
        return isCottonCandy ? const Color(0xFFD7CCC8) : const Color(0xFFA1887F);
      case 10:
        return isCottonCandy ? const Color(0xFFFFF59D) : const Color(0xFFFFF176);
      default:
        return Colors.grey;
    }
  }
}

// 数据封装模型
class _PaletteItem {
  final int day;
  final DiaryEntry entry;
  final int moodIndex;
  _PaletteItem({required this.day, required this.entry, required this.moodIndex});
}

// 像素级别拟物化玻璃微折射内部亮线绘制器
class _InnerBorderPainter extends CustomPainter {
  final bool isNight;
  _InnerBorderPainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isNight ? 0.12 : 0.22)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final path = Path();
    // 顶端高亮线
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    // 左端高亮线
    path.moveTo(0, 0);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
