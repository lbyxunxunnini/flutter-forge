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
