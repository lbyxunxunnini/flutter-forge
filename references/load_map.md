# Flutter Forge Reference - Load Map

这个文件定义主 skill 之外的按需加载映射。主 `SKILL.md` 不再重复列出大量"遇到什么就读什么"的声明。

归档文件（案例、模板、调试手册等低频参考）已移入 [archive/](archive/) 目录，需要时可直接读取。

## 场景 -> 参考文件

### 迭代中项目首次接入

- [project_init_flow.md](project_init_flow.md)
- [existing_project_entry.md](existing_project_entry.md)
- [existing_project_scan.md](existing_project_scan.md)
- [flutter_stack_detection.md](flutter_stack_detection.md)
- [stack_profiles.md](stack_profiles.md)
- [project_guardrails_template.yaml](project_guardrails_template.yaml)
- [example_project_guardrails.yaml](example_project_guardrails.yaml)
- [existing_rules_discovery.md](existing_rules_discovery.md)

### 新 Flutter 应用从 0 到 1

- [new_project_cocreation_mode.md](new_project_cocreation_mode.md)
- [stack_profiles.md](stack_profiles.md)
- [project_init_flow.md](project_init_flow.md)
- [project_guardrails_template.yaml](project_guardrails_template.yaml)

### 进入具体任务执行

- [fast_mode.md](fast_mode.md)
- [autonomous_mode.md](autonomous_mode.md)
- [decision_and_question_protocol.md](decision_and_question_protocol.md)
- [task_runtime_prompt.md](task_runtime_prompt.md)

### 需要记忆读写规则

- [memory_protocol.md](memory_protocol.md)
- [core_contracts.yaml](core_contracts.yaml)

### 需要工程判断标准或 Flutter 专项规则

- [engineering_heuristics.md](engineering_heuristics.md)
- [flutter_stack_detection.md](flutter_stack_detection.md)
- [stack_profiles.md](stack_profiles.md)

### 需要 Flutter skills 委托规则

- [official_flutter_skills.md](official_flutter_skills.md)
- [delegation_map.yaml](delegation_map.yaml)

### 需要判断宿主对子代理的支持与降级路径

- [host_subagent_support.md](host_subagent_support.md)
- [agent_isolation_protocol.md](agent_isolation_protocol.md)

### 需要网络层项目规则

- [network_and_api.md](network_and_api.md)

### 需要路由层项目规则

- [routing_and_navigation.md](routing_and_navigation.md)

### 需要测试与质量建议

- [roles/verify_agent.md](roles/verify_agent.md)
- [rubric_evaluation.md](rubric_evaluation.md)

### S4 实现中遇到 bug 或异常

- [systematic_debugging.md](systematic_debugging.md)
- [engineering_heuristics.md](engineering_heuristics.md)

### S4 实现中需要 TDD 纪律

- [tdd_discipline.md](tdd_discipline.md)
- [rubric_evaluation.md](rubric_evaluation.md)

### 需要模型选择建议

- [model_selection.md](model_selection.md)
- [host_subagent_support.md](host_subagent_support.md)

### Session Hook 配置

- hooks/hooks.json
- hooks/session_start.sh

### 需要 Rubric 评测或品质标准

- [rubric_evaluation.md](rubric_evaluation.md)
- [roles/verify_agent.md](roles/verify_agent.md)（Rubric 评分协议）
- [roles/requirement_analyst.md](roles/requirement_analyst.md)（Rubric 生成 + 品质锚定）
- [release_bindings.json](release_bindings.json)（Rubric P0/P1 release 反例绑定）

### 需要决策、提问或阶段门禁细则

- [decision_and_question_protocol.md](decision_and_question_protocol.md)
- [fast_mode.md](fast_mode.md)
- [autonomous_mode.md](autonomous_mode.md)
- [phase_checkpoint.md](phase_checkpoint.md)
- [gate_definitions.md](gate_definitions.md)

### 需要输出日志格式

- [logging_format.md](logging_format.md)
- [skill_visibility.md](skill_visibility.md)

### 需要可见性标记或当前大任务状态规则

- [skill_visibility.md](skill_visibility.md)
- [session_management.md](session_management.md)

### 需要启动握手输出格式

- [startup_handshake.md](startup_handshake.md)

### 需要 Project Guardrails 协议

- [project_guardrails_protocol.md](project_guardrails_protocol.md)

### 需要项目初始化流程

- [project_init_flow.md](project_init_flow.md)

### 需要触发词权威列表

- [trigger_words.md](trigger_words.md)

### 需要主工作流可视化

- [workflow_diagram.md](workflow_diagram.md)

### 需要维护者修改导航

- [maintenance_map.md](maintenance_map.md)
- [release_bindings.json](release_bindings.json)

### 需要 forge 系列 controller 抽象

- [forge_controller_protocol.md](forge_controller_protocol.md)
- [maintenance_map.md](maintenance_map.md)

## 反向索引：每个参考文件被哪些上层文件引用

维护时用此表检查引用完整性。新增 reference 文件时同步更新此表。

| 参考文件 | 被引用方 |
|---------|---------|
| task_runtime_prompt.md | SKILL.md（执行协议）、load_map.md |
| phase_checkpoint.md | task_runtime_prompt.md（阶段转换自检）、load_map.md |
| fast_mode.md | SKILL.md（ff-fast）、load_map.md |
| autonomous_mode.md | SKILL.md（ff-a）、load_map.md |
| decision_and_question_protocol.md | task_runtime_prompt.md、skill_visibility.md、load_map.md |
| skill_visibility.md | SKILL.md（输出日志）、load_map.md |
| session_management.md | SKILL.md（上下文恢复）、load_map.md |
| startup_handshake.md | SKILL.md（启动判定）、load_map.md |
| project_guardrails_protocol.md | SKILL.md（guardrails 检查）、load_map.md |
| project_init_flow.md | SKILL.md（项目初始化）、load_map.md |
| memory_protocol.md | SKILL.md（记忆机制）、load_map.md |
| core_contracts.yaml | maintenance_map.md、load_map.md |
| engineering_heuristics.md | load_map.md |
| flutter_stack_detection.md | load_map.md |
| stack_profiles.md | load_map.md |
| official_flutter_skills.md | SKILL.md（Flutter skills）、load_map.md |
| delegation_map.yaml | load_map.md |
| host_subagent_support.md | SKILL.md（并行协议）、load_map.md |
| network_and_api.md | load_map.md |
| routing_and_navigation.md | load_map.md |
| roles/verify_agent.md | load_map.md |
| rubric_evaluation.md | SKILL.md（目标治理）、roles/verify_agent.md（评分协议）、roles/requirement_analyst.md（Rubric 生成）、agent_isolation_protocol.md（隔离对象）、load_map.md |
| systematic_debugging.md | SKILL.md（核心原则第 14 条）、load_map.md |
| tdd_discipline.md | SKILL.md（目标治理第 8 条）、roles/page_engineer.md（test-first 条款）、load_map.md |
| model_selection.md | host_subagent_support.md（第 10 节）、load_map.md |
| agent_isolation_protocol.md | SKILL.md（角色隔离执行 + 目标治理信息隔离）、load_map.md |
| trigger_words.md | SKILL.md（命中路由）、README.md、QUICKSTART.md、CHEATSHEET.md、load_map.md |
| workflow_diagram.md | SKILL.md（按需加载）、load_map.md |
| maintenance_map.md | load_map.md |
| release_bindings.json | maintenance_map.md、load_map.md、rubric_evaluation.md 相关 release 绑定、scripts/validate_release_bindings.py |
| forge_controller_protocol.md | load_map.md、maintenance_map.md |
| gate_definitions.md | SKILL.md（阶段门禁）、load_map.md |
| logging_format.md | SKILL.md（输出日志）、load_map.md |
