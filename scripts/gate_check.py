#!/usr/bin/env python3
"""Evaluate flutter-forge phase/contract gates for a target write path."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def read_session(project_root: Path) -> dict[str, str]:
    candidates = [
        project_root / ".claude/.flutter-forge/session.md",
        project_root / ".trae/.flutter-forge/session.md",
        project_root / ".agents/.flutter-forge/session.md",
        project_root / ".flutter-forge/session.md",
    ]
    session_path = next((path for path in candidates if path.exists()), None)
    if session_path is None:
        return {}

    data: dict[str, str] = {"_path": str(session_path)}
    for line in session_path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("- ") or "：" not in line:
            continue
        field, value = line[2:].split("：", 1)
        data[field.strip()] = value.strip()
    return data


def read_task_gate(project_root: Path) -> dict[str, object]:
    path = project_root / ".flutter-forge/runtime/task_gate.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def classify_target(target_path: str) -> str:
    normalized = target_path.replace("\\", "/").lower()
    if normalized.startswith("./"):
        normalized = normalized[2:]
    if not normalized:
        return "unknown"
    project_config_suffixes = (
        "/pubspec.yaml",
        "/pubspec.lock",
        "/analysis_options.yaml",
        "/ios/podfile",
        "/ios/podfile.lock",
        "/android/build.gradle",
        "/android/settings.gradle",
        "/android/gradle.properties",
        "/android/app/build.gradle",
    )
    if normalized in {suffix[1:] for suffix in project_config_suffixes} or normalized.endswith(project_config_suffixes):
        return "project_config"
    if normalized.endswith((".md", ".txt", ".yaml", ".yml", ".json")):
        return "metadata"
    if "/test/" in normalized or normalized.endswith("_test.dart"):
        return "test"
    if "/router/" in normalized or "/route" in normalized or "routes" in normalized:
        return "router"
    if any(token in normalized for token in ("provider", "notifier", "bloc", "cubit", "controller", "/di/", "dependency_injection")):
        return "state"
    if "/lib/core/" in normalized or "/lib/shared/" in normalized:
        return "core_shared"
    if normalized.endswith(".dart"):
        return "implementation"
    return "other"


def mode_needs_contract(mode: str) -> bool:
    return mode in {"中等任务", "UI 优化", "架构级任务", "功能开发", "页面开发"}


def exempt_by_policy(task_gate: dict[str, object], mode: str) -> bool:
    policy = str(task_gate.get("policy", "标准"))
    if policy == "全自动":
        return True
    if mode in {"直通模式", "轻量任务"}:
        return True
    return False


# 角色边界：每个角色允许写入的目标类型（不在集合中的则阻断）
ROLE_ALLOWED_TARGETS: dict[str, set[str]] = {
    "requirement_analyst": {"metadata"},
    "ui_designer": {"metadata"},
    "architecture_designer": {"metadata"},
    "page_engineer": {"implementation", "core_shared", "router", "state", "test"},
    "verify_agent": {"test", "metadata"},
    # controller 不限制
}


def build_result(decision: str, gate: str, reason: str, target_kind: str, session: dict[str, str]) -> dict[str, object]:
    return {
        "decision": decision,
        "gate": gate,
        "reason": reason,
        "target_kind": target_kind,
        "phase": session.get("当前阶段", "-"),
        "mode": session.get("当前模式", "-"),
        "confirmation_status": session.get("确认状态", "-"),
        "change_contract": session.get("改动契约", "-"),
        "session_path": session.get("_path", "-"),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--target-path", default="")
    parser.add_argument("--mode", choices={"observe", "enforce"}, default="enforce")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    session = read_session(project_root)
    target_kind = classify_target(args.target_path)
    task_gate = read_task_gate(project_root)

    if target_kind in {"other", "unknown"}:
        print(json.dumps(build_result("allow", "none", "no_active_gate", target_kind, session), ensure_ascii=False))
        return 0

    if not session:
        if target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
            decision = "would_block" if args.mode == "observe" else "block"
            print(json.dumps(build_result(decision, "iron_law", "无活跃 session，无法验证需求/方案确认状态；实现类写入需要先启动 session", target_kind, session), ensure_ascii=False))
            return 0 if decision == "would_block" else 2
        if target_kind in {"metadata", "test"}:
            print(json.dumps(build_result("allow", "none", "no_active_gate", target_kind, session), ensure_ascii=False))
            return 0

    phase = session.get("当前阶段", "-")
    mode = session.get("当前模式", "-")
    confirmation_status = session.get("确认状态", "-")
    change_contract = session.get("改动契约", "-")
    exempt = exempt_by_policy(task_gate, mode)
    goal_status = session.get("目标状态", "未确认")
    scope_status = session.get("范围状态", "未确认")
    acceptance_status = session.get("验收状态", "未确认")
    constraint_status = session.get("约束状态", "未确认")
    current_work_unit = session.get("当前子单元", "-")
    work_unit_status = session.get("子单元状态", "未冻结")
    verification_status = session.get("验证状态", "未验证")
    scope_risk = session.get("超范围风险", "无")
    plan_conflict = session.get("计划冲突状态", "无")
    mode_lock = session.get("工作模式锁", "激活")
    exit_permission = session.get("退出许可", "禁止")

    decisions: list[tuple[str, str]] = []

    # Gate 1: 确认前阶段阻断实现类写入
    if phase in {"C0", "C1", "C2", "C3", "S0", "S1", "S2", "S3"}:
        if target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
            # S2 已确认时单独处理（Gate 2）
            if not (phase == "S2" and confirmation_status == "用户已确认" and change_contract != "-"):
                blocked_kind = "实现或项目配置" if target_kind == "project_config" else "实现类"
                decisions.append(("phase_progression", f"当前阶段 {phase} 尚未进入 S4，{blocked_kind}文件暂不允许写入"))

    # Gate 2: S2 已确认 → 强制推进到 S4（只放行实现类，阻断 metadata/test/project_config）
    if phase == "S2" and confirmation_status == "用户已确认" and change_contract != "-":
        if target_kind in {"metadata", "test", "project_config"}:
            decisions.append(("s2_force_progress", "S2 已确认，改动契约已冻结，请先进入 S4 实现阶段再写测试/文档/配置"))

    # Gate 3: S5 验证阶段 → 只允许测试写入
    if phase == "S5" and target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
        decisions.append(("s5_verify_only", "S5 验证阶段不允许写入实现/配置文件，只允许测试和元数据"))

    # Gate 4: 阶段日志缺失 → 阻断实现类写入
    if not exempt and target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
        recent_action = session.get("最近操作", "-")
        log_exempt_actions = {"初始化", "保存恢复点", "恢复后已消费用户输入", "等待用户输入", "-"}
        if recent_action not in log_exempt_actions and "[f-forge]" not in recent_action:
            decisions.append(("missing_phase_log", f"当前阶段 {phase} 未输出 [f-forge] 阶段日志，请先输出再写实现代码"))

    # Gate 5: 角色边界 → 活跃代理只能写入其职责范围内的文件
    active_agent = session.get("活跃代理", "controller")
    if active_agent not in {"controller", "-"}:
        allowed = ROLE_ALLOWED_TARGETS.get(active_agent, set())
        if allowed and target_kind not in allowed:
            role_display = {
                "requirement_analyst": "需求分析师",
                "ui_designer": "UI 设计师",
                "architecture_designer": "架构设计师",
                "page_engineer": "页面工程师",
                "verify_agent": "验证工程师",
            }.get(active_agent, active_agent)
            decisions.append(("role_scope", f"{role_display}（{active_agent}）无权写入 {target_kind} 类文件，当前角色只能操作：{', '.join(sorted(allowed))}"))

    # Gate 6: 输出校验缺失 → 阶段切换后必须先运行 validate_output.sh
    if not exempt and phase in {"S2", "S3", "S4", "S5"} and target_kind in {"implementation", "core_shared", "router", "state"}:
        output_validation = session.get("输出校验", "未校验")
        validation_phase = session.get("校验阶段", "-")
        if output_validation != "已通过" or validation_phase != phase:
            decisions.append(("output_validation", f"当前阶段 {phase} 尚未通过输出校验，请先运行 scripts/validate_output.sh 并更新 session（--output_validation 已通过 --validation_phase {phase}）"))

    # Gate 7: 工作模式锁未释放 → 禁止收口
    if phase == "S6" and mode_lock == "激活" and exit_permission != "允许":
        decisions.append(("mode_exit", "工作模式锁仍处于激活状态，且退出许可未打开，禁止进入 S6 收口"))

    # Gate 8: 核心任务定义未冻结 → 阻断实现类写入
    if target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
        missing_core = [
            label
            for label, field in (
                ("目标", goal_status),
                ("范围", scope_status),
                ("验收", acceptance_status),
                ("约束", constraint_status),
            )
            if field != "已确认"
        ]
        if missing_core:
            decisions.append(("core_definition", f"进入实现前必须先冻结核心任务定义，当前未确认：{', '.join(missing_core)}"))

    # Gate 9: 当前子单元未冻结 → 阻断实现类写入
    if target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
        if current_work_unit == "-" or work_unit_status not in {"已冻结", "实现中", "待验证", "已通过"}:
            decisions.append(("current_work_unit", "进入实现前必须先冻结当前子单元，并在 session 中记录 current_work_unit/work_unit_status"))

    # Gate 10: 发现超范围风险或计划冲突 → 先回退再继续
    if target_kind in {"implementation", "project_config", "core_shared", "router", "state"}:
        if scope_risk == "已发现":
            decisions.append(("scope_expansion", "已发现超范围风险，必须先回退到 S2/S3 重新确认，不能继续实现"))
        if plan_conflict == "已发现待回退":
            decisions.append(("plan_conflict", "当前计划与代码现实冲突，必须先回退对应确认阶段，不能继续实现"))

    # Gate 11: 当前子单元未验证通过 → 禁止切换收口
    if phase == "S5" and target_kind in {"metadata", "test"} and verification_status != "已通过":
        decisions.append(("verification_truth", "当前子单元验证尚未通过，禁止用验证日志或收口元数据伪装完成"))

    if not exempt and mode_needs_contract(mode) and change_contract == "-":
        decisions.append(("change_contract", "当前写入缺少已冻结的改动契约"))
    if not exempt and mode_needs_contract(mode) and confirmation_status != "用户已确认":
        decisions.append(("confirmation_status", "当前写入缺少用户确认，标准 ff- 流程不能直接实现"))

    if not decisions:
        print(json.dumps(build_result("allow", "none", "gates_passed", target_kind, session), ensure_ascii=False))
        return 0

    gate, reason = decisions[0]
    decision = "would_block" if args.mode == "observe" else "block"
    print(json.dumps(build_result(decision, gate, reason, target_kind, session), ensure_ascii=False))
    return 0 if decision == "would_block" else 2


if __name__ == "__main__":
    sys.exit(main())
