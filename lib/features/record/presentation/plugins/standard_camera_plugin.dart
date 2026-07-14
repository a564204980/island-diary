import 'package:flutter/material.dart';
import '../../../../../core/plugins/island_plugin.dart';
import '../pages/custom_camera_page.dart';

class StandardCameraPlugin extends CameraPlugin {
  @override
  String get pluginId => 'cam_standard_001';

  @override
  String get name => '经典模式';

  @override
  String get description => '岛屿手账的经典相机拍摄模式，稳妥、快速。';

  @override
  String get version => '1.0.0';

  @override
  String get previewImageUrl => 'https://example.com/assets/standard_cam_preview.png';

  @override
  Widget buildCameraPage(BuildContext context, {
    String? initialImagePath,
    String? initialMattedPath,
  }) {
    // 关闭 dynamic viewfinder 模式
    return CustomCameraPage(
      initialImagePath: initialImagePath,
      initialMattedPath: initialMattedPath,
      enableDynamicViewfinder: false,
    );
  }
}
