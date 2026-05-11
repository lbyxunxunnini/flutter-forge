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

### 官方 Flutter skill 检查

- 优先检查当前环境是否已安装对应官方 Flutter skill
- 已安装则优先委托
- 未安装则不阻塞，回退到 Flutter Forge 内置流程
- 不要为普通任务每次联网检查官方仓库

### 设计图兼容机制

如果输入里有设计图、截图、Figma 截图或原型图：

- 先判断当前环境是否具备可靠视觉理解能力
- 如果具备，再进入正常 UI 解析
- 如果不具备，或置信度不高，则要求文字化结构说明、图层说明、模块清单或相似页面代码
- 输出时标注 UI 解析来源：真实视觉输入 / 用户文字化描述 / 结构推断
