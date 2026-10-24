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
