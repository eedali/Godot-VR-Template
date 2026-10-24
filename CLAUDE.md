# Godot VR Template — Claude Code project guide

## What this repository is

A Godot 4.6 OpenXR VR game template (Meta Quest 3 first, PC VR / SteamVR second),
based on `GodotVR/godot-xr-template`, using **Godot XR Tools 4.5.2** (in `addons/`)
and the **OpenXR Vendors 4.3.0-stable** plugin (downloaded, not in git).
Owner: Ekrem (GitHub `eedali`). The owner will build *many different VR games* from
this template, so the template must contain every common VR mechanic as a
**component that can be switched on or off from one config file**.

## Your mission

When the user says **"planları uygula"**, **"apply the plan"**, or runs `/apply-plan`:
execute `docs/claude/PLAN.md` phase by phase, autonomously, until every phase is
done or hard-blocked. Read, in this order, before touching anything:

1. `docs/claude/PLAN.md` — phases, tasks, acceptance criteria
2. `docs/claude/AUDIT.md` — confirmed problems and things to verify
3. `docs/claude/ARCHITECTURE.md` — the target design (feature config + player rig)
4. `docs/claude/FEATURES.md` — the full feature matrix to implement
5. `docs/claude/VERIFICATION.md` — how to prove a phase works
6. `docs/claude/GODOT_NOTES.md` — Godot/XR Tools gotchas that bite autonomous edits

## Operating rules (non-negotiable)

1. **Autonomous. Never ask the user a question.** If something is ambiguous,
   choose the most sensible option, write one line in `docs/claude/DECISIONS.md`
   (what, why, alternatives) and keep going. The only reason to stop is a hard
   blocker you cannot work around (missing binary, no network, broken checkout).
   Then write the blocker in `docs/claude/PROGRESS.md` and finish with a report.
2. **Quiet.** Do not narrate. At most one short line when a phase starts and one
   when it ends. Everything else goes into `docs/claude/PROGRESS.md`. At the very
   end print a final report **in Turkish**, starting with the word `BİTTİ`, that
   lists: what changed, what was verified and how, what still needs a headset
   test, branch name and whether the push succeeded.
3. **Branch.** All work happens on branch `claude/template-overhaul`. Never commit
   to `main`. Never force-push. Never rewrite published history. Never delete
   branches.
4. **Commit per phase** with conventional-commit messages (`feat:`, `fix:`,
   `refactor:`, `docs:`, `chore:`). Push after each phase; if the push fails,
   continue working and retry at the end (see "Git & GitHub" below).
5. **Verify before you tick.** A phase is done only when `bash tools/check.sh`
   passes and the phase's acceptance criteria hold. Update the checkboxes in
   `docs/claude/PLAN.md` and the table in `docs/claude/PROGRESS.md` as you go.
6. **Do not modify** `addons/godot-xr-tools/**` (upstream library) or
   `addons/godotopenxrvendors/**`. Extend by composition in `components/`.
   Do not delete `.godot/`, `android/`, `build/` or any export template files.
7. **Keep Quest working.** `renderer/rendering_method.mobile` stays
   `gl_compatibility`. Mobile-side settings must not regress Quest performance.
8. **Prefer composition over clever edits.** Small scenes, small scripts,
   `class_name` on reusable components, `##` doc comments like XR Tools.
9. **No new third-party addons** unless a feature is impossible without one;
   if you add one, record it in `DECISIONS.md` and pin the version.
10. Code, comments, docs and commit messages are in **English**. Only the final
    report to the user is in **Turkish**.

## Environment (Windows 11, Git Bash)

- Claude Code runs commands in **Git Bash** on this machine. Use forward slashes
  and POSIX syntax. Windows paths look like `/d/Work/Code/...` and
  `/c/Open/...` inside Bash.
- Project folder: `D:\Work\Code\Godot_VR_Template` → `/d/Work/Code/Godot_VR_Template`.
- Godot editor: `C:\Open\Godot_v4.6-stable_win64.exe`. **For headless/terminal work
  always use the console build** `C:\Open\Godot_v4.6-stable_win64_console.exe`
  (the GUI build prints nothing to a terminal). `tools/godot.sh` resolves this
  automatically — always call Godot through `bash tools/godot.sh ...`.
- Python/pip and `gdlint` may or may not be installed. They are optional; never
  block on them (see `VERIFICATION.md`).
- `addons/godotopenxrvendors/` is gitignored. It is required only for the
  Android (Quest) export. `bash tools/setup_vendors.sh` installs it if missing.
- Network access (GitHub, docs sites) is normally available.

## Key commands

```bash
bash tools/check.sh              # import + script checks + smoke test (+ gdlint if present)
bash tools/check.sh --export     # same, plus a Windows debug export
bash tools/godot.sh --headless --path . --import
bash tools/godot.sh --headless --path . --script res://tools/smoke_test.gd
bash tools/setup_vendors.sh      # install OpenXR vendors addon if missing
bash tools/git_setup.sh          # branch + credential helper setup (phase 0)
```

## Code conventions

- GDScript 2.0, **tabs**, static typing everywhere (`var x : int = 0`,
  typed returns), `##` doc comments on classes and public members.
- Every new `.gd` file gets a `.gd.uid` sibling after the next import —
  **commit those `.uid` files**.
- Hand-written `.tscn`/`.tres` files: `format=3`, reference scripts/scenes by
  `path=` (a `uid=` is optional for new references; Godot adds it on save).
  After writing scene files always run the import and the smoke test.
- Signals over polling; `call_deferred` for tree changes inside notifications.
- Every feature is toggled through `VRFeatureConfig` (see `ARCHITECTURE.md`).
  A feature that cannot be toggled is not finished.

## Git & GitHub

- Remote `origin` = `https://github.com/eedali/Godot-VR-Template`.
- `tools/git_setup.sh` configures the Git Credential Manager so pushes do not ask
  for a password in the terminal. The **first** push may open a one-time browser /
  GUI login window on the user's screen; that is expected. If a push fails with an
  authentication error, do not retry in a loop: note it in `PROGRESS.md`, keep
  working, retry once at the end, and mention it in the final report.
- `GIT_TERMINAL_PROMPT=0` is set so git fails fast instead of hanging.

## Docs map (`docs/claude/`)

| File | Purpose |
|---|---|
| `PLAN.md` | The phases and tasks you execute. Tick boxes as you finish. |
| `AUDIT.md` | Problems already found in the code + items to verify. |
| `FEATURES.md` | Feature matrix: what exists, what is missing, toggle names. |
| `ARCHITECTURE.md` | Target design: `VRFeatureConfig`, `VRFeatures` autoload, `PlayerRig`. |
| `VERIFICATION.md` | Exactly how to check each kind of change. |
| `GODOT_NOTES.md` | Godot 4.6 / XR Tools gotchas. |
| `PROGRESS.md` | Your status log (you write it). |
| `DECISIONS.md` | Decisions you made instead of asking (you write it). |
