# Flutter Forge Reference - Example Workflow

这个文件展示一个真实任务在 Flutter Forge 里的推荐流转方式，用来说明四个角色如何接力，而不是提供唯一标准答案。

## 场景

用户给出：

- 一份会员中心页面 PRD
- 一张会员中心页面设计图
- 一个现有老 Flutter 项目

目标：

- 在老项目中新增“会员中心”页面
- 尽量复用已有页面模式
- 先出结构方案，再出代码

## 推荐流程

### 第一步：资深产品需求分析师

输入：

- PRD
- 需求补充说明

输出示例：

```text
需求交接：
- 页面目标：为已登录用户提供会员信息展示、权益入口和续费操作入口
- 核心用户路径：进入页面 -> 查看会员状态 -> 查看权益 -> 点击续费或管理会员
- 必须覆盖的状态：未开通会员、已开通会员、会员过期、加载中、请求失败
- 明确需求：展示会员等级、到期时间、权益卡片、续费按钮
- 推断需求：不同会员状态下页面主按钮文案和卡片内容可能不同
- 待确认项：会员过期后是否保留权益说明区；未登录用户是否允许进入页面
```

### 第二步：资深 Flutter UI 体验设计师

输入：

- 设计图 / Figma
- 上一步需求交接

输出示例：

```text
UI 交接：
- 页面结构树：
  - MemberCenterPage
    - HeaderSection
    - MembershipStatusCard
    - BenefitsSection
    - RenewalActionBar
- 区块划分：顶部信息区、会员状态卡、权益列表区、底部主操作区
- 组件边界草案：HeaderSection 和 MembershipStatusCard 保持页面私有；BenefitItem 视复用情况决定是否抽离
- 关键交互区域：续费按钮、权益入口点击、状态卡 CTA
- UI 风险点：设计图未明确空态和请求失败态布局
- 缺失的业务信息：不同会员等级是否有不同权益列表；按钮点击后跳转逻辑未说明
```

### 第三步：10 年经验的前端架构与实现设计师

输入：

- 需求交接
- UI 交接
- 老项目扫描结果
- 项目规则卡

输出示例：

```text
实现设计交接：
- 模块归属：落在 lib/features/member_center/
- 文件结构方案：
  - page/member_center_page.dart
  - widgets/member_center_header_section.dart
  - widgets/membership_status_card.dart
  - widgets/benefits_section.dart
  - state/member_center_controller.dart
  - models/member_center_view_model.dart
- 命名方案：页面以 *_page.dart 结尾；页面私有组件按业务语义 + section/card 命名
- 状态管理接法：沿用项目主流页面级 controller + provider 模式
- 复用策略：复用 shared 中现有 loading/error scaffold；权益列表项暂不抽公共
- 不可越过的实现边界：页面层不直接发请求；不直接改动现有公共会员卡组件
- 高风险确认点：是否复用老的 membership_card 样式组件；过期态按钮文案是否和 PRD 一致
```

### 第四步：资深 Flutter 页面开发工程师

输入：

- 实现设计交接

输出示例：

```text
开发回传：
- 已生成文件：
  - member_center_page.dart
  - member_center_header_section.dart
  - membership_status_card.dart
  - benefits_section.dart
  - member_center_controller.dart
- 已完成部分：页面结构、状态接入骨架、基础交互入口、loading/error 占位
- 保留占位：会员等级映射逻辑、实际接口字段映射、过期态按钮跳转
- 仍需确认：是否复用老组件样式；未登录用户进入策略
```

## 这个示例想说明什么

1. 角色不是装饰，它们各自负责不同类型的决策。
2. 大任务里最重要的不是马上写代码，而是先把“需求 -> UI -> 结构 -> 代码”这条链打通。
3. 页面开发角色不应该反过来替前面三个角色做拍板。
