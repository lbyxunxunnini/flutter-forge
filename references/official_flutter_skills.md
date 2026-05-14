# Flutter Forge Reference - Flutter Skills 本地集成

本项目将 Flutter 官方通用技能的副本存放在 `flutter-skills/` 目录下，不再依赖外部探测或 `npx skills add` 安装机制。

## 使用原则

Flutter Forge 负责总控和项目内决策，不负责替代所有 Flutter 通用技能。

当架构设计师决定调用某个 Flutter 子技能时，直接从本地 `flutter-skills/` 目录读取对应的 `SKILL.md`。

## 本地可用 Skills（10个）

以下名称以当前 `flutter/skills` 仓库为准，副本存放在 `flutter-skills/`：

| 本地目录 | 描述 |
|----------|------|
| `flutter-skills/flutter-add-integration-test` | 配置 Flutter Driver 集成测试 |
| `flutter-skills/flutter-add-widget-preview` | 添加交互式 widget 预览 |
| `flutter-skills/flutter-add-widget-test` | 添加组件级 widget 测试 |
| `flutter-skills/flutter-apply-architecture-best-practices` | 分层架构（UI/Logic/Data） |
| `flutter-skills/flutter-build-responsive-layout` | 响应式布局 |
| `flutter-skills/flutter-fix-layout-issues` | 修复布局溢出等问题 |
| `flutter-skills/flutter-implement-json-serialization` | JSON 序列化 |
| `flutter-skills/flutter-setup-declarative-routing` | 声明式路由配置 |
| `flutter-skills/flutter-setup-localization` | 本地化配置 |
| `flutter-skills/flutter-use-http-package` | HTTP 请求封装 |

## 委托策略

### 需求理解阶段

不要调用子技能。这个阶段属于项目和业务理解，必须由 Flutter Forge 自己完成。

### UI 解析阶段

如果问题主要是：

- 响应式布局
- 布局溢出
- 复杂约束系统

优先参考：

- `flutter-skills/flutter-build-responsive-layout`
- `flutter-skills/flutter-fix-layout-issues`

### 架构与实现设计阶段

如果问题主要是：

- 分层架构
- 路由方式
- 数据模型序列化
- 网络请求接入
- 本地化初始化

优先参考：

- `flutter-skills/flutter-apply-architecture-best-practices`
- `flutter-skills/flutter-setup-declarative-routing`
- `flutter-skills/flutter-implement-json-serialization`
- `flutter-skills/flutter-use-http-package`
- `flutter-skills/flutter-setup-localization`

### 页面开发阶段

如果问题主要是：

- 组件测试
- 页面预览
- 集成测试

优先参考：

- `flutter-skills/flutter-add-widget-test`
- `flutter-skills/flutter-add-widget-preview`
- `flutter-skills/flutter-add-integration-test`

## 收口规则

即使参考了 Flutter 子技能，Flutter Forge 仍然负责最终收口：

1. 是否符合当前项目目录结构
2. 是否符合当前项目命名规则
3. 是否符合当前项目主流状态管理模式
4. 是否需要复用已有实现
5. 是否要压缩或调整建议，避免和项目现状冲突

## 更新机制

`flutter-skills/` 目录下的副本需要手动同步更新。

更新时检查：

- 官方 `flutter/skills` 仓库是否有新版本
- `references/delegation_map.yaml` 是否仍然匹配
