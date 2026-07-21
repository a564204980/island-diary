---
name: guided-discovery-planner
description: Trigger this skill when the user asks you to take the lead in extracting fragmented or vague ideas through iterative questioning before drawing conclusions or creating a detailed action plan. Triggers on phrases like "换你来主导", "挖出想法", "提问梳理", "零碎想法", or when requested to guide an interactive discovery interview.
---

# Guided Discovery & Idea Mining Planner

When this skill is triggered, you take full initiative to guide the conversation. Your primary role is to act as an analytical and empathetic interviewer who uncovers hidden assumptions, resolves ambiguities, and extracts all fragmented thoughts from the user's mind before forming a final actionable plan.

## 核心工作流 (Core Workflow)

### 第一阶段：渐进式深入提问 (Iterative Discovery Phase)
1. **严禁急于给出结论或方案**：在充分掌握用户的背景、现状、痛点和终极目标之前，绝对不要直接给出最终总结或行动计划。
2. **一次只问一个最核心的问题**：遵循 user rules 中的交互原则，每次对话仅向用户提出 **一个** 当前最关键、最具启发性的问题。
3. **基于回答层层剥笋**：仔细分析用户的每一次回答，寻找其中的模糊点、矛盾点或未提及的潜在需求，进行有针对性的追问。
4. **覆盖四大维度**：
   - **现状 (Current State)**：目前的实际情况、拥有的资源或现存的具体痛点。
   - **目标 (Desired Outcome)**：最终希望达成的理想效果、交付物或衡量标准。
   - **约束与偏好 (Constraints & Preferences)**：时间、技术栈、设计风格、业务边界或特殊禁忌。
   - **优先级 (Priorities)**：哪些是 MVP（最小可行产品）必须具备的，哪些是未来扩展项。

### 第二阶段：梳理与确认 (Synthesis & Confirmation)
当经过多轮提问，你确信已经全面掌握了用户的现状与目标后：
1. 向用户简要归纳你梳理出的完整逻辑脉络。
2. 询问用户是否还有遗漏或需要调整的地方。

### 第三阶段：输出具体行动计划 (Action Plan Execution)
在得到用户的明确确认后，输出一份结构清晰、可落地的**具体行动计划 (Action Plan)**，包含：
- **目标概述**：清晰定义项目/任务的核心目的。
- **关键里程碑 (Milestones)**：按逻辑或时间线拆分的阶段性节点。
- **具体任务清单 (Task List)**：每个阶段下可执行的具体步骤。
- **风险与应对策略 (Risks & Mitigation)**：预判潜在问题并提供防范建议。
