# Flutter Forge Reference - 会话管理

这个文件定义 `.flutter-forge/session.md` 的结构和使用规则。它服务的是当前未完成大任务的运行状态，不是每轮消息的默认恢复机制。

## Session 文件路径

项目根目录下：

```text
.flutter-forge/session.md
```

## 基础结构

统一采用以下字段：

```markdown
# Flutter Forge Session

- 轨道：cocreation / execution
- 当前阶段：C0-C3 / S0-S6
- 当前模式：直通模式 / 轻量任务 / 中等任务 / UI 优化 / 架构级任务 / 功能开发 / 页面开发 / 新项目共创
- 决策版本：v1 / v2 / v3
- 规则卡：已加载 / 未加载
- 规则卡摘要：2-3 个关键字段
- 活跃代理：controller / ui-agent / arch-agent / impl-agent / verify-agent
- 工作包：无 / P1 / P2 / P3
- 失效结果：无 / impl-agent:v2 / ui-agent:v1
- 最近操作：具体做了什么
- 更新时间：YYYY-MM-DD HH:mm
```

## 带工作包的结构

当任务已经拆分为多个工作包时，增加清单：

```markdown
## 工作包

- [x] P1: member_center page structure
- [ ] P2: shared member widgets
- [ ] P3: member data integration
```

规则：

- 工作包状态必须显式维护
- 完成后立刻从 `[ ]` 更新为 `[x]`
- 如果上游方案变化导致结果失效，在 `失效结果` 中记录

## 写入时机

通过 `scripts/ff_session.sh` 操作 session，禁止 LLM 直接读写文件格式。

```bash
scripts/ff_session.sh read                                    # 读取
scripts/ff_session.sh init --track execution --phase S1       # 初始化
scripts/ff_session.sh update --phase S4 --mode 功能开发       # 更新字段
scripts/ff_session.sh reset                                   # 重置（任务完成时）
scripts/ff_session.sh validate                                # 校验字段完整性
```

### 必写

1. 路由和模式判定完成时 → `init` 或 `update --phase --mode`
2. 阶段切换时 → `update --phase`
3. 决策版本变化时 → `update --decision_version`
4. 工作包完成时 → `update --work_packages --recent_action`
5. 下游结果失效时 → `update --stale_results`
6. 整个任务完成时 → `reset`

### 不必写

- 每读一个文件
- 每调一次工具
- 中间推理过程
- 还没形成结论的临时思路

## 读取时机

通过 `scripts/ff_session.sh read` 读取。

### 可读场景

1. 当前大任务被压缩或中断时
2. 用户明确要求继续同一未完成任务时
3. 当前工作包尚未完成，且仍在同一轮任务内部时

任务已经完成时，不再读取旧 `session`（已通过 `reset` 清除）。

## 恢复逻辑

需要恢复时，读取 `session.md` 后按这个顺序恢复：

1. 是否存在未完成阶段
2. 当前轨道是 `cocreation` 还是 `execution`
3. 当前模式是什么
4. 当前有效 `decision_version` 是什么
5. 是否有未完成工作包
6. 是否有已失效结果需要丢弃

如果任务已完成或 `session` 已被重置，直接按新任务处理。

### 恢复输出

共创轨道示例：

```text
[f-forge] 模式：新项目共创
[f-forge] 阶段：C2 工程定型
[f-forge] 主控判断：继续上一轮工程定型，当前先确认目录结构和状态管理。
```

执行轨道示例：

```text
[f-forge] 模式：页面开发
[f-forge] 阶段：S4 实现中
[f-forge] 页面工程师：恢复上一轮实现进度，当前继续未完成工作包。
```

## 防误判规则

1. 不要只看”最近操作”，要看阶段和工作包状态
2. 不要跨 session 假设旧结论仍然有效
3. 如果 `决策版本` 已变化，旧实现结果可能失效
4. 如果用户开启新任务，默认覆盖旧 session，而不是恢复旧任务
5. 任务结束后不要保留可继续恢复的旧任务状态

## 失效结果（stale_results）写入规则

`失效结果` 字段由主控在以下时机写入：

1. 某个 `impl-agent` 回传阻塞，且主控评估影响范围超出当前工作包时
2. 上游方案（需求或架构）发生变化，导致已完成的下游结果不再可靠时
3. `decision_version` 递增时，旧版本下完成的工作包结果自动标记为待确认

写入格式：`代理名:版本号`，例如 `impl-agent-1:v2`

清除时机：

- 受影响的工作包重新完成后，从 `失效结果` 中移除
- 回退到 S3 重新拆包后，清空所有 `失效结果`

## 多任务边界

一个 `flutter-forge` 会话内可能包含多个子任务：

- 每个子任务有独立的路由判定和模式
- 直通模式子任务完成后，session 不写入（直通模式不创建 session）
- 轻量任务完成后，session 不写入
- 只有中等及以上任务才创建和维护 session
- 用户在同一轮对话中提出新任务时，如果旧任务已完成，重置 session 后按新任务处理

## 与规则卡的关系

- `session`：记录当前任务做到哪了
- 规则卡：记录这个项目长期怎么做

不要把项目规则写进 session，也不要把当前任务进度写进规则卡。
