# Flutter Forge

`flutter-forge` 是一个面向 Flutter 公司项目开发的单 skill。

它的职责不是只生成页面代码，而是帮助 agent 在真实项目里完成：

- 需求理解
- UI 解析
- 架构与实现设计
- 页面开发
- 老项目规则抽取
- 项目级与个人级记忆沉淀
- 新项目初始规则画像选择

它同时承担两个层次的职责：

- 作为项目内总控 skill，负责需求、UI、结构、命名、复用和项目记忆
- 作为 Flutter skill 编排器，在适当时委托官方 Flutter Agent Skills 处理通用框架子任务

## 何时使用

当任务符合以下任一情况时使用：

- 开发新页面
- 扩展已有页面或模块
- 首次进入老 Flutter 项目，需要先理解规则
- 需要根据 PRD / 设计图拆页面结构
- 需要决定模块归属、文件结构、组件边界、命名方案
- 需要判断先复用旧代码还是新写

## Quick Start

### 老项目首次接入

直接这样开始：

```text
使用 flutter-forge。这是一个老 Flutter 项目，先不要写代码。
先扫描目录结构、模块边界、命名风格、状态管理、组件边界和接口接入方式。
输出：
1. 项目规则理解摘要
2. 项目规则卡
3. 高风险确认项
```

### 新项目页面开发

直接这样开始：

```text
使用 flutter-forge。这是一个新 Flutter 项目。
先按 Flutter 通用最佳实践起步，同时套用我的稳定个人偏好。
先给我：
1. 页面结构树
2. 文件结构和命名方案
3. 关键实现决策
然后再生成代码
```

### 只给 PRD / 只给设计图

如果只给 PRD：

```text
使用 flutter-forge。我先给你 PRD，请先做需求理解。
如果继续推进需要设计图，再明确告诉我缺什么。
如果暂时没有设计图，先给页面结构树草案和待确认 UI 点。
```

如果只给设计图：

```text
使用 flutter-forge。我先给你设计图，请先做 UI 解析。
如果继续推进需要业务规则或 PRD，再明确告诉我缺什么。
如果暂时没有 PRD，先给页面结构树、文件结构和命名草案。
```

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

同时遵循 progressive disclosure：

- 默认只加载 `SKILL.md`
- 按需再读取 `references/` 中的细节文件
- 小任务不应一次性加载全部 references 和 memory

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

## 官方 Flutter skills

Flutter 官方文档明确建议在 Flutter / Dart 任务中使用官方 Agent Skills，并强调 progressive disclosure。参考：

- [Flutter Agent skills 文档](https://docs.flutter.dev/ai/agent-skills)
- [flutter/skills 仓库](https://github.com/flutter/skills)

Flutter Forge 不应替代这些通用技能，而应在以下场景优先委托它们：

- 分层架构：`flutter-apply-architecture-best-practices`
- 响应式布局：`flutter-build-responsive-layout`
- 布局错误修复：`flutter-fix-layout-issues`
- JSON 序列化：`flutter-implement-json-serialization`
- 路由：`flutter-setup-declarative-routing`
- 本地化：`flutter-setup-localization`
- HTTP：`flutter-use-http-package`
- Widget 测试 / 预览 / 集成测试

具体映射见：

- `references/official_flutter_skills.md`
- `references/delegation_map.yaml`

## 测试与质量

Flutter Forge 的完整交付链路默认包含测试与质量判断：

- Widget 测试什么时候加
- 集成测试什么时候加
- 测试文件放在哪
- 命名怎么定
- 是否需要 `flutter analyze`
- 是否需要 `dart format`

参考：

- `references/testing_strategy.md`
- `references/build_and_quality.md`
- `references/quality_gates.md`

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

- `memory/profiles/*.yaml`
  - 新项目可选的规则画像 / 初始模板

- `memory/runtime/current_task.template.yaml`
  - 短期任务记忆模板

具体的读取时机、写入时机、提升条件和项目隔离规则见：

- `references/memory_protocol.md`

新项目的规则选择流程见：

- `references/new_project_profile_selection.md`

## 工程规则补充

Flutter Forge 还补充了这些工程参考：

- `references/engineering_heuristics.md`
  - 可执行判断标准和 Flutter 专项规则

- `references/anti_patterns.md`
  - 常见 Flutter 反模式

- `references/templates_catalog.md`
  - 高频页面模板目录

- `references/debugging_playbook.md`
  - 调试排查手册

- `references/release_and_versioning.md`
  - 版本化、更新与冲突检测约定

- `references/case_studies.md`
  - 推荐维护的真实案例类型

- `references/case_study_member_center.md`
  - 真实任务示例

- `references/validation_log.md`
  - 真实试跑记录模板

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
- `references/official_flutter_skills.md`
- `references/memory_protocol.md`
- `references/engineering_heuristics.md`
- `references/testing_strategy.md`
- `references/build_and_quality.md`
- `references/quality_gates.md`
- `references/anti_patterns.md`
- `references/templates_catalog.md`
- `references/debugging_playbook.md`
- `references/release_and_versioning.md`
- `references/delegation_map.yaml`
- `references/case_studies.md`
- `references/case_study_member_center.md`
- `references/new_project_profile_selection.md`
- `references/validation_log.md`

## 红线

1. 不在未确认的情况下重构现有公共模块
2. 不把低置信度推断当成团队规则强行执行
3. 不为了追求 UI 还原破坏项目架构和可维护性
