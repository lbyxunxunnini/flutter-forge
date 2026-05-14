# Changelog

## 0.5.0

统一四角色提问预算与确认门禁

- 新增 `references/shared_workflow_gates/question_budget.md`，把 `L1-L4` 提问预算从主规则中拆出
- `SKILL.md` 新增四角色提问预算摘要，明确完整流程不等于问题越多越好
- `requirement_confirmation.md`、`role_gate_matrix.md` 补充预算和放行规则
- 需求分析师与 UI 设计师角色卡补充预算说明，强调“问到够用就停”
- 统一 `VERSION`、`.skillhub.json` 和 README 版本号到 `0.5.0`

## 0.4.4

去外部依赖，Flutter skills 本地化

- 删除 `scripts/discover_flutter_skills.sh` 外部探测脚本
- 删除 `references/official_skill_aliases.yaml` 别名映射
- `references/official_flutter_skills.md` 改为直接引用 `flutter-skills/` 本地副本
- `references/delegation_map.yaml` 每个 skill 加 `path` 字段指向本地副本
- 移除 task_runtime_prompt.md 中的探测/降级/安装命令整段
- LICENSE 加 Third-Party Components 段落，标注 flutter-skills/ 来源归属（BSD-3-Clause, Google LLC）
- README 更新架构图、项目结构、集成章节为本地副本模式

## 0.4.3

更新官方 Flutter Skills 映射：对齐 flutter/skills 仓库命名

- 删除 20 个旧的 Flutter Forge 命名 skills
- 安装 10 个官方 flutter/skills（2026-05-14 确认）
- 更新 official_skill_aliases.yaml：以官方名称为主键，旧名称为别名
- 更新 delegation_map.yaml：使用正确的官方 skill 名称
- 更新 official_flutter_skills.md：删除不存在的 16 个 skill，只保留 10 个官方 skill
- 更新 architecture_designer.md、page_engineer.md、engineering_heuristics.md、debugging_playbook.md、testing_strategy.md 中的 skill 引用

## 0.4.2

整理新项目分流与文档瘦身

- 把新项目判断拆成两个独立维度：`项目阶段` 决定是否进入共创模式，`架构状态` 决定规则卡是提取还是初始化
- 新增新项目入口三分流：明确共创意图、明确初始化意图、意图不清时默认推荐共创
- 新增"新增业务模块"的判定示例，明确区分现有项目扩展、空项目首个业务模块、新项目已有架构和忽略旧代码重做
- 主规则与初始化流程同步更新，避免把"新/老项目"和"有无架构"混成一个判断
- 继续压缩 `SKILL.md` 和 `README.md` 的重复规则说明，把详细分流和示例下沉到 reference 文件

## 0.4.1

同步共创与确认闸门

- 新增 `references/new_project_cocreation_mode.md`，支持从一个模糊 Flutter 项目想法出发，通过多轮问答逐步收口需求、风格、页面结构和第一版范围
- 主规则新增"新项目共创模式"，放在新项目初始化之前，避免只有想法时过早跳到规则卡和工程细节
- 补强确认绑定规则：用户一句"确认 / 可以 / 按这个来 / 没问题"只对上一轮明确摘要生效，不能自动吞掉摘要外的未决项
- 补强 UI 首轮输出闸门：新项目共创模式下，UI 设计师在方向确认后的第一轮只允许输出"结构草案"，不得一次性展开完整页面结构包
- 更新角色交接格式：新增"结构草案确认状态"和"用户确认状态"约束，未通过时禁止下发完整 UI 包
- 同步共享门禁：`shared_workflow_gates` 中的确认门禁、角色闸门与顾问式协作规则
- 更新 README、load map、项目初始化流程和运行时提示，使 Flutter 语义与 H5 版保持一致

## 0.4.0

开源准备与全接管路由升级

- 补充 MIT License、贡献指南、GitHub issue 模板和开源发布检查清单
- 修正 `.skillhub.json` 版本号，使其与 `VERSION` 和 README 的 `0.4.0` 保持一致
- 优化 README 首屏，明确 GitHub 首发状态、适用人群、暂缺 demo/截图的后续计划
- 新增老项目接入入口和新项目应用 profile 文档，README 增加可复制开场 prompt
- 优化任务路由为"硬排除 + 运维直通 + 轻量执行 + 完整流程"，让 Flutter 项目尽量全接管但不牺牲效率
- 调整上下文恢复：弱继续表述在存在未完成 session 时轻量恢复，避免长期任务被误当成新任务
- 新增完整流程升级原因规则：进入重流程时必须说明具体触发点，防止中等任务被过度流程化
- 收紧 10 秒测试：从需求/设计开始的新页面、新模块、新项目任务优先进入完整流程，不能因描述清晰而误判为轻量任务
- 补强误路由纠正、需求阶段强制重开、同任务续写恢复和用户确认状态门禁，对齐 h5-forge 的核心工作流闸门
- 新增 `references/shared_workflow_gates/` 子目录，沉淀可在 Flutter Forge 与 H5 Forge 之间直接复制的通用门禁规则
- 重构触发系统为"硬触发 + 语义触发 + 示例表达"三层结构，减少关键词堆积导致的误判和维护成本

## 0.3.7

重构任务路由为排除条件检查、全程接管模式、恢复触发标记明确化

- 重构任务路由：从"10秒测试+快速退出条件"改为"排除条件检查+10秒测试"
- 排除场景明确化：非Flutter项目、不涉及UI/Widget的操作（纯Dart、配置、CI、git、构建、部署、测试、文档）、纯知识问答、闲聊确认追问
- 全程接管模式：所有Flutter UI相关任务都进入flutter-forge，只有明确排除的场景才退出
- 上下文恢复规则增强：需要明确触发标记（ff-、业务关键词）才会恢复之前的工作，其他表述视为新任务
- 恢复触发标记：ff-、使用flutter-forge、/flutter-forge、继续做这个需求、继续页面开发、继续第2阶段、继续登录页
- 其他表述（"继续之前的工作"、"接着做"、"然后呢"）不触发恢复，视为新任务

## 0.3.6

设计边界规则、上游返回机制、上下文恢复规则

- 新增设计边界规则：四角色各自只在自己决策域内标注缺失，不越界代劳
- 需求分析师：只标注逻辑/交互缺失，不标注视觉设计缺失
- UI 设计师：设计缺失先问用户再搜项目；无法解析时触发降级机制并给出明显提示
- 架构设计师：三层决策边界（代码层自主、功能层跟需求、设计层跟 UI）
- 页面工程师：简单视觉缺失自主决策，复杂缺失反馈上游；不搜项目拼凑样式
- 新增上游返回机制：下游角色发现缺失时向上游角色反馈，架构影响决定是否显示架构师对话
- 新增上下文恢复规则：对话压缩/暂停恢复时必须先读 session.md，不能降级为轻量任务
- session.md 格式增强：新增任务模式、任务阶段、阶段进度字段
- session.md 写入时机改为关键节点（模式判定、阶段切换、任务完成）

## 0.3.5

可见性标记统一为 [f-forge]、轻量任务强制角色标签、四角色输出强制执行

- 可见性标记统一：`[ff]` 和 `[flutter-forge]` 全量替换为 `[f-forge]`，17 个文件 92 处
- 轻量任务强制角色标签：输出格式从 `[f-forge] 轻量任务，直接执行` 改为 `[f-forge] 页面工程师：轻量任务，直接执行`
- 轻量任务输出节奏约束：只在开始和结束时各输出一次 `[f-forge]` 标记，中间过程不逐条输出
- 大任务强制四角色输出：新增强制输出规则，禁止跳过需求分析师/UI设计师/架构设计师直接给结论
- 新增角色输出检查点：路由判定为完整流程后，输出前自检角色段落是否完整
- 红线新增第 5 条：大任务四角色流程中禁止无理由跳过角色（可简短声明后跳过，不可完全省略）
- 四个角色卡新增自检指令：每个角色输出必须以 `[f-forge] 角色名：` 开头

## 0.3.4

任务路由、四角色思考框架、讨论回合、skill 调度、冗余精简

- 新增任务路由决策逻辑：10 秒测试、5 条快速退出条件、完整流程触发条件、中间地带处理
- 新增输出后验证检查清单：7 项检查（编译/规则卡/架构/边界态/待补项/性能预算/i18n-a11y）
- 拆分 SKILL.md 为渐进式加载架构：HTML 注释分隔路由层和执行层，轻量任务只读 ~93 行
- 新增启动握手输出格式（`references/startup_handshake.md`）
- 新增规则卡协议（`references/rule_card_protocol.md`）
- 新增项目初始化流程（`references/project_init_flow.md`）：快速填写模式、5 个引导问题
- 规则卡模板增加 `performance_budget`、`i18n`、`accessibility` 字段组
- 新增四个角色思考框架：需求分析师（PRD 四层法/验收标准模板/隐含需求识别）、UI 设计师（四维评估/组件分类法/布局模式库）、架构设计师（技术选型权衡/风险评估矩阵/文件结构决策树/公共组件抽取标准）、页面工程师（实现优先级/性能优化检查/边界情况清单/代码生成决策）
- 新增讨论回合机制：触发条件、2 轮上限、决策权优先级（需求分析师>UI设计师>架构设计师>页面工程师）
- 新增角色输出标注：`[f-forge] 角色名：内容` 格式，每个角色独占一段
- 新增官方 Flutter skill 调度：架构设计师为调度者，页面工程师为执行者，含降级处理
- 新增代码审查模式（`references/code_review_mode.md`）：5 维度审查、严重程度分级
- 新增迁移辅助（`references/migration_assist.md`）：状态管理迁移、目录重构、命名统一
- 新增国际化/无障碍检查（`references/i18n_a11y_check.md`）：i18n 5 项 + a11y 6 项检查
- 新增工作模式标志表：8 种模式的 `[f-forge]`/`[f-forge]` 标志
- 项目整体冗余精简：SKILL.md 376→302 行（-20%），三文件合计减少 103 行
- README 重写：新增任务路由、讨论回合、工作模式、思考框架章节
- 更新 `references/load_map.md`：新增 6 个场景映射
- 更新四个角色卡：增加行为清单、思考框架、官方 Skill 调用与降级
- 更新记忆协议：区分项目状态判定（每次）vs 长期记忆启用（条件触发）

## 0.3.3

术语调整、README 重构、可见性标记、输入处理增强

- 术语调整："小任务"改为"轻量任务"，"老项目"改为"迭代中项目"
- README 重构：新增实际效果展示、诊断命令，安装和使用提前，架构总览下移
- 安装方式更新：支持 `npx skills add` 安装，git clone 作为备选
- 新增可见性标记：`[f-forge]` 标记让用户在连续对话中感知 skill 是否在工作
- 新增会话状态：`.flutter-forge/session.md` 记录当前工作状态，用户可主动查询
- 拆分 SKILL.md：输入不完整处理、官方 Flutter skills、可见性标记拆为独立 reference（707→518 行）
- 输入处理增强：区分视觉输入（截图/Figma）和文字 UI 描述两条路径，文字 UI 描述不依赖多模态能力
- UI 输入增加需求确认步骤：从 UI 结构推断业务意图，列出待确认项，不跳过直接写代码

## 0.3.2

更新 CHANGELOG

## 0.3.1

拆分已有项目规则发现和相似实现检索到独立 reference 文件

- 将已有项目规则发现和相似实现检索拆分为独立 reference 文件，主文档按需加载
- 同步更新 task_runtime_prompt、legacy_project_scan、memory_protocol、engineering_heuristics、load_map

## 0.3.0

发布 0.3.0：重写 README、轻量任务降噪、兼容已有规则、相似实现检索

- 重写 README，从架构师视角增加架构总览图、核心机制详解、项目结构树
- 轻量任务降噪：跳过完整启动握手和输入模型日志，只输出一行直接执行
- 启动判定增加轻量任务前置判断，命中后不走四步判定
- 兼容已有项目规则：扫描 `.claude/rules/`、`.trae/rules/`、`.agents/rules/` 等已有规则文件，作为规则卡生成和校正的一等输入
- 规则卡模板增加 `source_rules` 字段，标注内容来源
- 新增相似实现检索：进入任务前先搜索相似页面、组件、路由、接口
- 复用追踪：检索发现可复用模式时记录到规则卡 `reusable_patterns`，同一模式出现第 2 次时主动建议抽取公共组件

## 0.2.1

发布 0.2.1

- 同步 `system_prompt.md`、`legacy_project_scan.md`、`task_runtime_prompt.md`，避免旧 reference 漂移
- 补充网络层与 API 规则参考
- 补充路由与导航规则参考
- 强化 `templates_catalog.md` 中的列表页与表单页结构建议
- 将记忆协议调整为"仓库内模板 + 仓库外真实记忆目录"
- 明确 skill 的核心能力与辅助参考边界，避免功能过度具象化
- 补充 Quick Start 与远程安装说明

## 0.2.0

Release Flutter Forge 0.2.0

- 收紧 `flutter-forge` 的主控定位与触发描述，强调 Flutter 项目任务应优先进入 `flutter-forge`，而不是先走通用编码模式
- 精简 `README`，只保留用户真正需要的信息：用途、安装、自然使用方式、推荐开场、官方 Flutter skills 可选安装，以及触发失败时的 fallback 用法
- 增加显式触发兜底说明：支持 `ff- ...`、`使用 flutter-forge ...`、`按 flutter-forge 工作模式处理 ...`
- 将启动流程收口为更明确的握手机制：项目类型、规则卡状态、Flutter skills 状态三项判定
- 增加"完全态"概念：只有正式规则卡存在且 Flutter skills 状态已就绪时，后续进入项目才静默跳过完整握手
- 增加"进入工作阶段"日志与输入模型日志，区分 `只给 PRD`、`只给设计图`、`PRD + 设计图`、`上下文不足`、`直接开发任务`
- 强化规则卡语义：没有正式规则卡就视为项目未初始化；扫描推断、会话记忆、宿主项目记忆不得冒充"已加载规则卡"
- 统一正式规则卡来源：只认 `~/.flutter-forge/projects/*.rule_card.yaml`，明确排除 `.claude/projects/.../memory/*.yaml` 等宿主侧记忆文件
- 固定新项目规则卡生成时机：完成起步方式选择并产出首个设计包后，进入代码前必须生成规则卡并打印路径
- 调整记忆协议：检查规则卡存在性始终执行，但读取 / 写入长期记忆只在长期协作或用户明确要求时启用
- 增加 Flutter skills "已就绪 / 未就绪" 状态位，并要求该状态参与是否展开握手日志的判断
- 新增 Flutter skills 安装 / 映射提醒抑制机制：当用户明确表示不想下载或映射时，记录跨项目偏好，后续只保留探测和状态输出，不再重复提醒安装命令或映射脚本
- 校正官方 Flutter skills 名称基准，改为以当前 `flutter/skills` 仓库实际 skill 名称为主，旧名称降级为兼容别名
- 新增 `references/official_skill_aliases.yaml`，统一维护官方名称与历史名称的兼容映射
- 更新 `references/delegation_map.yaml`，按当前官方 skill 名称重写委托映射
- 更新官方 skill 文档，明确探测顺序、更新命令、命名兼容策略，以及不要在多个可发现目录放置同名 skill 副本
- 新增 `references/load_map.md`，把 reference 的按需加载入口从主文档中抽离，进一步落实 progressive disclosure
- 新增 `scripts/discover_flutter_skills.sh`，用于扫描项目内与宿主根技能目录、选择 Flutter 协作技能根目录并写入本地映射文件
- 扩展脚本探测模型，统一覆盖项目内目录与宿主根目录：`.claude/skills/`、`.agents/skills/`、`.cc-switch/skills/`、`.trae/skills/` 及其 `~/` 根目录版本
- 补充启动握手与工作阶段的示例日志，更新 `example_workflow.md`，让接管时机、规则卡生成时机和技能状态更可见
- 持续收敛主文档与 reference 边界，降低主文档噪音，把模型内部工作细节从用户文档中剥离

## 0.1.0

Initial Flutter Forge skill

- 明确定位为 Flutter 项目内编排 skill，而不是通用代码生成器
- 补充四个角色定义与角色交接格式
- 补充只给 PRD、只给设计图、输入不完整时的处理规则
- 补充官方 Flutter Agent Skills 对接策略与委托映射
- 补充 progressive disclosure 读取规则
- 补充记忆读写协议与新项目规则选择流程
- 新增全局偏好、项目规则卡、规则画像、短期任务记忆分层
- 补充工程判断标准与 Flutter 专项知识
- 补充测试策略、质量门、构建与静态分析建议
- 补充反模式检测、模板目录、调试手册
- 扩展规则卡字段：路由、国际化、主题、性能、依赖注入、质量偏好
- 补充真实案例说明与会员中心案例
- 补充真实试跑记录模板
- 调整为 `cc-switch` 可识别单 skill 结构
- 移除安装脚本，改为仓库根目录即 skill 目录
- 忽略 `.claude/`
