part of '../../pages/statistics_page.dart';

extension BentoUtils on _StatisticsPageState {
  void _showPosterPreview(BuildContext context, bool isNight) {
    final filtered = _getFilteredDiaries();
    if (filtered.isEmpty) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('数据不足'),
            content: const Text('记录更多日记，才能生成专属的情感海报哦 🎨'),
            actions: [
              CupertinoDialogAction(child: const Text('我知道了'), onPressed: () => Navigator.pop(context)),
            ],
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MoodPosterWidget(
          entries: filtered,
          isNight: isNight,
        ),
      ),
    );
  }

  void _showMoodDetailSheet(BuildContext context, int moodIndex, List<DiaryEntry> subset, bool isNight) {
    final config = kMoods[moodIndex % kMoods.length];
    final moodColor = config.glowColor ?? Colors.yellow;
    final entries = subset.where((e) => e.moodIndex == moodIndex).toList();
    entries.sort((a,b) => b.dateTime.compareTo(a.dateTime));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: moodColor)),
                  const SizedBox(width: 8),
                  Text('${config.label} (${entries.length}篇)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
                ]
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(DateFormat('MM月dd日 HH:mm').format(e.dateTime), style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black45)),
                           const SizedBox(height: 8),
                           Text(e.content, style: TextStyle(fontSize: 14, color: isNight ? Colors.white : Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      )
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  Widget _buildGlassCard({required bool isNight, required Widget child, EdgeInsetsGeometry? padding}) {
    return GlassBento(
      isNight: isNight,
      padding: padding,
      child: child,
    );
  }

  TextStyle _bentoTitleStyle(bool isNight) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isNight ? Colors.white : const Color(0xFF5A3E28),
      letterSpacing: 0.5,
    );
  }
}
