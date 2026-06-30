import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class DiarySearchPanel extends StatefulWidget {
  final Function(String query, int? moodIndex) onSearch;
  final VoidCallback onClear;
  final bool isNight;

  const DiarySearchPanel({
    super.key,
    required this.onSearch,
    required this.onClear,
    this.isNight = false,
  });

  @override
  State<DiarySearchPanel> createState() => _DiarySearchPanelState();
}

class _DiarySearchPanelState extends State<DiarySearchPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int? _selectedMoodIndex;
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 延迟 350ms 等弹窗滑出动画完全结束后再唤起键盘，防止两组动画抢占渲染资源导致卡顿
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  // 与 diary_editor_page 相同的模式：在 didChangeDependencies 里缓存键盘高度，
  // build() 不直接订阅 viewInsets，键盘动画期间背景页面完全不重建
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset > 100 && inset > _keyboardHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && inset > _keyboardHeight) {
          setState(() => _keyboardHeight = inset);
        }
      });
    } else if (inset < 10 && _keyboardHeight > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _keyboardHeight = 0);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    widget.onSearch(_controller.text, _selectedMoodIndex);
  }

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final isCottonCandy = themeId == 'cotton_candy';
    final isCottonCandyDark = isCottonCandy && widget.isNight;

    final textColor = widget.isNight ? Colors.white70 : Colors.black87;
    final hintColor = widget.isNight ? Colors.white38 : Colors.black38;
    final Color highlightColor = isCottonCandyDark
        ? const Color(0xFFC0A6FF)
        : const Color(0xFFE1AF78);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return DiaryBottomSheet(
      height: screenHeight * 0.9,
      paperStyle: 'default',
      showDragHandle: true,
      isDiary: false,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 100 + MediaQuery.paddingOf(context).bottom + viewInsetsBottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // 搜索输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isNight
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isNight
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _handleSearch(),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textColor, fontFamily: 'LXGWWenKai', fontSize: 14.5),
              decoration: InputDecoration(
                hintText: "寻找某段回忆...",
                hintStyle: TextStyle(
                  color: hintColor,
                  fontFamily: 'LXGWWenKai',
                  fontSize: 14.5,
                ),
                border: InputBorder.none,
                icon: Icon(CupertinoIcons.search, color: highlightColor, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: hintColor,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                          _handleSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 心情筛选标题
          Text(
                "按心情筛选",
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.6),
                  fontFamily: 'LXGWWenKai',
                  fontWeight: FontWeight.bold,
                ),
              ),
 
              const SizedBox(height: 12),
 
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 强制每行显示 7 个
                  crossAxisSpacing: 6, // 稍微缩小横向间距，保证文字排版空间
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.73, // 宽高比：高度大于宽度，给下方文字预留空间
                ),
                itemCount: kMoods.length,
                itemBuilder: (context, index) {
                  final mood = kMoods[index];
                  final isSelected = _selectedMoodIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMoodIndex = isSelected ? null : index;
                      });
                      _handleSearch();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 图标容器
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(5),
                          transformAlignment: Alignment.center,
                          transform: isSelected
                              ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (mood.glowColor ?? Colors.amber).withValues(alpha: 0.25)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (mood.glowColor ?? Colors.amber).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Image.asset(
                            mood.iconPath ?? 'assets/icons/happy.png',
                            width: 30,
                            height: 30,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 中文文本标签
                        Text(
                          mood.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? (mood.glowColor ?? highlightColor) 
                                : textColor.withValues(alpha: 0.7),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        _KeyboardFollower(
          keyboardInset: viewInsetsBottom,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: viewInsetsBottom > 0
                  ? 16
                  : MediaQuery.paddingOf(context).bottom + 24,
            ),
            child: GestureDetector(
              onTap: () {
                _handleSearch();
                Navigator.pop(context);
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "确 认",
                    style: TextStyle(
                      color: isCottonCandyDark ? Colors.black87 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _KeyboardFollower extends StatefulWidget {
  final Widget child;
  final double keyboardInset;
  const _KeyboardFollower({required this.child, required this.keyboardInset});

  @override
  State<_KeyboardFollower> createState() => _KeyboardFollowerState();
}

class _KeyboardFollowerState extends State<_KeyboardFollower> {
  double _maxKeyboardHeight = 320; 
  double _lastInset = 0;
  bool _isOpening = false;
  int _durationMs = 120;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = widget.keyboardInset;
    
    if (bottomInset > _maxKeyboardHeight) {
      _maxKeyboardHeight = bottomInset;
    }

    final double jump = bottomInset - _lastInset;

    if (jump > 5) {
      if (!_isOpening) {
        _isOpening = true;
        if (_lastInset > 0 || jump > _maxKeyboardHeight * 0.6) {
          _durationMs = 0;
        } else {
          _durationMs = 120;
        }
      }
    } else if (jump < -5) {
      if (_isOpening) {
        _isOpening = false;
        if (_lastInset < _maxKeyboardHeight * 0.9 || jump < -(_maxKeyboardHeight * 0.6)) {
          _durationMs = 0;
        } else {
          _durationMs = 120;
        }
      }
    }

    if (bottomInset == 0) {
      _isOpening = false;
      _durationMs = 0;
    }

    _lastInset = bottomInset;
    final double targetHeight = _isOpening ? _maxKeyboardHeight : 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: targetHeight),
        duration: Duration(milliseconds: _durationMs),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, child) {
          final double actualBottom = bottomInset > animatedValue ? bottomInset : animatedValue;
          return Padding(
            padding: EdgeInsets.only(bottom: actualBottom),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
