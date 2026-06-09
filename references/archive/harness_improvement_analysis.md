## Flutter Forge 改进方向分析

基于 Harness Engineering（实操方法论）和 Loop Engineering（底层哲学）两篇文章，对照 flutter-forge v0.3.0 现有架构的深度差距分析。

---

### 两个视角，一个结论

两篇文章看似在说不同的事。Harness Engineering 讲的是"怎么做"——Rubric 评测、品质锚定、多轮迭代循环、Agent 专业化分工。Loop Engineering 讲的是"为什么"——循环是智能的底层架构，Prompt 是目标函数，从过程控制到目标治理的转变才是本质。

但它们指向同一个结论：**flutter-forge 的过程控制已经足够强大，下一步的杠杆在目标治理。**

具体地说：你的 13 道阶段门禁（G01、G05-G16）、7 条 Global Constitution、5 个角色铁律、gate_check.py 强制文件写入权限（G08 角色边界）、32 个 session 字段、脚本管控体系——这些都是在确保 Agent "不走错路"。它们极其重要，但它们是过程控制。真正拉开产出质量差距的，是"目标定义得有多好"和"怎么判断做得好不好"——这两件事目前在 flutter-forge 中相对薄弱。

一个有启发的对比：task-driver 只有 10 条铁律、不到 30 行 SKILL.md，但"目标是唯一终点"这一条，可能比 forge 系列所有门禁更能驱动 Agent 交付好结果。因为 task-driver 把全部能量放在了目标治理上。forge 系列不需要变得像 task-driver 一样极简，但需要从 task-driver 那里借一个核心直觉——**门禁是手段，目标才是引擎。**

以下改进方向按这个逻辑组织：先强化目标端（"什么是好"），再让循环转起来（迭代驱动），最后优化过程端（协作质量）。

---

### 第一部分：强化目标端 — 让"什么是好"变得可操作

Loop Engineering 的核心洞见：写 Prompt 的人定义的不是执行步骤，而是目标、约束和价值判断。好的 Loop 不在于机制多精巧，而在于目标定义多清晰。

#### 改进一：Rubric 评测框架 — 把"什么是好"变成可评分的清单

这是两篇文章共同的最高优先级改进。Harness Engineering 用实测数据证明了它的效果（评分从 3.35 迭代到 4.66）。从 Loop Engineering 的视角看，Rubric 就是在回答"什么是好"这个价值论问题——它把抽象的品质期待拆成了可独立判断、可量化加权的检查条目。

**现状诊断**

flutter-forge 当前的验证体系本质上是二元判定：verify_agent 的 Mandatory Checklist 是 pass/fail 字段（spec_compliance: true/false），验证强度分三级但没有量化评分，回退机制是"不通过 → 回 S4"但没有评分驱动。这套机制能防止"该查的没查"，但不能回答"做得有多好"。

用 Loop Engineering 的话说：你的循环有 `evaluate()` 函数，但它只返回布尔值，不返回分数。没有分数，循环就没有方向感——它只知道"没过"或"过了"，不知道"差多远"和"哪个方向差"。

**改进方案：引入四层 Rubric 评测**

核心思路：S1 需求确认阶段生成评测 Rubric（定义"好"的标准），S5 验证阶段逐条评分（量化"好"的程度），评分结果驱动迭代循环（朝着"更好"的方向修正）。

Rubric 条目遵循 Scale AI 论文 *Rubrics as Rewards* 的四原则：基于专家知识（引用 project_guardrails 和 engineering_heuristics 的项目级知识）、全面覆盖（正向标准 + 负向 Pitfall）、分级权重（Essential 1.0 / Important 0.7 / Optional 0.3 / Pitfall 0.9）、自包含可评判（每条独立可操作）。

四层评测框架（适配 Flutter 场景）：

| 层 | 名称 | 默认权重 | 关注点 |
|---|------|---------|--------|
| L1 | 功能正确性 | 0.40 | 数据逻辑、状态管理、条件分支、API 集成、Widget 行为 |
| L2 | 健壮性 | 0.25 | 空状态、错误处理、边界输入、并发时序、表单校验 |
| L3 | UI 呈现 | 0.20 | 页面完整渲染、布局合理、组件一致、响应式适配 |
| L4 | 交互体验 | 0.15 | 操作反馈、加载状态、动画过渡、无障碍支持 |

权重不是固定的——它由"品质锚定"（改进二）动态调整。

Rubric 条目示例（以"订单列表页"为例）：

```yaml
rubric:
  - id: L1-001
    layer: functional
    level: Essential
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
```

verify_agent 评分输出改造（在现有 checklist 基础上增加 Rubric 评分）：

```yaml
rubric_evaluation:
  total_score: 3.85
  layer_scores:
    functional: 4.2
    robustness: 3.0
    ui: 3.5
    interaction: 4.0
  essential_pass_rate: 0.85
  pitfall_violations: 2
  details:
    - id: L1-001
      result: PASS
      evidence: "ListView 渲染 15 条数据，与 mock 一致"
    - id: L2-001
      result: FAIL
      evidence: "空数据时渲染了空白 Container，无空态提示"
```

**落地建议**：新增 `references/rubric_evaluation.md`，定义 Rubric 生成协议、四层框架、评分规则。改造 `references/roles/verify_agent.md` 增加 Rubric 评分输出格式。新增 `scripts/validate_rubric.py` 校验条目完整性。在 `references/load_map.md` 中增加 Rubric 相关的场景加载映射。

---

#### 改进二：品质锚定 — 让 Developer 开工前就知道"做成什么样"

**现状诊断**

S1 需求确认的 4 个核心维度（目标、范围、验收、约束）回答的是"做什么算对"，不回答"做到什么品质算好"。project_guardrails 的 `performance_budget` 是项目级工程约束（最大 Widget 嵌套层数、列表 builder 等），不是任务级的品质标杆。

Harness Engineering 的迭代 4 发现，没有品质锚定时：Developer 知道"做什么"但不知道"做成什么样"；没有参照物；Evaluator 偏向功能验收，缺乏品质性验收。

从 Loop Engineering 的视角看，这是一个**目标函数不完整**的问题。你的 Prompt（SKILL.md）定义了"重构"这个目标，但没有定义"好的重构长什么样"。AI 在循环中搜索最优解时，搜索空间的边界模糊，结果自然飘忽。

**改进方案**

在 S1 需求确认中增加品质锚定维度：

```yaml
quality_anchor:
  quality_tier: "production"        # mvp / polished / production
  positive_references:              # 正面参考
    - source: "https://example.com/app"
      annotation: "卡片式布局、信息密度适中、下拉刷新动画"
  negative_references:              # 反面参考
    - source: "Material 默认样式直出"
      annotation: "不要纯默认样式，需要品牌化定制"
  design_intent:                    # 设计意图关键词
    style: "简洁商务"
    density: "中等"
    interaction_paradigm: "卡片式、底部导航"
  quality_redlines:                 # 品质红线
    - "不允许出现白屏或布局塌陷"
    - "所有列表必须有 loading 和空态"
```

`quality_tier` 为必填（mvp/polished/production），其余为选填。ff-fast 和轻量任务豁免。

品质定位直接传导到 Rubric 权重（不是悬空的声明）：

| quality_tier | L1 功能 | L2 健壮 | L3 UI | L4 交互 |
|-------------|---------|---------|-------|---------|
| mvp | 0.50 | 0.25 | 0.15 | 0.10 |
| polished | 0.35 | 0.25 | 0.25 | 0.15 |
| production | 0.30 | 0.25 | 0.25 | 0.20 |

**落地建议**：在 `references/roles/requirement_analyst.md` 的 Mandatory Checklist 中增加 `quality_anchor` 字段。Rubric 生成时引用 quality_anchor 调整权重。

---

### 第二部分：让循环转起来 — 从线性流程到迭代循环

Loop Engineering 的核心结构就是一个 while 循环：`while not done: think → act → observe → adjust`。flutter-forge 当前的 S1→S2→S4→S5→S6 是一条线性路径，verify_agent 可以在 S5 打回 S4，但没有评分驱动的循环、没有退出条件、没有边际效益判断。

Harness Engineering 的实测数据：4 轮迭代评分从 3.35 到 4.66，核心驱动就是"评分不达标 → 带改进建议回到开发 → 重新评估"这个循环。迭代 4 进一步跑到 7 轮 7 小时全自动。

#### 改进三：评分驱动的迭代循环与退出条件

**现状诊断**

- 没有循环计数（同一任务可能被反复修，也可能只修一次就过了）
- 没有评分驱动的退出条件（通过/不通过是二元的）
- 没有边际效益判断（不知道继续迭代还有没有意义）
- 没有最大轮次限制（理论上可以无限回退）
- task-driver 有"目标未达成禁止结束"的铁律，但 forge 系列没有引入

**改进方案**

session 新增迭代管理字段：

```yaml
iteration:
  current_round: 2
  max_rounds: 5                   # S1 设定，默认 5
  score_threshold: 4.0            # S1 设定，默认 4.0
  score_history: [3.35, 3.85]
  marginal_improvement: 0.50      # 最近一轮提升幅度
  exit_reason: ""                 # score_reached / max_rounds / marginal_stall / user_override
```

S5 迭代循环逻辑：

```
verify_agent 评分完成
  │
  ├── essential_pass_rate < 0.9 或 pitfall_violations > 0
  │     → 强制回到 S4，附带结构化改进建议（列出 FAIL 的 Rubric 条目）
  │
  ├── total_score < score_threshold
  │     │
  │     ├── current_round < max_rounds 且 marginal_improvement > 0.1
  │     │     → 回到 S4，传递 FAIL 条目作为改进重点
  │     │
  │     ├── marginal_improvement <= 0.1（连续 2 轮）
  │     │     → [f-forge] 边际效益警告，询问用户：
  │     │       继续迭代 / 接受当前结果 / 重新规划
  │     │
  │     └── current_round >= max_rounds
  │           → [f-forge] 最大轮次警告，询问用户：
  │             增加轮次 / 接受当前结果
  │
  └── total_score >= score_threshold 且 essential_pass_rate == 1.0
        → 允许进入 S6
```

从 Loop Engineering 的视角看，这就是把 `done = evaluate(context, goal)` 从布尔判断升级为量化判断。循环不再只问"完成了吗"，而是问"距离目标还有多远，值不值得继续跑"。

**落地建议**：SKILL.md 阶段门禁增加 S5 迭代循环规则（新增 G17/G18）。session 新增 iteration 字段，`ff_session.sh` 增加 `iteration-update` 子命令。verify_agent 角色卡增加"迭代建议"输出。边际效益判断规则内嵌在循环逻辑中，不需要单独文件。

---

#### 改进四：verify_agent 角色升级 — 从合规审查员到挑剔评估专家

Harness Engineering 反复强调的核心观点：真正拉开差距的，是为 Agent 配备一个"足够挑剔、能够感知运行环境的评估模块"。文章的迭代 1 和 2 失败的核心原因不是循环没转起来，而是 Evaluator 不够挑剔——Agent 反馈"已经生成了所有功能"，其实只是做了表面 UI 占位。

**现状诊断**

verify_agent 的定位是"判断当前子单元是否真实达到验收标准"。5 条铁律 + Mandatory Checklist + 脚本校验，作为合规审查员已经很强。但它不是挑剔的品质评估者——它检查"是否满足规格"，不评估"做得有多好"。

用 Loop Engineering 的话说：你的 `evaluate()` 函数实现得很健壮（各种校验、各种门禁），但它缺少价值判断能力——它能判断"代码对不对"，不能判断"体验好不好"。

**改进方案**

1. **使命升级**：在 verify_agent.md 中增加品质评估维度——"你的职责不仅是判断'是否满足规格'，还要评估'做得有多好'。像一个挑剔的用户一样使用功能，像严格的 QA 一样测试边界，像资深设计师一样审视 UI。"

2. **主动测试协议**：基于 Rubric 自动生成测试操作序列，不只是"审查代码"，而是"模拟用户行为"。

```yaml
active_testing:
  test_sequences:
    - name: "正常路径"
      steps: ["打开页面", "输入数据", "提交", "验证结果"]
      expected: "数据正确保存，列表刷新"
    - name: "异常路径 - 空输入"
      steps: ["打开页面", "不输入任何内容", "提交"]
      expected: "表单校验拦截，显示错误提示"
    - name: "边界路径 - 连续操作"
      steps: ["快速连续点击提交按钮 5 次"]
      expected: "只发送一次请求，按钮在请求期间禁用"
```

3. **红队铁律**：新增第 6 条铁律——"主动寻找问题。如果你审查后没有发现任何问题，这本身就是一个红旗。重新审查，特别关注 Pitfall 类条目和可能遗漏的边界情况。"

**落地建议**：改造 `references/roles/verify_agent.md`，增加品质评估使命、主动测试协议和红队铁律。

---

### 第三部分：优化过程端 — 让协作更干净

以下改进不是为了增加更多控制，而是为了让已有的控制更精确、更高效。Loop Engineering 提醒我们：过程控制应该服务于目标治理，如果过程控制远多于目标治理，系统就会变得僵硬。

#### 改进五：执行者与评估者信息隔离

**现状诊断**

flutter-forge 已有写入权限隔离（gate_check.py 强制角色边界，门禁 G08）和角色隔离执行协议（agent_isolation_protocol.md），通过 controller 中转摘要包传递。但当前的隔离是写入权限隔离，不是信息可见性隔离。

引入 Rubric 后这个问题会更突出：page_engineer 如果看到具体 Rubric 条目，会"针对性优化"而不是真正做好功能；verify_agent 如果看到 page_engineer 的实现思路注释，会偏向正面评价。

**改进方案**

信息隔离矩阵：

| 信息类型 | page_engineer 可见？ | verify_agent 可见？ |
|---------|---------------------|-------------------|
| 需求冻结摘要包 | 是 | 是 |
| 改动契约 | 是 | 是 |
| 具体 Rubric 条目 | 否（只知大致验收标准） | 是 |
| page_engineer 实现思路/注释 | 是 | 否 |
| page_engineer 自评 checklist | 是 | 否 |
| 前几轮评分记录 | 否 | 是 |
| guardrails 摘要 | 是 | 是 |

controller 组装 verify_agent 上下文时只传入：需求冻结摘要包 + Rubric 条目 + 代码文件路径。不传入：page_engineer 的 checklist 输出、实现过程的 `[f-forge]` 日志。

**落地建议**：在 `references/agent_isolation_protocol.md` 中增加信息隔离矩阵。controller 组装 prompt 时增加过滤逻辑。

---

#### 改进六：结构化交接文件实体化

**现状诊断**

`references/archive/role_handoff_formats.md` 定义了角色返回格式，摘要包有最小结构。但这些是"角色输出的格式规范"，不是独立文件。下一个角色通过 controller 中转消费摘要包文本内容。

**改进方案**

将关键交接内容实体化为 `.flutter-forge/handoff/` 下的独立文件：

| 阶段 | 交接文件 | 产出角色 | 消费角色 |
|------|---------|---------|---------|
| S1 后 | `requirement_brief.yaml` | 需求分析师 | UI设计师、架构设计师、verify_agent |
| S2 后 | `ui_structure.yaml` | UI 设计师 | 架构设计师、页面工程师 |
| S2 后 | `architecture_decision.yaml` | 架构设计师 | 页面工程师、verify_agent |
| S4 后 | `implementation_result.yaml` | 页面工程师 | verify_agent |
| S5 后 | `evaluation_report.yaml` | verify_agent | controller、页面工程师（迭代时） |

好处：交接内容可被脚本校验；迭代循环时 Developer 可直接读上一轮 evaluation_report.yaml；人类可随时查看文件了解进度。

这也让循环中的 `observe(result)` 步骤有了持久化的载体——不再是 Agent 脑子里的临时记忆，而是落在磁盘上的可追溯记录。

**落地建议**：新增 `references/handoff_protocol.md`，定义文件路径、schema、写入时机和校验规则。扩展 `validate_checklist.py` 支持交接文件校验。

---

#### 改进七：上下文管理增强

**现状诊断**

flutter-forge 的三层记忆体系（Session / Guardrails / 跨项目偏好）和摘要包传递已经是强项。可加强两点：

1. **上下文用量感知**：Harness Engineering 提出"上下文甜区"（约窗口 40%），避免"上下文焦虑"导致过早收尾。建议在 session 中增加粗略的上下文用量估算，接近阈值时提示拆分子任务。

2. **工作包启动模板**：为 S3 的每个工作包定义标准启动上下文：

```yaml
work_package_context:
  package_id: "WP-1"
  source: ""                      # 来自哪个摘要包
  guardrails_summary: ""
  acceptance_criteria: ""
  freeze_constraints: ""
  write_scope: []
  forbidden_scope: []
  rubric_items: []                # 本工作包相关的 Rubric
```

**落地建议**：session 字段增加 context_usage_estimate。工作包启动模板加入 `references/task_runtime_prompt.md`。

---

#### 改进八：应用环境可读性

**现状诊断**

verify_agent 可以运行 `flutter analyze` 和 `flutter test`，但看不到渲染结果。Agent 写完代码后是"盲的"。

这是纯 skill 层面最难解决的，高度依赖宿主环境。但 Loop Engineering 的视角给了一个启发：**Agent 如果不能"观察"（observe），循环就断了。** `observe(result)` 是 while 循环中不可缺的一环。

**改进方案（分层策略）**

层 1（引导用户）：verify_agent 在涉及 L3/L4 Rubric 时主动请求截图——"请运行应用并截图当前页面，我来分析视觉效果。"

层 2（脚本辅助）：增加 `scripts/capture_screenshot.sh`，在支持的环境中自动截图（Flutter Web 通过 CDP、Desktop 通过系统工具、模拟器通过 adb/xcrun）。

层 3（降级策略）：无法获取视觉反馈时，对 L3/L4 Rubric 标注 `verification_method: code_review_only`，评估报告中说明"未进行视觉验证"并列出建议手动检查项。

**落地建议**：verify_agent 角色卡增加条件触发的截图请求逻辑。新增截图脚本。

---

### 总结：改进全景与优先级

| 优先级 | 改进 | 本质 | 投入产出比 | 复杂度 |
|--------|------|------|-----------|--------|
| P0 | 一、Rubric 评测框架 | 回答"什么是好" | 最高 | 高 |
| P0 | 三、迭代循环与退出条件 | 让循环转起来 | 高 | 中 |
| P1 | 二、品质锚定 | 让"好"有具体标准 | 高 | 低 |
| P1 | 四、verify_agent 角色升级 | 让评估者足够挑剔 | 中 | 低 |
| P1 | 五、信息隔离增强 | 让评估更客观 | 中 | 中 |
| P2 | 六、交接文件实体化 | 让循环中的 observe 可追溯 | 中 | 中 |
| P2 | 七、上下文管理增强 | 让循环跑得更稳 | 低 | 低 |
| P3 | 八、应用环境可读性 | 让循环不断在 observe 环节 | 高（长期） | 高 |

P0 的两项互为依赖——没有 Rubric 评分就没有迭代循环的驱动力。建议同步实施。

P1 的三项是评估体系的配套：品质锚定让 Rubric 有权重依据，verify_agent 升级让评分更客观，信息隔离让评分不受干扰。

P2/P3 在前两轮改进验证效果后再推进。

**最后一个 Loop Engineering 视角的提醒**：你的门禁体系（13 道，G01、G05-G16）已经很强了，不需要再加更多门禁。上面所有改进都不是在增加过程控制——Rubric 是目标定义，品质锚定是目标定义，迭代循环是目标驱动的反馈回路，信息隔离是目标评估的客观性保障。它们都在目标治理的层面工作。

如果后续实施过程中发现新增的规则让系统变得过于复杂，可以反过来问自己 Loop Engineering 的核心问题：**这条规则是在帮 Agent 更好地理解目标，还是在限制 Agent 的行为？** 前者留下，后者考虑是否能精简。
