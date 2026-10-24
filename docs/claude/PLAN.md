# PLAN — Godot VR Template overhaul

Execute phases in order. Each phase ends with: `bash tools/check.sh` green →
boxes ticked here → `PROGRESS.md` updated → commit → push. Do not start the next
phase while the current one has a failing check. If a task turns out to be
impossible, mark it `[~]` with a one-line reason and move on; never leave the
project in a non-importing state between commits.

Branch: `claude/template-overhaul`. Commit prefix per phase is given below.

---

## Phase 0 — Setup & baseline (`chore:`)

- [x] 0.1 Run `bash tools/git_setup.sh`. Confirm you are on `claude/template-overhaul`
      and that any pre-existing local changes were committed.
- [x] 0.2 Append to `.gitignore` (if missing): `build/claude-logs/` and
      `.claude/settings.local.json`.
- [x] 0.3 `bash tools/godot.sh --version` works. If not, find the console
      binary under `C:/Open/` and fix `GODOT_BIN` in `.claude/settings.json`
      and `tools/godot.sh`.
- [x] 0.4 `bash tools/setup_vendors.sh` (installs `addons/godotopenxrvendors`
      if absent; the folder is gitignored).
- [x] 0.5 Run `bash tools/check.sh --run` once **before changing any game code**
      and copy the summary into `PROGRESS.md` as the baseline (a failing
      baseline is information, not a blocker — note which checks fail and why).
- [x] 0.6 If `gdlint` is missing and `pip`/`python` exist, `pip install 'gdtoolkit==4.*'`
      (user install). If Python is missing, note it and continue; lint is optional.
- [x] 0.7 Commit anything still uncommitted (`chore: add Claude Code project tooling`)
      and push the branch (`git push -u origin claude/template-overhaul`). If the
      push opens a credential window or fails, follow CLAUDE.md "Git & GitHub".

**Acceptance:** branch exists, tooling committed, baseline recorded.

---

## Phase 1 — Audit fixes & hygiene (`fix:` / `chore:`)

Work through `docs/claude/AUDIT.md`:

- [x] 1.1 A1 — `persistent_zone.gd`: clear `current_zone` after saving; add
      `is_instance_valid` guards in `game_state.gd` (`save_world_state`,
      `quit_game`, `load_world_state`).
- [x] 1.2 A2/A3 — `game_state.gd`: default + type-check `game_difficulty` on load.
- [x] 1.3 A4 — `start_ui.gd`: enum for panes, remove debug prints, typed vars.
- [x] 1.4 A5 — `zone_switch_area.gd`: modern signal connect, skip in editor.
- [~] 1.5 A6 (optional) — try the headless re-save from `GODOT_NOTES.md §4`;
      keep it only if the diff is limited to `uid=` additions, otherwise
      `git checkout -- game components` and mark `[~]`.
      _Skipped: a `--script` re-save **removed** every `uid=` (and the scenes' own
      header uids) instead of adding them; reverted (D-4)._
- [x] 1.6 A7 — fix `script_class` headers in the three `*_zone_info.tres`.
- [x] 1.7 C1 — remove stale `exclude_filter` entries from `export_presets.cfg`.
- [x] 1.8 D3 — add `.gdlintrc` (from `gdlint --dump-default-config` if available;
      otherwise write a minimal YAML with `max-line-length: 100` and
      `function-name: "(_on_[A-Za-z0-9]+(_[a-z0-9]+)*|_?[a-z][a-z0-9]*(_[a-z0-9]+)*)"`),
      lint `components game tools` locally if `gdlint` exists and fix findings.
- [x] 1.9 Add `.editorconfig` (provided in this package) — verify it is present.
- [x] 1.10 `bash tools/check.sh --run` green. Commit, push.

**Acceptance:** all A-items and C1 closed; check green; no behaviour change
other than bug fixes.

---

## Phase 2 — Feature config system (`feat:`)

Per `ARCHITECTURE.md §1–2`:

- [x] 2.1 Create `config/vr_feature_config.gd` (`class_name VRFeatureConfig`)
      with every toggle from `FEATURES.md` (names exactly as listed).
- [x] 2.2 Create `config/vr_features_default.tres` (defaults: today's behaviour
      + `teleport`, `vignette`, `haptics`, `hand_tracking`, `desktop_fallback` on).
- [x] 2.3 Create `components/system/vr_features.gd` autoload; register
      `VRFeatures` in `project.godot` `[autoload]` **before** `GameState`.
- [x] 2.4 Add `SCAN_DIRS` entry `res://config` to `tools/smoke_test.gd` (already
      present) and extend the smoke test with an assertion that
      `VRFeatureConfig.new()` exposes every name in a `REQUIRED_FEATURES` list
      copied from `FEATURES.md` (so a renamed toggle fails the check).
- [x] 2.5 Write `docs/HOWTO_TOGGLE.md`: how to copy the default resource, point
      the project setting `vr_template/feature_config` at it, and what each
      toggle does (table generated from `FEATURES.md`).
- [x] 2.6 Check green. Commit, push.

**Acceptance:** `VRFeatures.is_enabled(&"teleport")` works in a headless run
(`--run` log shows no errors); the config has ≥ 40 toggles.

---

## Phase 3 — PlayerRig refactor (`refactor:`)

Per `ARCHITECTURE.md §3–4`. This is the riskiest phase; commit after 3.3 and
after 3.6 separately.

- [x] 3.1 Create `components/player/player_rig.tscn` + `player_rig.gd`
      containing **everything** `zone_base.tscn` has today (camera near plane
      0.03, grip pose, collision hands, low-poly hands with bone poses, pokes,
      pointers, pickups, direct/strafe, jump, crouch, turn, sprint, pockets,
      wrist UI, highlight rings). Reproduce the transforms exactly.
- [x] 3.2 Add `FEATURE_NODES` mapping + `_apply_all` / `_on_feature_changed`
      logic; implement the special cases listed in `ARCHITECTURE.md §3`.
- [x] 3.3 Extend `tools/smoke_test.gd`: instantiate the rig and assert every
      `FEATURE_NODES` path exists (`has_node`). Check green. **Commit.**
- [x] 3.4 Rewrite `game/zones/zone_base.tscn` as a non-inheriting scene with
      the rig instanced as `XROrigin3D` (see inheritance constraint).
- [x] 3.5 Rewrite the three demo zones to drop the copied rig overrides and keep
      only content. Diff the node lists before/after (`grep '^\[node' file`)
      to prove no content node was lost; record the counts in `PROGRESS.md`.
- [x] 3.6 `bash tools/check.sh --run` green; also run the headless main scene
      and confirm the start menu → zone load path has no `SCRIPT ERROR`.
      **Commit, push.**
- [x] 3.7 Run the `godot-reviewer` subagent on `git diff main...HEAD -- components game`
      and fix every `high` finding.

**Acceptance:** zones are thin; the rig is the only place mechanics live;
toggling `direct_movement` off in the default config and running headless
shows the node disabled (log a line from `_apply_all` in debug builds).

---

## Phase 4 — Missing mechanics & custom components (`feat:`)

Wire every `addon` row of `FEATURES.md` into the rig (default state per the
matrix) and write the `custom` components:

- [x] 4.1 Locomotion: teleport, physical jump, jog, climb, flight, glide,
      grapple, wall walk, world grab, wind, footsteps. Respect each script's
      documented parent requirement (read the `##` header of each
      `addons/godot-xr-tools/functions/movement_*.gd`). Keep distinct `order`
      values so providers do not fight (teleport before direct; climb/world-grab
      before body physics; see XR Tools docs).
- [x] 4.2 Comfort: `effects/vignette.tscn` under the camera (`vignette`,
      `vignette_auto_adjust`), `head_behavior`, `player_body`, `loading_prompt`
      (wired to `GameStaging.prompt_for_continue`).
- [x] 4.3 Hands/interaction: gaze pointer, hand-pose detectors, `laser_visible`,
      `ranged_pickup`, `collision_hands` off-path (re-parent to plain controller
      child), `hand_models` off (hide + disable AnimationTree).
- [x] 4.4 `components/feedback/haptics.gd` + `tap.tres`; call it from
      `PersistentItem` pick-up/drop and from pointer press (guarded by toggle).
- [x] 4.5 `components/system/passthrough_controller.gd` + project setting
      `xr/openxr/environment_blend_mode` left at opaque (runtime switch only);
      verify with a headless run that calling it without an XR interface is a
      no-op with a `push_warning`, not an error.
- [x] 4.6 Hand tracking: `project.godot` → `xr/openxr/extensions/hand_tracking=true`,
      `xr/openxr/extensions/hand_interaction_profile=true`; rig sets
      `show_when_tracked` from the toggle. Document that controller-free hand
      tracking still needs a headset test.
- [x] 4.7 `components/system/desktop_fallback.tscn` grouping the XR Tools
      desktop-support nodes; the rig instances it only when XR failed to start
      (`XRServer.primary_interface == null` after `StartXR.xr_failed_to_initialize`).
- [x] 4.8 `components/system/debug_hud.tscn` (+ `.gd`), default off, never in
      release (`OS.is_debug_build()` check).
- [x] 4.9 Interactables prefabs in `components/interactables/` (one scene per
      XR Tools interactable with sensible defaults + a `Label3D` title) and
      `components/locomotion/` zone-side prefabs (teleport area, world grab
      area, wind area, climbable wall).
- [x] 4.10 Extend `FEATURE_NODES` + smoke-test assertions for every new node.
      Check green. Commit (one commit per sub-area is fine), push.
- [ ] 4.11 `godot-reviewer` pass on the diff; fix `high` findings.

**Acceptance:** every row in `FEATURES.md` with a toggle has a node/handler in
the rig; the smoke test asserts every path; the headless run is clean.

---

## Phase 5 — Showcase zone & menu (`feat:`)

- [x] 5.1 Build `game/zones/showcase/showcase_zone.tscn` + `showcase_zone_info.tres`
      per `ARCHITECTURE.md §6` with the five stations and `Label3D` titles.
      Use the existing prototype materials; no new art.
- [x] 5.2 Register it in `game/zones/zone_database.tres`.
- [x] 5.3 Start menu: "New Game" pane gets a **Showcase** button that calls a new
      `GameState.new_game_in_zone(zone_info)`; Options pane embeds
      `addons/godot-xr-tools/user_settings/user_settings_ui.tscn` with a working
      Back button (`start_ui.gd`).
- [x] 5.4 Add a "Showcase" entry to the wrist UI (zone switch) so testers can
      jump there from any zone.
- [x] 5.5 Check green (`--run`). Commit, push.

**Acceptance:** showcase loads headless without errors; zone database has 4 zones;
Options pane shows the settings UI.

---

## Phase 6 — Platform, export & CI (`chore:` / `ci:`)

- [x] 6.1 `project.godot`: MSAA is currently off everywhere (probed). Set
      `rendering/anti_aliasing/quality/msaa_3d=2` (4x) for desktop and the
      `.mobile` override `rendering/anti_aliasing/quality/msaa_3d.mobile=1` (2x)
      for Quest; add shadow atlas size overrides for mobile; document the knobs
      in `docs/HOWTO_NEW_GAME.md`.
- [x] 6.2 `export_presets.cfg`: stale filters gone (Phase 1), presets still
      export; `gradle_build/min_sdk`/`target_sdk` unchanged.
- [x] 6.3 CI (`publish-demo-on-push.yaml`): export step fails on error and on
      missing output; `BUTLER_USER_GAME` → `eedali/godot-vr-template` with a
      comment; verify `GODOT_VERSION` exists on
      `https://github.com/godotengine/godot-builds/releases` (web fetch); align
      README. `gdlint-on-push.yml`: lint `components game tools`, `setup-python@v5`.
- [x] 6.4 `bash tools/check.sh --export` → `build/windows/Game.exe` produced.
      If export templates are missing, note it in `PROGRESS.md` (the user can
      install them from the editor) and do not fail the phase on that alone.
- [ ] 6.5 Commit, push.

**Acceptance:** Windows debug export succeeds (or templates confirmed missing);
CI YAML passes `yamllint`-level sanity (valid YAML, no tabs).

---

## Phase 7 — Documentation (`docs:`)

- [ ] 7.1 Rewrite `README.md` (English): what the template is, feature list
      (link `docs/FEATURES.md`), quick start (PC + Quest), the one-config toggle
      story, folder layout, how to make a new game (link), credits/licence.
      Keep the useful operational notes from the current README (vendors,
      Android template, logs).
- [ ] 7.2 `docs/FEATURES.md` — user-facing version of the matrix (toggle, what,
      default, headset-tested? column).
- [ ] 7.3 `docs/HOWTO_NEW_GAME.md` — checklist: copy config, set `starting_zone`,
      package name/product name keys, icon/splash, keystore, per-platform knobs.
- [ ] 7.4 `docs/HOWTO_TOGGLE.md` (from Phase 2) — final pass.
- [ ] 7.5 `VERSIONS.md` / `docs/CHANGELOG.md` — add an entry for this overhaul
      (XR Tools 4.5.2, feature config, rig, showcase).
- [ ] 7.6 Commit, push.

**Acceptance:** a newcomer can go from clone to a toggled, exported build using
only the docs.

---

## Phase 8 — Final verification, push, report (`chore:`)

- [ ] 8.1 `bash tools/check.sh --run --export` green from a clean import
      (delete `.godot/imported` is **not** allowed; just run the import again).
- [ ] 8.2 `godot-reviewer` on `git diff main...HEAD`; fix `high` findings.
- [ ] 8.3 `PROGRESS.md` final table; `DECISIONS.md` complete.
- [ ] 8.4 `git push -u origin claude/template-overhaul`. If a PR can be opened
      with `gh pr create --fill --base main` (gh logged in), do it and record the
      URL; otherwise record the compare URL
      `https://github.com/eedali/Godot-VR-Template/compare/main...claude/template-overhaul`.
- [ ] 8.5 Print the final **Turkish** report (CLAUDE.md rule 2): what changed,
      what was verified, what needs a headset test (list every feature marked
      "needs headset test"), branch/PR link, push status.

---

## Headset-test list (append as you go; include in the final report)

- controller-free hand tracking (Quest 3)
- passthrough blend (Quest 3)
- teleport arc visuals in gl_compatibility
- vignette strength / comfort defaults
- collision-hands feel with climb + world-grab enabled
- 72/90/120 Hz target refresh rate switch
