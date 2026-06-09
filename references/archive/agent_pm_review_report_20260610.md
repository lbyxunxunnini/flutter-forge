# Agent PM 审查报告

- 审查日期：2026-06-10
- 项目路径：/Users/lby/Desktop/项目/ai-forge/flutter-forge
- 项目类型：skill（开发类）
- 产品评审状态：completed（技术审查 + 产品评审均完成）

---

## 技术审查

### ReviewSpec

- project_type: skill
- mode: discovery
- enabled_dimensions: 指令层、工作流层、逻辑正确性、目标治理层
- excluded_dimensions: 工具层（选检，本轮跳过）、输出层（选检）、用户交互层（选检）、设计质量（选检）、最佳实践（通过目标治理层覆盖 BP-013~016）
- max_findings: 8
- severity_threshold: P1
- checklist_version: 2026-06-10（含 Dimension 9 目标治理层）

---

### 目标治理层（Dimension 9，必检）

- `APM-GOV-001` **[P1 必须改]** status: open
  - 检查项：G-001 评估反馈体系
  - 证据：verify_agent.md Mandatory Checklist 全部字段（spec_compliance、requirement_coverage、contract_alignment、edge_cases_checked、code_quality、regression_clear、quality_checks、logs_compliant）均为 true/false 二元判定。decision 字段只有 pass / back_to_implementation / back_to_design 三个枚举值。无任何量化评分机制。
  - 影响：验证只能回答"做对了吗"，不能回答"做得有多好"。循环没有方向感——只知道"没过"或"过了"，不知道"差多远"和"哪个方向差"。
  - 建议：引入四层 Rubric 评测框架（功能正确性 0.40 / 健壮性 0.25 / UI 呈现 0.20 / 交互体验 0.15），评估条目在 S1 需求阶段生成，verify_agent 在 S5 逐条评分。
  - 验收条件：verify_agent.md 中新增 rubric_evaluation 输出格式，包含 total_score、layer_scores、essential_pass_rate、pitfall_violations；新增 references/rubric_evaluation.md 定义 Rubric 生成协议。

- `APM-GOV-002` **[P2]** status: open
  - 检查项：G-002 目标定义丰富度
  - 证据：S1 需求确认的 4 个核心维度（目标、范围、验收、约束）回答的是"做什么算对"。project_guardrails 的 performance_budget 是项目级工程约束。无任何任务级的品质标杆（quality_tier、positive_references、design_intent）定义。
  - 影响：Developer 知道"做什么"但不知道"做成什么样"。没有参照物，Evaluator 偏向功能验收，缺乏品质性验收。
  - 建议：在 S1 需求确认中增加品质锚定维度 quality_anchor（quality_tier / positive_references / negative_references / design_intent / quality_redlines）。quality_tier 传导到 Rubric 权重。
  - 验收条件：requirement_analyst.md 的 Mandatory Checklist 中新增 quality_anchor 字段；Rubric 生成时引用 quality_anchor 调整权重。

- `APM-GOV-003` **[P1 必须改]** status: open
  - 检查项：G-003 迭代循环设计
  - 证据：SKILL.md 门禁表 G01-G16 共 13 条门禁（G01、G05-G16，其中 G02/G03/G04 不存在），无一条涉及循环次数或评分驱动退出条件。verify_agent.md decision 字段无附加循环计数逻辑。S5→S4 回退路径存在，但无 max_rounds、score_threshold、marginal_improvement 任何退出机制。项目自身 archive 文档 harness_improvement_analysis.md 第 160-166 行已逐条承认此缺陷。
  - 影响：理论上可以无限回退。没有边际效益判断，不知道继续迭代还有没有意义。
  - 建议：session 新增 iteration 字段（current_round / max_rounds / score_threshold / score_history / marginal_improvement / exit_reason）。S5 增加评分驱动的迭代循环逻辑：essential_pass_rate < 0.9 强制回 S4；total_score < threshold 且未达 max_rounds 且边际改善 > 0.1 回 S4；边际改善 <= 0.1 连续 2 轮则询问用户。
  - 验收条件：SKILL.md 阶段门禁增加 S5 迭代循环规则（新增 G17/G18）；session 新增 iteration 字段定义。

- `APM-GOV-004` **[P2]** status: open
  - 检查项：G-004 执行者与评估者分离
  - 证据：写入权限隔离已完成——gate_check.py 强制角色边界（门禁 G08），agent_isolation_protocol.md 定义了 controller 中转摘要包传递。但信息可见性隔离不完整：page_engineer 可以看到 Rubric 条目（当前不存在但引入后会出问题），verify_agent 可以看到 page_engineer 的实现思路注释。降级模式下隔离协议约束力更弱。
  - 影响：引入 Rubric 后，执行者针对性优化、评估者正面偏见的风险会加剧。
  - 建议：在 agent_isolation_protocol.md 中增加信息隔离矩阵，明确 7 类信息的可见性规则。controller 组装 verify_agent 上下文时只传入需求冻结摘要包 + Rubric 条目 + 代码文件路径。
  - 验收条件：agent_isolation_protocol.md 新增完整信息隔离矩阵表。

- `APM-GOV-005` **[P1 必须改]** status: open
  - 检查项：G-005 过程控制与目标治理平衡
  - 证据：SKILL.md 过程控制类规则约 35 条（Iron Law 1 条 + Global Constitution 7 条 + 核心原则约 6 条 + P0 硬规则约 20 条 + P1 偏过程 1 条），目标治理类规则约 5 条（Global Constitution 中涉及目标 2 条 + P1 核心规则约 3 条）。比例约 7:1。多次提到"验收"但都是在过程约束语境下使用，没有定义验收标准本身应包含哪些维度、达到什么水平。
  - 影响：系统趋于僵硬。项目的能量主要花在确保 Agent 不走错路（13 道门禁、7 条宪法、35 条过程控制），但在"帮 Agent 理解什么是好结果"方面近乎空白。
  - 建议：不是减少过程控制（它们都很重要），而是增加目标治理。APM-GOV-001（Rubric）和 APM-GOV-002（品质锚定）落地后，目标治理规则自然增加。目标是在 7:1 基础上向 3:1 靠拢。
  - 验收条件：目标治理类规则数量占比不低于 20-25%（当前约 12.5%）。

- `APM-GOV-006` **[P3]** status: deferred
  - 检查项：G-006 可观测性
  - 证据：verify_agent 可运行 flutter analyze 和 flutter test（代码级检查），但看不到渲染结果。涉及 L3/L4（UI 呈现 / 交互体验）的验证只能靠代码审查推断视觉效果。
  - 影响：Agent 写完代码后是"盲的"，循环断在 observe 环节。
  - 建议：分三层策略——层 1 引导用户截图；层 2 增加 capture_screenshot.sh 脚本；层 3 降级标注 verification_method: code_review_only。
  - 验收条件：verify_agent.md 增加条件触发的截图请求逻辑。

---

### 工作流层（Dimension 3，必检）

- `APM-WORKFLOW-005` **[P1 必须改]** status: open
  - 证据：workflow_diagram.md 第 31 行节点标签为 `cocreate [label="新项目共创\nC0→C1→C2→C3→S3"]`，第 79 行路由边为 `cocreate -> s1`。节点自身标签说从 C0 起步，但路由边指向 S1。与 SKILL.md 双轨模型（第 166-168 行"C3 完成后进入 S3"）和执行要点表（第 209 行"C0→C1→C2→C3→S3"）三处矛盾。
  - 影响：Agent 参考流程图时会误入 S1（需求确认），跳过整个共创轨道 C0-C3（目标共创→技术评估→方案确认→设计冻结）。
  - 建议：将 `cocreate -> s1` 改为 `cocreate -> c0`，新建 c0 节点。
  - 验收条件：workflow_diagram.md 中 cocreate 节点的出边指向 c0，且 c0→c1→c2→c3→s3 路径完整。

- `APM-WORKFLOW-006` **[P2]** status: open
  - 证据：S5 verify_agent 可输出 `decision: back_to_implementation` 触发 S5→S4 回退。SKILL.md 门禁表 G01-G16 无任何循环终止条件。verify_agent.md 铁律 5 条均无循环计数。项目 archive 文档承认"理论上可以无限回退"。
  - 影响：极端情况下 S5↔S4 可能无限循环。
  - 建议：与 APM-GOV-003（迭代循环设计）合并解决，通过 max_rounds 字段设定上限。
  - 验收条件：同 APM-GOV-003。

- `APM-WORKFLOW-008` **[P2]** status: open
  - 证据：verify_agent.md 第 114 行 decision 字段定义 `back_to_design` 为合法枚举值。validate_checklist.py 第 115 行同样定义了该枚举。但 workflow_diagram.md 主流程图无 S5→S2 回退边。SKILL.md 门禁表无对应处理逻辑（G12 只覆盖 S4 执行中发现超范围的情况，不覆盖 S5 验证后 decision=back_to_design 的场景）。verify_agent.md 失控处理（第 73-80 行）提到"回退到 S4 或 S2"，但这是非结构化的应急指引，不是正式路径定义。
  - 影响：verify_agent 合法输出 back_to_design 时，controller 没有标准化的处理流程——不知道触发哪些门禁、如何回退到 S2、哪些状态需要重置。
  - 建议：workflow_diagram.md 增加 S5→S2 回退边。SKILL.md 门禁表增加对应条目（如"当 decision=back_to_design 时，回退到 S2，重置设计阶段状态"）。
  - 验收条件：workflow_diagram.md 有 S5→S2 边；SKILL.md 门禁表有 back_to_design 处理条目。

---

### 逻辑正确性（Dimension 4，必检）

本轮扫描发现的候选问题 APM-LOGIC-003（S5→S6 转段条件缺因果链）**未通过执行验证**，予以淘汰。

验证过程：
- 读完上下文：S5→S6 的转段条件分布在 SKILL.md（第 189-196 行）、decision_and_question_protocol.md（第 283-285 行）、task_runtime_prompt.md（第 433 行）三处，形成四层约束。
- 模拟执行：verify_agent checklist 全部 pass → 满足退出许可和工作模式锁 → 输出 [f-forge] 本轮完成日志 → 进入 S6。因果链完整，时序清晰。
- 层次判定：四层约束（验证层/门禁层/状态层/日志层）互相交叉印证，无矛盾。
- 逻辑链：checklist pass → G09（工作模式锁检查）+ G14（验证未通过禁止写收口元数据）→ 退出许可=允许 + 工作模式锁=可退出 → 输出完成日志 → S6。
- 结论：**淘汰**（S5→S6 转段条件定义完整，因果链清晰，不构成问题）。

---

### 审查小结

| 维度 | 扫描结果 |
|------|---------|
| 目标治理层 | 5 个问题（P1×3、P2×2、P3×1） |
| 工作流层 | 3 个问题（P1×1、P2×2） |
| 逻辑正确性 | 1 个候选问题经验证淘汰 |
| **合计** | **8 个有效发现**（P1×4、P2×4） |

---

## 修复计划（共 8 项）

### 必须修复（P1，阻塞）

1. APM-GOV-001 [P1] 评估反馈体系仅二元判定 → 无依赖（先修，Rubric 是其他改进的基础）
   - 验收条件：新增 rubric_evaluation.md + verify_agent.md 新增评分输出格式
2. APM-GOV-003 [P1] 迭代循环无退出条件 → 依赖 APM-GOV-001（需要评分才有循环驱动力）
   - 验收条件：session 新增 iteration 字段 + SKILL.md 新增 G17/G18 迭代门禁
3. APM-GOV-005 [P1] 过程控制与目标治理 7:1 失衡 → 与 APM-GOV-001/002 联动解决
   - 验收条件：目标治理类规则占比 ≥ 20%
4. APM-WORKFLOW-005 [P1] cocreate 入口路由到 S1 → 无依赖（独立修复）
   - 验收条件：workflow_diagram.md 中 cocreate→c0 路径正确

### Backlog（P2/P3，本轮不阻塞）

5. APM-GOV-002 [P2] 目标定义缺品质锚定 → 依赖 APM-GOV-001（Rubric 权重需要品质锚定驱动）
6. APM-GOV-004 [P2] 信息可见性隔离不完整 → 依赖 APM-GOV-001（隔离矩阵需要 Rubric 作为隔离对象）
7. APM-WORKFLOW-006 [P2] S5↔S4 无最大重试 → 合并入 APM-GOV-003
8. APM-WORKFLOW-008 [P2] back_to_design 路径未接通 → 无依赖（可独立修复）
9. APM-GOV-006 [P3] 可观测性不足 → deferred

→ 确认修复顺序？(Y/n/调整)

---

## 产品评审

- status: completed
- triggered_after: tech_review（本轮未进入修复阶段，直接做产品评审）

### 价值评定

- **痛度**：4/5（严重阻碍）
  AI 辅助编码的产出质量不稳定是行业级痛点。flutter-forge 试图用结构化流程解决这个问题，痛度感知很强。但当前验证体系的二元判定让"不稳定"难以量化追踪。

- **技术质量**：4/5（设计良好）
  双轨模型（C0-C3 共创 + S0-S6 执行）、5 角色分工、13 道阶段门禁、三层记忆体系、渐进式文档加载——架构设计水平在 AI skill 领域属于上乘。扣分点在目标治理层的系统性缺失。

- **差异化**：3.5/5（有差异）
  结构化 Flutter 协作 skill 在开源社区几乎没有同类竞品。forge 系列（flutter-forge、h5-forge、ui-forge）形成了方法论生态。但与通用编码 Agent（Cursor、Windsurf）相比，差异化主要体现在流程纪律而非产出质量。

- **ROI**：3/5（合理）
  投入了大量精力构建 30+ reference 文件、5 个角色卡、13 道门禁、校验脚本体系。产出是一套可复用的 skill 框架。ROI 合理，但当前 7:1 的过程控制/目标治理比例说明投入方向需要调整——更多精力应花在"帮 Agent 理解好结果"而非"限制 Agent 行为"。

- **Loop 成熟度**：2/5（有 pass/fail 但无量化和迭代）
  具备 evaluate() 函数（verify_agent Mandatory Checklist），但只返回布尔值。没有量化评分、没有迭代循环、没有品质锚定、没有退出条件。距离 Level 4（Rubric + 循环 + 锚定 + 退出）还有两步。

### 目标治理综合分析

> 此步骤不是列问题清单，而是从整体上回答三个核心问题。

**过程控制 vs 目标治理**：
- 过程控制规则：约 35 条（Iron Law 1 条、Global Constitution 7 条、核心原则约 6 条、P0 硬规则约 20 条、P1 偏过程 1 条）
- 目标治理规则：约 5 条（Global Constitution 中涉及目标 2 条、P1 核心规则约 3 条）
- 比例：7:1
- 判断：**严重偏向过程控制**
- 具体分析：flutter-forge 的能量绝大部分花在确保 Agent 不走错路——13 道阶段门禁防止跳阶段、7 条宪法防止越权、20 条 P0 硬规则防止各种反模式。这些都是"过程控制"，它们极其重要且设计精良。但在"帮 Agent 理解什么是好结果"方面近乎空白：没有品质标准定义（"好的页面长什么样"）、没有量化评估体系（"做得有多好"）、没有迭代改进循环（"怎么变得更好"）。结果是：Agent 非常擅长"不犯错"，但不知道"什么叫优秀"。

**最高杠杆改进方向**：
1. **Rubric 评测框架**（APM-GOV-001）— 这是整个目标治理体系的基石。有了量化评分，迭代循环才有驱动力（APM-GOV-003），信息隔离才有隔离对象（APM-GOV-004），过程控制/目标治理比例才能改善（APM-GOV-005）。一项改进连带激活三项。
2. **迭代循环与退出条件**（APM-GOV-003）— 这是让系统从"线性执行"进化为"目标驱动的反馈循环"的关键一步。当前 S1→S2→S4→S5→S6 是一条直线，加上迭代循环后变成一个 while loop：`while score < threshold and round < max: implement → evaluate → improve`。从 Loop Engineering 的视角看，这是从"过程"到"智能"的质变。

**改进依赖关系**：
- APM-GOV-001（Rubric）和 APM-GOV-003（迭代循环）**必须同步实施**——没有评分就没有循环的驱动力，没有循环评分就没有用途
- APM-GOV-002（品质锚定）应在 APM-GOV-001 之后，因为品质锚定的核心价值是调整 Rubric 权重
- APM-GOV-004（信息隔离）应在 APM-GOV-001+003 之后，因为隔离矩阵需要 Rubric 条目作为隔离对象
- APM-WORKFLOW-005（cocreate 入口 bug）和 APM-WORKFLOW-008（back_to_design 路径）**可独立实施**，与目标治理改进无关
- APM-GOV-006（可观测性）在 Rubric 引入 L3/L4 层之后才有迫切需求

### 发展方向

**短期（1-2 周）**：
- 修复两个独立的 workflow bug（APM-WORKFLOW-005 cocreate 入口、APM-WORKFLOW-008 back_to_design 路径）
- 实施 APM-GOV-001（Rubric 评测框架）+ APM-GOV-003（迭代循环）——这两项互为依赖，同步落地

**中期（3-4 周）**：
- 实施 APM-GOV-002（品质锚定）让 Rubric 有权重依据
- 实施 APM-GOV-004（信息隔离增强）让评估更客观
- 在 2-3 个真实 Flutter 任务上验证迭代循环效果，收集评分数据

**长期（1-2 月）**：
- 实施 APM-GOV-006（可观测性）补全 observe 环节
- 基于评分数据优化 Rubric 权重和层级划分
- 考虑 APM-GOV-005 的深层目标：不是增加更多目标治理规则，而是审视现有过程控制规则是否可以精简——每条规则问"是在帮 Agent 理解目标，还是在限制行为？"

### 用户接受策略

- **定位**：面向使用 AI 辅助 Flutter 开发的工程师，核心卖点是"结构化协作流程保证 AI 产出质量"。一句话介绍："让 AI 写 Flutter 代码时像有经验的团队成员一样遵循流程、接受评审、持续改进。"

- **行动清单**：
  1. 先修两个 workflow bug（5 分钟搞定），确保流程图与执行逻辑一致
  2. 在一个简单的 Flutter 页面上测试 Rubric 评测——用 verify_agent 跑一次，看评分是否合理
  3. 测试迭代循环——故意写一个有问题的实现，看 verify_agent 能否评分打回、page_engineer 能否基于评分改进
  4. 对比改进前后的产出质量——用同一个需求，分别在改进前和改进后跑一遍，对比 verify_agent 的输出差异
  5. 把品质锚定用起来——在下一个真实需求中设定 quality_tier，观察它如何影响 Rubric 权重和最终产出

---

## 交叉对照：agent-pm 审查 vs 改进分析文档

> 将 agent-pm 模拟审查的发现与 `references/archive/harness_improvement_analysis.md` 进行交叉对照，标注重叠、差异和优先级分歧。

### 重叠覆盖（两者一致）

| 改进分析文档 | agent-pm 审查 | 一致性 |
|-------------|-------------|--------|
| 改进一：Rubric 评测框架 | APM-GOV-001（评估反馈体系） | 完全一致，均判 P1/P0 |
| 改进二：品质锚定 | APM-GOV-002（目标定义丰富度） | 完全一致，均判 P2/P1 |
| 改进三：迭代循环与退出条件 | APM-GOV-003（迭代循环设计） | 完全一致，均判 P1/P0 |
| 改进四：verify_agent 角色升级 | 隐含在 APM-GOV-001 的改进建议中 | 方向一致，agent-pm 未单独立项 |
| 改进五：信息隔离增强 | APM-GOV-004（执行者与评估者分离） | 完全一致，均判 P2/P1 |
| 过程控制 vs 目标治理 7:1 | APM-GOV-005 | 完全一致（分析文档判 P1，agent-pm 按 G-005 表格判 P1） |

### agent-pm 独有发现（改进分析文档未覆盖）

| agent-pm 审查 | 说明 |
|-------------|------|
| APM-WORKFLOW-005（cocreate 入口 bug） | 改进分析文档聚焦在目标治理层面，没有逐维度扫描工作流正确性。这个 P1 bug 只有通过 checklist 驱动的系统性扫描才能发现。 |
| APM-WORKFLOW-008（back_to_design 路径缺口） | 同上。verify_agent 定义了 back_to_design 但流程图和门禁表未接通，这是工作流完整性问题，不是目标治理问题。 |
| APM-LOGIC-003 候选 → 验证淘汰 | S5→S6 转段条件被验证为完整（四层约束），展示了执行验证机制的纠错能力。 |

### 改进分析文档独有洞见（agent-pm 未覆盖）

| 改进分析文档 | 说明 |
|-------------|------|
| 改进六：交接文件实体化 | agent-pm 的 checklist 维度 9 没有专门检查交接文件持久化。BP-012（阶段间结构化交接）覆盖了概念但没有深入到文件实体化层面。 |
| 改进七：上下文管理增强 | 上下文用量感知、工作包启动模板——这些属于执行效率优化，agent-pm 的 checklist 不覆盖。 |
| 改进八：可观测性（分层策略） | agent-pm 覆盖了概念（APM-GOV-006），但改进分析文档的分层策略（引导用户→脚本辅助→降级标注）更具体、更可操作。 |
| task-driver 对比视角 | "task-driver 只有 10 条铁律，但'目标是唯一终点'这一条可能比 forge 系列所有门禁更能驱动交付"——这种跨项目的哲学对比是 agent-pm 单项目审查无法产出的。 |
| 权重传导机制 | 品质锚定 → Rubric 权重传导的具体表格（mvp/polished/production 对应不同 L1-L4 权重），agent-pm 的改进建议没有这么细。 |
| 边际效益判断逻辑 | 连续 2 轮边际改善 ≤ 0.1 触发用户询问——这种具体的循环退出策略设计，agent-pm 只指出了"缺退出条件"但没有设计具体机制。 |

### 优先级分歧

| 改进项 | 改进分析文档优先级 | agent-pm 优先级 | 说明 |
|--------|-------------------|----------------|------|
| 品质锚定（G-002） | P1 | P2 | G-002 表格定义"缺失=P2"。分析文档判 P1 是因为它是 Rubric 的配套，agent-pm 的 checklist 独立评估时倾向 P2。**agent-pm 应调整为 P1（在修复计划中标注依赖关系后升级）**。 |
| 可观测性（G-006） | P3 | P3 | 一致。 |

### 结论

agent-pm 审查覆盖了改进分析文档约 **70%** 的核心发现（6/8 项重叠），并额外发现了 2 个改进分析文档未覆盖的 workflow bug。改进分析文档在以下三个方面提供了 agent-pm 无法替代的价值：

1. **跨项目哲学对比**（task-driver vs forge 系列的极简 vs 复杂张力）
2. **具体方案设计深度**（权重传导表、边际效益阈值、交接文件 schema）
3. **改进协同效应分析**（哪些改进必须同步、哪些有先后依赖）

这正是"先用 agent-pm 审查，再交叉对照改进分析文档"这个策略的价值所在：agent-pm 提供系统性覆盖和独立验证，改进分析文档提供深度方案和元视角。两者互补而非替代。

---

## 合并修改计划

> 综合 agent-pm 审查发现和改进分析文档的方案深度，输出最终修改计划。

### 第一批：独立 bug 修复（无依赖，可立即执行）

**1. 修复 cocreate 入口路由 bug**（APM-WORKFLOW-005，P1）
- 文件：`references/workflow_diagram.md`
- 改动：将第 79 行 `cocreate -> s1` 改为 `cocreate -> c0`；新建 c0/c1/c2/c3 节点（如不存在）
- 预计工作量：5 分钟

**2. 接通 back_to_design 路径**（APM-WORKFLOW-008，P2）
- 文件：`references/workflow_diagram.md` + `SKILL.md`
- 改动：workflow_diagram.md 增加 S5→S2 回退边；SKILL.md 门禁表增加条目"当 verify_agent decision=back_to_design 时，回退到 S2，重置设计阶段状态，触发 G06（设计冻结检查）"
- 预计工作量：15 分钟

### 第二批：目标治理核心（APM-GOV-001 + APM-GOV-003 同步实施）

**3. 引入 Rubric 评测框架**（APM-GOV-001，P1）
- 新增文件：`references/rubric_evaluation.md`（Rubric 生成协议、四层框架、评分规则、Pitfall 定义）
- 修改文件：`references/roles/verify_agent.md`（增加 Rubric 评分输出格式 + 红队铁律）
- 修改文件：`references/roles/requirement_analyst.md`（S1 阶段增加 Rubric 生成职责）
- 修改文件：`references/load_map.md`（增加 Rubric 相关场景加载映射）
- 新增脚本：`scripts/validate_rubric.py`（校验 Rubric 条目完整性）
- 预计工作量：2-3 小时

**4. 增加评分驱动的迭代循环**（APM-GOV-003，P1）
- 修改文件：`SKILL.md`（session 字段增加 iteration 块；阶段门禁增加 G17 迭代循环规则、G18 边际效益检查）
- 修改文件：`references/roles/verify_agent.md`（增加"迭代建议"输出——列出 FAIL 的 Rubric 条目作为改进重点）
- 修改文件：`scripts/ff_session.sh`（增加 `iteration-update` 子命令）
- 预计工作量：1-2 小时

### 第三批：目标治理配套（依赖第二批）

**5. 增加品质锚定**（APM-GOV-002，P2→升级为 P1）
- 修改文件：`references/roles/requirement_analyst.md`（Mandatory Checklist 增加 quality_anchor 字段）
- 品质锚定 → Rubric 权重传导表写入 `references/rubric_evaluation.md`
- 预计工作量：30 分钟

**6. 增强信息隔离**（APM-GOV-004，P2）
- 修改文件：`references/agent_isolation_protocol.md`（增加信息隔离矩阵表）
- controller 组装 verify_agent 上下文时增加过滤逻辑说明
- 预计工作量：30 分钟

### 第四批：长期优化（在前三批验证效果后推进）

**7. verify_agent 角色升级**（改进分析文档改进四）
- 合并入第二批的 verify_agent.md 改造中（使命升级 + 主动测试协议 + 红队铁律）

**8. 交接文件实体化**（改进分析文档改进六）
- 新增文件：`references/handoff_protocol.md`
- 预计工作量：1 小时

**9. 可观测性增强**（APM-GOV-006，P3）
- 新增脚本：`scripts/capture_screenshot.sh`
- 修改文件：verify_agent.md（条件触发截图请求）
- 预计工作量：1 小时

### 依赖关系图

```
第一批（独立）          第二批（核心，同步）         第三批（配套）
  │                       │                          │
  ├─ W-005 cocreate bug   ├─ GOV-001 Rubric ─────────┤─ GOV-002 品质锚定
  └─ W-008 back_to_design └─ GOV-003 迭代循环 ───────┤─ GOV-004 信息隔离
                                                      └─ GOV-006 可观测性（第四批）
```

### 预期效果

完成第二批后，flutter-forge 的 Loop 成熟度预计从 Level 2 提升到 Level 4（有 Rubric + 循环 + 锚定 + 退出）。过程控制/目标治理比例预计从 7:1 改善到约 3:1。

---

## 自定义规则更新

- 本轮无新增候选规则
- 现有候选规则 CR-002（评估体系缺口）、CR-003（线性执行流程）、CR-004（执行者/评估者上下文共享）、CR-005（过程控制 >80%）均由本次审查验证为 flutter-forge 的真实问题，等待跨项目验证后可升级为正式规则

---

## 修复记录

- 本轮未执行修复，仅输出审查报告和修改计划
- 修复状态：待用户确认后执行
