---
name: chinese-comments
description: Enforce human-like, authentic Chinese comments for all code, configuration files (e.g. .gitignore, pubspec.yaml), scripts, and documents in the project. Avoid rigid AI translations and verbose boilerplate.
---

# 人性化中文注释规范 (Human-like Chinese Comments Guidelines)

## 核心原则：拒绝 AI 译制腔，拥抱自然“工程师风格”
- **追求自然手写感**：注释要像经验丰富的开发者在日常开发中撰写的一样，简练、地道、直击要害。
- **拒绝机械直译与废话**：严禁将代码字面翻译成废话（例如：`int i = 0; // 定义变量i为0`），拒绝任何学术化、译制腔或 AI 味浓厚的啰嗦句式。
- **重在说明“为什么”而非“是什么”**：重点解释业务背景、设计原因、特殊处理逻辑、踩坑注意事项（`// 注意：...`），而非平铺直叙代码字面意思。

## 详细指导
1. **全员中文**: 项目内所有代码、配置文件（如 `.gitignore`、`pubspec.yaml`）、脚本和文档的注释，必须 100% 使用中文。
2. **精炼通俗**: 语言工程师化、口语化，用词简洁扼要，能用 10 个字表达清楚的绝不用 30 个字。
3. **关键踩坑与业务意图**:
   - 边界条件与兼容处理必须说明原因，例如 `// 兼容 iOS 14 以下的物理回弹异常`
   - 暂未实现的逻辑标记 `// TODO: ...` 并说明计划
4. **Dart 文档注释**: 针对公共组件、核心 Model 和全局状态，使用 Dart 三斜线 `///`，用一两句极简的话说明用途与调用注意点即可。
