import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';

class DiaryBookDetailReaderPage extends StatefulWidget {
  final List<DiaryEntry> entries;
  final int initialIndex;

  const DiaryBookDetailReaderPage({
    super.key,
    required this.entries,
    this.initialIndex = 0,
  });

  @override
  State<DiaryBookDetailReaderPage> createState() => _DiaryBookDetailReaderPageState();
}

class _DiaryBookDetailReaderPageState extends State<DiaryBookDetailReaderPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.entries.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return DiaryDetailPage(
                entry: widget.entries[index],
                isNight: isNight,
                showFloatingActions: false,
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isNight ? Colors.white70 : Colors.black87,
                ),
              ),
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.entries.length}',
                      style: TextStyle(
                        color: isNight ? Colors.white38 : Colors.black38,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
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
}
