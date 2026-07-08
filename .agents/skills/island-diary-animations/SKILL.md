---
name: island-diary-animations
description: Core animation and interaction guidelines for the Island Diary Flutter app. Trigger this skill whenever building new UI components, pages, or animations to ensure consistent motion design and interactions.
---

# Island Diary Animation & Interaction Guidelines

When developing new pages, components, or features for the Island Diary project, you **MUST** follow these animation and interaction rules to maintain the app's signature healing, immersive, and premium feel.

## 1. 页面转场 (Page Transitions)
- **杜绝原生生硬切换**：尽量避免使用 Flutter 默认的 Material 左右推屏动画。
- **推荐转场**：优先使用**淡入淡出 + 轻微缩放 (Fade + Scale)** 或者平滑的自下而上滑入。
- **Tab 切换避坑**：在底部导航栏切换时，严禁使用 `AnimatedOpacity` 直接包裹带有 `BackdropFilter`（毛玻璃）的复杂组件，因为这会导致 Impeller 渲染引擎在底层疯狂报错（Validation Break）。优先使用 `Offstage` 进行硬切换，或确保透明度动画与毛玻璃层分离。

## 2. 微交互与反馈 (Micro-interactions)
- **按钮点击反馈**：弱化原生的水波纹（Ripple）效果。对于自定义的精致按钮，统一采用**按下时轻微缩放回弹 (Scale down)** 的动效。
- **拥抱 flutter_animate**：无状态的轻量级入场/状态切换动效，强制优先使用 `flutter_animate` 库的链式调用（如 `.animate().fade().slideY()`），避免手动编写冗长的 `AnimationController` 模板代码。
- **列表加载**：列表卡片（如日记流、岁月成书）首次渲染时，应采用**阶梯式上浮显现 (Staggered Slide & Fade)**，使得卡片依次优雅地进入视野。

## 3. 弹窗与浮层 (Dialogs & Overlays)
- **呼出动画**：无论是全局 Dialog 还是 BottomSheet，统一采用**平滑升起 (Slide up) + 伴随背景高斯模糊渐隐入**。
- **退出动画**：平滑下落 + 模糊自然消散。

## 4. 氛围与持续动效 (Ambient Animations)
- **悬浮与呼吸感**：对于场景装饰物（如首页云朵、小岛、星星等），必须添加基于 `SineCurve`（正弦曲线）的往复上下浮动动画，营造呼吸感与失重感。
- **复杂动画选型**：如果是复杂的天气、情绪、宠物等动画，优先采用 **Lottie** 或 **Rive**；对于极简的路径动画或粒子，再考虑自绘 (CustomPaint)。

## 5. 组件化与复用
- 尽可能将通用的动画逻辑（如悬浮动画包裹器、标准按钮点击包裹器）抽离到专门的共享组件目录（如 `lib/shared/animations/`）中，确保整个 App 的物理规律和阻尼感高度一致。
