# Verification — how to prove a change works without a headset

There is no human in the loop. Every phase must be verified mechanically with
the commands below, and every claim in `PROGRESS.md` must point at a log in
`build/claude-logs/`.

## The standard gate

```bash
bash tools/check.sh          # mandatory after every phase
bash tools/check.sh --run    # also runs the main scene headless ~4 s (use for phases 1,3,4,5,8)
bash tools/check.sh --export # also exports Windows debug build (phases 6 and 8)
```

What it does:

| Step | Command | Fails when |
|---|---|---|
| Import | `godot --headless --path . --import` | log contains script/resource load errors |
| Smoke | `godot --headless --xr-mode off --path . --script res://tools/smoke_test.gd` | any script fails to compile (`can_instantiate()`), any scene/resource has a missing dependency or fails to load/instantiate; rig path assertions fail |
| Lint | `gdlint components game tools` (only if installed) | lint errors |
| Run | `godot --headless --xr-mode off --path . --quit-after 240` | `SCRIPT ERROR` in log |
| Export | `godot --headless --path . --export-debug "Windows" build/windows/Game.exe` | exe/pck missing |

Why there is no per-script `--check-only` step: in this project it reports
`Identifier not found: GameState` / `XRToolsUserSettings` because autoload
singletons are not registered in that mode. The smoke test compiles every script
with the project loaded, so it is the reliable check (verified on 4.6-stable).

**Always pass `--xr-mode off` when running the project** (smoke test, headless
run, single scene). Without it Godot tries to start OpenXR, finds no headset and
opens a blocking Windows alert ("OpenXR was requested but failed to start") on
the user's screen. Import and export run the editor, which does not start
OpenXR, so they do not need the flag.

Expected noise you may ignore in logs: `OpenXR: Failed to initialize`,
`Failed to create XR instance`, `No XR interface`, anything about `WebXR`
or `XR_ERROR_...` — in headless mode there is no runtime; XR Tools then falls
back to desktop mode.

## Extra checks per kind of change

**New `.gd` with `class_name`** → run the import, then make sure
`.godot/global_script_class_cache.cfg` lists the class (`grep class_name_here`),
otherwise scenes using it by class will fail to load.

**New / edited `.tscn`** → smoke test + open it in a headless run that
instantiates it inside the tree:

```bash
bash tools/godot.sh --headless --xr-mode off --path . --quit-after 60 res://game/zones/showcase/showcase_zone.tscn
```

(A zone run outside staging will complain about missing `PersistentStaging.instance`
— that is expected; look only for `SCRIPT ERROR` lines that mention your files.)

**Rig / feature toggles** → add the node path to `FEATURE_NODES` **and** to the
smoke test assertion list; run the headless main scene with a temporary copy of
the config where the feature is off and confirm the debug log line from
`_apply_all` (`VRFeatures: <name> -> off (<node>)`). Restore the config.

**project.godot edits** → `bash tools/godot.sh --headless --path . --import`
must not print `Error parsing project.godot`; `git diff project.godot` must
show only the intended keys (the editor rewrites nothing in headless import).

**export_presets.cfg edits** → `--export` run.

**CI YAML** → `python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" <file>`
if Python exists; otherwise eyeball indentation and ensure no tabs
(`grep -P '\t' file` must be empty).

**Docs** → every relative link resolves (`grep -o '](\S*\.md' README.md docs/*.md`
and check the files exist).

## Reading the logs

- `build/claude-logs/import.log`, `parse.log`, `smoke.log`, `run.log`,
  `export-windows.log`, `gdlint.log`.
- First real error is what matters; later errors cascade from it.
- `SCRIPT ERROR: ... at: <func> (res://path.gd:line)` → fix that line.
- `Resource file not found: res://...` → a path typo in a `.tscn`/`.tres`.
- `Cannot get class 'X'` → class cache stale → run import.

## When something cannot be verified headless

Mark it in `PROGRESS.md` under **Needs headset test** with the exact steps a
human should do on the Quest 3, and keep the code path defensive
(`if XRServer.primary_interface == null: return`).
