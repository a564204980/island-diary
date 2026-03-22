import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/diary_utils.dart';
import '../components/diary_date_picker_sheet.dart';
import '../components/diary_time_picker_sheet.dart';
import '../components/diary_weather_picker_sheet.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import './diary_editor_core_mixin.dart';

mixin DiaryEditorInsertMixin<T extends DiaryEditorPage> on State<T>, DiaryEditorCoreMixin<T> {
  void insertTopic() {
    final activeBlock = activeTextBlock;
    if (activeBlock == null) return;
    final controller = activeBlock.controller;
    final text = controller.text;
    final selection = controller.selection;
    final insertion = "# ";
    final newText = text.replaceRange(
      selection.start.clamp(0, text.length),
      selection.end.clamp(0, text.length),
      insertion,
    );
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
    addFocusListener(activeBlock);
    activeBlock.focusNode.requestFocus();
    onBlocksChanged();
  }

  void onLocationClick() async {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在获取位置...'), 
          duration: Duration(seconds: 15), 
        ),
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3), 
        onTimeout: () => true, // 如果检测超时，假设开着继续往下走
      );
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请开启系统定位服务')));
        }
        return;
      }
    } catch (_) { }

    try {
      LocationPermission permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
        onTimeout: () => LocationPermission.always,
      );
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
      // 3. 优先尝试获取缓存位置（最快）
      position = await Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      
      // 4. 如果没有缓存或已过期，则申请当前位置（增加 10s 超时）
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      }
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
      // 5. 逆地理编码解析地址
      final placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // 拼接更友好的地址格式
        final rawAddress = "${p.locality ?? ''}${p.subLocality ?? ''}${p.street ?? ''}";
        address = rawAddress.trim();
      }
    } catch (e) {
      debugPrint("逆地理编码失败: $e");
      // 静默处理，后面会降级显示经纬度
    }

    // 6. 如果地址解析失败，降级为显示经纬度
    if (address.isEmpty) {
      address = "东经${position.longitude.toStringAsFixed(2)}°, 北纬${position.latitude.toStringAsFixed(2)}°";
    }

    setState(() {
      location = address;
    });
    onBlocksChanged();
  }

  void onDateClick() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaryDatePickerSheet(
        initialDate: DateTime.now(),
        onConfirm: (date) {
          final activeBlock = activeTextBlock;
          if (activeBlock != null) {
            final controller = activeBlock.controller;
            final text = controller.text;
            final selection = controller.selection;
            final insertion = DiaryUtils.getFormattedDateWithWeekday(date);

            final newText = (selection.isValid)
                ? text.replaceRange(
                    selection.start.clamp(0, text.length),
                    selection.end.clamp(0, text.length),
                    insertion,
                  )
                : text + insertion;

            setState(() {
              controller.value = controller.value.copyWith(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: (selection.isValid ? selection.start : text.length) + insertion.length,
                ),
              );
            });
            activeBlock.focusNode.requestFocus();
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => isColorPickerOpen = false);
    });
  }

  void onTimeClick() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaryTimePickerSheet(
        initialTime: TimeOfDay.now(),
        onConfirm: (time) {
          final activeBlock = activeTextBlock;
          if (activeBlock != null) {
            final controller = activeBlock.controller;
            final text = controller.text;
            final selection = controller.selection;
            final insertion = DiaryUtils.getFormattedFullTime(time);

            final newText = (selection.isValid)
                ? text.replaceRange(
                    selection.start.clamp(0, text.length),
                    selection.end.clamp(0, text.length),
                    insertion,
                  )
                : text + insertion;

            setState(() {
              controller.value = controller.value.copyWith(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: (selection.isValid ? selection.start : text.length) + insertion.length,
                ),
              );
            });
            activeBlock.focusNode.requestFocus();
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => isColorPickerOpen = false);
    });
  }

  void onTagClick() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签功能开发中...')));
  }

  void onWeatherClick() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaryWeatherPickerSheet(
        onConfirm: (w, t) {
          setState(() {
            weather = w;
            temp = "$t°C";
          });
          onBlocksChanged();
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => isColorPickerOpen = false);
    });
  }

  void onMoreClick() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更多功能开发中...')));
  }
}
