# Flutter Forge Reference - Host Subagent Support

这个文件说明 `flutter-forge` 在不同宿主中的子代理支持情况，以及当宿主能力未知或不支持真实子代理时，如何安全降级为串行执行。

## 1. 先看结论

`子代理` 主要是宿主能力，不是模型本身的天然能力。

- 模型决定：质量、速度、成本、上下文容量
- 宿主决定：能不能拉起独立子代理、能不能隔离 context、能不能并行、能不能给子代理单独配工具和权限

因此，判断“支不支持子代理”时，优先看宿主文档，而不是先看模型名字。

## 2. 能力状态矩阵

| 宿主 | 子代理能力状态 | 独立 context | 并行 | 自定义子代理 | 备注 |
|------|------------------------|--------------|------|--------------|------|
| Claude Code / Agent SDK | 是 | 是 | 是 | 是 | 文档最完整，支持 built-in subagents 和 custom subagents |
| OpenAI Codex | 是 | 是 | 是 | 是 | 需要显式要求才会 spawn subagents |
| Cursor | 是 | 是 | 是 | 是 | 支持 foreground/background，自带内置 subagents |
| Trae SOLO / SOLO Coder | 部分明确，接近是 | 是 | 文档上偏间接 | 是 | 官方明确支持 agent 调 agent 和独立 context，但"subagent"统一产品表述不如前三者清晰 |
| Gemini CLI | 兼容候选，待验证 | 待确认 | 待确认 | 待确认 | Google 官方 CLI agent，需进一步验证 skill 发现机制 [Flexible] |
| OpenCode | 兼容候选，待验证 | 待确认 | 待确认 | 待确认 | 开源 AI 编码工具，需验证 skill 兼容性 [Flexible] |
| GitHub Copilot CLI | 兼容候选，部分明确 | 待确认 | 待确认 | 待确认 | Copilot agent mode 支持 subagent 概念；CLI skill 加载需验证 [Flexible] |
| Factory Droid | 待确认 | 待确认 | 待确认 | 待确认 | 新兴工具，需持续跟踪 [Flexible] |

## 3. 宿主说明

### 3.1 Claude Code / Agent SDK

官方明确支持：

- subagents
- context isolation
- parallelization
- tool restrictions
- custom subagents

适合 `flutter-forge` 的点：

- 可以把搜索、规划、实现、验证拆给不同子代理
- 可以限制不同子代理的工具权限
- 可以把探索和长日志隔离到独立上下文

官方文档：

- [Anthropic Agent SDK - Subagents](https://docs.anthropic.com/en/docs/agent-sdk/subagents)
- [Claude Code - Create custom subagents](https://docs.claude.com/en/docs/claude-code/sub-agents)

### 3.2 OpenAI Codex

官方明确支持：

- subagent workflows
- parallel agents
- agent threads
- custom agents

需要注意：

- Codex 只会在你明确要求时拉起 subagents
- 适合把探索、review、triage、summarization 分给不同子代理
- 并行写入类任务要谨慎，避免冲突

官方文档：

- [Codex - Subagents](https://developers.openai.com/codex/subagents)
- [Codex - Subagent concepts](https://developers.openai.com/codex/concepts/subagents)

### 3.3 Cursor

官方明确支持：

- subagents
- own context window
- parallel execution
- foreground / background
- custom subagents

适合 `flutter-forge` 的点：

- 探索、终端、浏览器等噪音型任务适合隔离到 subagents
- 支持并行子代理和更清晰的上下文隔离

官方文档：

- [Cursor - Subagents](https://cursor.com/docs/context/subagents)
- [Cursor 2.4 changelog](https://www.cursor.so/changelog/2-4)

### 3.4 Trae

官方明确支持：

- custom agents
- callable by other agents
- independent context
- SOLO Coder orchestrates multiple agents

当前公开文档里已能确认：

- 自定义 agent 可以被其他 agent 调用
- 被调用时拥有独立 context
- 目前只有 `SOLO Coder` 可以调用 custom agents
- 官方明确说可以 orchestrate multiple agents 形成 AI team

需要注意：

- 我们能确认 Trae 支持“agent 调 agent”与独立 context
- 但暂未看到像 Claude Code / Codex / Cursor 那样集中表述为“标准 subagent 产品能力”的统一官方页面
- 因此在 Trae 中更稳的说法是：支持多 agent 协作与独立上下文，是否具备稳定并行子代理能力要以当前版本实际试跑为准

官方文档：

- [Trae - Create and manage agents](https://docs.trae.ai/ide/agent)
- [Trae - SOLO Coder](https://docs.trae.ai/ide/solo-coder)
- [Trae - SOLO mode overview](https://docs.trae.ai/ide/solo-mode)

## 4. 扩展平台说明 [Flexible]

以下平台的详细能力说明基于初步调研，标注 [Flexible] 表示待确认，实际支持以试跑为准。

### 4.1 Gemini CLI

Google 官方 CLI agent，基于 Gemini 模型。skill 加载机制与 Claude Code 类似，但子代理能力尚待确认。

- skill 安装路径：`~/.gemini/skills/`
- 子代理支持：待确认
- 备注：需验证 skill 文件发现机制和上下文隔离能力

### 4.2 OpenCode

开源 AI 编码工具，支持多模型切换。skill 兼容性需验证。

- skill 安装路径：`~/.opencode/skills/`
- 子代理支持：待确认
- 备注：开源项目，能力随版本迭代较快

### 4.3 GitHub Copilot CLI

Copilot agent mode 支持 subagent 概念，但 CLI 场景下的 skill 加载和子代理能力与 IDE 插件可能有差异。

- skill 安装路径：`~/.copilot/skills/`
- 子代理支持：部分明确（agent mode）
- 备注：IDE 内 Copilot 与 CLI Copilot 能力不完全等同

### 4.4 Factory Droid

新兴 AI 编码工具，skill 机制和子代理能力需持续跟踪。

- skill 安装路径：待确认
- 子代理支持：待确认
- 备注：产品仍在快速迭代中

## 5. 什么时候不要假设“支持真实子代理”

出现以下任一情况时，不要直接假设宿主支持真实子代理：

- 官方文档只说“可以创建多个 agent”，没说独立 context
- 官方文档没说 agent 可以被其他 agent 调用
- 官方文档没说并行或后台执行
- 当前运行环境里没有明确的 agent / subagent tool
- 当前宿主版本和官方文档能力不一致
- 你无法确认当前工作流是否真的会 spawn 独立 agent instance

## 6. 降级原则

如果无法确认宿主支持真实子代理，或者当前环境下没有子代理工具，`flutter-forge` 必须降级为：

`单主控 + 串行阶段推进 + 逻辑角色分工`

也就是说：

- 保留 `需求分析师 / UI 设计师 / 架构设计师 / 页面工程师` 的逻辑分工
- 但不再假设它们对应真实独立 agent instance
- 前置阶段按串行门禁推进
- 进入实现后，若无真实并行能力，则按串行工作包顺序执行

## 7. 串行降级协议

### 7.1 前置阶段

前置阶段默认就偏串行，因此降级后仍然成立：

- `S1` 收口需求
- `S2` 收口 UI / 架构
- `S3` 冻结拆包

这时只保留：

- 摘要包
- 一问一答
- 阶段门禁
- 角色标签

不强依赖真实子代理。

### 7.2 实现阶段

如果宿主不支持真实并行，或当前环境无法确认支持，`S4` 改为：

- 仍先产出工作包
- 但不同时并行执行多个 `impl-agent`
- 改为由同一主控按工作包顺序串行处理
- 每完成一个工作包，输出一次结果摘要

示例：

```text
[f-forge] 阶段：S4 实现中
[f-forge] 页面工程师：当前宿主未确认支持真实并行子代理，改按串行工作包执行。
[f-forge] 页面工程师：工作包 1 处理中：授权弹窗。
[f-forge] 页面工程师：工作包 1 完成：已完成授权弹窗结构和交互。
[f-forge] 页面工程师：工作包 2 处理中：提示栏与回流链路。
[f-forge] 页面工程师：工作包 2 完成：已完成提示栏展示和回流逻辑。
```

### 7.3 验证阶段

即使降级为串行，也必须保留统一收口：

- 汇总所有工作包结果
- 检查是否越界改动
- 做统一验证
- 再进入 `S6`

## 8. 对外输出要求

当进入降级路径时，必须对用户明确说明当前是降级执行。

推荐格式：

```text
[f-forge] 页面工程师：当前宿主未确认支持真实子代理并行，改按串行工作包执行，不影响阶段门禁和最终收口质量。
```

不要做的事：

- 不要假装已经并行
- 不要继续输出 `impl-agent-1 / impl-agent-2` 这类会误导用户的并行标识
- 不要把“逻辑角色分工”说成“宿主已拉起独立实例”

## 9. 适用于 flutter-forge 的宿主判断顺序

每次准备进入并行前，按这个顺序判断：

1. 当前宿主官方是否明确支持子代理？
2. 当前环境是否真的暴露了子代理调用能力？
3. 当前任务是否已经满足 `S3` 拆包冻结？
4. 当前 write scope 是否足够清晰？
5. 当前工作包数量是否值得并行？（≤2 个工作包时，串行通常更快，因为并行调度本身有开销：context 初始化、工作包分派、结果汇总。只有 3 个及以上工作包且彼此无依赖时，并行才有明确收益）
6. 如果上述任一项不满足，直接降级为串行工作包执行

## 10. 推荐实践

对 `flutter-forge` 来说，更稳的默认策略是：

- 前置阶段默认按串行门禁推进
- 只有在宿主能力明确、环境支持、工作包已冻结时，才启用真实并行
- 一旦能力不明确，立即降级为串行，不影响协议完整性

这意味着：

- 子代理是增强项，不是协议成立的前提
- 摘要包、提问机制、阶段门禁、guardrails出口在无子代理环境下仍然成立

## 11. 模型选择策略 [Flexible]

模型选择是宿主能力，不是协议要求。当宿主支持多模型时，controller 可按角色和阶段选择不同模型层级以优化成本和质量。

核心原则：前置决策用强模型，实现阶段用轻量/标准模型，验证评估用强模型。

完整策略见 [model_selection.md](model_selection.md)。
