---
name: slim-code-structure
description: Enforce slim, modular code structure. Avoid overly bloated files, split complex pages and widgets into reusable sub-components and domain modules. Use whenever creating or refactoring code.
---

# 精简代码与模块化规范 (Slim Code Structure Guidelines)

## 核心原则
1. **控制文件体积，拒绝文件臃肿**：
   - 单个文件应保持精简明了，避免出现上千行的巨型代码文件。
   - 当一个文件功能过于复杂或膨胀时，必须主动进行模块与组件拆分。

2. **合理的组件化拆分 (UI Componentization)**：
   - 将大型页面（Page/View）中的卡片、头部栏、侧滑面板、对话框、小构件等，提炼为独立的可复用组件文件（置于同级或 `widgets/` / `components/` 目录）。
   - 避免在单一 Widget 的 `build` 方法中堆砌过多嵌套子树。

3. **业务逻辑与工具解耦 (Logic Decoupling)**：
   - 将复杂的数据处理、格式化转换、数学计算等独立逻辑抽离至 Service、Provider/Notifier 或 `utils/` 工具文件中。
   - 保持 UI 层只关注渲染与交互，视觉与逻辑分离。

4. **崇尚简洁与可维护性**：
   - 恪守 KISS（Keep It Simple, Stupid）原则，保持代码清晰可读，避免冗余代码与重复嵌套。
