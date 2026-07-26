import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { Want, AbilityConstant } from '@kit.AbilityKit';

/**
 * 岛屿日记 (Island Diary) 纯血鸿蒙 NEXT Flutter 启动入口
 */
export default class EntryAbility extends FlutterAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    await super.onCreate(want, launchParam);
  }

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    // 可在此处初始化鸿蒙原生 PlatformChannel 插件
  }
}
