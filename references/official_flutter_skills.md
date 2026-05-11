# Flutter Forge Reference - Official Flutter Skills Integration

Flutter 官方维护了 `flutter/skills` 仓库，Flutter 文档也明确建议在 Flutter / Dart 任务中优先利用官方 Agent Skills，而不是重复发明通用框架知识。

参考：

- Flutter 文档：`docs.flutter.dev/ai/agent-skills`
- 官方仓库：`github.com/flutter/skills`

## 使用原则

Flutter Forge 负责总控和项目内决策，不负责替代所有 Flutter 通用技能。

默认先检查**当前环境是否已安装**对应官方 Flutter skill，而不是每次联网查询官方仓库。

如果环境里已安装对应 skill：

- 优先委托官方 skill
- 再由 Flutter Forge 做项目内适配和最终收口

如果环境里未安装：

- 不阻塞任务
- 明确告知当前环境缺少对应官方 skill
- 回退到 Flutter Forge 自己的参考规则和本地流程

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

- `flutter-apply-architecture-best-practices`
- `flutter-build-responsive-layout`
- `flutter-fix-layout-issues`
- `flutter-implement-json-serialization`
- `flutter-setup-declarative-routing`
- `flutter-setup-localization`
- `flutter-use-http-package`
- `flutter-add-widget-test`
- `flutter-add-widget-preview`
- `flutter-add-integration-test`

## 委托策略

### 需求理解阶段

不要调用官方 skill。这个阶段属于项目和业务理解，必须由 Flutter Forge 自己完成。

### UI 解析阶段

如果问题主要是：

- 响应式布局
- 布局溢出
- 复杂约束系统

优先参考：

- `flutter-build-responsive-layout`
- `flutter-fix-layout-issues`

### 架构与实现设计阶段

如果问题主要是：

- 分层架构
- 路由方式
- 数据模型序列化
- 网络请求接入
- 本地化初始化

优先参考：

- `flutter-apply-architecture-best-practices`
- `flutter-setup-declarative-routing`
- `flutter-implement-json-serialization`
- `flutter-use-http-package`
- `flutter-setup-localization`

### 页面开发阶段

如果问题主要是：

- 组件测试
- 页面预览
- 集成测试

优先参考：

- `flutter-add-widget-test`
- `flutter-add-widget-preview`
- `flutter-add-integration-test`

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
