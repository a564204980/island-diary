import 'package:flutter/material.dart';
import '../../../../../core/plugins/island_plugin.dart';
import '../pages/custom_camera/custom_camera_page.dart';

class DynamicIslandCameraPlugin extends CameraPlugin {
  @override
  String get pluginId => 'cam_dynamic_island_001';

  @override
  String get name => '灵动取景相机';

  @override
  String get description => '以“灵动胶囊”为灵感的沉浸式取景器，带来丝滑顺畅的拍摄、裁剪与编辑体验。';

  @override
  String get version => '1.0.0';

  @override
  String get previewImageUrl => 'https://example.com/assets/dynamic_cam_preview.png'; // 模拟云端预览图

  @override
  Widget buildCameraPage(BuildContext context, {
    String? initialImagePath,
    String? initialMattedPath,
  }) {
    // 启用 dynamic viewfinder 模式
    return CustomCameraPage(
      initialImagePath: initialImagePath,
      initialMattedPath: initialMattedPath,
      enableDynamicViewfinder: true,
    );
  }
}
