import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class DiaryUtils {
  /// 预设文本颜色
  static const List<Color> presetTextColors = [
    Color(0xFF5D4037),
    Color(0xFF2C3E50),
    Color(0xFF34495E),
    Color(0xFF27AE60),
    Color(0xFF16A085),
    Color(0xFFC0392B),
    Color(0xFFE74C3C),
    Color(0xFF8E44AD),
    Color(0xFF9B59B6),
    Color(0xFFF39C12),
    Color(0xFFD35400),
    Color(0xFF2980B9),
    Color(0xFF7F8C8D),
    Color(0xFF1ABC9C),
    Color(0xFFD4AC0D),
  ];

  /// 预设背景高亮颜色
  static const List<Color> presetBgColors = [
    Color(0xFFFFF9EE),
    Color(0xFFF9EED8),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFFFEBEE),
    Color(0xFFF3E5F5),
    Color(0xFFE0F2F1),
    Color(0xFFF1F8E9),
    Color(0xFFFFFDE7),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFFFF00FF),
    Color(0xFFC0C0C0),
  ];

  /// 获取格式化的当前日期 (yyyy年MM月dd日)
  static String getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  /// 获取中文星期 (1-7)
  static String getWeekdayChinese(int weekday) {
    const List<String> weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    if (weekday < 1 || weekday > 7) return "";
    return weekdays[weekday - 1];
  }

  /// 获取月份英文缩写 (1-12)
  static String getMonthEnglish(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month < 1 || month > 12) return "";
    return months[month - 1];
  }

  /// 获取增强格式化的日期 (yyyy/MM/dd 星期X)
  static String getFormattedDateWithWeekday(DateTime date) {
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} $weekday';
  }

  /// 获取格式化的当前时间 (HH:mm)
  static String getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 获取完整的格式化时间 (HH:mm:ss)
  static String getFormattedFullTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 根据心情获取治愈系语录
  static String getMoodQuote(String label) {
    const Map<String, List<String>> quotes = {
      '期待': ['愿所有的美好，都如约而至。', '心之所向，便是阳光。', '未来可期，人间值得。'],
      '厌恶': ['在这个喧嚣的世界，守住内心的清凉。', '不必讨好世界，只需取悦自己。', '烦恼随风去，清风自归来。'],
      '恐惧': ['勇敢不是不害怕，而是带着畏惧继续前行。', '黑暗终会过去，黎明就在前方。', '你比想象中更强大。'],
      '惊喜': ['生活总会在不经意间，给你温柔的重击。', '好运不期而遇，惊喜如约而至。', '每一场不期而遇，都是最好的礼物。'],
      '平静': ['世界喧嚣，我自安然。', '心若不动，风又奈何。', '静坐听蝉鸣，淡然看烟云。'],
      '愤怒': ['别让别人的错误，惩罚了自己的心情。', '深呼吸，把不快交给风。', '平和是最高级的优雅。'],
      '悲伤': ['眼泪是灵魂的洗礼。', '万物皆有裂痕，那是光照进来的地方。', '难过的时候，就抱抱那个勇敢的自己。'],
      '开心': ['你笑起来的样子，藏着一整个夏天的风。', '今日心情：明亮且温柔。', '收集世间的每一份好心情。'],
    };

    final List<String> options = quotes[label] ?? ['记录下这一刻的触动。'];
    return options[DateTime.now().second % options.length];
  }

  /// 获取日期对应的星座 (Sync: 2026-04-21)
  static String getZodiacSign(int month, int day) {
    const List<String> signs = [
      '摩羯座', '水瓶座', '双鱼座', '白羊座', '金牛座', '双子座',
      '巨蟹座', '狮子座', '处女座', '天秤座', '天蝎座', '射手座', '摩羯座'
    ];
    // 对应 1-12 月的星座分界点
    const List<int> cutoffs = [20, 19, 21, 20, 21, 22, 23, 23, 23, 24, 23, 22];
    return day < cutoffs[month - 1] ? signs[month - 1] : signs[month];
  }

  /// 获取心情强度描述文字 (如：万分激动)
  static String getMoodIntensityPrefix(String label, double intensity) {
    const Map<String, List<String>> moodPrefixes = {
      '期待': ['略带憧憬', '满心向往', '迫不及待'],
      '厌恶': ['有些反感', '深感蹙眉', '嫌弃至极'],
      '恐惧': ['隐约不安', '忐忑紧锁', '灵魂颤栗'],
      '惊喜': ['意料之外', '万分激动', '喜从天降'],
      '平静': ['凡事从容', '岁月安好', '万籁寂静'],
      '愤怒': ['隐隐不快', '火冒三丈', '怒气冲天'],
      '悲伤': ['隐隐哀愁', '满怀感伤', '痛彻心扉'],
      '开心': ['眉开眼笑', '神采飞扬', '狂喜雀跃'],
    };

    final int level = intensity.toInt();
    final List<String>? options = moodPrefixes[label];
    if (options == null) return "";

    final int index = level <= 3 ? 0 : (level <= 7 ? 1 : 2);
    return options[index];
  }

  /// 拟人化展示文案 (仅形容词+标题，不带强度后缀)
  static String getPureMoodDescription(String label, double intensity) {
    final prefix = getMoodIntensityPrefix(label, intensity);
    if (prefix.isEmpty) return label;
    return "$prefix的$label";
  }

  /// 拟人化强度描述文案映射 (带强度后缀，兼容旧版)
  static String getPersonifiedMoodDescription(
    String label,
    double intensity, {
    String? tag,
  }) {
    // 如果有自定义标签，直接显示标签及其强度，不添加预设形容词
    if (tag != null && tag.trim().isNotEmpty) {
      return "${tag.trim()}/${intensity.toInt()}";
    }
    return "${getPureMoodDescription(label, intensity)}/${intensity.toInt()}";
  }

  /// 奖励配置映射表
  static const Map<String, Map<String, String>> rewardConfigs = {
    'fox': {'name': '灵动小狐狸', 'path': 'assets/images/reward_fox.png'},
    'flower': {'name': '治愈小花朵', 'path': 'assets/images/reward_flower.png'},
    'bird': {'name': '和平小白鸟', 'path': 'assets/images/reward_bird.png'},
  };

  /// 智能图片加载器：自动识别 asset, network 或 file 路径 (适配移动端拍照与相册)
  static Widget buildImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    // 路径规格化处理
    final String normalizedPath = _normalizeImagePath(path);
    
    Widget image;
    // 限制解码分辨率，防止大图瞬间打满内存导致严重卡顿
    final int? cacheW = width != null ? (width * 3).toInt() : 400;

    if (normalizedPath.startsWith('http') || normalizedPath.startsWith('blob:') || normalizedPath.startsWith('data:')) {
      image = Image.network(
        normalizedPath, 
        width: width, 
        height: height, 
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.black.withValues(alpha: 0.05),
            child: const Center(child: CupertinoActivityIndicator(radius: 10)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Image load error ($normalizedPath): $error");
          return _buildErrorPlaceholder(width, height, borderRadius);
        },
      );
    } else if (normalizedPath.startsWith('/') ||
        normalizedPath.contains('cache/') ||
        normalizedPath.contains('files/')) {
      // 移动端文件路径
      if (kIsWeb) {
        // 在 Web 平台上，所有的本地文件路径实际上是由浏览器代理的 blob 或相对路径，必须使用 Image.network
        image = Image.network(
          normalizedPath, 
          width: width, 
          height: height, 
          fit: fit,
        );
      } else {
        // 关键修复：确保文件确实存在，否则返回错误占位符，防止 PathNotFoundException
        final file = io.File(normalizedPath);
        if (!file.existsSync()) {
          debugPrint("Physical file not found ($normalizedPath), skipping...");
          return _buildErrorPlaceholder(width, height, borderRadius);
        }

        image = Image.file(
          file, 
          width: width, 
          height: height, 
          fit: fit,
          cacheWidth: cacheW, // 关键优化：限制本地原图解码尺寸
        );
      }
    } else {
      // 默认作为资产路径
      image = Image.asset(
        normalizedPath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheW,
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Asset load error ($normalizedPath): $error");
          return _buildErrorPlaceholder(width, height, borderRadius);
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: image);
    }
    return image;
  }

  /// 智能路径标准化逻辑：自动识别并补全路径
  static String _normalizeImagePath(String path) {
    if (path.isEmpty) return path;

    // 1. 如果已经是绝对路径、URL、Blob 或 Base64，则保持原样
    if (path.startsWith('http') || 
        path.startsWith('blob:') || 
        path.startsWith('data:') || 
        path.startsWith('/') || 
        path.startsWith('assets/')) {
      return path;
    }

    // 2. 只有文件名的相对路径修复 (多见于 Mock 数据)
    // 根据系统习惯，尝试优先匹配 note 目录，再匹配通用 images 目录
    if (!path.contains('/')) {
      return 'assets/images/note/$path';
    }
    
    // 3. 包含路径但缺少 assets/ 前缀
    if (path.startsWith('images/')) {
      return 'assets/$path';
    }

    return path;
  }

  /// 构建统一的加载失败占位符
  static Widget _buildErrorPlaceholder(double? width, double? height, BorderRadius? borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.photo, size: 24, color: Colors.black.withValues(alpha: 0.2)),
          const SizedBox(height: 4),
          const Text('图片加载失败', style: TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }

  /// 将 RepaintBoundary 截取为图片并返回字节流
  static Future<Uint8List?> captureWidgetToImage(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 增加像素比以获得更高清的分享图片
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture failed: $e");
      return null;
    }
  }

  /// 将图片字节流保存为临时文件供分享/导出
  static Future<String?> saveImageToTempFile(
    Uint8List bytes, {
    String? fileName,
  }) async {
    return saveDataToTempFile(bytes, fileName: fileName);
  }

  /// 将任意二进制数据保存为临时文件供分享/导出
  static Future<String?> saveDataToTempFile(
    Uint8List bytes, {
    String? fileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final name =
          fileName ??
          "diary_data_${DateTime.now().millisecondsSinceEpoch}.bin";
      final file = io.File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint("Save temp data failed: $e");
      return null;
    }
  }

  /// 从内容中提取位置和天气信息
  static Map<String, String> getExtraInfoFromContent(String content) {
    final info = <String, String>{};
    final locationMatch = RegExp(r'#地点:\s*([^\n#]+)').firstMatch(content);
    if (locationMatch != null) {
      info['location'] = locationMatch.group(1)?.trim() ?? "";
    }
    final weatherMatch = RegExp(r'#天气:\s*(.+?)\s*(-?\d+°C)').firstMatch(content);
    if (weatherMatch != null) {
      info['weather'] = weatherMatch.group(1)?.trim() ?? "";
      info['temp'] = weatherMatch.group(2)?.trim() ?? "";
    }
    return info;
  }

  /// 过滤掉正文中的位置和天气标记
  static String getFilteredContent(String content) {
    final info = getExtraInfoFromContent(content);
    String filtered = content;
    if (info.containsKey('location')) {
      filtered = filtered.replaceFirst(RegExp(r'\n?#地点:\s*[^\n#]+\s*'), "");
    }
    if (info.containsKey('weather')) {
      filtered = filtered.replaceFirst(RegExp(r'\n?#天气:\s*(.+?)\s*-?\d+°C\s*'), "");
    }
    return filtered.trim();
  }

  /// 获取信纸对应的墨水颜色 (文字颜色)
  static Color getInkColor(String paperStyle, bool isNight) {
    if (isNight) {
      return const Color(0xFFE5E0D5); 
    }

    // 针对“时光叙事”(note2) 风格使用深咖啡色
    if (paperStyle == 'note2') {
      return const Color(0xFF5A463D);
    }

    // 针对“粉色梦境”(note9) 风格使用深玫瑰木色
    if (paperStyle == 'note9') {
      return const Color(0xFF4E3B3B);
    }

    // 针对“林间听雨”(note7) 风格使用深海石板蓝
    if (paperStyle == 'note7') {
      return const Color(0xFF2F3E46);
    }

    // 针对“云端独白”(note3) 风格使用深碳灰色
    if (paperStyle == 'note3') {
      return const Color(0xFF3A3A3A);
    }

    // 默认白天模式：具有质感的深灰蓝绿色
    return const Color(0xFF3D4E4F);
  }

  /// 获取信纸对应的 UI 控件背景色 (如工具栏底色)
  static Color getPaperBaseColor(String paperStyle, bool isNight) {
    if (isNight && !paperStyle.startsWith('note')) {
      return const Color(0xFF141426);
    }

    if (paperStyle == 'note1') {
      return isNight ? const Color(0xFF1B2E3D) : const Color(0xFFE8EEF2);
    } else if (paperStyle == 'note2') {
      return isNight ? const Color(0xFF2D261F) : const Color(0xFFF1E4CF);
    } else if (paperStyle == 'note3') {
      return isNight ? const Color(0xFF262626) : const Color(0xFFEEEDED);
    } else if (paperStyle == 'note4') {
      return isNight ? const Color(0xFF2D2C28) : const Color(0xFFF2F1E8);
    } else if (paperStyle == 'note5') {
      return isNight ? const Color(0xFF2C2825) : const Color(0xFFF8EFDF);
    } else if (paperStyle == 'note6') {
      return isNight ? const Color(0xFF2C2A28) : const Color(0xFFEBE6DF);
    } else if (paperStyle == 'note7') {
      return isNight ? const Color(0xFF1B262D) : const Color(0xFFEBF5FB);
    } else if (paperStyle == 'note8') {
      return isNight ? const Color(0xFF1B2626) : const Color(0xFFF7FBFB);
    } else if (paperStyle == 'note9') {
      return isNight ? const Color(0xFF28263D) : const Color(0xFFFCEFF9);
    } else if (paperStyle.startsWith('note')) {
      return isNight ? const Color(0xFF2D2A26) : const Color(0xFFF3EBE1);
    }

    return const Color(0xFFF7F2E9);
  }

  /// 获取信纸对应的 UI 强调色 (图标、开关等)
  static Color getAccentColor(String paperStyle, bool isNight) {
    if (isNight) {
      return const Color(0xFFE0C097); 
    }

    // 针对“时光叙事”(note2) 风格使用复古棕褐色
    if (paperStyle == 'note2') {
      return const Color(0xFF8B6B5D);
    }

    // 针对“粉色梦境”(note9) 风格使用灰粉玫瑰色
    if (paperStyle == 'note9') {
      return const Color(0xFF8B6B6B);
    }

    // 针对“林间听雨”(note7) 风格使用雾霾蓝
    if (paperStyle == 'note7') {
      return const Color(0xFF546E7A);
    }

    // 针对“云端独白”(note3) 风格使用冷月灰
    if (paperStyle == 'note3') {
      return const Color(0xFF757575);
    }

    // 白天模式：使用比墨水色略浅的深灰色
    return const Color(0xFF4A5A58);
  }

  /// 获取与信纸风格高度协调的弹窗背景色
  static Color getPopupBackgroundColor(String paperStyle, bool isNight) {
    final Color baseBgColor = getPaperBaseColor(paperStyle, isNight);
    final Color accent = getAccentColor(paperStyle, isNight);

    // 夜间模式下增加透明度，为后续的 BackdropFilter 预留透气感
    final double opacity = isNight ? 0.85 : 0.98;

    // 通过与强调色微弱混合，让背景带上一层温润的色调
    return Color.lerp(baseBgColor, accent, 0.05)!.withValues(alpha: opacity);
  }

  /// 获取信纸背景资产路径
  static String getPaperBackgroundPath(String paperStyle, bool isNight) {
    if (!paperStyle.startsWith('note')) return '';
    
    final String prefix = isNight ? 'note_night_bg' : 'note_bg';
    // 目前 note1-9 都是 png
    return 'assets/images/note/${paperStyle.replaceFirst('note', prefix)}.png';
  }
}
