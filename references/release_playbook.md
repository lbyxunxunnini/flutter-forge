# Flutter Forge Reference - Release Playbook

## 发布前

1. 更新 `VERSION`。
2. 更新 `.skillhub.json` 的 `version`。
3. 更新 README 当前版本。
4. 在 `CHANGELOG.md` 顶部补对应版本条目。
5. 运行发布检查：

```bash
scripts/validate_release.sh
```

## 必须通过的检查

- 版本一致。
- 规则卡模板和示例可校验。
- Flutter 技术栈扫描 fixture 通过。
- 路由 golden cases 通过。
- 文档链接和必备引用同步。
- 本地-only 文件没有被 git 跟踪。

## 发布后

- 补充真实 validation case。
- 如果新增入口或模式，补 `references/mode_test_cases.md` 和 `tests/route_golden_cases.json`。
- 如果新增 reference，补 `references/load_map.md`。
