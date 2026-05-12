# Flutter Forge

`flutter-forge` 是一个给 Flutter 项目使用的开发辅助 skill。

它主要解决这些事：

- 新页面开发
- 老项目首次接入
- 根据 PRD / 设计图拆页面结构
- 收口文件结构、命名、组件边界和复用方案

## 安装

推荐安装到 `cc-switch` 的 skills 目录：

```bash
rm -rf ~/.cc-switch/skills/flutter-forge
git clone https://github.com/lbyxunxunnini/flutter-forge ~/.cc-switch/skills/flutter-forge
```

更新：

```bash
git -C ~/.cc-switch/skills/flutter-forge pull
```

## 怎么用

直接自然描述任务即可，不需要固定调用格式。

例如：

- “帮我做一个 Flutter 新页面”
- “先看看这个老 Flutter 项目结构，再开始开发”
- “我给你 PRD 和设计图，先拆页面结构”
- “这个页面能不能复用旧代码”

如果没有稳定触发，可以这样说：

- `ff- 我有一个 Flutter 需求需要你做`
- `使用 flutter-forge 处理这个任务`
- `按 flutter-forge 工作模式处理`

## 推荐开场

### 老项目首次接入

```text
这是一个老 Flutter 项目，先不要写代码。
先扫描目录结构、模块边界、命名风格、状态管理、组件边界和接口接入方式。
输出：
1. 项目规则理解摘要
2. 项目规则卡
3. 高风险确认项
```

### 新项目页面开发

```text
这是一个新 Flutter 项目。
先按 Flutter 通用最佳实践起步。
先给我：
1. 页面结构树
2. 文件结构和命名方案
3. 关键实现决策
然后再生成代码
```

### 只给 PRD

```text
我先给你 PRD，请先做需求理解。
如果继续推进需要设计图，再明确告诉我缺什么。
如果暂时没有设计图，先给页面结构树草案和待确认 UI 点。
```

### 只给设计图

```text
我先给你设计图，请先做 UI 解析。
如果继续推进需要业务规则或 PRD，再明确告诉我缺什么。
如果暂时没有 PRD，先给页面结构树、文件结构和命名草案。
```

## 官方 Flutter skills（可选）

如果你的环境里已经安装官方 Flutter skills，`flutter-forge` 会优先复用它们处理通用子任务。

- 仓库：[flutter/skills](https://github.com/flutter/skills)
- 文档：[Agent skills for Flutter and Dart](https://docs.flutter.dev/ai/agent-skills)

安装：

```bash
npx skills add flutter/skills --skill '*' --agent universal
```

更新：

```bash
npx skills update flutter/skills
```

## 版本

- [VERSION](/Users/agi00114/Desktop/AI/agent设计/flutter-forge/VERSION)
- [CHANGELOG.md](/Users/agi00114/Desktop/AI/agent设计/flutter-forge/CHANGELOG.md)
