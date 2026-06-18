# Flutter Forge Reference - 阶段门禁定义

所有门禁由 `scripts/gate_check.py` 强制执行，写操作前 hook 自动检查，不满足条件直接阻断。

## 门禁矩阵

| 门禁 | 编号 | 触发条件 | 阻断原因 |
|------|------|---------|---------|
| session 不存在 | G01 | 写入实现类文件时 session 不存在 | 必须先调用 `ff_session.sh init` 初始化 session |
| 阶段未进入 S4 | G05 | 当前阶段 C0-C3/S0-S3 且未满足 S2→S4 条件 | 禁止写入实现类文件 |
| S2→S4 强制推进 | G06 | S2 已确认且改动契约已冻结，但写入非实现类 | 必须先进入 S4 |
| S5 验证阶段 | G07 | S5 阶段写入实现类文件 | 禁止写入，只允许测试和元数据 |
| 角色边界 | G08 | 活跃代理写入其职责范围外的文件 | 禁止越权写入 |
| 工作模式锁 | G09 | S6 阶段但工作模式锁激活且退出许可未打开 | 禁止 S6 收口 |
| 核心定义未冻结 | G10 | 目标/范围/验收/约束任一未确认 | 禁止进入实现 |
| 子单元未冻结 | G11 | 当前子单元未设置或状态非已冻结/实现中/待验证/已通过 | 禁止进入实现 |
| 超范围风险 | G12 | session 中超范围风险=已发现 | 必须先回退到 S2/S3 |
| 计划冲突 | G13 | session 中计划冲突状态=已发现待回退 | 必须先回退对应确认阶段 |
| 验证未通过 | G14 | S5 阶段写入收口元数据但验证状态未通过 | 禁止写入收口元数据 |
| 改动契约缺失 | G15 | 中等及以上模式但改动契约未冻结 | 必须先设置改动契约 |
| 改动契约未确认 | G16 | 改动契约已设置但未获用户确认 | 必须等待用户确认 |
| S5 迭代循环 | G17 | S5 验证完成，`essential_pass_rate < 1.0` 或 `pitfall_violations > 0` | 强制回退 S4，附带结构化改进建议（列出 FAIL 的 Rubric 条目）；session `iteration.current_round` +1 |
| S5 边际效益 | G18 | S5 验证完成，`total_score < score_threshold` 且 `marginal_improvement ≤ 0.1` 连续 2 轮 | 暂停迭代，输出边际效益警告并询问用户：继续迭代 / 接受当前结果 / 重新规划 |
| S5→S2 回退 | G12b | verify_agent `decision=back_to_design` | 回退到 S2，重置设计阶段状态，触发 G06（设计冻结检查）；session `iteration` 重置 |

## 豁免规则

- `ff-a` 全自动策略：豁免 G15、G16
- 直通模式/轻量任务：豁免 G05-G18
- 非实现类文件（metadata/test/other）：豁免大部分门禁
- `ff-fast` 未升级轻量路径：豁免 G17、G18（无 Rubric 评测则无迭代循环）

## S5 评分驱动迭代循环

verify_agent 在 S5 阶段输出 Rubric 评分后，controller 按以下逻辑决定迭代方向（详见 [rubric_evaluation.md](rubric_evaluation.md)）：

```
verify_agent 评分完成
  │
  ├── essential_pass_rate < 1.0 或 pitfall_violations > 0
  │     → [G17] 强制回退 S4，附带结构化改进建议
  │
  ├── total_score < score_threshold
  │     │
  │     ├── current_round < max_rounds 且 marginal_improvement > 0.1
  │     │     → 回退 S4，传递 FAIL 条目作为改进重点
  │     │
  │     ├── marginal_improvement ≤ 0.1（连续 2 轮）
  │     │     → [G18] 边际效益警告，询问用户：
  │     │       继续迭代 / 接受当前结果 / 重新规划
  │     │
  │     └── current_round >= max_rounds
  │           → 最大轮次警告，询问用户：
  │             增加轮次 / 接受当前结果
  │
  └── total_score >= score_threshold 且 essential_pass_rate == 1.0
        且 pitfall_violations == 0 且 decision == pass
        → 允许进入 S6
```

session `iteration` 字段记录迭代状态，通过 `scripts/ff_session.sh iteration-update` 操作。

## 硬规则补充

1. **S2 完成 → 必须进入 S4**：S2 方案确认完成后，必须输出 `[f-forge] 阶段：S4 实现中` 并开始实现。不允许在 S2 输出"结论"后退出、等待或重新分析
2. **Session 状态持久化**：每次阶段切换、等待用户输入、等待截图/文稿、等待确认或生成长文档摘要包时，必须通过 `scripts/ff_session.sh` 写入状态
3. **验证真实性**：未记录实际验证动作与验证结果前，不得输出"已完成修改并完成验证""符合预期""允许进入 S6"
4. **日志与状态分工明确**：对话可见日志由 `scripts/validate_output.sh` 校验；阶段、等待态和确认态必须通过 `scripts/ff_session.sh` 写入 session。`gate_check.py` 只消费 session 与 task gate，不消费对话日志

用户要求阶段回退时，先回退再继续。

详细阶段转换条件见 [decision_and_question_protocol.md](decision_and_question_protocol.md) 第 5 节。
