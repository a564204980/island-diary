import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

class DiarySearchPanel extends StatefulWidget {
  final Function(String query, int? moodIndex, DateTime? date) onSearch;
  final VoidCallback onClear;
  final bool isNight;
  final DateTime? initialDate;

  const DiarySearchPanel({
    super.key,
    required this.onSearch,
    required this.onClear,
    this.isNight = false,
    this.initialDate,
  });

  @override
  State<DiarySearchPanel> createState() => _DiarySearchPanelState();
}

class _DiarySearchPanelState extends State<DiarySearchPanel> {
  final TextEditingController _controller = TextEditingController();
  int? _selectedMoodIndex;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  void _handleSearch() {
    widget.onSearch(_controller.text, _selectedMoodIndex, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isNight ? const Color(0xFF2C2E30) : Colors.white;
    final textColor = widget.isNight ? Colors.white70 : Colors.black87;
    final hintColor = widget.isNight ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isNight ? 0.5 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部指示条
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: widget.isNight ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 搜索输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isNight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isNight
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _handleSearch(),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textColor, fontFamily: 'LXGWWenKai'),
              decoration: InputDecoration(
                hintText: "寻找某段回忆...",
                hintStyle: TextStyle(
                  color: hintColor,
                  fontFamily: 'LXGWWenKai',
                ),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: hintColor, size: 20),
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

          const SizedBox(height: 20),

          // 日期筛选
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "按日期筛选",
                style: TextStyle(
                  fontSize: 13,
                  color: hintColor,
                  fontFamily: 'LXGWWenKai',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedDate != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = null;
                    });
                    _handleSearch();
                  },
                  child: Text(
                    "清除日期",
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFD4A373).withValues(alpha: 0.8),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFFD4A373),
                        onPrimary: Colors.white,
                        surface: widget.isNight
                            ? const Color(0xFF2C2E30)
                            : Colors.white,
                        onSurface: widget.isNight
                            ? Colors.white70
                            : Colors.black87,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD4A373),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
                _handleSearch();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isNight
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDate != null
                      ? const Color(0xFFD4A373).withValues(alpha: 0.5)
                      : (widget.isNight
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: _selectedDate != null
                        ? const Color(0xFFD4A373)
                        : hintColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? "选择日期..."
                        : "${_selectedDate!.year}年${_selectedDate!.month}月${_selectedDate!.day}日",
                    style: TextStyle(
                      color: _selectedDate != null ? textColor : hintColor,
                      fontSize: 14,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 心情筛选标题
          Text(
            "按心情筛选",
            style: TextStyle(
              fontSize: 13,
              color: hintColor,
              fontFamily: 'LXGWWenKai',
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // 心情图标列表
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (mood.glowColor ?? Colors.amber).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (mood.glowColor ?? Colors.amber).withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Tooltip(
                      message: mood.label,
                      child: Image.asset(
                        mood.iconPath ?? 'assets/images/icons/sun.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
