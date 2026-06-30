part of '../../pages/statistics_page.dart';

extension _BentoEmotionMetrics on _StatisticsPageState {
  Widget _buildStatsBentoList(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    int streak = 0;
    int totalWords = 0;

    if (allEntries.isNotEmpty) {
      for (var d in allEntries) {
        totalWords += d.content.length;
      }
      
      final sortedDates = allEntries.map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day)).toSet().toList();
      sortedDates.sort((a, b) => b.compareTo(a));
      
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime current = sortedDates.first == today ? today : sortedDates.first;
      
      for (int i = 0; i < sortedDates.length; i++) {
        if (sortedDates[i] == current) {
          streak++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    final streakColor = isNight ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
    final wordColor = isNight ? const Color(0xFF75C7B7) : const Color(0xFF2E7E6E);

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            isNight: isNight,
            isCottonCandy: isCottonCandy,
            topText: '当前',
            middleText: '连记',
            bottomText: '连续记录',
            value: streak,
            unit: '天',
            numColor: streakColor,
            themeColor: themeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            isNight: isNight,
            isCottonCandy: isCottonCandy,
            topText: '累计',
            middleText: '字数',
            bottomText: '累计写下',
            value: totalWords,
            unit: '字',
            numColor: wordColor,
            themeColor: themeColor,
          ),
        ),
      ],
    );
  }



  Widget _buildMoodProgressBarBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    if (filtered.isEmpty) {
       return _buildGlassCard(
        isNight: isNight,
        backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBentoHeader(
              context: context,
              title: '情绪成分',
              helpContent: '量化展示这段时间里，各种情绪分别出现了多少。你可以直接看到哪种情绪更常见。',
              isNight: isNight,
            ),
            const SizedBox(height: 16),
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.withValues(alpha: 0.04)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无数据',
              style: TextStyle(
                color: isNight ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontFamily: fontFamily,
              ),
            ),
          ],
        )
      );
    }

    final unifiedData = _getUnifiedEmotionData(filtered);
    final visibleData = unifiedData.where((data) => data.count > 0).take(7).toList();
    final int total = visibleData.isEmpty ? 1 : visibleData.fold<int>(0, (sum, item) => sum + item.count);
    final topItem = visibleData.isEmpty
        ? null
        : visibleData.reduce((a, b) => a.count >= b.count ? a : b);
    final summaryText = topItem == null
        ? '量化展示您的情绪占比。最近的情绪分布还比较平均。'
        : '量化展示您的情绪占比。最近出现最多的是 ${topItem.label}，占 ${((topItem.count / total) * 100).toStringAsFixed(0)}%。点击下方标签可回顾相关日记。';

    return AnimatedBuilder(
      animation: _timeCarvingAnimController,
      builder: (context, child) {
        final double animValue = _timeCarvingAnimController.value;
        final double easeValue = Curves.easeOutCubic.transform(animValue);

        List<Widget> barSegments = [];
        List<Widget> legendChips = [];

        for (int i = 0; i < visibleData.length; i++) {
          final data = visibleData[i];
          final flex = (data.count / total * 100).toInt().clamp(1, 100);

          final bool isHovered = _hoveredEmotionLabel == data.label;
          final bool hasHover = _hoveredEmotionLabel != null;

           Widget segmentWidget = GestureDetector(
            onTapDown: (_) {
              setState(() {
                _hoveredEmotionLabel = data.label;
              });
            },
            onTapUp: (_) {
              setState(() {
                _hoveredEmotionLabel = null;
              });
            },
            onTapCancel: () {
              setState(() {
                _hoveredEmotionLabel = null;
              });
            },
            onTap: () async {
              if (data.originalMoodIndex != null) {
                setState(() {
                  _hoveredEmotionLabel = data.label;
                });
                await _showMoodDetailSheet(context, data.originalMoodIndex!, filtered, isNight);
                if (mounted) {
                  setState(() {
                    _hoveredEmotionLabel = null;
                  });
                }
              }
            },
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    data.color.withValues(alpha: 0.95),
                    data.color.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          );

          // 联动交互高亮：被点击的气泡微微上浮，未点击的比例条渐淡弱化
          segmentWidget = AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, isHovered ? -5.0 : 0.0, 0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: hasHover ? (isHovered ? 1.0 : 0.35) : 1.0,
              child: segmentWidget,
            ),
          );

          if (isLego) {
            final double startOffset = i * 0.08;
            final double segProgress = ((animValue - startOffset) * 2.5).clamp(0.0, 1.0);
            final double segOpacity = (segProgress * 3.0).clamp(0.0, 1.0);
            final double segY = (1.0 - Curves.bounceOut.transform(segProgress)) * -32.0;

            segmentWidget = Transform.translate(
              offset: Offset(0, segY),
              child: Opacity(
                opacity: segOpacity,
                child: segmentWidget,
              ),
            );
          }

          barSegments.add(Expanded(
            flex: flex,
            child: segmentWidget,
          ));

          if (i < visibleData.length - 1) {
            barSegments.add(const SizedBox(width: 3.5));
          }

          // 标签卡片采用从左到右微小 staggered 渐入效果
          final double chipProgress = ((animValue - (i * 0.06)) * 2.2).clamp(0.0, 1.0);
          final double chipOpacity = chipProgress;
          final double chipSlide = (1.0 - Curves.easeOutCubic.transform(chipProgress)) * 10.0;

          // 核心动效：图2中 Top-3 情绪气泡字体更大，普通气泡更小，但所有卡片高度保持一致
          final bool isTop3 = i < 3;
          final double paddingHorizontal = isTop3 ? 12.0 : 9.0;
          final double borderRadiusValue = isLego ? 8.0 : 15.0; // 乐高模式下使用方圆角以符合积木质感
          final double dotSize = isTop3 ? 7.5 : 6.0;
          final double labelFontSize = isTop3 ? 13.0 : 10.5;
          final double percentFontSize = isTop3 ? 11.5 : 9.5;
          final double dotTextSpacing = isTop3 ? 6.0 : 4.0;
          final double textPercentSpacing = isTop3 ? 4.0 : 2.5;
          final FontWeight labelFontWeight = isTop3 ? FontWeight.w800 : FontWeight.w600;

          legendChips.add(
            Transform.translate(
              offset: Offset(0, chipSlide),
              child: Opacity(
                opacity: chipOpacity,
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _hoveredEmotionLabel = data.label;
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _hoveredEmotionLabel = null;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _hoveredEmotionLabel = null;
                    });
                  },
                  onTap: () async {
                    if (data.originalMoodIndex != null) {
                      setState(() {
                        _hoveredEmotionLabel = data.label;
                      });
                      await _showMoodDetailSheet(context, data.originalMoodIndex!, filtered, isNight);
                      if (mounted) {
                        setState(() {
                          _hoveredEmotionLabel = null;
                        });
                      }
                    }
                  },
                  child: Container(
                    height: 30, // 固定高度以保证每个气泡卡片高度完全一致
                    padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                    decoration: BoxDecoration(
                      color: isNight
                          ? data.color.withValues(alpha: 0.16)
                          : data.color.withValues(alpha: isCottonCandy ? 0.12 : 0.14),
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      border: Border.all(
                        color: data.color.withValues(alpha: isNight ? 0.22 : 0.2),
                        width: 0.7,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: isLego ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: isLego ? BorderRadius.circular(1.5) : null,
                            color: data.color,
                          ),
                        ),
                        SizedBox(width: dotTextSpacing),
                        Text(
                          data.label,
                          style: TextStyle(
                            fontSize: labelFontSize,
                            color: isNight
                                ? Colors.white70
                                : (isCottonCandy ? const Color(0xFF6F574A) : Colors.black87),
                            fontFamily: fontFamily,
                            fontWeight: labelFontWeight,
                          ),
                        ),
                        SizedBox(width: textPercentSpacing),
                        Text(
                          '${((data.count / total) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: percentFontSize,
                            color: isNight
                                ? Colors.white54
                                : (isCottonCandy ? const Color(0xFF8F7464) : Colors.black45),
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return _buildGlassCard(
          isNight: isNight,
          backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBentoHeader(
                context: context,
                title: '情绪成分',
                helpContent: null,
                isNight: isNight,
              ),
              const SizedBox(height: 8),
              Text(
                summaryText,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: isNight
                      ? Colors.white60
                      : (isCottonCandy ? const Color(0xFF8F7464) : const Color(0xFF6D5A4B)),
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 14),
              isLego
                  ? Row(children: barSegments)
                  : ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: easeValue,
                        child: Row(children: barSegments),
                      ),
                    ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: legendChips,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaxStreaksBento(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    
    int maxDaily = 0;
    int maxWeekly = 0;
    
    if (allEntries.isNotEmpty) {
      // 1. 计算最长每日连记
      final sortedDates = allEntries
          .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      
      int currentDaily = 0;
      DateTime? prevDate;
      for (var date in sortedDates) {
        if (prevDate == null) {
          currentDaily = 1;
        } else {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            currentDaily++;
          } else if (diff > 1) {
            if (currentDaily > maxDaily) {
              maxDaily = currentDaily;
            }
            currentDaily = 1;
          }
        }
        prevDate = date;
      }
      if (currentDaily > maxDaily) {
        maxDaily = currentDaily;
      }
      
      // 2. 计算最长每周连记
      DateTime getStartOfWeek(DateTime date) {
        return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
      }
      
      final sortedWeeks = allEntries
          .map((e) => getStartOfWeek(e.dateTime))
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      
      int currentWeekly = 0;
      DateTime? prevWeek;
      for (var week in sortedWeeks) {
        if (prevWeek == null) {
          currentWeekly = 1;
        } else {
          final diff = week.difference(prevWeek).inDays;
          final weeksDiff = (diff / 7).round();
          if (weeksDiff == 1) {
            currentWeekly++;
          } else if (weeksDiff > 1) {
            if (currentWeekly > maxWeekly) {
              maxWeekly = currentWeekly;
            }
            currentWeekly = 1;
          }
        }
        prevWeek = week;
      }
      if (currentWeekly > maxWeekly) {
        maxWeekly = currentWeekly;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            isNight: isNight,
            isCottonCandy: isCottonCandy,
            topText: '最长',
            middleText: '每日',
            bottomText: '连续记录',
            value: maxDaily,
            unit: '天',
            numColor: const Color(0xFFD36B5F),
            themeColor: themeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            isNight: isNight,
            isCottonCandy: isCottonCandy,
            topText: '最长',
            middleText: '每周',
            bottomText: '连续记录',
            value: maxWeekly,
            unit: '周',
            numColor: const Color(0xFF5A7EC8),
            themeColor: themeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required bool isNight,
    required bool isCottonCandy,
    required String topText,
    required String middleText,
    required String bottomText,
    required num value,
    required String unit,
    required Color numColor,
    required Color themeColor,
  }) {
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String cardFont = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    // 乐高积木拼搭专属：采用莫兰迪/马卡龙低饱和度乐高积木色系，柔和养眼
    Color? customBg;
    if (isLego) {
      if (middleText == '连记') {
        customBg = isNight ? const Color(0xFF5D508A) : const Color(0xFFA394D8); // 柔和紫
      } else if (middleText == '字数') {
        customBg = isNight ? const Color(0xFF356150) : const Color(0xFF6EAA94); // 柔和绿
      } else if (middleText == '每日') {
        customBg = isNight ? const Color(0xFF8C4743) : const Color(0xFFDF8680); // 柔和粉红
      } else if (middleText == '每周') {
        customBg = isNight ? const Color(0xFF3C5A85) : const Color(0xFF7BA0CB); // 柔和蓝
      }
    } else if (isCottonCandy) {
      customBg = const Color(0xFFFFF4EF);
    }

    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: customBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SizedBox(
        height: 86,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  topText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLego 
                        ? Colors.white.withValues(alpha: 0.7)
                        : (isNight ? Colors.white38 : Colors.black38),
                    fontFamily: cardFont,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  middleText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLego 
                        ? Colors.white 
                        : (isNight ? Colors.white : const Color(0xFF333333)),
                    fontFamily: cardFont,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bottomText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLego 
                        ? Colors.white.withValues(alpha: 0.7)
                        : (isNight ? Colors.white38 : Colors.black38),
                    fontFamily: cardFont,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _timeCarvingAnimController,
              builder: (context, child) {
                final double progress = Curves.easeOutCubic.transform(_timeCarvingAnimController.value);
                final currentVal = (value * progress).round();
                
                String displayVal;
                if (middleText == '字数' && value > 999) {
                  final double kVal = (value * progress) / 1000.0;
                  displayVal = '${kVal.toStringAsFixed(1)}k';
                } else {
                  displayVal = '$currentVal';
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      displayVal,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: isLego ? Colors.white : numColor,
                        fontFamily: cardFont,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLego ? Colors.white : numColor,
                        fontFamily: cardFont,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
