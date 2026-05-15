# Flutter Forge

> 让 AI 真正理解你的 Flutter 项目，而不只是生成代码。

Flutter Forge 是一个面向 Flutter 开发的结构化 AI 协作工作流 skill。它不是代码生成器，而是一个**项目内的编排与决策层**：在动手写代码之前，先理解项目上下文、收口设计方案、统一工程规则。

GitHub: [lbyxunxunnini/flutter-forge](https://github.com/lbyxunxunnini/flutter-forge) · License: MIT · 当前版本：**v0.1.0**

---

## 一句话定位

它解决的不是「Flutter 怎么写」，而是「AI 在你的 Flutter 项目里应该按什么规则写」。

小改动直接做；已有项目先收口再实现；只有想法时先共创需求、风格、页面结构，再动代码。

## 你只需要记住 3 个入口

```text
ff-       标准结构化流程：新页面、新模块、PRD、设计图、重构、迁移
ff-fast  快速路径：小改动、局部 bug、轻量/中等任务，发现风险再升级
ff-a      全自动路径：缺少的非阻塞信息用推荐方案，一路做到验证完成
```

第一次接入已有项目时，用：

```text
ff- 这是一个迭代中的 Flutter 项目。先扫描项目结构，输出规则卡草案，不要先写代码。
```

更短的上手说明见 [QUICKSTART.md](QUICKSTART.md)，常用 prompt 见 [CHEATSHEET.md](CHEATSHEET.md)。

## 适合 / 不适合

**适合**
- 用 Claude Code、Codex、Cursor、Trae 等 AI 编码工具长期维护 Flutter 项目
- 项目有固定的目录、命名、状态管理或组件复用规则
- 经常把 PRD、设计图、页面需求交给 AI 拆解
- 希望 AI 先扫描项目，再决定复用还是新写

**不适合**
- 只想找 Flutter UI 组件库
- 只需要复制粘贴页面模板
- 不使用 agent skills 或类似 AI 工作流机制

---

## 安装

### 推荐：npx skills

```bash
npx skills add lbyxunxunnini/flutter-forge
```

CLI 会自动检测已安装的 AI 编码工具（Claude Code、Trae、Cursor、Codex 等）并安装到对应目录。

```bash
# 全局安装（所有项目共享）
npx skills add lbyxunxunnini/flutter-forge -g

# 指定工具
npx skills add lbyxunxunnini/flutter-forge -a claude-code
npx skills add lbyxunxunnini/flutter-forge -a trae -a codex
```

### 备选：git clone

```bash
git clone https://github.com/lbyxunxunnini/flutter-forge ~/.claude/skills/flutter-forge
```

可替换为 `~/.trae/skills/`、`~/.agents/skills/`、`~/.cc-switch/skills/`、`~/.codex/skills/`。

### 更新

```bash
npx skills update                                # npx 安装
git -C <安装路径> pull                            # git clone 安装
```

`<安装路径>` 替换为实际安装目录，如 `~/.claude/skills/flutter-forge`、`~/.trae/skills/flutter-forge` 等。

---

## 使用

推荐显式触发：`ff-`、`ff-fast`、`ff-a` 或 `/flutter-forge`。

```
ff- 帮我做一个订单列表页
ff-fast 订单页加 3 个筛选条件，先快速看相似实现再改
ff-a 新建一个商品详情页，缺少的部分按推荐方案自动做完
/flutter-forge 帮我 review 这个页面
```

一旦显式进入，本轮任务由 controller 主动分流，不需要为子步骤重复触发；任务结束自动退出。

`ff-fast` 表示快速执行：轻量优先，自动生成项目摘要，最多读少量关键文件；发现需求、UI 或架构风险再升级。

`ff-a` 表示全自动执行：非阻塞缺口不反复确认，Flutter Forge 会采用推荐方案继续推进，并在结束时列出自动采用了哪些方案。安全、不可逆、生产环境或全项目架构切换仍会中断确认。

快速上手见 [QUICKSTART.md](QUICKSTART.md)，常用 prompt 见 [CHEATSHEET.md](CHEATSHEET.md)。

### 四个常用入口

**快速小改**
```text
ff-fast 把登录页按钮文案改成“立即开始”
```

**已有 Flutter 项目首次接入**
```text
这是一个迭代中的 Flutter 项目。先用 flutter-forge 扫描项目结构，输出规则卡草案，不要先写代码。
```

**新 Flutter 应用**
```text
新 Flutter 项目，使用 flutter-forge business profile。先定目录、状态管理、路由、网络层和首批页面结构，再开始写代码。
```

| Profile | 适合场景 |
|---------|----------|
| `mvp` | 快速原型、演示、想法验证 |
| `business` | 标准业务应用（默认推荐） |
| `team` | 多人长期维护，规范优先 |

**只有一个想法**
```text
我有个想法，想做一个新的 Flutter 项目。先不要直接写代码，先帮我一起收口需求、讨论风格和页面结构，再决定第一版做什么。
```

进入「新项目共创模式」：说清想法 → 补全需求 → 推荐风格 → 收口页面结构 → 生成项目。

**希望自动做完**
```text
ff-a 新建商品详情页，包含轮播图、价格、规格选择和底部购买按钮，缺少的部分按推荐方案自动做完
```

---

## 实际效果

**轻量任务 — 直接干活**
```
用户: 帮我改一下登录页的按钮颜色

[f-forge] 页面工程师：轻量任务，直接执行
→ 读取 lib/pages/login_page.dart
→ 找到 ElevatedButton，颜色从 blue 改为 theme.primaryColor
→ 完成
```

**快速任务 — 少读少说，发现风险再升级**
```
用户: ff-fast 订单页加 3 个筛选条件，先快速看相似实现再改

[f-forge] 页面工程师：ff-fast 快速策略，轻量优先，发现架构风险再升级。
[f-forge] 页面工程师：中等任务，先扫描后执行
→ 读取 project snapshot 和 1-3 个相似实现
→ 直接修改筛选逻辑并完成最小验证
```

**复杂任务 — 先收口再动手**
```
用户: 我有个需求，做一个订单列表页，支持筛选和下拉刷新

[f-forge] 模式：页面开发
[f-forge] 阶段：S1 需求确认
[f-forge] 需求分析师：提取 8 个约束，核心是订单列表+筛选+分页
[f-forge] 阶段：S2 方案确认
[f-forge] 架构设计师：先冻结状态归属和路由接入，再进入实现
[f-forge] 页面工程师：开始扫描相似实现并准备落地
```

**全自动任务 — 缺口用推荐方案**
```
用户: ff-a 新建商品详情页，缺少的部分按推荐方案自动做完

[f-forge] 全自动：已启用 ff-a，非阻塞缺口将采用推荐方案推进；安全、不可逆或高风险架构决策才中断确认。
[f-forge] 模式：页面开发
[f-forge] 全自动摘要：本轮自动采用 3 项推荐方案：规格联动价格库存；详情页卡片风格；项目主流状态管理接入。
```

---

## 它解决的问题

| 直接让 AI 写代码常见的问题 | Flutter Forge 的做法 |
|------|---------------------|
| 不了解现有项目风格，生成的代码格格不入 | 首次接入扫描项目，生成规则卡，后续都基于规则卡 |
| 拿到不完整需求就硬编 | 显式处理不完整输入，缺什么告诉你 |
| 把猜的 UI 当成设计图真实内容 | UI 来源标注：真实视觉 / 文字描述 / 结构推断 |
| 轻任务啰嗦、复杂任务又不收口 | 任务路由：10 秒测试快速分流 |
| 多个视角混在一起 | 模式日志 + 阶段日志 + 角色标签 |
| 需求没确认 UI 和实现一起开工 | 阶段门禁：先需求 → 方案 → 实现 |

---

## 任务分级

| 级别 | 适用场景 | 参与角色 |
|------|---------|----------|
| **直通模式** | 文档、代码环境、打包、CI/CD、闲聊 | 主控直接处理 |
| **轻量任务** | 文案/颜色/字号/已定位 bug、analyze/test/build | 页面工程师 |
| **中等任务** | 局部结构调整、单页内增加几个功能点 | 页面工程师（先扫描后执行） |
| **UI 优化任务** | 现有页面样式、布局、动效优化 | UI 设计师 → 页面工程师 |
| **架构级任务** | 性能优化、重构、审查、迁移、依赖清理、i18n/a11y | 架构设计师 → 页面工程师 |
| **功能开发** | 大功能闭环、跨页面状态联动、深链 | 完整流程 |
| **页面开发** | 新页面、模块扩展、PRD/设计图解析 | 完整流程 |
| **新项目共创** | 仅有初步想法 | C0–C3 共创轨道 |

### 快速入口 `ff-fast`

```text
ff-fast 订单页加 3 个筛选条件，先快速看相似实现再改
```

`ff-fast` 会轻量优先，适合小改动、局部 bug、轻量 UI/交互调整和中等任务。它会优先使用 `project_snapshot` 和 1-3 个关键文件定位问题；如果发现路由、状态管理、组件边界、需求缺口或 UI 结构风险，再升级到标准流程。

### 全自动入口 `ff-a`

```text
ff-a 新建商品详情页，包含轮播图、价格、规格选择和底部购买按钮，缺少的部分按推荐方案自动做完
```

全自动并不跳过流程。它会：

- 自动采用空态、加载态、错误态、页面结构、状态接入和路由接入的推荐方案
- 优先沿用规则卡、相似实现和项目主流 Flutter 技术栈
- 做完后输出全自动摘要，列出采用了哪些默认方案
- 遇到删除数据、生产环境、密钥、支付、隐私权限、不可逆迁移或全项目架构切换时中断确认

---

## 核心机制

### 1. 任务路由（第一道门）
显式触发后，先按直通 / 优化类 / 架构级 / 页面新增 / 业务闭环 / 10 秒测试等顺序快速分流。

### 2. 主控 + 按需专项判断
- `controller` 负责命中、路由、阶段推进
- 需求分析师 / UI 设计师 / 架构设计师 / 页面工程师 仅在当前阶段需要时出现
- UI 设计师遇到关键视觉输入不足时，先向用户补要设计图或文字化描述

### 3. 阶段门禁
- 需求未确认前不进实现
- 方案未稳定前不进实现
- 拆包未冻结前不进多实现并行
- 上游变化让下游结果失效

### 4. 双轨模型
- `C0–C3`：新项目共创轨道
- `S0–S6`：开发执行轨道
- `C3` 通过后才允许进入 `S3`

### 5. 规则卡（Rule Card）
核心持久化机制，一份 YAML 文件捕获项目工程约定：

```yaml
project:
  name: "my_app"
  type: existing
  flutter_version: "3.x"
naming:
  page_suffix: "Page"
  file_case: snake_case
state_management: riverpod
routing: go_router
performance_budget:
  max_widget_depth: 5
  list_must_use_builder: true
i18n:
  enabled: false
accessibility:
  enabled: false
```

存储位置优先：`.claude/.flutter-forge/projects/`、`.trae/.flutter-forge/projects/`、`.agent/.flutter-forge/projects/`，回退到项目根目录 `.flutter-forge/projects/`。

### 6. 不完整输入处理

| 输入 | 行为 |
|------|------|
| 只给 PRD | 先做需求分析，产出页面结构树草案和待确认 UI 点 |
| 只给设计图 | 先做 UI 解析，缺业务规则再明确告诉你 |
| PRD + 设计图 | 完整流程：需求 → UI → 结构 → 实现 |
| 上下文不足 | 明确告诉你缺什么，不会硬编 |

### 7. UI 来源标注
- `真实视觉输入` — 能可靠读取设计图
- `用户文字描述` — 基于用户口述
- `结构推断` — 设计图不可读时的降级推断

### 8. 渐进式加载
主控 `SKILL.md` 只保留编排逻辑，30+ 参考文档按需加载。完整映射见 [`references/load_map.md`](references/load_map.md)。

### 9. Flutter Skills 本地集成
`flutter-skills/` 目录下集成了 10 个官方 Flutter Agent Skill 本地副本，可直接委托：

```
flutter-add-integration-test           flutter-add-widget-preview
flutter-add-widget-test                flutter-apply-architecture-best-practices
flutter-build-responsive-layout        flutter-fix-layout-issues
flutter-implement-json-serialization   flutter-setup-declarative-routing
flutter-setup-localization             flutter-use-http-package
```

委托映射见 [`references/delegation_map.yaml`](references/delegation_map.yaml)。

### 10. 工作模式可见性

每次命中后输出一行模式标志：

| 模式 | 标志 |
|------|------|
| 轻量任务 | `[f-forge] 页面工程师：轻量任务，直接执行` |
| 中等任务 | `[f-forge] 页面工程师：中等任务，先扫描后执行` |
| UI 优化 | `[f-forge] 模式：UI 优化` |
| 架构级 | `[f-forge] 模式：架构级任务` |
| 功能开发 | `[f-forge] 模式：功能开发` |
| 页面开发 | `[f-forge] 模式：页面开发` |
| 新项目共创 | `[f-forge] 模式：新项目共创` |

阶段变化时还会输出阶段日志，例如 `[f-forge] 阶段：S2 方案确认`。

---

## 架构总览

```
┌─────────────────────────────────────────────────────┐
│                   用户自然语言输入                     │
└────────────────────────┬────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────┐
│       Flutter Forge 主控（SKILL.md 编排逻辑）          │
│                                                       │
│   硬排除检查 → 完整流程触发 → 轻量/中等判定            │
│                         │                             │
│                         ▼                             │
│   任务路由 & 工作模式：                                │
│     直通模式 / 轻量 / 中等 /                           │
│     UI 优化 / 架构级 / 功能开发 /                      │
│     页面开发 / 新项目共创                              │
└─────────────────────────┬───────────────────────────┘
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  按需加载     │ │ 本地 Flutter │ │  记忆协议     │
│  30+ 参考文档 │ │ Skills 委托  │ │  规则卡/偏好  │
└──────────────┘ └──────────────┘ └──────────────┘
```

---

## 项目结构

```
flutter-forge/
├── SKILL.md                        # 主控文档（编排逻辑）
├── README.md                       # 本文件
├── VERSION                         # 版本号
├── CHANGELOG.md                    # 变更记录
│
├── references/                     # 按需加载的参考文档
│   ├── load_map.md
│   ├── rule_card_protocol.md
│   ├── project_init_flow.md
│   ├── memory_protocol.md
│   ├── skill_visibility.md
│   ├── code_review_mode.md
│   ├── migration_assist.md
│   ├── i18n_a11y_check.md
│   ├── official_flutter_skills.md
│   ├── engineering_heuristics.md
│   ├── testing_strategy.md
│   ├── routing_and_navigation.md
│   ├── network_and_api.md
│   ├── adr_format.md
│   └── roles/
│       ├── requirement_analyst.md
│       ├── ui_designer.md
│       ├── architecture_designer.md
│       └── page_engineer.md
│
├── memory/                         # 记忆模板与画像
│   ├── global_preferences.yaml
│   ├── profiles/
│   ├── projects/
│   └── runtime/
│
└── flutter-skills/                 # Flutter 通用技能本地副本（10个）
```

---

## 诊断

```bash
# 检查 Node.js
node -v && npm -v

# 检查 skills CLI
npx skills --version
npx skills list

# 检查 flutter-forge 是否被探测到
ls ~/.claude/skills/flutter-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
ls ~/.trae/skills/flutter-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
ls ~/.codex/skills/flutter-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
```

## 本地验证

```bash
# 发布前总检查：版本一致性、规则卡 schema、路由 golden cases
scripts/validate_release.sh

# 本地健康检查
scripts/doctor.sh

# 检查某个 Flutter 项目是否适合接入
scripts/validate_project.sh /path/to/flutter/app

# 输出冷启动项目摘要
python3 scripts/project_snapshot.py /path/to/flutter/project --json

# 生成规则卡草案
python3 scripts/init_rule_card.py /path/to/flutter/project --profile auto --interactive

# 单独扫描 Flutter 技术栈
python3 scripts/flutter_stack_scan.py /path/to/flutter/project --json

# 单独检查路由用例
python3 scripts/route_golden_tests.py

# 单独检查规则卡模板 / 示例
python3 scripts/validate_rule_card.py --allow-placeholders references/rule_card_template.yaml memory/projects/example_project.rule_card.yaml

# 单独检查文档链接和必备引用
python3 scripts/validate_docs_sync.py
```

---

## 当前状态

`v0.1.0` 是新的 v 前缀发布线，用于和历史无 `v` 的 `0.x.x` 版本隔离。当前已具备完整文档、任务路由、规则卡、角色协作、官方 Flutter skills 委托策略和本地发布检查。

当前已提供：

- Demo transcript：[references/demo_transcript.md](references/demo_transcript.md)
- 真实回归记录：[references/validation_log.md](references/validation_log.md)
- Flutter 技术栈扫描器：`scripts/flutter_stack_scan.py`
- 项目快照：`scripts/project_snapshot.py`
- 规则卡初始化向导：`scripts/init_rule_card.py`
- Doctor / 项目校验：`scripts/doctor.sh`、`scripts/validate_project.sh`
- 发布 gate：`scripts/validate_release.sh`

仍缺至少一个真实 Flutter app 试跑记录和截图 / 录屏。没有真实项目时不会补虚构 validation case，欢迎通过 issue 提交真实项目试跑反馈。

## 参与贡献

- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)
- 快速上手：[QUICKSTART.md](QUICKSTART.md)
- 速查卡：[CHEATSHEET.md](CHEATSHEET.md)
- 开源发布检查：[OPEN_SOURCE_CHECKLIST.md](OPEN_SOURCE_CHECKLIST.md)
- 模式测试用例：[references/mode_test_cases.md](references/mode_test_cases.md)
- Demo transcript：[references/demo_transcript.md](references/demo_transcript.md)
- Flutter 技术栈识别：[references/flutter_stack_detection.md](references/flutter_stack_detection.md)
- 技术栈 profile：[references/stack_profiles.md](references/stack_profiles.md)
- 快速执行策略：[references/fast_mode.md](references/fast_mode.md)
- 全自动执行策略：[references/autonomous_mode.md](references/autonomous_mode.md)
- 发布流程：[references/release_playbook.md](references/release_playbook.md)
- 大改版标准案例：[references/case_study_large_rework.md](references/case_study_large_rework.md)
- 宿主子代理支持：[references/host_subagent_support.md](references/host_subagent_support.md)
- 真实试跑记录模板：[references/validation_log.md](references/validation_log.md)

如果你在真实项目中试用过，优先提交 GitHub issue 中的 `Validation case`，这比泛泛的反馈更有助于改进路由和规则卡。

## 第三方组件归属

`flutter-skills/` 下 10 个 skill 是 [flutter/skills](https://github.com/flutter/skills) 的本地副本，原始版权属于 Google LLC，采用 BSD-3-Clause 许可证。详见 [LICENSE](LICENSE)。

相关链接：
- [flutter/skills 仓库](https://github.com/flutter/skills)
- [Agent skills for Flutter and Dart](https://docs.flutter.dev/ai/agent-skills)

## 版本

当前版本：**v0.1.0** · [CHANGELOG](CHANGELOG.md)

`v0.1.0` 开启 v 前缀发布线，新增 `ff-fast`、`ff-a`、规则卡初始化向导、项目快照、doctor、自检脚本、技术栈 profile 和发布 gate。
