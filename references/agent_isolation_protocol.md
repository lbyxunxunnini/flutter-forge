# Flutter Forge Reference - Agent Isolation Protocol

flutter-forge 的 5 个角色（需求分析师、UI 设计师、架构设计师、页面工程师、验证工程师）通过隔离子代理执行，避免单 LLM 上下文污染和角色越权。

## 架构

```text
controller.py (决策引擎)
    ├── 选择角色 → choose_role(phase, mode)
    ├── 读取角色合约 → references/roles/<role>.md
    ├── 组装上下文 → session + guardrails + user_input
    └── 生成 agent_prompt → 完整隔离提示词
         ↓
SKILL.md (执行器)
    ├── 调用 Agent tool 启动子代理
    ├── 子代理携带独立上下文执行
    └── 返回结果给主控
```

## 子代理启动流程

### 1. 主控调用 controller 生成提示词

```bash
python3 scripts/controller.py generate-agent-prompt \
  --project-root <project_root> \
  --user-input "<用户输入>" \
  --role <role_name>  # 可选，省略时从 session 自动检测
```

输出 JSON：

```json
{
  "role": "page_engineer",
  "role_display": "页面工程师",
  "phase": "S4",
  "mode": "页面开发",
  "agent_prompt": "完整的隔离提示词...",
  "context": {
    "project_root": "/path/to/project",
    "session": {...},
    "guardrails_summary": "..."
  }
}
```

### 2. SKILL.md 使用 Agent tool 启动子代理

主控读取 `agent_prompt`，通过 Claude Code 的 Agent tool 启动子代理：

- 每个子代理拥有独立上下文，不共享主控对话历史
- 子代理只能看到 controller 组装的上下文（角色合约 + session + 护栏 + 用户输入）
- 子代理无法访问其他角色的输出或主控的决策过程

### 3. 子代理返回结果

子代理完成执行后，结果返回主控。主控根据结果决定：
- 是否需要调用下一个角色
- 是否需要将结果传递给下游角色作为上下文
- 是否需要上报用户确认

## 角色隔离边界

| 角色 | 可以做 | 不可以做 |
|------|--------|----------|
| 需求分析师 | 确定任务目标、需求边界、确认清单 | 决定 UI 结构、状态管理、目录结构 |
| UI 设计师 | 判断页面结构、信息层级、交互边界 | 决定状态管理、路由、模块归属 |
| 架构设计师 | 决定模块归属、状态方案、路由方案 | 重定义业务目标、覆盖 UI 决策 |
| 页面工程师 | 修改代码、本地实现判断、必要验证 | 重定义需求、私改架构方向 |
| 验证工程师 | 质量门禁检查、回归验证 | 重定义需求、重写架构 |

## 代码强制边界（Gate 5）

`gate_check.py` 基于 session 的 `活跃代理` 字段强制执行文件写入权限：

| 角色 | 允许写入 | 阻断写入 |
|------|---------|---------|
| requirement_analyst | metadata | implementation, project_config, core_shared, router, state, test |
| ui_designer | metadata | implementation, project_config, core_shared, router, state, test |
| architecture_designer | metadata | implementation, project_config, core_shared, router, state, test |
| page_engineer | implementation, core_shared, router, state, test | metadata, project_config |
| verify_agent | test, metadata | implementation, project_config, core_shared, router, state |
| controller | 不限制 | - |

hook 在每次写操作时自动检查，越权写入直接 block。不依赖 LLM 自觉。

## 上下文传递

子代理之间的上下文传递通过 controller 中转：

1. **需求分析师** → 产出需求冻结摘要包 + 品质锚定 + Rubric 条目 → controller 传递给下游
2. **UI 设计师** → 产出 UI 冻结摘要包 → controller 传递给下游
3. **架构设计师** → 产出架构冻结摘要包 + 工作包列表 → controller 传递给实现
4. **页面工程师** → 产出实现结果 + 验证结果 → controller 传递给验证
5. **验证工程师** → 产出验证结论 + Rubric 评分 → controller 决定是否通过

摘要包格式见 `references/archive/role_handoff_formats.md`。

## 信息隔离矩阵

引入 Rubric 评测后，执行者和评估者之间的信息可见性隔离至关重要。以下矩阵定义 7 类信息的可见性规则：

| 信息类型 | page_engineer 可见？ | verify_agent 可见？ | 说明 |
|---------|---------------------|-------------------|------|
| 需求冻结摘要包 | 是 | 是 | 双方均需理解需求目标 |
| 改动契约 | 是 | 是 | 双方均需理解改动范围 |
| 具体 Rubric 条目 | **否**（只知大致验收标准） | 是 | 防止执行者针对性优化而非真正做好功能 |
| 品质锚定（quality_tier） | 是（知道 tier） | 是 | 执行者需知道品质期望水平 |
| page_engineer 实现思路/注释 | 是 | **否** | 防止评估者因了解实现过程而产生正面偏见 |
| page_engineer 自评 checklist | 是 | **否** | 自评是执行者内部产物，不传递给评估者 |
| 前几轮评分记录 | **否** | 是 | 评估者需参考历史评分判断边际改善 |
| guardrails 摘要 | 是 | 是 | 双方均需遵守项目级约束 |

### controller 组装上下文时的过滤规则

**组装 page_engineer 上下文时**：传入需求冻结摘要包（含 `quality_tier`，不含具体 Rubric 条目）+ 改动契约 + guardrails 摘要。不传入：Rubric 条目详情、前几轮评分记录、verify_agent 的评估报告。

**组装 verify_agent 上下文时**：传入需求冻结摘要包 + Rubric 条目 + 代码文件路径 + 前几轮评分记录（如有）。不传入：page_engineer 的 checklist 输出、实现过程的 `[f-forge]` 日志、page_engineer 的实现思路注释。

### 迭代循环中的信息传递

当 S5→S4 回退时（迭代循环），controller 向 page_engineer 传递的是 verify_agent 输出的**结构化改进建议**（列出 FAIL 的 Rubric 条目 ID 和改进方向），而非完整的 Rubric 评分详情。这确保 page_engineer 知道"改什么"但不知道"怎么评分"。

## 降级路径

当 Agent tool 不可用（如宿主不支持子代理）时，降级为串行单 LLM 模式：

1. 主控按角色顺序依次执行
2. 每个角色的输出作为下一个角色的输入上下文
3. 通过 session 的 `活跃代理` 字段标记当前执行角色
4. 角色切换时输出 `[f-forge] 角色切换：xxx → yyy`

## 与大任务并行的关系

大任务并行（S3 拆包 → 多 impl-agent 并行 → verify-agent 收口）依赖宿主支持真实子代理。详见 `references/host_subagent_support.md`。

本协议中的"隔离子代理"是基础能力——即使不并行，每个角色也应该在独立上下文中执行，防止角色越权和上下文污染。
