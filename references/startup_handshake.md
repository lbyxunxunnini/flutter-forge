# Flutter Forge Reference - 启动握手

启动握手是启动判定的显式输出形式，不是每次命中 `flutter-forge` 都必须展示的固定仪式。

## 什么时候需要显式握手

只有在以下情况，才向用户展开启动握手：

1. 当前项目首次被 `flutter-forge` 接管
2. 规则卡不存在、刚生成、刚迁移或刚失效
3. 当前项目是空项目或近似空项目，需要判断是否进入共创
4. 用户明确要求查看当前接管状态
5. Flutter skills 或本地协作链路状态不明确

轻量任务、普通中等任务、普通 UI 优化、普通架构级任务，默认只做静默启动判定，不展开完整握手。

## 握手的最小输出

第一行：

```text
[f-forge] 模式：启动握手
```

后面补最小状态：

```text
- 项目阶段：新项目 / 迭代项目
- 规则卡：已加载 / 未发现 / 待生成
- 规则卡路径：<resolved_rule_card_path>
- Flutter skills：已就绪 / 未就绪
- 下一步：进入新项目共创 / 进入页面开发 / 继续当前任务
```

其中 `规则卡路径` 只能在当前目标项目根目录内按以下顺序精确解析：

1. `.claude/.flutter-forge/projects/<project>.rule_card.yaml`
2. `.trae/.flutter-forge/projects/<project>.rule_card.yaml`
3. `.agent/.flutter-forge/projects/<project>.rule_card.yaml`
4. `.flutter-forge/projects/<project>.rule_card.yaml`

禁止把 `~/.claude/projects/.../memory/*.yaml`、其他项目目录中的规则卡、当前项目目录下其他项目名的规则卡当作已加载规则卡。

如果以上路径没有精确命中，启动握手必须输出：

```text
- 规则卡：未发现，准备初始化
- 规则卡草案路径：.flutter-forge/projects/<project>.rule_card_draft.yaml
- 下一步：扫描当前项目并生成规则卡草案
```

## 握手后续

握手结束后，直接切入当前真实轨道和阶段。

示例一：已有项目首次接管

```text
[f-forge] 模式：启动握手
- 项目阶段：迭代项目
- 规则卡：未发现
- 规则卡草案路径：.flutter-forge/projects/<project>.rule_card_draft.yaml
- Flutter skills：已就绪
- 下一步：扫描当前项目并生成规则卡草案

[f-forge] 模式：页面开发
- 升级原因：当前任务涉及页面结构和路由接入
[f-forge] 阶段：S1 需求确认
```

示例二：空项目起步

```text
[f-forge] 模式：启动握手
- 项目阶段：新项目
- 规则卡：待生成
- Flutter skills：已就绪
- 下一步：进入新项目共创

[f-forge] 模式：新项目共创
- 升级原因：当前只有产品方向，需要先收口页面结构和工程方案
[f-forge] 阶段：C0 想法收口
```

## 约束

- 握手本身不是主工作模式
- 握手结束后直接进入当前轨道和阶段
