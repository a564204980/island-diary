# 🏝️ 岛屿日记 (Island Diary) 纯血鸿蒙 Next (Flutter-OHOS) 实战编译指南

本文档为《岛屿日记》打包编译为 **HarmonyOS NEXT (纯血鸿蒙)** 原生 `.hap` 应用提供完整的步骤指引。

---

## 📋 一、环境搭建准备

### 1. 安装 DevEco Studio
- 下载并安装 **DevEco Studio NEXT Release** (建议 5.0.3+ 以上版本)。
- 打开 DevEco Studio，在 SDK Manager 中安装 `HarmonyOS NEXT SDK` (API Version 12+)。

### 2. 配置 Flutter-OHOS SDK
- 克隆或下载开源社区与华为官方支持的 `flutter_flutter` OHOS 分支：
  ```bash
  git clone -b dev https://gitee.com/openharmony-sig/flutter_flutter.git
  ```
- 配置环境变量：
  - `FLUTTER_STORAGE_BASE_URL`: `https://gitee.com/openharmony-sig/flutter_infrastructure`
  - `PUB_HOSTED_URL`: `https://pub.flutter-io.cn`
  - 将 `flutter_flutter/bin` 添加至系统 `PATH` 中。

---

## 🛠️ 二、工程构建与打包命令

### 1. 检查鸿蒙开发环境
在项目根目录运行环境诊断命令：
```bash
flutter doctor -v
```
确认输出中 `[√] OpenHarmony toolchain - develop for OpenHarmony devices` 为正常通过状态。

### 2. 获取依赖包
```bash
flutter pub get
```

### 3. 编译生成鸿蒙 HAP 安装包
- **调试包 (Debug HAP)**:
  ```bash
  flutter build hap --debug
  ```
- **正式发布包 (Release HAP)**:
  ```bash
  flutter build hap --release
  ```
生成成功后，产物位于 `ohos/entry/build/default/outputs/default/entry-default-signed.hap`。

---

## 📱 三、真机安装与调试

1. 开启鸿蒙手机的 **开发者模式** (设置 -> 关于手机 -> 连续点击版本号 -> 开发者选项)。
2. 通过 USB 连接电脑，并在 DevEco Studio 中完成 **自动签名 (Auto Signing)**。
3. 使用 `hdc` 命令行工具将安装包推送到手机：
   ```bash
   hdc app install ohos/entry/build/default/outputs/default/entry-default-signed.hap
   ```
4. 或直接在 DevEco Studio 中打开 `ohos` 目录，点击 `Run 'entry'` 按钮一键部署调试！

---

## 🌟 四、常见三方库鸿蒙适配清单

| 插件名称 | 纯血鸿蒙适配状态 | 说明 |
| :--- | :--- | :--- |
| `shared_preferences` | ✅ 已完美支持 | 自动映射鸿蒙 Preferences 存储 |
| `path_provider` | ✅ 已完美支持 | 自动映射鸿蒙应用沙盒目录 |
| `sensors_plus` | ✅ 已完美支持 | 支持陀螺仪与重力感应器 |
| `flutter_animate` | ✅ 100% 纯 Dart 支持 | 阻尼动画与微交互完全保持一致 |
| `audioplayers` | ✅ 已支持 | 播放海岛自然声效 |
