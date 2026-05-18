# Agent PM Issue Ledger

本文件记录 `agent-pm` 审查发现的问题生命周期，避免后续审查重复报告已处理问题。

## flutter-forge — 2026-05-18

### Fixed

| issue_id | severity | status | summary | verification |
|---|---:|---|---|---|
| APM-WORKFLOW-001 | P1 | fixed | 轻量 / ff-fast 日志数量限制与 Mandatory Checklist 输出要求冲突 | 明确 checklist 是结构化校验产物，不计入主要 `[f-forge]` 日志限制；轻量任务顺序为开始日志 → checklist → 校验 PASS → 完成日志 |
| APM-WORKFLOW-002 | P1 | fixed | `draft` 规则卡状态在“提示确认”和“advisory 继续执行”之间不收敛 | 定义 `draft` 默认 advisory，只有首次接入、用户询问/确认、提醒阈值或高风险冲突时中断确认 |
| APM-TOOL-001 | P1 | fixed | `validate_output.sh` 无法验证进入日志、模式顺序和完成日志 | 增加进入日志、模式先于阶段、`--require-complete` 完成日志检查，并在 release validation 中加入正反例 |
| APM-TOOL-002 | P1 | fixed | `classify_task.sh` 的 `should_load_rule_card` 与运行协议不一致 | 按任务类型和置信度输出 `should_load_rule_card` 与 `rule_card_check` |
| APM-LOGIC-001 | P1 | fixed | `ff-apple` / `ff-fastlane` 被误判为 `ff-a` / `ff-fast` 策略 | 触发词策略 regex 改为空白或字符串结束边界，并加入 golden cases |
| APM-OUTPUT-001 | P2 | fixed | 输出规范“所有对外输出必须带 `[f-forge]`”与列表/YAML/diff 示例冲突 | 改为 workflow 状态行必须带前缀，解释列表、选项、YAML checklist、命令输出和 diff 可跟随状态行 |
| APM-DESIGN-001 | P2 | fixed | `SKILL.md` 与 `trigger_words.md` 重复维护完整触发词列表 | `SKILL.md` 改为引用 `trigger_words.md`，不再内联完整列表 |
| APM-WORKFLOW-003 | P1 | fixed | 轻量任务规则卡启动跳过与写操作 hook 硬阻断冲突 | `classify_task.sh --write-gate` 写入 task gate；hook 仅在 gate 明确允许且目标文件不触碰架构边界时放行无规则卡轻量/直通写入 |
| APM-WORKFLOW-004 | P1 | fixed | 空触发和首次接入提示被误分到中等任务 | `classify_task.sh` 增加 `等待态` 与 `启动握手`；route golden 增加 `ff-` 空触发和首次接入用例 |
| APM-TOOL-003 | P1 | fixed | 规则卡状态日志被 `validate_output.sh` 误判为非法角色 | 规则卡初始化、转正、刷新日志统一改为 `[f-forge] 主控：...`，release gate 增加正反例 |
| APM-LOGIC-002 | P2 | fixed | `draft_reminder_count` 只有文档承诺，没有脚本状态实现 | `check_rule_card.sh` 增加 `draft_reminder_count` 输出、`--increment-reminder` 和 `--reset-reminder` |
| APM-DESIGN-002 | P2 | fixed | 路由 golden 复制分类逻辑，不能验证真实脚本 | `route_golden_tests.py` 改为直接调用 `scripts/classify_task.sh` 并断言输出字段 |
| APM-DESIGN-003 | P1 | fixed | `SKILL.md` description 只引用 `references/trigger_words.md`，宿主召回不读取 reference 导致显式触发词失灵 | description 直接内联正式触发入口，`trigger_words.md` 改为要求 frontmatter 保留触发词，详细匹配规则仍单源维护 |

### Candidate Rules

- CR-2026-05-18-001: 可见性协议若声明 P0 日志顺序，校验脚本必须覆盖“进入日志、模式日志、阶段顺序、收口完成日志”的正反例。
- CR-2026-05-18-002: 预分类脚本输出的辅助字段必须与主运行协议的分级表保持一致，否则 LLM 会优先消费机器输出并偏离文档协议。
- CR-2026-05-18-003: 当 hook 执行硬阻断而主协议允许轻量例外时，必须有机器可读 task gate 传递最终路由结果，不能只靠自然语言说明。
- CR-2026-05-18-004: golden tests 不应复制被测脚本的核心逻辑；应调用真实入口并断言输出字段，避免实现和测试一起漂移。
