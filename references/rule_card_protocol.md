# Flutter Forge Reference - 规则卡协议

规则卡是 flutter-forge 的核心记忆文件，定义了项目规则的存储、检查和来源判定。

## 规则卡路径

项目规则卡使用项目内目录，按以下顺序查找：

1. `.claude/.flutter-forge/projects/*.rule_card.yaml`
2. `.trae/.flutter-forge/projects/*.rule_card.yaml`
3. `.agents/.flutter-forge/projects/*.rule_card.yaml`
4. `.flutter-forge/projects/*.rule_card.yaml`

查找规则：

- 优先检查 `.claude/.flutter-forge`
- 其次检查 `.trae/.flutter-forge`
- 再检查 `.agents/.flutter-forge`
- 如果前三个目录都不存在或都没有当前项目规则卡，则回退到项目根目录下的 `.flutter-forge`
- 当需要初始化正式规则卡时，按优先级在第一个存在的目录中创建；如果都不存在，优先在 `.claude/.flutter-forge/projects/` 创建

这是 **唯一正式规则卡来源范围**。

以下内容都不应视为正式规则卡来源：

- `.claude/projects/.../memory/*.yaml`
- 未命中上述四个目录的其他宿主项目记忆目录
- 仓库内示例规则卡或模板文件
- 当前会话临时总结或扫描推断

## 快速查找脚本

每次任务启动时，通过脚本完成路径解析，LLM 只消费输出结果：

```bash
scripts/check_rule_card.sh <project_root>
```

输出格式：

```text
status: found | draft | not_found
path: <相对路径或 ->
project_name: <项目名>
has_draft: true | false
draft_path: <草案相对路径或 ->
```

- `status: found` → 加载 `path` 指向的正式规则卡
- `status: draft` → 提示用户确认草案
- `status: not_found` → 进入初始化流程

LLM 禁止自行遍历上述四个路径查找规则卡。路径解析由脚本完成，确保精确匹配项目名且不跨项目污染。

## 脚本降级路径解析

仅在 `scripts/check_rule_card.sh` 不存在或执行失败（非零退出码、超时、缺依赖）时启用降级路径，**正常情况下不允许走降级**。

降级触发时必须：

1. 先输出 `[f-forge] 规则卡：脚本不可用，进入降级路径解析`，保留可观测性
2. 按下列顺序读取项目根目录下的规则卡，命中第一个存在的即停：
   - `.claude/.flutter-forge/projects/*.rule_card.yaml`
   - `.trae/.flutter-forge/projects/*.rule_card.yaml`
   - `.agents/.flutter-forge/projects/*.rule_card.yaml`
   - `.flutter-forge/projects/*.rule_card.yaml`
3. 同时检查同名 `*.rule_card_draft.yaml` 文件，判定草案状态
4. 命中规则卡时按 `status: found` 处理；只有草案时按 `status: draft` 处理；都没有时按 `status: not_found` 处理
5. 全程不跳过规则卡检查环节——降级是路径解析方式的降级，不是检查环节的降级

降级路径解析后，LLM 应在任务收口前提示用户检查脚本环境（如 `bash` 不可用、脚本文件被误删），避免长期降级运行。

## 规则卡的意义

规则卡不只是记忆文件，而是 **项目初始化状态标记**：

- 有规则卡：说明该项目已经被 Flutter Forge 初始化过
- 无规则卡：说明该项目尚未完成初始化，或至少尚未完成规则沉淀

项目一旦存在真实规则卡文件，就视为已经被 Flutter Forge 接管。

## 输出规则

只有在**真实规则卡文件存在且路径可明确指出**时，才允许输出 `规则卡：已加载`，并且应同时输出 `规则卡路径：...`

如果真实规则卡文件不存在：

- 一律输出 `规则卡：未发现，准备初始化`
- 一律视为 `项目状态：未初始化`
- 不要把扫描推断、代码印象或会话记忆误报成"已加载规则卡"
- 应显式标注 `当前判断来源：项目扫描 / 当前代码结构 / 会话上下文`

即使其他宿主目录中存在项目记忆文件，只要不在上述查找顺序内，也不能据此输出"已加载规则卡"。

## 无规则卡时的强制处理

如果当前项目不存在真实规则卡：

- 不允许输出 `规则卡：已加载`
- 不允许把无规则卡视为普通上下文缺口后直接跳过
- 不允许在未处理初始化前直接进入普通执行流程

必须执行：

- 先输出 `规则卡：未发现，准备初始化`
- 迭代项目：扫描当前项目并生成规则卡草案
- 新项目：进入共创流程，并在共创过程中完成规则卡初始化

说明：

- 无规则卡是初始化入口，不是可忽略缺口
- 只有“用户单纯询问规则卡位置”这类直通说明场景，才可以只回答现状而不立即展开初始化执行

## 用户询问规则卡位置时

当用户直接询问"规则卡位置在哪"、"规则卡路径在哪"、"当前加载的是哪张规则卡"时，必须先回答**正式规则卡路径**，不能先回答项目里的其他规则文件。

回答规则：

- 如果存在真实规则卡：先输出 `规则卡路径：...`
- 如果不存在真实规则卡：先明确输出 `当前项目未发现正式规则卡`
- `.trae/rules/rules.md`、`.claude/*.md`、`CLAUDE.md`、`AGENTS.md` 等只能作为"已有项目规则文件"补充说明，不能称为"规则卡"或"核心规则卡"
- 不允许用宿主规则、用户规则、会话记忆或扫描推断替代正式规则卡回答

错误示例：

```text
规则卡在 .trae/rules/rules.md
```

```text
当前 Trae 默认加载的项目规则就是规则卡：.claude/project-rules-v2.md
```

正确示例：

```text
当前项目的正式规则卡路径是：
- .claude/.flutter-forge/projects/<project>.rule_card.yaml

补充说明：
- `.trae/rules/rules.md`、`.claude/*.md`、`CLAUDE.md`、`AGENTS.md` 属于项目规则文件，不是正式规则卡。
```

```text
当前项目未发现正式规则卡。

正式规则卡只会出现在以下路径之一：
- .claude/.flutter-forge/projects/*.rule_card.yaml
- .trae/.flutter-forge/projects/*.rule_card.yaml
- .agents/.flutter-forge/projects/*.rule_card.yaml
- .flutter-forge/projects/*.rule_card.yaml
```

## 已有项目规则发现

除了 Flutter Forge 自己的规则卡，还要扫描项目中已有的规则文件：

- `.claude/rules/`、`.claude/*.md`
- `.trae/rules/`
- `.agents/rules/`
- 项目根目录的 `rules.md`、`analysis_rules.md`、`CONVENTIONS.md`
- `analysis/` 目录下的规则或分析文档

这些文件作为规则卡生成和校正的一等输入。已有规则与扫描推断冲突时，优先以已有规则为准。

详见 [existing_rules_discovery.md](existing_rules_discovery.md)。

## 规则卡检查流程

规则卡检查**不再每次启动强制执行**，而是按任务类型分级触发（详见 [task_runtime_prompt.md](task_runtime_prompt.md) "启动顺序"节第 3 步与 [SKILL.md](../SKILL.md) "路由顺序"节第 2 步的分级表格）：

- 直通模式：跳过
- 轻量任务：启动跳过；实现中触碰状态管理/路由/目录约定时按需触发
- 中等任务：`confidence: high` 跳过；`low` 检查
- UI 优化 / 架构级 / 功能开发 / 页面开发：必须检查
- 新项目共创：C0/C1 跳过；进入 C2 工程定型时必须检查

需要检查时，运行 `scripts/check_rule_card.sh <project_root> --cached 300`（缓存优先，300 秒 TTL）。

写操作硬阻断由 preToolCall hook（`scripts/hook_check_rule_card.sh`）兜底——`not_found` 状态下，写操作（Edit/Write/创建文件）触发硬阻断，读操作和命令执行只软提醒。

按状态执行：

- `status: found`：
  1. 加载 `path` 指向的规则卡内容
  2. 视为 `项目状态：已初始化`
  3. 视为 `项目已被 Flutter Forge 接管`
  4. 加载跨项目长期偏好
  5. 判断是否需要补扫描

- `status: draft`：提示用户确认草案，草案期间按草案参考执行

- `status: not_found`：进入初始化流程

只有在 `status: found` 且 Flutter skills 状态也已就绪时，才允许静默进入下一环节。

## 规则卡草案与正式规则卡

### 草案生成

当迭代项目首次接入且无规则卡时，扫描后生成的是**规则卡草案**，不是正式规则卡。

草案文件命名：`*.rule_card_draft.yaml`（注意 `_draft` 后缀）

### 草案确认流程

1. 扫描完成后，输出规则卡草案内容摘要
2. 明确向用户展示草案中的关键决策点（状态管理、路由、目录结构等）
3. 询问用户是否确认草案，或需要调整哪些字段
4. 用户确认后，将 `_draft` 后缀去掉，写入正式规则卡路径
5. 输出 `[f-forge] 规则卡已初始化：{路径}`

### 草案期间的行为

- 草案未确认期间，如果用户发起新任务，按草案内容作为参考（非强制约束）执行
- 草案中的规则不具有正式规则卡的强制力，但应尽量遵循以保持一致性
- 如果新任务的执行结果与草案冲突，在任务完成后提示用户更新草案

### 草案超时

- 草案超时计数持久化到 `.flutter-forge/session.md` 的 `draft_reminder_count` 字段，跨会话累积
- 每次触发 flutter-forge 任务且草案未确认时，计数 +1
- 计数达到 3 时，在第 4 次任务开始时再次提醒用户确认或放弃草案
- 用户确认后计数清零；用户明确放弃时，删除草案文件并清零计数
- 如果 session 文件不存在或无法写入，回退为会话内计数（不跨会话）

### 草案校验

草案生成后必须经过校验，确保质量足够支撑后续决策。校验清单、必填字段、置信度规则和扫描深度建议见：

- 归档参考：[archive/rule_card_validation.md](archive/rule_card_validation.md)

### 草案静默转正

草案被连续多次任务作为参考执行且无冲突时，自动转为正式规则卡，无需用户显式确认。

**转正条件**：

- `draft_usage_count` 达到 **5**（连续 5 次中等及以上任务完成且未与草案冲突）
- 直通模式和轻量任务不计入（它们不读规则卡，无法验证一致性）
- 每次任务完成时，controller 判断"本轮实现是否与草案规则冲突"：
  - 无冲突：`draft_usage_count` +1
  - 有冲突（实现结果与草案中的目录结构/状态管理/路由/命名规则不一致）：计数清零，提醒用户确认或更新草案

**转正执行**：

1. `draft_usage_count` 达到 5 时，在下次任务开始时（规则卡检查环节）自动执行：
   - 将 `*.rule_card_draft.yaml` 重命名为 `*.rule_card.yaml`（去掉 `_draft` 后缀）
   - 清零 `draft_usage_count` 和 `draft_reminder_count`
   - 输出日志：`[f-forge] 规则卡草案已连续 5 次任务无冲突使用，自动转为正式规则卡：{路径}`
2. 转正后，规则卡具有正式强制力
3. 用户可随时手动确认草案（不必等 5 次），手动确认优先级高于静默转正

**计数持久化**：

- `draft_usage_count` 持久化到 `.flutter-forge/runtime/rule_card_status.json` 的 `draft_usage_count` 字段
- 由 `scripts/check_rule_card.sh` 在输出 `status: draft` 时一并返回当前计数
- 由任务完成时的 controller 逻辑递增或清零（通过 `scripts/check_rule_card.sh` 的 `--increment-usage` 或 `--reset-usage` 参数）

**与草案超时的关系**：

- 草案超时（`draft_reminder_count`）和静默转正（`draft_usage_count`）是两条独立路径
- 超时提醒是"催用户确认"，静默转正是"用户不确认也能自动收口"
- 两者可以并行：超时提醒照常触发，但如果用户继续忽略，静默转正会在第 5 次无冲突任务后自动生效
- 用户在超时提醒时明确放弃草案 → 删除草案文件，两个计数都清零

**安全边界**：

- 静默转正不改变草案内容，只改变文件名和强制力等级
- 如果草案中有明显错误字段（如状态管理写了 `unknown`），应在草案校验阶段就被拦住，不会进入静默转正流程
- 转正后如果发现规则卡与代码不一致，走正常的"规则卡刷新时机"流程

## 规则卡刷新时机

以下情况发生时，大任务结束后应询问用户是否刷新规则卡：

1. **重构完成**：模块拆分、目录结构调整、文件重命名
2. **批量文件结构变更**：新建 feature 目录、迁移文件、统一命名
3. **状态管理方案切换**：从 Provider 换到 Bloc 等
4. **路由方案变更**：新增路由注册方式、切换路由库
5. **组件边界调整**：公共组件抽取、页面私有组件下沉
6. **性能预算调整**：修改 Widget 嵌套限制、函数行数限制等
7. **国际化/无障碍启用**：项目首次启用 i18n 或 a11y 支持

刷新流程：

- 大任务执行完后，对比规则卡与实际代码的差异
- 先询问用户是否刷新规则卡
- 用户确认后，只更新有变化的字段，不重写整个规则卡
- 输出一行日志：`[f-forge] 规则卡已刷新：{变更字段列表}`
- 如果变更涉及高风险项（状态管理、目录结构），明确提示本次变更点

不更新的情况：

- 轻量任务（改样式、改文案、修 bug）
- 单文件小改动
- 未涉及结构、命名或架构变更
