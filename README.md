# Flutter Forge

> 让 AI 真正理解你的 Flutter 项目，而不只是生成代码。

Flutter Forge 是一个为 Flutter 开发提供结构化的 AI 协作工作流skill。它不是代码生成器——它是一个**项目内编排与决策层**，在动手写代码之前先理解项目上下文、收口设计方案、统一工程规则。

## 为什么需要它

直接让 AI 写 Flutter 代码，常见问题：

| 问题 | Flutter Forge 的做法 |
|------|---------------------|
| 不了解现有项目风格，生成的代码格格不入 | 首次接入时扫描项目，生成规则卡，后续开发都基于规则卡 |
| 拿到不完整需求就硬编，全要返工 | 显式处理不完整输入，缺什么告诉你，不会假装理解了没看到的东西 |
| 把猜出来的 UI 结构当成设计图真实内容 | UI 来源标注：真实视觉 / 文字描述 / 结构推断，三种来源不混淆 |
| 轻量任务啰嗦一大堆，大任务反而没有设计过程 | 任务分级：轻量任务直接执行，大任务先走四角色设计流程 |

## 实际效果

装了之后打字会发生什么？两个典型场景：

**轻量任务 — 直接干活**

```
用户: 帮我改一下登录页的按钮颜色

[flutter-forge] 轻量任务，直接执行
→ 读取 lib/pages/login_page.dart
→ 找到 ElevatedButton，颜色从 blue 改为 theme.primaryColor
→ 完成
```

**大任务 — 先设计再动手**

```
用户: 我有个需求，做一个订单列表页，支持筛选和下拉刷新

[flutter-forge] 检测到规则卡（GetX + Dio + snake_case）
[flutter-forge] 大任务，进入四角色流程

需求分析师：
- 订单列表：分页加载、筛选（状态/时间）、下拉刷新
- 待确认：筛选条件是单选还是多选？

用户: 单选

架构设计师：
- 文件方案：lib/pages/order/order_list_page.dart
- 状态管理：OrderListController extends GetxController
- 复用：复用现有 OrderCard widget

页面工程师：
→ 生成页面骨架代码...
```

轻量任务不打扰你，大任务先对齐再动手。

## 安装

### 方式一：npx skills（推荐）

需要先安装 [Node.js](https://nodejs.org/)，然后运行：

```bash
npx skills add lbyxunxunnini/flutter-forge
```

CLI 会自动检测你安装的 AI 编码工具（Claude Code、Trea、Cursor、Codex 等），并安装到对应目录。

全局安装（所有项目共享）：

```bash
npx skills add lbyxunxunnini/flutter-forge -g
```

指定工具安装：

```bash
npx skills add lbyxunxunnini/flutter-forge -a claude-code
npx skills add lbyxunxunnini/flutter-forge -a trae -a codex
```

### 方式二：git clone

```bash
git clone https://github.com/lbyxunxunnini/flutter-forge ~/.claude/skills/flutter-forge
```

根据你的工具替换路径，可选 `~/.trae/skills/`、`~/.agents/skills/`、`~/.cc-switch/skills/`。

### 更新

```bash
# npx 方式安装的
npx skills update

# git clone 方式安装的（替换为你实际的路径）
git -C ~/.claude/skills/flutter-forge pull
```

## 使用

自然语言描述任务即可，不需要固定格式。

```
ff- 帮我做一个 Flutter 新页面
ff- 先看看这个迭代中项目结构，再开始开发
ff- 我给你 PRD 和设计图，先拆页面结构
```

手动触发兜底：

```
使用 flutter-forge 处理这个任务
按 flutter-forge 工作模式处理
```

### 典型场景

| 场景 | 说什么 |
|------|--------|
| 迭代中项目接入 | "这是一个迭代中 Flutter 项目，先扫描结构再开发" |
| 新项目起步 | "新 Flutter 项目，先给页面结构和文件方案" |
| 只有 PRD | "先做需求分析，缺设计图再告诉我" |
| 只有设计图 | "先做 UI 解析，缺业务规则再告诉我" |

## 诊断

安装后跑一下，确认环境正常：

```bash
# 检查 Node.js
node -v && npm -v

# 检查 skills CLI
npx skills --version

# 查看已安装的 skills
npx skills list

# 检查 flutter-forge 是否被探测到
ls ~/.claude/skills/flutter-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
ls ~/.trae/skills/flutter-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
ls ~/.agents/skills/flutter-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
```

如果用的是 git clone 方式，确认 SKILL.md 文件存在于你 clone 的目录即可。

## 架构总览

```
┌─────────────────────────────────────────────────┐
│                  用户自然语言输入                   │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│              Flutter Forge 主控 (SKILL.md)        │
│                                                   │
│  ┌───────────┐ ┌───────────┐ ┌───────────────┐  │
│  │ 启动判定   │ │ 输入分级   │ │ 规则卡检查     │  │
│  │ 4步握手    │ │ 任务分级   │ │ 状态机管理     │  │
│  └─────┬─────┘ └─────┬─────┘ └───────┬───────┘  │
│        └──────────────┼───────────────┘          │
│                       ▼                           │
│  ┌─────────────────────────────────────────────┐ │
│  │           任务路由 & 角色切换                  │ │
│  │                                               │ │
│  │  轻量任务 → 直接执行                           │ │
│  │  中任务 → 设计收口 + 执行                      │ │
│  │  大任务 → 需求分析 → UI设计 → 架构设计 → 实现  │ │
│  └──────────────────────┬──────────────────────┘ │
└─────────────────────────┼───────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  按需加载     │ │  官方 Skills  │ │  记忆协议     │
│  20+ 参考文档 │ │  委托子任务   │ │  规则卡/偏好  │
└──────────────┘ └──────────────┘ └──────────────┘
```

## 核心机制

### 1. 启动握手（四步判定）

每次进入 Flutter 任务时，自动执行：

1. **规则卡检查** — 当前项目是否存在 `~/.flutter-forge/projects/*.rule_card.yaml`
2. **项目类型判定** — 迭代中项目还是新项目
3. **输入模型判定** — PRD / 设计图 / 两者都有 / 上下文不足
4. **任务分级** — 轻量任务 / 中等任务 / 大任务

只有在项目未初始化（无规则卡）时才向用户输出完整握手日志。已有规则卡的项目静默进入工作阶段。

### 2. 项目状态机

```
未初始化 ──扫描──→ 规则卡草案 ──确认──→ 已初始化（完全态）
                                        │
                                        ├── 规则卡存在
                                        └── Flutter skills 状态已就绪
```

- **未初始化** — 首次进入迭代中项目，触发扫描流程
- **规则卡草案** — 扫描完成，生成 YAML 规则卡，抛出高风险确认项
- **完全态** — 规则卡 + Flutter skills 就绪，后续进入静默跳过握手

### 3. 不完整输入处理

Flutter Forge 的设计前提：**用户不会总是给你完整需求**。

| 输入模型 | 行为 |
|---------|------|
| 只给 PRD | 先做需求分析，产出页面结构树草案和待确认 UI 点 |
| 只给设计图 | 先做 UI 解析，缺业务规则再明确告诉你 |
| PRD + 设计图 | 完整流程：需求分析 → UI 解析 → 结构设计 → 实现 |
| 上下文不足 | 明确告诉你缺什么，不会硬编 |

### 4. UI 来源标注

每次 UI 分析输出都标注来源，防止 AI 把猜测当事实：

- `真实视觉输入` — 能可靠读取设计图
- `用户文字描述` — 基于用户口述
- `结构推断` — 设计图不可读时的降级推断

### 5. 四角色协作模型

复杂任务（大任务）自动切换四个专业视角：

| 角色 | 职责 | 产出 |
|------|------|------|
| 需求分析师 | 理解 PRD，拆解功能点，识别边界条件 | 需求理解摘要、待确认项 |
| UI 设计师 | 解析设计图，规划页面结构和交互 | 页面结构树、组件拆分方案 |
| 架构设计师 | 设计文件结构、状态管理、组件边界 | 文件方案、复用策略、技术决策 |
| 页面工程师 | 生成接近可运行的代码骨架 | Flutter 页面代码 |

轻量任务直接由页面工程师执行，不走完整流程。

### 6. 规则卡（Rule Card）

规则卡是 Flutter Forge 的核心持久化机制，一份 YAML 文件捕获项目的工程约定：

```yaml
project:
  name: "my_app"
  type: legacy
  flutter_version: "3.x"
naming:
  page_suffix: "Page"
  widget_suffix: "Widget"
  file_case: snake_case
state_management: riverpod
routing: go_router
patterns:
  list_page: standard
  form_page: standard
```

- 存储位置：`~/.flutter-forge/projects/*.rule_card.yaml`
- 生成时机：迭代中项目扫描后 / 新项目完成起步选择后
- 后续所有开发都基于规则卡保持一致性

### 7. 渐进式加载（Progressive Disclosure）

主控文档 `SKILL.md` 只包含编排逻辑（~600 行），20+ 参考文档按需加载：

| 场景 | 加载的参考文档 |
|------|--------------|
| 迭代中项目接入 | `legacy_project_scan.md`、`rule_card_template.yaml` |
| 任务执行 | `task_runtime_prompt.md` |
| 工程判断 | `engineering_heuristics.md` |
| 官方 Skills 委托 | `official_flutter_skills.md`、`delegation_map.yaml` |
| 测试与质量 | `testing_strategy.md`、`quality_gates.md` |
| 反模式检测 | `anti_patterns.md`、`templates_catalog.md` |

完整映射见 [`references/load_map.md`](references/load_map.md)。

### 8. 官方 Flutter Skills 集成

Flutter Forge 不重复造轮子。它检测本地是否安装了 Flutter 官方 skills，有就委托通用子任务：

```
探测顺序：
1. 当前项目目录 (.claude/skills/, .agents/skills/, .cc-switch/skills/, .trae/skills/)
2. 宿主根目录 (~/.claude/skills/, ~/.agents/skills/, ~/.cc-switch/skills/, ~/.trae/skills/)
3. 未检测到 → 使用内置参考文档兜底
```

委托映射见 [`references/delegation_map.yaml`](references/delegation_map.yaml)。

## 项目结构

```
flutter-forge/
├── SKILL.md                        # 主控文档（编排逻辑）
├── README.md                       # 本文件
├── VERSION                         # 版本号
├── CHANGELOG.md                    # 变更记录
│
├── references/                     # 按需加载的参考文档
│   ├── load_map.md                 # 场景 → 文档映射
│   ├── legacy_project_scan.md      # 迭代中项目扫描协议
│   ├── task_runtime_prompt.md      # 任务执行规则
│   ├── memory_protocol.md          # 记忆读写协议
│   ├── engineering_heuristics.md   # 工程判断标准
│   ├── templates_catalog.md        # 页面模板目录
│   ├── anti_patterns.md            # 反模式检测
│   ├── roles/                      # 四角色卡
│   │   ├── requirement_analyst.md
│   │   ├── ui_designer.md
│   │   ├── architecture_designer.md
│   │   └── page_engineer.md
│   └── ...
│
├── memory/                         # 记忆模板与画像
│   ├── global_preferences.yaml     # 全局偏好
│   ├── profiles/                   # 状态管理画像（Riverpod/Bloc）
│   ├── projects/                   # 项目规则卡示例
│   └── runtime/                    # 运行时任务记忆模板
│
└── scripts/
    └── discover_flutter_skills.sh  # Flutter skills 探测脚本
```

## 官方 Flutter Skills（可选）

安装后 Flutter Forge 会自动委托通用子任务（布局、路由、HTTP、测试）：

```bash
npx skills add flutter/skills --skill '*' --agent universal
```

`--agent universal` 会安装到 `.agents/skills/` 目录，兼容大多数 AI 编码工具。安装后 Flutter Forge 会自动探测该目录。

- [flutter/skills 仓库](https://github.com/flutter/skills)
- [Agent skills for Flutter and Dart](https://docs.flutter.dev/ai/agent-skills)

## 版本

当前版本：**0.6.3** · [CHANGELOG](CHANGELOG.md)
