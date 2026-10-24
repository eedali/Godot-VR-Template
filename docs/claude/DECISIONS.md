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
