"""Run Godot regression scripts with isolated saves, logs and explicit failure detection."""
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CURRENT = ["standard_expeditions", "onboarding_controls", "menu_loadout", "smithy_loop", "slot_progression", "blueprint_progression", "blueprint_planning", "smithy_equipment_feedback", "ui_build_sources", "ui_flow_improvements", "ui_notifications_display", "ui_synergy_access", "tracked_goal", "fixed_loadout_progression", "expedition_rewards", "weapon_family_balance", "safe_return", "combat_presentation", "early_journey", "floor_identity", "validation_reports", "flow_combat", "fair_damage_guard", "attack_timing_music", "boss_access"]

def engine_path(explicit):
    candidates = [explicit, os.environ.get("GODOT"), shutil.which("godot"), shutil.which("godot4")]
    candidates += [str(Path.home()/"Downloads/Godot_v4.6-stable_win64.exe/Godot_v4.6-stable_win64_console.exe")]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(Path(candidate).resolve())
    raise SystemExit("Pass --godot PATH or set GODOT to the Godot console executable.")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--suite", nargs="+")
    parser.add_argument("--timeout", type=int, default=90)
    args = parser.parse_args()
    engine = engine_path(args.godot)
    suites = args.suite or (sorted(p.stem for p in (ROOT/"tests").glob("*.gd") if not p.stem.endswith("audit")) if args.all else CURRENT)
    work = ROOT/"work"
    work.mkdir(exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix="regressions-", dir=work)).resolve()
    results = []
    try:
        for name in suites:
            source = ROOT/"tests"/(name+".gd")
            if not source.is_file():
                results.append({"suite": name, "passed": False, "error": "Missing suite"})
                continue
            case = staging/name
            case.mkdir()
            prefix = "res://"+case.relative_to(ROOT).as_posix()+"/"
            # Rewrite fixture output paths only; production modules and assertions stay intact.
            text = source.read_text(encoding="utf-8").replace("/private/tmp/", prefix).replace("res://tests/.", prefix+".").replace('"/private/tmp"', json.dumps(prefix.rstrip("/"))).replace('DirAccess.open("res://tests")', 'DirAccess.open('+json.dumps(prefix.rstrip("/"))+')')
            script = case/(name+".gd")
            script.write_text(text, encoding="utf-8")
            try:
                process = subprocess.run([engine, "--headless", "--path", str(ROOT), "--log-file", str(case/"engine.log"), "--script", prefix+script.name], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=args.timeout)
                output = process.stdout+process.stderr
                payloads = []
                for line in output.splitlines():
                    try:
                        value = json.loads(line)
                        if isinstance(value, dict):
                            payloads.append(value)
                    except (ValueError, TypeError):
                        pass
                fatal = [line for line in output.splitlines() if "SCRIPT ERROR" in line or line.startswith("ERROR:") and "resources still in use at exit" not in line]
                failures = [failure for payload in payloads for failure in payload.get("failures", [])]
                result = {"suite": name, "passed": process.returncode == 0 and not fatal and not failures, "exit": process.returncode, "failures": failures, "fatal": fatal, "checks": sum(int(payload.get("checks", 0)) for payload in payloads), "cleanup_warning": "resources still in use at exit" in output}
                if not result["passed"]:
                    result["output"] = output
                    (work/(name+"-failure.log")).write_text(output, encoding="utf-8")
            except subprocess.TimeoutExpired as error:
                partial = (error.stdout or b"")+(error.stderr or b"")
                (work/(name+"-failure.log")).write_text(partial.decode("utf-8", errors="replace") if isinstance(partial, bytes) else partial, encoding="utf-8")
                result = {"suite": name, "passed": False, "error": "Timeout"}
            results.append(result)
            print(f"{'PASS' if result['passed'] else 'FAIL'} {name}" + (": "+str(result.get("failures") or result.get("fatal") or result.get("error")) if not result["passed"] else ""), flush=True)
    finally:
        assert staging.is_relative_to(work.resolve()) and staging.name.startswith("regressions-")
        shutil.rmtree(staging)
    report = {"suites": len(results), "passed": sum(row["passed"] for row in results), "failed": [row["suite"] for row in results if not row["passed"]], "results": results}
    (work/"regression_results.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({key: report[key] for key in ["suites", "passed", "failed"]}))
    raise SystemExit(bool(report["failed"]))

if __name__ == "__main__":
    main()
