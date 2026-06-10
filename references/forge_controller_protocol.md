# Forge Controller Protocol

本文档定义 forge 系列 controller 的通用协议层。它不是 Flutter 专项运行手册；Flutter Forge 只是在该协议上增加 Flutter 项目识别、project_guardrails、Flutter skills 委托和 Dart/Flutter 校验。

## 目标边界

forge 系列 controller 负责六类稳定能力：

1. 触发入口：识别显式 forge 触发词，避免误命中相邻词。
2. 任务路由：把用户输入预分类为等待态、直通、轻量、中等、专项优化、架构级、功能/页面开发、新项目共创。
3. 项目护栏：在写入前确认项目状态、初始化状态和长期规则来源。
4. 阶段门禁：把需求确认、方案确认、实现写入、验证和收口变成可检查状态。
5. 角色隔离：按角色组装上下文，避免实现者提前看到验证 Rubric，避免验证者被实现自检污染。
6. 发布绑定：任何 P0/P1 行为规则都必须绑定到 release check 的正反例。

## 通用状态模型

最小 controller 状态字段：

- `phase`：当前阶段，如 discovery / design / implement / verify / close
- `mode`：任务路由结果
- `policy`：standard / fast / autonomous
- `guardrails_status`：found / missing / empty_new / unsupported
- `confirmation_status`：pending / confirmed / auto_assumption
- `scope_status`：in_scope / risk / conflict
- `work_unit`：当前可执行子单元
- `verification_status`：not_started / running / passed / failed
- `waiting_state`：none / confirmation / artifact / clarification

Flutter Forge 当前中文 session 字段可以继续保留，但跨 forge 抽象时应映射到上述语义字段。

## 通用命令面

controller 至少应提供以下机器入口：

- `classify`：返回 mode、policy、guardrails_check、required_phases、upgrade_signals
- `gate-check`：返回 allow/block、gate_id、reason、target_kind
- `session-init/read/update/wait/resume`：持久化阶段与等待态
- `generate-agent-prompt`：按角色生成边界化 prompt
- `validate-output`：校验可见日志和收口摘要
- `validate-release-bindings`：校验 P0/P1 规则绑定

命令输出应优先使用 JSON 或稳定 key-value，不应依赖 LLM 解析长自然语言。

## 产品专项扩展点

每个 forge 变体只应扩展以下部分：

- 触发词：如 `ff-` / `h5f-` / 其他领域前缀
- 项目根检测：如 Flutter、H5、iOS、后端服务
- 护栏模板：领域专属的 guardrails schema
- 角色合约：领域内分析、设计、实现、验证角色
- 委托地图：官方 skills、MCP、测试工具、构建工具
- release golden cases：领域高频误判和高风险门禁

不应在产品专项层重复实现通用阶段门禁、等待态恢复、release binding 校验和角色隔离过滤。

## Flutter Forge 当前映射

| 通用概念 | Flutter Forge 当前实现 |
|---|---|
| `classify` | `scripts/classify_task.sh` + `tests/route_golden_cases.json` |
| `gate-check` | `scripts/gate_check.py` + `scripts/hook_check_project_guardrails.sh` |
| `session-*` | `scripts/ff_session.sh` |
| `generate-agent-prompt` | `scripts/controller.py generate-agent-prompt` |
| `guardrails` | `scripts/detect_project_root_state.py`, `scripts/check_project_guardrails.sh`, `scripts/init_project_guardrails.py` |
| `validate-output` | `scripts/validate_output.sh` |
| `validate-release-bindings` | `scripts/validate_release_bindings.py` |

## 迁移原则

- 先抽协议，再抽代码。当前阶段只要求 Flutter Forge 行为能映射到通用协议，不强行改 runtime。
- 协议字段先保持最小集，只有两个以上 forge 变体真实复用后再提升为共享库。
- 共享化必须以 release golden cases 为前提；没有 golden case 的抽象只算文档草案。
- Flutter 专项规则不得上移为通用规则，除非能在非 Flutter forge 中成立。
