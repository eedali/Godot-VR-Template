---
description: Execute docs/claude/PLAN.md autonomously, phase by phase, no questions
---

Apply the plan in `docs/claude/PLAN.md` from start to finish.

Rules (also in CLAUDE.md, repeated here because they matter):

- Read `docs/claude/PLAN.md`, `AUDIT.md`, `ARCHITECTURE.md`, `FEATURES.md`,
  `VERIFICATION.md`, `GODOT_NOTES.md` and `PROGRESS.md` first. If `PROGRESS.md`
  shows phases already completed, resume from the first unfinished phase.
- Never ask the user anything. Decide, log the decision in
  `docs/claude/DECISIONS.md`, continue.
- Work only on branch `claude/template-overhaul` (phase 0 creates it).
- After each phase: run `bash tools/check.sh`, fix what it finds, tick the
  phase's boxes in `PLAN.md`, update `PROGRESS.md`, commit, push.
- Keep chat output minimal: one line per phase start/end.
- Finish with a Turkish report starting with `BİTTİ` (see CLAUDE.md, rule 2).

Start now with Phase 0.
