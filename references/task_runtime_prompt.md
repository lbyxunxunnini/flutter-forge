# Flutter Forge Reference - Task Runtime

这个文件定义每次任务开始时的最小运行检查，不再维护与 `SKILL.md` 重复的大量静态说明。

## 开始前先判断

1. 当前任务大小
2. 当前项目规则是否足够支撑本次工作
3. 是否需要补扫描上下文
4. 是否应该优先复用旧实现
5. 是否存在需要用户确认的高风险点
6. 是否需要委托官方 Flutter skill
7. 是否需要补测试或质量检查
8. 如果输入包含设计图或截图，当前环境是否具备可靠视觉理解能力
9. 当前是否需要给用户一个可见的模式提示

## 启动握手最小日志

只有在以下情况才向用户显式输出完整握手日志：

1. 项目未初始化
2. 正式规则卡缺失
3. 项目首次被 Flutter Forge 接管
4. 规则卡刚生成、迁移或失效
5. Flutter skills 状态未就绪、未映射或未确认

如果项目已经存在正式规则卡，则默认视为**已被 Flutter Forge 接管**。

但只有当以下两项同时成立时，才视为进入**完全态**：

1. 已存在正式规则卡
2. Flutter skills 状态已就绪

Flutter skills 状态已就绪指满足任一条件：

- 当前会话已明确可见 Flutter skills
- 已选定本地协作技能目录，且其中检测到可协作 Flutter skills

此时：

- 仍然要在内部执行项目状态检查、规则卡检查和 Flutter skills 探测
- 只有在进入完全态后，才不要重复输出完整握手日志
- 直接进入任务阶段
- 只有在规则冲突、技能缺失、规则卡异常或用户明确要求时，才重新展开握手日志

每次命中 `flutter-forge` 时，第一行先输出：

- `[flutter-forge] 模式：启动握手`

然后至少输出三条短结果：

1. `- 项目类型：老项目 / 新项目`
2. `- 规则卡：已加载 / 未发现，准备初始化`
   - 如果是已加载，应同时给出：
     - `- 规则卡路径：...`
     - `- 项目状态：已初始化`
   - 如果未发现，应同时给出：
     - `- 项目状态：未初始化`
     - `- 当前判断来源：项目扫描 / 当前代码结构 / 会话上下文`
   - 只认 `${FLUTTER_FORGE_HOME:-~/.flutter-forge}/projects/*.rule_card.yaml` 为正式规则卡
3. `- Flutter skills：当前会话可见 / 已检测到本地协作技能目录 / 未检测到，将使用内置流程`
   - 同时给出：`- Flutter skills 状态：已就绪 / 未就绪`

如果分流已经明确，再补一条：

- `- 当前模式：老项目扫描 / 新项目初始化 / 直接进入当前任务 / 需求理解 -> 设计包`

## 进入工作阶段日志

当握手结束、开始真正处理任务时，输出：

- `[flutter-forge] 模式：进入工作阶段`
- `- 输入模型：只给 PRD / 只给设计图 / PRD + 设计图 / 上下文不足 / 直接开发任务`

如果项目已经进入完全态，这条日志可以替代完整握手，作为唯一可见状态提示。

## 复杂度规则

- 小任务：直接执行
- 中等任务：必要时询问是否升级
- 大任务：先给简短执行计划，再进入多角色流程

## 用户确认触发条件

1. 大模块命名需要确认
2. 模块归属存在高风险歧义
3. 需要改动现有公共模块
4. 多种主流规则并存且会影响本次架构决策
5. 低置信度推断会直接影响长期维护

## 运行时必查文件

- 官方 skill 委托：`references/delegation_map.yaml`
- 工程判断标准：`references/engineering_heuristics.md`
- 质量门：`references/quality_gates.md`
- 反模式：`references/anti_patterns.md`
- 测试策略：`references/testing_strategy.md`
- 网络层规则：`references/network_and_api.md`
- 路由规则：`references/routing_and_navigation.md`

## 运行时补充规则

### 新项目规则卡生成时机

如果当前分支是 **新项目 + 无规则卡**，并且已经：

1. 收到最小业务方向
2. 完成起步方式选择
3. 输出了首个设计包

那么在开始写代码前，必须先输出：

- `规则卡：已生成`
- `规则卡路径：~/.flutter-forge/projects/<project>.rule_card.yaml`
- `项目状态：已初始化`

然后才能进入代码阶段。

### 官方 Flutter skill 检查

- 如果当前会话没有直接暴露可用 skill 列表，先看本地映射文件 `.flutter-forge/skill_mapping.local.env`，再看项目内和宿主根技能目录
- 优先检查当前环境是否已安装对应官方 Flutter skill
- 已安装则优先委托
- 未安装则不阻塞，回退到 Flutter Forge 内置流程
- 不要为普通任务每次联网检查官方仓库

如果本地还没有选定协作技能目录，先提示：

- `[flutter-forge] 正在查询需要协作的 Flutter skill...`
- 引导用户运行：`scripts/discover_flutter_skills.sh`

如果用户已明确表示不想下载官方 Flutter skills、也不想做本地映射，则应记录一个长期偏好标记。之后：

- 继续探测 Flutter skills
- 继续输出 Flutter skills 状态
- 不再提示安装命令
- 不再提示 `scripts/discover_flutter_skills.sh`

未安装时，启动握手阶段应明确提醒一次，并提供：

- 官方仓库：https://github.com/flutter/skills
- 官方文档：https://docs.flutter.dev/ai/agent-skills
- 安装命令：`npx skills add flutter/skills --skill '*' --agent universal`

已安装时：

- 直接按委托映射使用
- 不再把官方 skills 当成“理论上可用但本轮没接上”的空悬能力

探测时允许使用本地别名映射，不要求当前环境的 skill 名称与 Flutter 官方 canonical 名称完全一致。

参考：

- `references/official_skill_aliases.yaml`

### 设计图兼容机制

如果输入里有设计图、截图、Figma 截图或原型图：

- 先判断当前环境是否具备可靠视觉理解能力
- 如果具备，再进入正常 UI 解析
- 如果不具备，或置信度不高，则要求文字化结构说明、图层说明、模块清单或相似页面代码
- 输出时标注 UI 解析来源：真实视觉输入 / 用户文字化描述 / 结构推断

### 可见模式提示

为避免用户感知不到 skill 被调用或角色切换：

- 任务开始时，用一行短提示说明当前模式
- 大任务阶段变化时，再给一行当前阶段提示
- 小任务不要过度播报
- 不要为了存在感制造完整角色交接文档
