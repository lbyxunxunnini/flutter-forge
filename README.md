# Flutter Forge

`flutter-forge` 是一个面向 Flutter 公司项目开发的单 skill。

它的职责不是只生成页面代码，而是帮助 agent 在真实项目里完成：

- 需求理解
- UI 解析
- 架构与实现设计
- 页面开发
- 老项目规则抽取
- 项目级与个人级记忆沉淀

## 何时使用

当任务符合以下任一情况时使用：

- 开发新页面
- 扩展已有页面或模块
- 首次进入老 Flutter 项目，需要先理解规则
- 需要根据 PRD / 设计图拆页面结构
- 需要决定模块归属、文件结构、组件边界、命名方案
- 需要判断先复用旧代码还是新写

## 工作方式

默认是统一人格助手；复杂任务时内部切换为四个角色协作：

1. 资深产品需求分析师
2. 资深 Flutter UI 体验设计师
3. 10 年经验的前端架构与实现设计师
4. 资深 Flutter 页面开发工程师

大任务按固定顺序推进：

1. 需求理解
2. UI 解析
3. 实现设计
4. 页面开发

## 老项目怎么用

首次进入老项目时，不要直接写代码。先让 skill：

1. 扫描目录结构
2. 理解模块边界
3. 识别命名风格
4. 识别状态管理主模式
5. 识别组件边界和接口接入方式
6. 输出项目规则摘要、规则卡和高风险确认项

参考文件：

- `references/legacy_project_scan.md`
- `references/rule_card_template.yaml`
- `references/example_rule_card.yaml`

## 新项目怎么用

新项目没有历史代码时：

1. 先按 Flutter 通用最佳实践起步
2. 再逐步套用个人偏好
3. 先给页面结构树、文件结构、命名方案和关键实现决策
4. 再生成代码

## 输入不完整时

- 只给 PRD / 需求文档：先做需求理解，再判断是否必须补设计图
- 只给设计图 / Figma：先做 UI 解析，再判断是否必须补业务说明
- 两者都不完整：先明确当前能确认什么，再请求最少必要输入

## 记忆存储

Flutter Forge 使用纯文件记忆：

- `memory/global_preferences.yaml`
  - 跨项目长期偏好

- `memory/projects/*.rule_card.yaml`
  - 项目级长期记忆

- `memory/runtime/current_task.template.yaml`
  - 短期任务记忆模板

## 目录

```text
SKILL.md
.skillhub.json
references/
memory/
README.md
VERSION
CHANGELOG.md
```

## 关键参考文件

- `references/system_prompt.md`
- `references/legacy_project_scan.md`
- `references/task_runtime_prompt.md`
- `references/rule_card_template.yaml`
- `references/example_rule_card.yaml`
- `references/example_workflow.md`

## 红线

1. 不在未确认的情况下重构现有公共模块
2. 不把低置信度推断当成团队规则强行执行
3. 不为了追求 UI 还原破坏项目架构和可维护性
