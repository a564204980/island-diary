import { FlutterPage } from '@ohos/flutter_ohos';

/**
 * 岛屿日记 Flutter 页面宿主容器 Page
 */
@Entry
@Component
struct Index {
  build() {
    Column() {
      FlutterPage()
    }
    .width('100%')
    .height('100%')
  }
}
