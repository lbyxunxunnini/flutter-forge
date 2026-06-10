# Flutter Forge Reference - Rubric 评测框架

本文档定义 flutter-forge 的 Rubric 评测体系。Rubric 在 S1 需求确认阶段由需求分析师生成，在 S5 验证阶段由验证工程师逐条评分，评分结果驱动迭代循环。

## 核心理念

验证体系不仅回答"做对了吗"（二元判定），更要回答"做得有多好"（量化评分）。评分为迭代循环提供方向感——循环不再只问"完成了吗"，而是问"距离目标还有多远，值不值得继续跑"。

## 四层评测框架

| 层 | 名称 | 默认权重 | 关注点 |
|---|------|---------|--------|
| L1 | 功能正确性 | 0.40 | 数据逻辑、状态管理、条件分支、API 集成、Widget 行为 |
| L2 | 健壮性 | 0.25 | 空状态、错误处理、边界输入、并发时序、表单校验 |
| L3 | UI 呈现 | 0.20 | 页面完整渲染、布局合理、组件一致、响应式适配 |
| L4 | 交互体验 | 0.15 | 操作反馈、加载状态、动画过渡、无障碍支持 |

权重不是固定的——由品质锚定（`quality_anchor.quality_tier`）动态调整。

## 品质锚定 → 权重传导

`quality_tier` 在 S1 需求确认阶段由需求分析师与用户确认，直接传导到 Rubric 权重：

| quality_tier | L1 功能 | L2 健壮 | L3 UI | L4 交互 | 适用场景 |
|-------------|---------|---------|-------|---------|---------|
| mvp | 0.50 | 0.25 | 0.15 | 0.10 | 快速验证、原型、内部工具 |
| polished | 0.35 | 0.25 | 0.25 | 0.15 | 正式产品、面向用户 |
| production | 0.30 | 0.25 | 0.25 | 0.20 | 高要求产品、品牌敏感场景 |

`ff-fast` 和轻量任务豁免品质锚定，默认使用 mvp 权重。

## Rubric 条目生成协议

### 生成时机

S1 需求确认阶段，需求分析师在冻结需求后、放行前生成 Rubric 条目。Rubric 条目是需求冻结摘要包的组成部分。

### 生成依据

Rubric 条目基于以下信息源生成（按优先级排序）：

1. **冻结需求**：已确认的目标、范围、验收标准
2. **品质锚定**：`quality_tier` 决定权重分配，`design_intent` 影响 L3/L4 条目方向
3. **项目护栏**：`project_guardrails` 中的 `engineering_heuristics` 和 `performance_budget`
4. **品质红线**：`quality_anchor.quality_redlines`（如有）直接生成为 Pitfall 条目

### 四原则（基于 Scale AI *Rubrics as Rewards*）

1. **基于专家知识**：引用 `project_guardrails` 和 `engineering_heuristics` 的项目级知识，不凭空编造
2. **全面覆盖**：正向标准（Essential / Important / Optional）+ 负向 Pitfall
3. **分级权重**：Essential 1.0 / Important 0.7 / Optional 0.3 / Pitfall 0.9
4. **自包含可评判**：每条独立可操作，验证工程师不需要额外上下文即可评分

### 条目级别定义

| 级别 | 权重 | 含义 | 未通过后果 |
|------|------|------|-----------|
| Essential | 1.0 | 核心功能/关键约束，必须通过 | `essential_pass_rate` 下降；< 1.0 强制回退 S4 |
| Important | 0.7 | 重要品质标准，应当满足 | 拉低 `total_score`；影响迭代决策 |
| Optional | 0.3 | 锦上添花，可延后 | 对评分影响小；不触发回退 |
| Pitfall | 0.9 | 必须避免的反模式/已知陷阱 | `pitfall_violations` 增加；> 0 强制回退 S4 |

### 条目格式

```yaml
rubric:
  - id: L1-001
    layer: functional          # functional / robustness / ui / interaction
    level: Essential           # Essential / Important / Optional / Pitfall
    criterion: "列表正确渲染全部订单数据（条数一致、字段无缺漏）"
    verification: "运行后检查 ListView children 数量与 mock 数据一致"

  - id: L2-001
    layer: robustness
    level: Pitfall
    criterion: "空数据时不白屏，展示合理的空态 UI"
    verification: "传入空列表，检查是否渲染 EmptyState widget"

  - id: L2-002
    layer: robustness
    level: Pitfall
    criterion: "连续快速点击不触发重复请求或数据不一致"
    verification: "快速连续触发下拉刷新，检查请求去重或 loading 态阻断"

  - id: L3-001
    layer: ui
    level: Important
    criterion: "列表项布局层次清晰，信息密度合理"
    verification: "截图检查，无元素重叠、文字截断、间距异常"
    verification_method: screenshot_observation  # runtime_observation / screenshot_observation / interactive_observation / code_review_only

  - id: L4-001
    layer: interaction
    level: Optional
    criterion: "下拉刷新有平滑动画过渡"
    verification: "触发下拉刷新，检查动画流畅度和回弹效果"
    verification_method: interactive_observation
```

`verification_method` 是 L3/L4 条目的证据类型标记。S1 生成 Rubric 时可以给出预期方法；S5 实际评分时必须记录真实采用的方法。若验证阶段没有截图、设备运行、浏览器或模拟器交互证据，L3/L4 评分必须降级为 `code_review_only`，不能写成“看起来正常”。

### 条目数量指引

- 小型任务（单页面 / 单组件）：6-10 条
- 中型任务（跨 2-3 个页面 / 模块）：10-18 条
- 大型任务（完整业务闭环）：18-30 条
- 每层至少 1 条；Pitfall 至少 2 条（L2 层必须有防白屏和防重复操作）

## verify_agent 评分协议

### 评分输出格式

verify_agent 在 S5 阶段除了输出 Mandatory Checklist 外，额外输出 Rubric 评分块：

```yaml
rubric_evaluation:
  total_score: 3.85           # 加权总分（0-5）
  layer_scores:
    functional: 4.2
    robustness: 3.0
    ui: 3.5
    interaction: 4.0
  essential_pass_rate: 0.85   # Essential 条目通过率（0.0-1.0）
  pitfall_violations: 2       # Pitfall 条目违反数量
  details:
    - id: L1-001
      result: PASS
      score: 5
      evidence: "ListView 渲染 15 条数据，与 mock 一致"
    - id: L2-001
      result: FAIL
      score: 1
      evidence: "空数据时渲染了空白 Container，无空态提示"
      improvement_hint: "添加 EmptyState widget，参考 project_guardrails 的空态规范"
    - id: L2-002
      result: FAIL
      score: 2
      evidence: "连续快速下拉刷新触发了 3 次重复请求"
      improvement_hint: "添加 loading 态阻断或在请求期间禁用 RefreshIndicator"
    - id: L3-001
      result: WARN
      score: 4
      verification_method: code_review_only
      evidence: "未进行视觉验证；基于代码审查确认使用约束布局且未发现固定宽度"
      limitation: "无截图或设备运行证据，不能背书最终视觉观感"
```

### 评分规则

- 每条 Rubric 条目评分 1-5 分（1=完全不满足，5=完全满足）
- `total_score` = Σ(条目评分 × 条目权重 × 层权重) / Σ(条目权重 × 层权重)
- `essential_pass_rate` = Essential 条目中评分 ≥ 3 的比例
- `pitfall_violations` = Pitfall 条目中评分 < 3 的数量
- `layer_scores` = 各层条目的加权平均分
- L3/L4 或 `ui`/`interaction` 评分明细必须包含 `verification_method`
- `verification_method: code_review_only` 时，`evidence` 或 `limitation` 必须明确写出未进行视觉/交互验证及证据限制

### 评分与迭代循环联动

评分结果直接驱动 S5 的迭代决策（详见 SKILL.md 门禁 G17/G18）：

| 条件 | 动作 |
|------|------|
| `essential_pass_rate < 1.0` 或 `pitfall_violations > 0` | 强制回退 S4，附带结构化改进建议 |
| `total_score < score_threshold` 且 `current_round < max_rounds` 且 `marginal_improvement > 0.1` | 回退 S4，传递 FAIL 条目作为改进重点 |
| `total_score < score_threshold` 且 `marginal_improvement ≤ 0.1` 连续 2 轮 | 边际效益警告，询问用户 |
| `total_score < score_threshold` 且 `current_round >= max_rounds` | 最大轮次警告，询问用户 |
| `total_score >= score_threshold` 且 `essential_pass_rate == 1.0` 且 `pitfall_violations == 0` | 允许进入 S6 |

## 迭代建议输出

当 decision 为 `back_to_implementation` 时，verify_agent 必须在评分块之后输出结构化改进建议：

```text
[f-forge] 验证工程师：迭代建议（第 N 轮）
- 改进重点：
  1. [L2-001] 空数据时不白屏 — 添加 EmptyState widget
  2. [L2-002] 连续快速点击防重复 — 添加 loading 态阻断
- 本轮评分：3.85（目标：4.0）
- 边际改善：+0.50（上轮：3.35）
```

## Pitfall 标准库

以下为通用 Pitfall 条目模板，需求分析师在生成 Rubric 时应参考并按任务场景裁剪：

| ID 前缀 | 适用层 | Pitfall 描述 | 适用场景 |
|---------|--------|-------------|---------|
| PF-WHITE | L2 | 任何状态下不允许白屏或布局塌陷 | 所有页面 |
| PF-DUP-ACT | L2 | 连续快速操作不触发重复请求或数据不一致 | 有交互操作的页面 |
| PF-DATA-LEAK | L2 | 页面退出后不保留脏数据到下一次进入 | 有表单/输入的页面 |
| PF-ORIENTATION | L3 | 横竖屏切换不导致布局崩溃 | 支持多方向的页面 |
| PF-OVERSCROLL | L4 | 列表滚动不出现越界弹性异常 | 有列表的页面 |
| PF-A11Y-TRAP | L4 | 无障碍焦点不陷入死循环 | 所有页面 |

## 降级策略

- **轻量任务 / ff-fast 未升级**：跳过 Rubric 评测，使用原有 Mandatory Checklist
- **中等任务**：生成精简 Rubric（4-6 条，每层至少 1 条），仅 Essential + Pitfall
- **无截图/运行/交互证据时**：L3/L4 评分明细必须标注 `verification_method: code_review_only`，评分只能基于代码审查推断，评估报告中必须注明"未进行视觉验证"或"未进行交互验证"；不得把代码推断包装成真实视觉观察

## 与其他文件的关系

- `references/roles/requirement_analyst.md`：S1 阶段负责生成 Rubric 条目和品质锚定
- `references/roles/verify_agent.md`：S5 阶段负责 Rubric 评分和迭代建议
- `SKILL.md`：门禁 G17/G18 基于 Rubric 评分驱动迭代循环
- `references/session_management.md`：session `iteration` 字段记录迭代状态
- `scripts/validate_rubric.py`：校验 Rubric 条目完整性
- `scripts/validate_rubric_evaluation.py`：校验 S5 Rubric 评分块，强制 L3/L4 证据方式和 `code_review_only` 降级说明
- `references/agent_isolation_protocol.md`：Rubric 条目对 page_engineer 不可见
