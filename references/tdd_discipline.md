# Flutter Forge Reference - TDD 执行纪律

S4 实现阶段的测试先行纪律。当品质锚定为 polished 或 production 时激活，mvp 和轻量任务豁免。

## TDD 铁律 [Rigid]

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
品质锚定为 polished 或 production 时，禁止在未写失败测试前写产品代码。
```

先写了代码再写测试？删除代码。先写测试，再从头实现。

**没有例外：**
- 不要保留代码作为"参考"
- 不要在写测试时"适配"它
- 不要看它
- 删除就是删除

## 适用范围矩阵

| quality_tier | TDD 要求 | 说明 |
|-------------|---------|------|
| mvp | 豁免 | 快速原型优先，测试后补 |
| polished | 关键路径必须 test-first | 核心业务逻辑、数据转换、状态管理、网络层 |
| production | 全面 test-first | 所有非 UI 层代码 |

## 豁免条件

以下情况不强制 test-first（即使品质锚定为 polished/production）：

- **UI 层代码**：Widget 树构建、纯布局调整、样式微调
- **纯配置文件**：pubspec.yaml、路由表配置、环境变量
- **轻量任务**：文案/颜色/字号等已定位的小改动
- **ff-fast 未升级路径**：轻量优先，不强制 TDD
- **一次性脚本**：数据迁移脚本、构建脚本

不确定是否豁免时，默认执行 test-first。

## Red-Green-Refactor 循环

```
RED（写失败测试）
  → 写一个描述期望行为的最小测试
  → 运行测试，确认它失败
  → 失败方式必须符合预期（不是因为编译错误）

GREEN（写最少代码）
  → 写刚好让测试通过的产品代码
  → 不多不少
  → 运行测试，确认全部通过

REFACTOR（重构）
  → 在测试保护下清理代码
  → 提取方法、消除重复、改善命名
  → 运行测试，确认仍然通过
  → 回到 RED
```

## 具体步骤

### RED：写失败测试

写一个最小的测试，描述你期望的行为：

```dart
// Good: 清晰的名字，测试真实行为，只测一件事
test('订单列表按创建时间倒序排列', () {
  final orders = [
    Order(id: '1', createdAt: DateTime(2024, 1, 3)),
    Order(id: '2', createdAt: DateTime(2024, 1, 1)),
    Order(id: '3', createdAt: DateTime(2024, 1, 2)),
  ];

  final sorted = sortOrdersByDate(orders);

  expect(sorted.map((o) => o.id).toList(), ['1', '3', '2']);
});
```

```dart
// Bad: 名字模糊，mock 太多，测的是实现不是行为
test('排序有效', () {
  final mockService = MockOrderService();
  when(mockService.getOrders()).thenReturn([...]);
  // ... 大量 mock 设置
});
```

### GREEN：写最少代码

只写让测试通过的代码。不多不少。

### REFACTOR：在测试保护下重构

- 提取公共方法
- 消除魔法数字
- 改善命名
- 保持测试全绿

## Red Flags — 合理化借口

| 想法 | 现实 |
|------|------|
| "先写代码再补测试更快" | 先写代码再补测试 = 写了不会被删的测试 = 测试只验证实现不验证行为 |
| "这个太简单不用测试" | 简单的东西测试也简单，不写测试的唯一理由是偷懒 |
| "测试会拖慢进度" | 没有测试的"进度"在 S5 会被打回，总体更慢 |
| "我确定代码是对的" | 确定 ≠ 证明，测试是证明 |
| "先实现，后面补测试" | "后面"永远不会来 |
| "这是 UI 代码，没法测试" | Widget test 可以测 UI，除非真的是纯样式微调 |
| "项目没有测试基础设施" | 没有基础设施正是从当前任务开始建的好时机 |
| "TDD 不适合 Flutter" | Flutter 官方提供 widget_test 和 integration_test，TDD 完全可行 |
| "这次跳过，下次补" | 每次都跳过 = 永远没有测试 |
| "测试代码比产品代码还多" | 好测试比产品代码多很正常 |
| "mock 太多测试不真实" | 减少 mock 的方法：依赖注入、接口抽象、fake 实现 |

## 违反处理

发现先写代码后补测试时：

1. **停止**
2. **删除产品代码**（不是保留作参考）
3. **先写测试**
4. **确认测试失败**
5. **重新实现**

verify_agent 在 S5 验证时检查 `tdd_compliance` 字段（仅 polished/production）。

## 验证 Checklist

实现完成后，自检以下 8 项：

1. 每个新增/修改的核心函数是否有对应测试？
2. 测试是否先于产品代码编写？（test_first_evidence 中有记录）
3. 测试失败时是否能准确指出哪个行为出了问题？
4. 测试名字是否描述了行为而非实现？
5. 是否有测试覆盖边界情况（空值、空列表、最大值）？
6. 测试是否独立（不依赖执行顺序）？
7. 重构后测试是否仍然全部通过？
8. 是否有不必要的 mock 可以替换为真实依赖？

## 与 flutter-forge 体系的集成

- **与品质锚定的关系**：`quality_tier` 直接控制 TDD 激活阈值。这是目标治理到执行纪律的传导链路
- **与 SKILL.md 的关系**：目标治理第 8 条定义了 TDD 纪律传导
- **与 page_engineer 的关系**：Mandatory Checklist 中 `tdd_compliance` 和 `test_first_evidence` 字段记录 TDD 合规情况
- **与 verify_agent 的关系**：S5 可查看 page_engineer 的 TDD 合规标记（`tdd_compliance` 作为结构化标记可传递给 verify_agent）
- **与 systematic_debugging.md 的关系**：调试阶段 4（实施修复）中，如果品质锚定 >= polished，先写失败测试再修复
- **与 Rubric 评测的关系**：TDD 合规本身不生成 Rubric 条目，但 test-first 产出的测试代码可作为 S5 验证证据
