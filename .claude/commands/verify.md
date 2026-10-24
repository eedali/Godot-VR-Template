---
description: Run the full project verification (import, script checks, smoke test, lint, optional export)
---

Run `bash tools/check.sh $ARGUMENTS` from the project root and report the result.

- If it fails, read the log files it names under `build/claude-logs/`, fix the
  root cause (never silence a check), and run it again until it passes.
- Pass `--export` as the argument to also perform a Windows debug export.
- Summarise in at most five lines: what ran, what passed, what was fixed.
