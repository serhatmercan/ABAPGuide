"""Read the Claude Code transcripts of experiment runs and report cost, speed and run conditions.

Usage:
    python -I collect_metrics.py <runs.csv> [--projects-dir ~/.claude/projects]
                                 [--settings kit/claude-config/settings.json] [--json out.json]

The experiment runs use a dedicated configuration directory, so pass
    --projects-dir C:\\ABAP-Experiment\\claude-config\\projects
and, to list tool calls outside the run configuration's allowlist,
    --settings C:\\ABAP-Experiment\\kit\\claude-config\\settings.json

runs.csv is written by start_run.ps1 (header in runs.csv.template); the
script needs the columns run_id, condition, task and folder.

For each run folder the script finds Claude Code's project directory for that
folder (the absolute path with every character that is not a letter or digit
replaced by "-", compared without regard to case), reads every *.jsonl in it
(subagent transcripts in sub-folders included) and reports:

- Tokens, two sources:
  * cost_state_*: the usage Claude Code itself recorded in the last
    "cost-state" record of each main session, per model. This includes model
    requests that the transcript does not record as an assistant message
    (the pilot showed one such request after the final answer in PB1 and PC1).
    M-1 is reported from this source, main model only;
  * transcript_*: input tokens (uncached), cache-creation, cache-read and
    output tokens summed over the assistant messages of the transcript (each
    message ID counted once). The difference to cost_state_* is reported as
    unrecorded_*;
- first_turn_context: uncached + cache-creation + cache-read input tokens of
  the first assistant message (the context the model saw for the task prompt,
  including the system prompt and any context file). This is the reported
  rule-file cost per turn (M-4);
- tool calls in total and per tool name; MCP tool calls (ToolSearch is not an
  MCP tool and is reported separately); questions to the user
  (AskUserQuestion); Skill tool calls;
- tool calls outside the allowlist of --settings, with the error flag of
  their results;
- permission modes: every value of the transcript's "permission-mode"
  records and of the permissionMode field of user records;
  permission_mode_deviation is true if any value is not dontAsk;
- activation attempts: calls of a tool whose name ends with "abap_object_activate",
  and how many of their results did not contain "Activation successful";
- unit test runs (in the experiment runs: denied attempts) and ATC runs started by the assistant;
- wall-clock time from the first to the last user or assistant record of the main session(s);
- number of main sessions (more than one means the run was restarted) and the models used.

The script only reads files. It prints a Markdown table and can write JSON.
"""
import argparse
import collections
import csv
import datetime as dt
import json
import pathlib
import re
import sys

TOKEN_FIELDS = ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens")
COST_STATE_FIELDS = {"input_tokens": "inputTokens", "cache_creation_input_tokens": "cacheCreationInputTokens",
                     "cache_read_input_tokens": "cacheReadInputTokens", "output_tokens": "outputTokens"}


def project_dir_for(folder: str, projects: pathlib.Path) -> pathlib.Path | None:
    encoded = re.sub(r"[^A-Za-z0-9]", "-", str(pathlib.Path(folder).resolve()))
    for candidate in projects.iterdir():
        if candidate.is_dir() and candidate.name.lower() == encoded.lower():
            return candidate
    return None


def parse_time(value: str | None):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(text_of(c.get("content", c.get("text", ""))) if isinstance(c, dict) else str(c) for c in content)
    return str(content)


def load_allowlist(settings: str | None) -> set[str] | None:
    if not settings:
        return None
    data = json.loads(pathlib.Path(settings).read_text(encoding="utf-8"))
    return set(data.get("permissions", {}).get("allow", []))


def analyse(project: pathlib.Path, allowlist: set[str] | None) -> dict:
    usage_by_message = {}
    first_usage = None
    tool_calls = collections.Counter()
    tool_names_by_id = {}
    results_by_id = {}
    activation_ids = set()
    activation_failures = 0
    models = set()
    times = []
    main_sessions = set()
    permission_modes = collections.Counter()
    cost_state_by_session = {}
    for path in sorted(project.rglob("*.jsonl")):
        is_subagent = path.parent != project
        with path.open(encoding="utf-8", errors="replace") as handle:
            for line in handle:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                kind = record.get("type")
                if not is_subagent and record.get("sessionId"):
                    main_sessions.add(record["sessionId"])
                if not is_subagent and kind == "permission-mode":
                    permission_modes[record.get("permissionMode")] += 1
                if not is_subagent and kind == "user" and record.get("permissionMode"):
                    permission_modes[record["permissionMode"]] += 1
                if not is_subagent and kind == "cost-state" and isinstance(record.get("modelUsage"), dict):
                    # the last cost-state record of a file holds the session's totals
                    cost_state_by_session[path.name] = record["modelUsage"]
                stamp = parse_time(record.get("timestamp"))
                if stamp and not is_subagent and kind in ("user", "assistant"):
                    times.append(stamp)
                message = record.get("message")
                if not isinstance(message, dict):
                    continue
                if kind == "assistant":
                    if message.get("model"):
                        models.add(message["model"])
                    usage = message.get("usage")
                    key = message.get("id") or record.get("uuid")
                    if usage and key:
                        usage_by_message[key] = usage
                        if first_usage is None and not is_subagent:
                            first_usage = usage
                    for block in message.get("content") or []:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            if block["id"] in tool_names_by_id:
                                continue
                            tool_names_by_id[block["id"]] = block.get("name", "")
                            tool_calls[block.get("name", "")] += 1
                            if str(block.get("name", "")).endswith("abap_object_activate"):
                                activation_ids.add(block["id"])
                elif kind == "user":
                    for block in message.get("content") or []:
                        if isinstance(block, dict) and block.get("type") == "tool_result":
                            results_by_id[block.get("tool_use_id")] = bool(block.get("is_error"))
                            if block.get("tool_use_id") in activation_ids \
                                    and "Activation successful" not in text_of(block.get("content")):
                                activation_failures += 1
    transcript = collections.Counter()
    for usage in usage_by_message.values():
        for field in TOKEN_FIELDS:
            transcript[field] += int(usage.get(field) or 0)
    main_model = sorted(models)[0] if len(models) == 1 else None
    cost_state = collections.Counter()
    cost_state_other = collections.Counter()
    cost_usd = 0.0
    for model_usage in cost_state_by_session.values():
        for model, usage in model_usage.items():
            cost_usd += float(usage.get("costUSD") or 0)
            target = cost_state if model in models else cost_state_other
            for field, key in COST_STATE_FIELDS.items():
                target[field] += int(usage.get(key) or 0)
    outside = None
    if allowlist is not None:
        outside = collections.Counter()
        errors = collections.Counter()
        for tool_id, name in tool_names_by_id.items():
            if name not in allowlist:
                outside[name] += 1
                if results_by_id.get(tool_id):
                    errors[name] += 1
        outside = {name: {"calls": n, "error_results": errors[name], "no_result": sum(
            1 for i, nm in tool_names_by_id.items() if nm == name and i not in results_by_id)}
            for name, n in outside.items()}
    wall = (max(times) - min(times)).total_seconds() if times else None
    result = {
        "first_turn_context": sum(int((first_usage or {}).get(f) or 0) for f in TOKEN_FIELDS[:3]) if first_usage else None,
        "first_turn_input_tokens": int((first_usage or {}).get("input_tokens") or 0) if first_usage else None,
        "first_turn_cache_creation_input_tokens": int((first_usage or {}).get("cache_creation_input_tokens") or 0) if first_usage else None,
        "first_turn_cache_read_input_tokens": int((first_usage or {}).get("cache_read_input_tokens") or 0) if first_usage else None,
    }
    for field in TOKEN_FIELDS:
        result["cost_state_" + field] = cost_state[field] if cost_state_by_session else None
        result["transcript_" + field] = transcript[field]
        result["unrecorded_" + field] = (cost_state[field] - transcript[field]) if cost_state_by_session else None
    result.update({
        "cost_state_other_models": dict(cost_state_other) if cost_state_other else {},
        "cost_state_usd": round(cost_usd, 6) if cost_state_by_session else None,
        "assistant_messages": len(usage_by_message),
        "tool_calls": sum(tool_calls.values()),
        "mcp_tool_calls": sum(n for name, n in tool_calls.items() if name.startswith("mcp__")),
        "tool_search_calls": tool_calls.get("ToolSearch", 0),
        "skill_calls": tool_calls.get("Skill", 0),
        "questions_to_user": tool_calls.get("AskUserQuestion", 0),
        "tool_calls_outside_allowlist": outside,
        "permission_modes": dict(permission_modes),
        "permission_mode_deviation": any(mode != "dontAsk" for mode in permission_modes),
        "activation_attempts": len(activation_ids),
        "activation_failures": activation_failures,
        "unit_test_runs": sum(n for name, n in tool_calls.items() if name.endswith("abap_unit_run_tests")),
        "atc_runs": sum(n for name, n in tool_calls.items() if name.endswith("abap_atc_run_start")),
        "wall_clock_seconds": round(wall) if wall is not None else None,
        "main_sessions": len(main_sessions),
        "models": sorted(models),
        "main_model": main_model,
        "tool_calls_by_name": dict(tool_calls.most_common()),
    })
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("runs_csv")
    parser.add_argument("--projects-dir", default=str(pathlib.Path.home() / ".claude" / "projects"))
    parser.add_argument("--settings", help="run configuration settings.json; lists tool calls outside its allowlist")
    parser.add_argument("--json")
    args = parser.parse_args()
    projects = pathlib.Path(args.projects_dir)
    allowlist = load_allowlist(args.settings)
    results = []
    # utf-8-sig: tolerate a byte order mark written by other tools
    with open(args.runs_csv, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            entry = dict(row)
            if not row.get("folder"):
                entry["error"] = "row has no folder (check the CSV quoting of runs.csv)"
                results.append(entry)
                continue
            project = project_dir_for(row["folder"], projects)
            if project is None:
                entry["error"] = "no transcript folder found"
            else:
                entry["project_dir"] = str(project)
                entry.update(analyse(project, allowlist))
            results.append(entry)
    columns = ["run_id", "condition", "task", "first_turn_context",
               "cost_state_input_tokens", "cost_state_cache_creation_input_tokens",
               "cost_state_cache_read_input_tokens", "cost_state_output_tokens",
               "unrecorded_cache_read_input_tokens", "mcp_tool_calls", "tool_search_calls", "tool_calls",
               "activation_attempts", "activation_failures", "unit_test_runs", "atc_runs",
               "questions_to_user", "skill_calls", "permission_mode_deviation",
               "wall_clock_seconds", "main_sessions", "models"]
    print("| " + " | ".join(columns) + " |")
    print("|" + "---|" * len(columns))
    for entry in results:
        print("| " + " | ".join(str(entry.get(c, entry.get("error", ""))) for c in columns) + " |")
    if args.json:
        pathlib.Path(args.json).write_text(json.dumps(results, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
