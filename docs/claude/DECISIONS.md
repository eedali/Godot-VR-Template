# Decisions log

Instead of asking the user, Claude Code records each judgement call here.
One entry per decision. Newest at the bottom.

Format:

```
### D-<n> — <short title>   (<phase>, <date>)
Context: what was ambiguous
Decision: what was chosen
Alternatives: what else was considered and why it lost
Reversible: yes/no — how
```

### D-0 — Defaults chosen before work started (planning, 2026-10-24)
Context: the user asked for a template with every feature available and easy
to switch off, no questions during execution.
Decision: toggles live in a single `VRFeatureConfig` resource; the default
config reproduces today's behaviour plus teleport, vignette, haptics,
hand-tracking and desktop fallback; "exotic" locomotion (climb, flight, glide,
grapple, wall-walk, world-grab, jog, physical jump, wind, footsteps) ships off.
Alternatives: ProjectSettings-only toggles (no inspector grouping, no per-game
copies); per-zone exports (duplicated config). Both lost to the resource.
Reversible: yes — edit `config/vr_features_default.tres`.

### D-1 — `setup_vendors.sh` install check   (phase 0, 2026-10-24)
Context: the script tested for `addons/godotopenxrvendors/plugin.cfg`, but the
4.3.0 addon is a GDExtension with `plugin.gdextension` and no `plugin.cfg`, so
it re-downloaded and replaced the (identical) addon on every run.
Decision: check for `plugin.gdextension`; print the version from the addon's
CHANGES file.
Alternatives: leave it (wasteful, deletes the folder each run).
Reversible: yes — one line in `tools/setup_vendors.sh`.

### D-2 — `--xr-mode off` for every project run in checks   (phase 0, 2026-10-24)
Context: `xr/openxr/enabled=true`; running the project headless without an HMD
makes Godot show a modal "OpenXR was requested but failed to start" alert on
Windows (the user reported it during the baseline run).
Decision: `tools/check.sh` passes `--headless --xr-mode off` to the smoke test
and the headless run; docs updated. `xr/openxr/startup_alert` stays at its
default (true) so real players still learn why VR did not start.
Alternatives: set `xr/openxr/startup_alert=false` project-wide (hides a useful
message from players and testers with a misconfigured runtime).
Reversible: yes — remove `--xr-mode off` from `RUN_FLAGS`.

### D-3 — Normalise `export_presets.cfg` line endings   (phase 1, 2026-10-24)
Context: the committed file had `CR CR LF` line endings (git stored it as
binary, `-text`), so any text tool edit produced a whole-file diff.
Decision: strip every `CR` (LF only, as `.gitattributes` asks) in the same
commit that removes the stale Godot 3 `exclude_filter` values (AUDIT C1).
`git diff -w` shows only the three filter lines.
Alternatives: keep the broken endings (every later edit would be unreadable).
Reversible: yes — git history.

### D-4 — Skip the headless scene re-save (A6)   (phase 1, 2026-10-24)
Context: GODOT_NOTES §4 suggests re-saving scenes from a `--script` run to add
`uid=` to path-only `ext_resource` lines.
Decision: tried it; `ResourceSaver.save` in a SceneTree script **dropped** every
existing `uid=` (including the scenes' header uids) and rewrote typed arrays.
Reverted with `git checkout -- game components`, removed the helper script,
marked 1.5 `[~]`. Path-only references keep working; the editor adds uids the
next time a scene is saved by hand.
Alternatives: hand-add uids (error-prone; GODOT_NOTES says never hand-write uids).
Reversible: n/a.

### D-5 — Fix the `script_class` header of the item-type resources too   (phase 1, 2026-10-24)
Context: AUDIT A7 named the three `*_zone_info.tres`; the four
`game/items/*/*_type.tres` had the same stale header (`ItemType` vs
`PersistentItemType`).
Decision: fixed all seven headers.
Reversible: yes.

### D-6 — `head_behavior` instead of `head_fade`   (phase 2, 2026-10-24)
Context: FEATURES.md named the head-in-wall toggle `head_fade`, while
ARCHITECTURE.md and PLAN 4.2 use `head_behavior` with the three XR Tools modes
(Push away / Fade / Disabled).
Decision: one setting, `head_behavior` (int enum mirroring
`XRToolsPlayerBody.head_behavior_mode`); FEATURES.md updated. A bool cannot
express three modes.
Alternatives: both names (two switches for one thing).
Reversible: yes.

### D-7 — `VRFeatures` API details   (phase 2, 2026-10-24)
Context: ARCHITECTURE §2 sketches `feature_changed(name, enabled : bool)` but
some settings are ints/enums (`turn_mode`, `head_behavior`,
`target_refresh_rate`, `physics_rate_multiplier`).
Decision: keep `feature_changed` for bool toggles and add
`value_changed(feature, value)` emitted for every change (rigs listen to this
one) plus `set_value()`; values are `type_convert`ed to the setting's type.
The config is loaded in `_init` (not `_ready`) so other autoloads/scenes can
query it from their own `_ready`. The project setting
`vr_template/feature_config` is written to `project.godot` (discoverable in
Project Settings) and still read with a default.
Alternatives: a Variant-typed `feature_changed` (breaks the documented
signature).
Reversible: yes.

### D-8 — `loading_prompt` semantics   (phase 2, 2026-10-24)
Context: today the first scene load shows "hold to continue" and
`GameStaging` clears `prompt_for_continue` after it. ARCHITECTURE defaults
`loading_prompt` to false.
Decision: `loading_prompt = true` keeps the prompt on every load;
false (default) is today's behaviour (first load only).
Reversible: yes.
