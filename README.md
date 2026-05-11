# Flutter Forge

`flutter-forge` 是一个面向 Flutter 公司项目开发的本地前端开发 skill，用来让 agent 在真实项目里完成需求理解、UI 解析、实现设计、页面开发，以及老项目规则抽取与复用决策。

它不是单纯代码生成器，也不是只会搭页面骨架的 UI 助手。它更像一个偏工程交付的 Flutter 前端副手：先理解项目，再决定怎么拆页面、怎么命名、怎么复用、怎么落代码。

## 适用场景

- 新页面开发，需要先把 PRD、UI 和旧代码一起翻成页面结构。
- 老页面扩展，需要判断沿用现有模式还是局部重写。
- 首次进入老 Flutter 项目，需要先抽取目录规则、命名规则、状态管理模式和组件边界。
- 需求复杂，页面大、交互多、模块边界不清，需要先出结构方案再写代码。
- 需要在团队规则优先的前提下，保留个人页面拆分习惯和私有组件命名偏好。

## 仓库结构

```text
SKILL.md
.skillhub.json
references/
  system_prompt.md
  legacy_project_scan.md
  example_rule_card.yaml
  task_runtime_prompt.md
  rule_card_template.yaml
memory/
  global_preferences.yaml
  projects/
    *.rule_card.yaml
  runtime/
    current_task.template.yaml
CHANGELOG.md
VERSION
README.md
```

仓库根目录本身就是 `cc-switch` 可识别的 skill 目录。`references/` 里放配套提示词和规则卡模板，`memory/` 里放长期和短期记忆文件。

## 核心能力

- 需求理解
- UI 解析
- 实现设计
  - 架构接入
  - 模块划分
  - 文件结构
  - 组件边界
  - 命名方案
- 页面开发
  - 页面骨架
  - 状态接入位
  - 接口占位
  - 交互占位
  - 上下文足够时生成接近可运行代码
- 老项目规则抽取
- 复用路径判断
- 规则卡沉淀
- 文件化记忆分层

## 工作方式

Flutter Forge 默认是统一人格助手，但内部保留多阶段工作流。

### 小任务

- 直接执行
- 少解释
- 优先复用现有模式

### 中等任务

- 先判断项目规则是否足够
- 必要时补扫描上下文
- 只在高风险点打断用户

### 大任务

以下情况直接视为大任务：

1. 需要新建整个业务模块，不只是新页面
2. 页面很大，包含多个功能区和复杂交互
3. 需要复用很多旧页面逻辑，但现有实现分散
4. 用户明确说明这是大任务

大任务按固定顺序推进：

1. 需求理解
2. UI 解析
3. 实现设计
4. 页面开发

最终由实现设计阶段收口，再进入代码生成。

## 老项目接入

首次进入老 Flutter 项目时，优先目标不是立刻写页面，而是先建立项目规则理解。

至少要理解这些内容后，才适合高置信度开发：

- 目录结构
- 模块边界
- 命名风格
- 状态管理主模式
- 组件库用法
- 接口接入方式
- 公共组件边界

首次接入时，推荐先让 skill 输出：

1. 项目规则理解摘要
2. 规则卡
3. 高风险确认项

## 规则优先级

决策顺序固定：

1. 用户最终拍板
2. 业务目标优先
3. 架构一致性与可维护性
4. UI 还原与实现细节接受建议

规则来源分层：

- 团队规则：目录结构、模块边界、统一命名规则
- 个人偏好：页面拆分细度、私有组件命名局部偏好

冲突时：

- 团队规则优先

当团队规则不明确时：

- 优先从最近、最主流的现有代码模式归纳临时规则
- 临时规则默认低置信度
- 不能把低置信度推断强行当成团队规则执行

## 记忆存储

Flutter Forge 采用纯文件记忆，不依赖 Python、数据库或额外服务。

长期记忆和短期记忆的落点如下：

- `memory/global_preferences.yaml`
  - 存跨项目长期偏好
  - 例如页面拆分习惯、私有组件命名偏好、复用倾向

- `memory/projects/*.rule_card.yaml`
  - 存每个项目的项目级长期记忆
  - 例如目录结构、模块边界、命名规则、状态管理模式、组件边界

- `memory/runtime/current_task.template.yaml`
  - 作为短期任务记忆模板
  - 用于当前任务的临时业务规则、字段特例、接口兼容说明
  - 默认不应跨任务长期保留

## 文件说明

- `SKILL.md`
  - 主 skill 入口
  - 定义触发场景、工作模式、默认输出和红线

- `.skillhub.json`
  - skill 元信息
  - 提供名称、描述和版本

- `references/system_prompt.md`
  - 主提示词参考
  - 保留完整规则定义，便于后续继续收敛或改写

- `references/legacy_project_scan.md`
  - 老项目首次接入时使用
  - 先抽规则，再开发

- `references/task_runtime_prompt.md`
  - 每次具体任务执行前附加
  - 用于判断任务大小、规则是否足够、是否要先复用、是否需要用户确认

- `references/rule_card_template.yaml`
  - 项目规则卡模板
  - 用于沉淀团队规则、个人偏好、临时推断和复用知识

- `references/example_rule_card.yaml`
  - 规则卡示例
  - 展示一次老项目扫描后的期望输出形态

- `memory/global_preferences.yaml`
  - 跨项目长期偏好记忆

- `memory/projects/`
  - 项目级长期记忆目录

- `memory/runtime/current_task.template.yaml`
  - 短期任务记忆模板

- `VERSION`
  - 当前 skill 版本号

- `CHANGELOG.md`
  - 版本变更记录

## 推荐使用方式

老项目首次接入：

1. 触发 `flutter-forge`
2. 先按 `references/legacy_project_scan.md` 扫描项目
3. 生成规则摘要和规则卡
4. 再开始具体开发任务

老项目日常开发：

1. 触发 `flutter-forge`
2. 按 `references/task_runtime_prompt.md` 判断任务大小
3. 小任务直接做
4. 大任务先给结构树、文件结构、命名方案和关键实现决策，再写代码

新项目启动：

1. 触发 `flutter-forge`
2. 先按 Flutter 通用最佳实践起步
3. 再逐步吸收个人偏好
4. 不直接继承旧项目局部规则

## 红线

1. 不在未确认的情况下重构现有公共模块
2. 不把低置信度推断当成团队规则强行执行
3. 不为了追求 UI 还原破坏项目架构和可维护性
