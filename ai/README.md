# AI Assistants — Using the Compact Rule File

[ai/AGENTS.md](AGENTS.md) gives an AI coding assistant this guide's rules in a short form: one line per rule of sections 1–13 and 15 of [docs/ABAP-Development-Rules.md](../docs/ABAP-Development-Rules.md), each with its rule number. Put it into your ABAP repository so the assistant reads it with every task, and cite the rules by number in reviews ([Rule 15.1](../docs/ABAP-Development-Rules.md#151-cite-these-rules-by-number-in-claudemd-and-similar-instruction-files)).

## 📄 What the File Is

- **Generated, not written by hand.** `tools/build_compact_rules.py` builds it from the "in short" lines of [20-Best-Practices](../20-Best-Practices/README.md) and the rules document. After a change to either, run `python tools/build_compact_rules.py`; `--check` reports whether the file is current.
- **A summary, not the rule set.** Each line names a rule; the binding text, the reasons and the examples stay in the rules document. An assistant that needs the reason for a rule should be pointed to the rule itself.
- **No replacement for review.** Review what the assistant writes against the checklist of [Rule 15.2](../docs/ABAP-Development-Rules.md#152-review-generated-abap-against-this-checklist-before-accepting-it), state the target language version in the prompt ([Rule 15.3](../docs/ABAP-Development-Rules.md#153-state-the-target-language-version-in-every-prompt-that-asks-for-code)) and ask what it did not verify ([Rule 15.4](../docs/ABAP-Development-Rules.md#154-ask-the-assistant-to-list-what-it-did-not-verify)).

> ⚠️ **This file has not been measured.** The experiment measured an earlier compact file, frozen as [experiment/conditions/C/CLAUDE.md](../experiment/conditions/C/CLAUDE.md). `ai/AGENTS.md` differs from it in the lines for 7.12, 7.22, 7.24, 8.17, 8.18 and 10.1 and in a note that the file is generated; [experiment/results/2026-11/README.md](../experiment/results/2026-11/README.md#-which-compact-file-was-measured) lists both versions of each line. A future run with this file will go into a new `experiment/results/<YYYY-MM>/` folder.

## 🛠️ Where Each Assistant Reads It

The file is named `AGENTS.md` because all three assistants below can read a file of that name. What each one reads, and when, is taken from its official documentation as read on 2026-11-24; it changes between versions, so check the linked page for yours.

### Claude Code

> ⚠️ **VERSION-DEPENDENT: instruction files in Claude Code.** Source: [Claude Code documentation, memory](https://code.claude.com/docs/en/memory).

- Claude Code reads project instructions from `CLAUDE.md` or `.claude/CLAUDE.md` in the working directory, and `CLAUDE.md` files in the folders above it, at launch. `CLAUDE.md` files in subfolders are loaded when Claude works with files in those subfolders.
- It reads `AGENTS.md` in place of `CLAUDE.md`, by default only when there is no `CLAUDE.md` or `CLAUDE.local.md` in the working directory or above it. The page states that reading `AGENTS.md` directly requires Claude Code v2.1.277 or later.
- A `CLAUDE.md` can import another file with `@path`, for example `@AGENTS.md`; a relative path resolves relative to the file that contains the import.

**Use:** copy `ai/AGENTS.md` to the root of your repository as `AGENTS.md`. If the repository already has a `CLAUDE.md`, add the line `@AGENTS.md` to it, because Claude Code then does not read `AGENTS.md` by itself.

### GitHub Copilot

> ⚠️ **VERSION-DEPENDENT: instruction files in GitHub Copilot.** Sources: [adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) and [support of custom instructions per feature](https://docs.github.com/en/copilot/reference/custom-instructions-support).

- Repository-wide instructions live in `.github/copilot-instructions.md`. Path-specific instructions live in `.github/instructions/NAME.instructions.md` files with an `applyTo` glob in their front matter.
- Agent instructions can be one or more `AGENTS.md` files anywhere in the repository; the nearest `AGENTS.md` in the directory tree takes precedence. The documentation states that agent instructions are not supported by all Copilot features; the support page lists, per IDE and feature, which file each feature reads.
- The documentation describes instructions as short, self-contained statements that are sent with every chat message.

**Use:** copy `ai/AGENTS.md` to the root of your repository as `AGENTS.md` for the features that read agent instructions. For a feature that reads only `.github/copilot-instructions.md`, put the same lines into that file; check the support page for the features you use.

### Cursor

> ⚠️ **VERSION-DEPENDENT: rules in Cursor.** Source: [Cursor documentation, rules](https://cursor.com/docs/context/rules).

- Cursor reads `AGENTS.md` in the project root and in subfolders. Instructions of nested `AGENTS.md` files are combined with those of parent folders, the more specific taking precedence. `AGENTS.md` is plain Markdown without metadata.
- Project rules in `.cursor/rules` are a different mechanism: they must use the `.mdc` extension with front matter (`description`, `globs`, `alwaysApply`); a plain `.md` file there is ignored by the rules system.

**Use:** copy `ai/AGENTS.md` to the root of your repository as `AGENTS.md`.

## 💰 Measured Cost: Full Rule Set Versus Compact File

From the [2026-11 results](../experiment/results/2026-11/README.md): six tasks, one run per task and condition, one model (`claude-opus-5-5`) in Claude Code `2.1.331`. Condition C used the earlier compact file described above, not `ai/AGENTS.md`.

| Item | A: no file | B: full rule set | C: compact file |
|---|---|---|---|
| Size of the context file | — | 137,807 bytes | 11,314 bytes |
| First-turn context per run, T2–T6 (tokens) | 41,145–41,215 | 95,951–96,023 | 45,808–45,878 |
| Added to the first turn, compared with A | — | about +54,800 | about +4,600 |
| `cost_state_usd`, sum of 6 runs | 3.81 | 9.54 | 5.72 |
| Cost compared with A | 1.00 | 2.50 | 1.50 |
| Wall-clock, sum of 6 runs (s) | 503 | 795 | 883 |
| Acceptance tests passed after the T2 test fix | 6 of 6 | 6 of 6 | 6 of 6 |
| Defects in the items a task targets | 3 runs (A1, A2, A4) | none | 1 run (C4) |
| Own unit test methods written | 0 | 20 | 30 |

The first-turn context is the input of the assistant's first request, which carries the context file; the full rule set costs it in every request of a session. The cost figure is Claude Code's own cost record for the run. With one run per cell, the differences show tendencies, not significant effects; see the experiment's [known limits](../experiment/README.md#-known-limits).

## 🔗 Related

- [experiment/README.md](../experiment/README.md) — how the rule files were compared, and how to repeat the runs
- [docs/ABAP-Development-Rules.md](../docs/ABAP-Development-Rules.md) — the binding rules
- [20-Best-Practices](../20-Best-Practices/README.md) — one line per rule, the source of `ai/AGENTS.md`
- [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md) — AI assistants, MCP servers for ADT and their safety model
