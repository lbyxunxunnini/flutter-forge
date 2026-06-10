# Flutter Forge Maintenance Map

这份文档只服务维护者。它回答一件事：**改某个能力时，最少要同步哪些文件和测试，避免“改 A 忘 B”。**

不要把它写成协议文档。它是维护导航图，不是行为规范。

## 0. 改动前先判定能力域

每次维护先选一个主能力域，再按下表同步。若一次改动命中多个域，逐行叠加，不要只改最显眼的入口文件。

| 要改的能力 | 文档权威源 | 执行/校验脚本 | release 断言位置 | 最小验收命令 |
|---|---|---|---|---|
| 触发词 / 路由分类 | [trigger_words.md](trigger_words.md), [SKILL.md](../SKILL.md), [task_runtime_prompt.md](task_runtime_prompt.md) | [classify_task.sh](../scripts/classify_task.sh), [route_golden_tests.py](../scripts/route_golden_tests.py) | [guardrails.sh](../scripts/release_checks/guardrails.sh) | `python3 scripts/route_golden_tests.py` |
| 项目根状态 / guardrails | [project_guardrails_protocol.md](project_guardrails_protocol.md), [project_init_flow.md](project_init_flow.md) | [detect_project_root_state.py](../scripts/detect_project_root_state.py), [check_project_guardrails.sh](../scripts/check_project_guardrails.sh), [init_project_guardrails.py](../scripts/init_project_guardrails.py), [hook_check_project_guardrails.sh](../scripts/hook_check_project_guardrails.sh) | [guardrails.sh](../scripts/release_checks/guardrails.sh) | `bash scripts/release_checks/guardrails.sh` |
| 阶段门禁 / 写入权限 | [SKILL.md](../SKILL.md), [decision_and_question_protocol.md](decision_and_question_protocol.md), [task_runtime_prompt.md](task_runtime_prompt.md) | [gate_check.py](../scripts/gate_check.py), [hook_check_project_guardrails.sh](../scripts/hook_check_project_guardrails.sh), [controller.py](../scripts/controller.py) | [gates.sh](../scripts/release_checks/gates.sh) | `bash scripts/release_checks/gates.sh` |
| session / 等待态 / 恢复 | [session_management.md](session_management.md), [phase_checkpoint.md](phase_checkpoint.md), [task_runtime_prompt.md](task_runtime_prompt.md) | [ff_session.sh](../scripts/ff_session.sh), [controller.py](../scripts/controller.py) | [session.sh](../scripts/release_checks/session.sh), [gates.sh](../scripts/release_checks/gates.sh) | `bash scripts/release_checks/session.sh` |
| `ff-fast` / `ff-a` 策略 | [fast_mode.md](fast_mode.md), [autonomous_mode.md](autonomous_mode.md), [decision_and_question_protocol.md](decision_and_question_protocol.md), [SKILL.md](../SKILL.md) | [classify_task.sh](../scripts/classify_task.sh), [gate_check.py](../scripts/gate_check.py), [validate_output.sh](../scripts/validate_output.sh) | [guardrails.sh](../scripts/release_checks/guardrails.sh), [gates.sh](../scripts/release_checks/gates.sh), [output_protocol.sh](../scripts/release_checks/output_protocol.sh) | `python3 scripts/route_golden_tests.py` + `bash scripts/release_checks/output_protocol.sh` |
| 输出日志 / 可见性协议 | [skill_visibility.md](skill_visibility.md), [task_runtime_prompt.md](task_runtime_prompt.md), [phase_checkpoint.md](phase_checkpoint.md) | [validate_output.sh](../scripts/validate_output.sh) | [output_protocol.sh](../scripts/release_checks/output_protocol.sh) | `bash scripts/release_checks/output_protocol.sh` |
| 角色 checklist / Rubric | [roles/requirement_analyst.md](roles/requirement_analyst.md), [roles/verify_agent.md](roles/verify_agent.md), [rubric_evaluation.md](rubric_evaluation.md) | [validate_checklist.py](../scripts/validate_checklist.py), [validate_rubric.py](../scripts/validate_rubric.py), [validate_rubric_evaluation.py](../scripts/validate_rubric_evaluation.py) | [checklists.sh](../scripts/release_checks/checklists.sh), [rubric_evaluation.sh](../scripts/release_checks/rubric_evaluation.sh) | `bash scripts/release_checks/checklists.sh` + `bash scripts/release_checks/rubric_evaluation.sh` |
| 角色隔离 / 写入边界 | [agent_isolation_protocol.md](agent_isolation_protocol.md), [roles/](roles) | [controller.py](../scripts/controller.py), [gate_check.py](../scripts/gate_check.py) | [gates.sh](../scripts/release_checks/gates.sh) | `bash scripts/release_checks/gates.sh` |
| 文档链接 / 脚本引用 | [load_map.md](load_map.md), [maintenance_map.md](maintenance_map.md), 用户入口文档 | [validate_docs_sync.py](../scripts/validate_docs_sync.py) | [output_protocol.sh](../scripts/release_checks/output_protocol.sh) | `python3 scripts/validate_docs_sync.py` |
| 调试方法论 | [systematic_debugging.md](systematic_debugging.md), [engineering_heuristics.md](engineering_heuristics.md), [SKILL.md](../SKILL.md)（核心原则第 14 条） | [validate_output.sh](../scripts/validate_output.sh) | [output_protocol.sh](../scripts/release_checks/output_protocol.sh) | `python3 scripts/validate_docs_sync.py` |
| TDD 纪律 | [tdd_discipline.md](tdd_discipline.md), [SKILL.md](../SKILL.md)（目标治理第 8 条）, [roles/page_engineer.md](roles/page_engineer.md) | [validate_checklist.py](../scripts/validate_checklist.py) | [checklists.sh](../scripts/release_checks/checklists.sh) | `bash scripts/release_checks/checklists.sh` |
| 模型选择策略 | [model_selection.md](model_selection.md), [host_subagent_support.md](host_subagent_support.md) | - | - | `python3 scripts/validate_docs_sync.py` |
| forge controller 通用协议 | [forge_controller_protocol.md](forge_controller_protocol.md), [task_runtime_prompt.md](task_runtime_prompt.md), [agent_isolation_protocol.md](agent_isolation_protocol.md) | [classify_task.sh](../scripts/classify_task.sh), [gate_check.py](../scripts/gate_check.py), [ff_session.sh](../scripts/ff_session.sh), [controller.py](../scripts/controller.py) | [guardrails.sh](../scripts/release_checks/guardrails.sh), [gates.sh](../scripts/release_checks/gates.sh), [session.sh](../scripts/release_checks/session.sh) | `python3 scripts/route_golden_tests.py` + `bash scripts/release_checks/session.sh` |
| P0/P1 release 绑定 | [release_bindings.json](release_bindings.json), [maintenance_map.md](maintenance_map.md) | [validate_release_bindings.py](../scripts/validate_release_bindings.py) | [release_bindings.sh](../scripts/release_checks/release_bindings.sh) | `python3 scripts/validate_release_bindings.py` |
| 发布校验框架 | [maintenance_map.md](maintenance_map.md), [release_bindings.json](release_bindings.json) | [validate_release.sh](../scripts/validate_release.sh), [release_checks/](../scripts/release_checks) | 对应 `release_checks/*.sh` | `bash scripts/validate_release.sh` |

### P0/P1 release binding index

新增或修改 P0/P1 硬规则时，必须同时完成三件事：

1. 在 [release_bindings.json](release_bindings.json) 增加或更新绑定。
2. 在对应 `scripts/release_checks/*.sh` 或 golden fixture 增加正反例断言。
3. 在本索引保留对应的 `release_binding:` 标记，确保 `python3 scripts/validate_release_bindings.py` 能反查到 active docs。

当前绑定清单：

- release_binding: RB-ROUTE-001 — 触发词与路由边界
- release_binding: RB-GUARDRAILS-001 — 项目根状态与 guardrails 状态
- release_binding: RB-GATE-001 — S4 前写入门禁
- release_binding: RB-GATE-002 — 核心任务定义与退出锁门禁
- release_binding: RB-SESSION-001 — 等待态与恢复
- release_binding: RB-SESSION-002 — 迭代控制决策
- release_binding: RB-OUTPUT-001 — 可见输出协议
- release_binding: RB-AUTONOMOUS-001 — 全自动模式边界
- release_binding: RB-CHECKLIST-001 — 角色 checklist 与 Rubric
- release_binding: RB-RUBRIC-EVAL-001 — Rubric 评分证据协议
- release_binding: RB-DOCS-001 — 文档链接与脚本引用同步
- release_binding: RB-BINDINGS-001 — release binding 注册表完整性

## 1. 改阶段门禁

必看：

- [SKILL.md](../SKILL.md)
- [decision_and_question_protocol.md](decision_and_question_protocol.md)
- [task_runtime_prompt.md](task_runtime_prompt.md)

必改：

- [SKILL.md](../SKILL.md)
- [scripts/gate_check.py](../scripts/gate_check.py)
- [scripts/release_checks/gates.sh](../scripts/release_checks/gates.sh)

如果门禁依赖 session 状态，还要改：

- [session_management.md](session_management.md)
- [scripts/ff_session.sh](../scripts/ff_session.sh)
- [scripts/controller.py](../scripts/controller.py)

验收：

- 至少新增一个 block 反例和一个 allow 正例。
- `gate_check.py` 返回的 `gate` ID 必须与 release 断言一致。
- 运行 `bash scripts/release_checks/gates.sh`。

## 2. 改 session 字段

必改：

- [session_management.md](session_management.md)
- [scripts/ff_session.sh](../scripts/ff_session.sh)

通常还要改：

- [scripts/gate_check.py](../scripts/gate_check.py)
- [scripts/controller.py](../scripts/controller.py)
- [scripts/release_checks/session.sh](../scripts/release_checks/session.sh)
- [scripts/release_checks/gates.sh](../scripts/release_checks/gates.sh)

验收：

- `ff_session.sh init/read/update/validate` 能读写新字段。
- 如果字段参与恢复，补 `check-resume` / `consume-resume` 用例。
- 运行 `bash scripts/release_checks/session.sh`。

## 3. 改角色边界

必改：

- [roles/requirement_analyst.md](roles/requirement_analyst.md)
- [roles/ui_designer.md](roles/ui_designer.md)
- [roles/architecture_designer.md](roles/architecture_designer.md)
- [roles/page_engineer.md](roles/page_engineer.md)
- [roles/verify_agent.md](roles/verify_agent.md)

如果角色边界涉及文件写入权限，还要改：

- [scripts/gate_check.py](../scripts/gate_check.py)
- [agent_isolation_protocol.md](agent_isolation_protocol.md)

如果角色输出 schema 变化，还要改：

- [scripts/validate_checklist.py](../scripts/validate_checklist.py)
- [scripts/validate_rubric_evaluation.py](../scripts/validate_rubric_evaluation.py)（涉及 S5 Rubric 评分块时）
- [tests/checklist_fixtures/](../tests/checklist_fixtures)
- [scripts/release_checks/checklists.sh](../scripts/release_checks/checklists.sh) 或 [scripts/release_checks/rubric_evaluation.sh](../scripts/release_checks/rubric_evaluation.sh)（需要 release 级断言时）

验收：

- 对应角色的 pass fixture 必须通过。
- 至少保留一个缺字段/占位符反例。
- Rubric 评估协议变更必须同时保留一个正例和一个失败反例；L3/L4 证据规则要覆盖 `code_review_only` 降级。

## 4. 改 `ff-fast` / `ff-a` 豁免边界

必改：

- [SKILL.md](../SKILL.md)
- [fast_mode.md](fast_mode.md)
- [autonomous_mode.md](autonomous_mode.md)
- [decision_and_question_protocol.md](decision_and_question_protocol.md)

通常还要改：

- [scripts/gate_check.py](../scripts/gate_check.py)
- [scripts/release_checks/gates.sh](../scripts/release_checks/gates.sh)
- [scripts/release_checks/output_protocol.sh](../scripts/release_checks/output_protocol.sh)

验收：

- 路由 golden 覆盖策略判定。
- gate release 覆盖豁免和不豁免两边。
- 输出协议 release 覆盖启动日志和收口摘要。

## 5. 改 output protocol / 日志协议

必改：

- [skill_visibility.md](skill_visibility.md)
- [task_runtime_prompt.md](task_runtime_prompt.md)
- [scripts/validate_output.sh](../scripts/validate_output.sh)

通常还要改：

- [scripts/release_checks/output_protocol.sh](../scripts/release_checks/output_protocol.sh)
- [README.md](../README.md)

验收：

- 新日志必须有正例。
- 缺日志、错顺序、错角色名前缀必须有反例。
- 运行 `bash scripts/release_checks/output_protocol.sh`。

## 6. 改 project guardrails 协议

必改：

- [project_guardrails_protocol.md](project_guardrails_protocol.md)
- [scripts/check_project_guardrails.sh](../scripts/check_project_guardrails.sh)
- [scripts/init_project_guardrails.py](../scripts/init_project_guardrails.py)

通常还要改：

- [scripts/hook_check_project_guardrails.sh](../scripts/hook_check_project_guardrails.sh)
- [scripts/release_checks/guardrails.sh](../scripts/release_checks/guardrails.sh)

验收：

- 覆盖 `empty_new` / `flutter_existing` / `non_flutter`。
- 覆盖 `missing` / `found` / stale 或 refresh 相关状态。
- 运行 `bash scripts/release_checks/guardrails.sh`。

## 7. 改发布校验

入口：

- [scripts/validate_release.sh](../scripts/validate_release.sh)

按领域改对应模块：

- 元数据与版本：`scripts/release_checks/metadata.sh`
- guardrails 与路由：`scripts/release_checks/guardrails.sh`
- session：`scripts/release_checks/session.sh`
- gate 与 controller：`scripts/release_checks/gates.sh`
- 日志与输出协议：`scripts/release_checks/output_protocol.sh`

原则：

- 不要再把新的大段逻辑直接塞回 `validate_release.sh`
- 优先在对应模块文件里新增/修改断言
- 每个 P0/P1 协议变化必须有一个 release 反例，否则只算文档承诺，不算落地
- release 断言不要复制实现逻辑，只断言工具真实输出
- 新增或修改 P0/P1 规则时，同步 [release_bindings.json](release_bindings.json)，并确保 `python3 scripts/validate_release_bindings.py` 通过

## 8. 改入口文档

用户入口：

- [README.md](../README.md)
- [QUICKSTART.md](../QUICKSTART.md)
- [CHEATSHEET.md](../CHEATSHEET.md)

维护入口：

- [load_map.md](load_map.md)
- [maintenance_map.md](maintenance_map.md)

## 9. 先查哪里，再动哪里

推荐顺序：

1. 先看 [core_contracts.yaml](core_contracts.yaml) 确认当前主数据项
2. 再看这份 `maintenance_map.md` 找出受影响文件
3. 修改权威文档和执行脚本
4. 补对应 `release_checks/*.sh` 正反例
5. 跑领域最小验收命令
6. 最后跑 `bash scripts/validate_release.sh`

## 10. 不要这样改

- 只改 `SKILL.md`，不改脚本和 release check。
- 只改脚本，不更新角色合约或 reference 文档。
- 只改 pass fixture，不加失败反例。
- 在 `validate_release.sh` 里堆大段新逻辑，而不是放到对应 `release_checks/*.sh`。
- 让 archive 历史文档决定当前 release 是否通过；archive 只能作为背景，不应成为当前协议权威源。
