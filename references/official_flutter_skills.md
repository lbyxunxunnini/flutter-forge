# Flutter Forge Reference - Official Flutter Skills Integration

Flutter 官方维护了 `flutter/skills` 仓库，Flutter 文档也明确建议在 Flutter / Dart 任务中优先利用官方 Agent Skills，而不是重复发明通用框架知识。

参考：

- Flutter 文档：`docs.flutter.dev/ai/agent-skills`
- 官方仓库：`github.com/flutter/skills`

## 使用原则

Flutter Forge 负责总控和项目内决策，不负责替代所有 Flutter 通用技能。

默认先检查**当前环境是否已安装**对应官方 Flutter skill，而不是每次联网查询官方仓库。

探测优先看：

- 当前会话上下文已明确列出的可用 skills
- 本地映射文件 `.flutter-forge/skill_mapping.local.env`
- 当前工作区 `.claude/skills/`、`.agents/skills/`、`.cc-switch/skills/`、`.trae/skills/`
- 当前宿主根目录 `~/.claude/skills/`、`~/.agents/skills/`、`~/.cc-switch/skills/`、`~/.trae/skills/`

如果当前环境中的 skill 名称和 Flutter 官方当前名称或历史名称不一致，应优先使用兼容映射，而不是直接误判为“未安装”。

别名映射见：

- `references/official_skill_aliases.yaml`

如果环境里已安装对应 skill：

- 优先委托官方 skill
- 再由 Flutter Forge 做项目内适配和最终收口
- 进入实际任务时直接映射使用，不要把这层能力继续悬空

如果环境里未安装：

- 不阻塞任务
- 明确告知当前环境缺少对应官方 skill
- 回退到 Flutter Forge 自己的参考规则和本地流程
- 并提供：
  - 仓库：https://github.com/flutter/skills
  - 文档：https://docs.flutter.dev/ai/agent-skills
  - 安装命令：`npx skills add flutter/skills --skill '*' --agent universal`

如果用户希望先在本机统一选择一个协作技能目录，可运行：

- `scripts/discover_flutter_skills.sh`

只有在维护 `flutter-forge` 本身或更新委托映射时，才需要检查官方仓库最新变化。

当以下类型的子任务出现时，如果工作区已经安装了对应官方 Flutter skill，应优先委托给官方 skill 提供实现蓝图，再由 Flutter Forge 结合项目上下文收口：

- 架构分层与重构
- 响应式布局
- 路由配置
- JSON 序列化
- HTTP 请求封装
- 本地化
- Widget 测试
- Widget 预览
- 集成测试
- Flutter 布局问题修复

## 当前应优先识别的官方 Flutter skills

以下名称以当前 `flutter/skills` 仓库 README 为准：

- `flutter-architecting-apps`
- `flutter-building-layouts`
- `flutter-building-forms`
- `flutter-handling-http-and-json`
- `flutter-implementing-navigation-and-routing`
- `flutter-localizing-apps`
- `flutter-managing-state`
- `flutter-testing-apps`
- `flutter-theming-apps`
- `flutter-working-with-databases`
- `flutter-caching-data`
- `flutter-interoperating-with-native-apis`
- `flutter-embedding-native-views`
- `flutter-adding-home-screen-widgets`
- `flutter-animating-apps`
- `flutter-improving-accessibility`
- `flutter-building-plugins`
- `flutter-handling-concurrency`
- `flutter-reducing-app-size`
- `flutter-setting-up-on-linux`
- `flutter-setting-up-on-macos`
- `flutter-setting-up-on-windows`

## 兼容名称映射

本项目曾经使用过一套较旧的技能命名。现在统一以 `flutter/skills` 当前仓库名称为主，历史名称只作为兼容映射。例如：

- `flutter-apply-architecture-best-practices` -> `flutter-architecting-apps`
- `flutter-build-responsive-layout` / `flutter-fix-layout-issues` -> `flutter-building-layouts`
- `flutter-setup-declarative-routing` -> `flutter-implementing-navigation-and-routing`
- `flutter-implement-json-serialization` / `flutter-use-http-package` -> `flutter-handling-http-and-json`
- `flutter-setup-localization` -> `flutter-localizing-apps`
- `flutter-add-widget-test` / `flutter-add-widget-preview` / `flutter-add-integration-test` -> `flutter-testing-apps`

因此探测逻辑应分三类：

1. 当前官方 skill 名称已安装
2. 历史兼容名称已安装
3. 两者都未安装

只有第三种情况，才应提醒用户当前环境缺少对应官方 Flutter skills。

## 更新机制

如果你是通过官方方式把 `flutter/skills` 安装到项目或宿主目录，更新时优先使用官方命令：

```bash
npx skills update flutter/skills
```

更新后应重新检查：

- 官方技能名称是否有变动
- `references/delegation_map.yaml` 是否仍然匹配
- `references/official_skill_aliases.yaml` 是否仍然需要保留兼容项

## 引用说明

`flutter-forge` 明确引用以下官方资源：

- 官方仓库：`flutter/skills`
- 官方文档：`docs.flutter.dev/ai/agent-skills`

本项目不复制官方 skill 内容作为自有实现，而是：

- 在已安装时直接映射使用
- 在未安装时给出官方安装和更新方式
- 在项目内仅保留委托规则、兼容映射和收口策略

## 同名冲突规则

如果你把官方 `flutter/skills` 直接复制到多个参与发现的目录，并且保留相同 skill 名称，确实可能出现同名冲突或宿主优先级不清的问题。

建议只选一种作为**权威发现源**：

1. 项目内技能目录（`.claude/skills/`、`.agents/skills/`、`.cc-switch/skills/`、`.trae/skills/`）
2. 宿主根技能目录（`~/.claude/skills/`、`~/.agents/skills/`、`~/.cc-switch/skills/`、`~/.trae/skills/`）

不要同时在多个可发现目录里保留同名官方 skill 副本。

如果你只是想在仓库里保留官方 skill 内容做参考，应放在**不参与 skill 发现**的目录，例如：

- `.flutter-forge/vendor/flutter-skills/`

## 委托策略

### 需求理解阶段

不要调用官方 skill。这个阶段属于项目和业务理解，必须由 Flutter Forge 自己完成。

### UI 解析阶段

如果问题主要是：

- 响应式布局
- 布局溢出
- 复杂约束系统

优先参考：

- `flutter-building-layouts`

### 架构与实现设计阶段

如果问题主要是：

- 分层架构
- 路由方式
- 数据模型序列化
- 网络请求接入
- 本地化初始化

优先参考：

- `flutter-architecting-apps`
- `flutter-implementing-navigation-and-routing`
- `flutter-handling-http-and-json`
- `flutter-localizing-apps`

### 页面开发阶段

如果问题主要是：

- 组件测试
- 页面预览
- 集成测试

优先参考：

- `flutter-testing-apps`

## 收口规则

即使调用官方 Flutter skills，Flutter Forge 仍然负责最终收口：

1. 是否符合当前项目目录结构
2. 是否符合当前项目命名规则
3. 是否符合当前项目主流状态管理模式
4. 是否需要复用已有实现
5. 是否要压缩或调整官方建议，避免和项目现状冲突

换句话说：

- 官方 Flutter skill 提供通用最佳实践
- Flutter Forge 负责项目内适配和最终决策

## 降级处理

当官方 Flutter skill 不可用时，必须降级到 flutter-forge 内置流程。降级不降质量。

### 降级触发条件

满足以下任一条件时触发降级：

1. 初始化时检测到对应 skill 未安装
2. 架构设计师指定使用某个 skill，但调用时发现不可用
3. skill 安装后被卸载或路径变更

### 降级流程

```
需要使用 {skill_name}？
  → 检查是否已安装
  → 已安装 → 正常委托
  → 未安装 → 降级：
    1. 输出 [ff] 降级模式：{skill_name} 未安装，使用内置流程
    2. 读取 flutter-forge 内置参考规则（references/ 目录）
    3. 按内置规则生成等质量输出
    4. 在规则卡 task_only_context 中记录降级事件
    5. 任务完成后提醒用户安装
```

### 内置降级映射

| skill | 降级到的内置参考 |
|-------|----------------|
| `flutter-managing-state` | `memory_protocol.md` + 规则卡 `state_management` |
| `flutter-implementing-navigation-and-routing` | `routing_and_navigation.md` |
| `flutter-building-forms` | `engineering_heuristics.md` |
| `flutter-handling-http-and-json` | `network_and_api.md` |
| `flutter-testing-apps` | `testing_strategy.md` |
| `flutter-localizing-apps` | `i18n_a11y_check.md` |
| `flutter-improving-accessibility` | `i18n_a11y_check.md` |
| `flutter-building-layouts` | `engineering_heuristics.md` |
| `flutter-animating-apps` | `engineering_heuristics.md` |
| `flutter-caching-data` | `engineering_heuristics.md` |
| `flutter-working-with-databases` | `engineering_heuristics.md` |
| `flutter-handling-concurrency` | `engineering_heuristics.md` |

### 降级原则

1. **透明告知**：降级时必须输出 `[ff] 降级模式：...`，用户知道当前在用降级流程
2. **质量不降**：内置规则和官方 skill 的输出标准一致，不能因为降级就降低代码质量
3. **记录在案**：降级事件写入规则卡 `task_only_context.api_compat_notes`，后续有机会时提醒用户安装
4. **不阻塞**：降级后立即继续执行，不等用户确认是否要安装 skill
5. **主动提醒**：任务完成后，主动提醒用户可以安装缺失的 skill：
   - `[ff] 提示：安装 {skill_name} 可获得更好的 {功能描述} 支持`
   - 安装命令：`npx skills add flutter/skills --skill '{skill_name}' --agent universal`
