import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/diary_utils.dart';
import '../components/diary_date_picker_sheet.dart';
import '../components/diary_time_picker_sheet.dart';
import '../components/diary_weather_picker_sheet.dart';
import '../components/paper_picker_sheet.dart';
import '../components/diary_bottom_sheet.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../components/diary_tag_picker_sheet.dart';
import './diary_editor_core_mixin.dart';

mixin DiaryEditorInsertMixin<T extends DiaryEditorPage> on State<T>, DiaryEditorCoreMixin<T> {

  void onLocationClick() {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';
    final themeId = UserState().selectedIslandThemeId.value;
    final Color inkColor;
    final Color themeAccentColor;
    if (isNight) {
      inkColor = Colors.white;
      themeAccentColor = themeId == 'cotton_candy' ? const Color(0xFFC0A6FF) : const Color(0xFFE0C097);
    } else {
      inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
      themeAccentColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFFA68565);
    }

    final controller = TextEditingController(text: location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryBottomSheet(
        paperStyle: currentPaperStyle,
        showDragHandle: true,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 24 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '记录你的足迹',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: inkColor,
                fontFamily: fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: inkColor.withValues(alpha: 0.15),
                ),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: inkColor, fontFamily: fontFamily),
                decoration: InputDecoration(
                  hintText: '输入地点名称 (如: 杭州·西湖)',
                  hintStyle: TextStyle(
                    color: inkColor.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _autoGetLocation();
                    },
                    icon: Icon(Icons.my_location_rounded, size: 16, color: themeAccentColor),
                    label: Text(
                      '自动定位',
                      style: TextStyle(
                        color: themeAccentColor,
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: themeAccentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        location = controller.text.trim().isEmpty ? null : controller.text.trim();
                      });
                      onBlocksChanged();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeAccentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      '确定',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _autoGetLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3), 
        onTimeout: () => true,
      );
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请开启系统定位服务')));
        }
        return;
      }
    } catch (_) { }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      permission = LocationPermission.denied;
    }
    try {
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('定位权限被拒绝，无法获取位置')));
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('权限被禁用，请在系统设置中开启定位权限')));
        }
        return;
      }
    } catch (_) { }

    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      String msg = "获取位置失败";
      if (e.toString().contains("timeout")) {
        msg = "定位超时，请移至开阔地带重试";
      } else {
        msg = "无法获取当前坐标 ($e)";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

    String address = "";
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final locality = p.locality ?? '';
        final subLocality = p.subLocality ?? '';
        final street = p.street ?? '';
        
        String rawAddress = '';
        if (street.contains(locality) || street.contains(subLocality)) {
          rawAddress = street;
        } else {
          rawAddress = "$locality$subLocality$street";
        }
        address = rawAddress.trim();
      }
    } catch (e) {
      debugPrint("逆地理编码失败: $e");
    }

    if (address.isEmpty) {
      address = "东经${position.longitude.toStringAsFixed(2)}°, 北纬${position.latitude.toStringAsFixed(2)}°";
    }

    setState(() {
      location = address;
    });
    onBlocksChanged();
  }

  void onDateClick() {
    final activeBlock = activeTextBlock;
    final bool hadFocus = activeBlock?.focusNode.hasFocus ?? false;

    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryDatePickerSheet(
        initialDate: entryDateTime ?? DateTime.now(),
        paperStyle: currentPaperStyle,
        onConfirm: (date) {
          final String insertion = DiaryUtils.getFormattedDateWithWeekday(date);
          
          if (hadFocus && activeBlock != null) {
            final controller = activeBlock.controller;
            final text = controller.text;
            final selection = controller.selection;
            
            // 需求：内容插入时前后加个空格
            final String spacedInsertion = " $insertion ";

            final newText = (selection.isValid)
                ? text.replaceRange(
                    selection.start.clamp(0, text.length),
                    selection.end.clamp(0, text.length),
                    spacedInsertion,
                  )
                : text + spacedInsertion;

            setState(() {
              controller.value = controller.value.copyWith(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: (selection.isValid ? selection.start : text.length) + spacedInsertion.length,
                ),
              );
            });
            activeBlock.focusNode.requestFocus();
            onBlocksChanged();
          } else {
            // 无焦点模式：作为标签
            setState(() {
              final current = entryDateTime ?? DateTime.now();
              entryDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                current.hour,
                current.minute,
                current.second,
              );
              customDate = insertion;
            });
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => isColorPickerOpen = false);
      }
    });
  }

  void onTimeClick() {
    final activeBlock = activeTextBlock;
    final bool hadFocus = activeBlock?.focusNode.hasFocus ?? false;

    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryTimePickerSheet(
        initialTime: TimeOfDay.fromDateTime(entryDateTime ?? DateTime.now()),
        paperStyle: currentPaperStyle,
        onConfirm: (time) {
          final String insertion = DiaryUtils.getFormattedFullTime(time);
          
          if (hadFocus && activeBlock != null) {
            final controller = activeBlock.controller;
            final text = controller.text;
            final selection = controller.selection;
            
            // 需求：内容插入时前后加个空格
            final String spacedInsertion = " $insertion ";

            final newText = (selection.isValid)
                ? text.replaceRange(
                    selection.start.clamp(0, text.length),
                    selection.end.clamp(0, text.length),
                    spacedInsertion,
                  )
                : text + spacedInsertion;

            setState(() {
              controller.value = controller.value.copyWith(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: (selection.isValid ? selection.start : text.length) + spacedInsertion.length,
                ),
              );
            });
            activeBlock.focusNode.requestFocus();
            onBlocksChanged();
          } else {
            // 无焦点模式：作为标签
            setState(() {
              final current = entryDateTime ?? DateTime.now();
              entryDateTime = DateTime(
                current.year,
                current.month,
                current.day,
                time.hour,
                time.minute,
              );
              customTime = insertion;
            });
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => isColorPickerOpen = false);
      }
    });
  }

  void onTagClick() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false, // 禁用系统默认的外部悬浮拖拽条，确保仅显示自定义组件内高保真把手
      builder: (context) => DiaryTagPickerSheet(
        paperStyle: currentPaperStyle,
        initialTags: currentTags,
        onConfirm: (tags) {
          setState(() {
            currentTags = tags;
          });
          onBlocksChanged();
        },
      ),
    ).then((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => isColorPickerOpen = false);
      }
    });
  }

  void onWeatherClick() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false, // 禁用系统默认的外部悬浮拖拽条，确保仅显示自定义组件内高保真把手
      builder: (context) => DiaryWeatherPickerSheet(
        paperStyle: currentPaperStyle,
        initialWeather: weather,
        initialTemp: temp,
        onConfirm: (w, t) {
          setState(() {
            if (w.isEmpty) {
              weather = null;
              temp = null;
            } else {
              weather = w;
              temp = "$t°C";
            }
          });
          onBlocksChanged();
        },
      ),
    ).then((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => isColorPickerOpen = false);
      }
    });
  }

  void showPaperPicker() {
    final bool isNight = UserState().isNight;
    final mood = (currentMoodIndex != null && currentMoodIndex! >= 0) ? kMoods[currentMoodIndex!] : null;
    final defaultAccentColor = isNight ? const Color(0xFFE0C097) : const Color(0xFF8B5E3C);
    final moodGlowColor = mood?.glowColor;
    final accentColor = mood == null 
        ? defaultAccentColor 
        : isNight 
          ? (moodGlowColor ?? defaultAccentColor) 
          : Color.lerp(moodGlowColor ?? defaultAccentColor, Colors.black, 0.45)!;

    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false, // 禁用系统默认的外部悬浮拖拽条，确保仅显示自定义组件内高保真把手
      builder: (context) => PaperPickerSheet(
        currentStyle: currentPaperStyle,
        accentColor: accentColor,
        onStyleSelected: (style) {
          setState(() {
            currentPaperStyle = style;
            syncBlockColors();
          });
          UserState().setPreferredPaperStyle(style);
          onBlocksChanged();
        },
      ),
    ).then((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => isColorPickerOpen = false);
      }
    });
  }
}
