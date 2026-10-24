# How to switch VR features on and off

Every VR mechanic of the template is controlled by **one resource**: a
`VRFeatureConfig` (`res://config/vr_feature_config.gd`). The template ships the
defaults in `res://config/vr_features_default.tres`. The `VRFeatures` autoload
loads it at startup and every `PlayerRig` applies it.

## 1. Make a configuration for your game

1. In the FileSystem dock, duplicate `res://config/vr_features_default.tres`
   (right click → *Duplicate…*), e.g. to `res://config/my_game_features.tres`.
2. Open **Project → Project Settings → General**, enable *Advanced Settings*,
   find **Vr Template → Feature Config** (`vr_template/feature_config`) and set
   it to your file. (Or edit `project.godot`:
   `[vr_template]` → `feature_config="res://config/my_game_features.tres"`.)
3. Select your `.tres` and tick / untick features in the inspector. The groups
   (Locomotion, Comfort, Hands & Interaction, System, Behaviour) match the table
   below.
4. Run the game. In debug builds the log prints one line per disabled feature,
   e.g. `VRFeatures: jog -> off (MovementJog)`.

If the setting is missing or points at a file that is not a `VRFeatureConfig`,
`VRFeatures` logs a warning and uses the built-in defaults.

## 2. Change features at runtime

```gdscript
# Query
if VRFeatures.is_enabled(&"teleport"):
	pass

# Switch a boolean feature (rigs react immediately)
VRFeatures.set_enabled(&"vignette", false)

# Change a non-boolean setting
VRFeatures.set_value(&"turn_mode", XRToolsMovementTurn.TurnMode.SNAP)

# Swap the whole configuration (e.g. a level that forbids teleport)
VRFeatures.replace_config(load("res://config/no_teleport.tres"))

# React to changes in your own code
VRFeatures.feature_changed.connect(func(feature, enabled): print(feature, enabled))
```

The resource on disk is never modified at runtime: `VRFeatures` works on a
copy.

**`remove_disabled_nodes`** (Behaviour group): when on, the nodes of features
that are off at startup are freed (zero runtime cost, but they cannot be
switched back on until the next zone load). When off (default), they stay in
the tree disabled and can be re-enabled at runtime.

## 3. The toggles

Default = value in `vr_features_default.tres`. "Rig" says where the node lives
in `components/player/player_rig.tscn` (L/R = left/right hand, origin, camera,
body = `PlayerBody`, zone = must also be placed in the zone scene).

### Locomotion

| Toggle | Default | What it does | Rig |
|---|---|---|---|
| `direct_movement` | on | Smooth movement with the thumbsticks | L + R |
| `strafe` | on | Sideways movement on the left stick | L |
| `turn` | on | Turning with the right stick | R |
| `turn_mode` | Default | `DEFAULT` follows the user setting (Options menu), `SNAP`, `SMOOTH` | R |
| `teleport` | on | Arc teleport on the left trigger | L |
| `jump` | on | Jump with A/X | L + R |
| `physical_jump` | off | Jump by jumping in real life | origin |
| `crouch` | on | Crouch with B/Y | L + R |
| `sprint` | on | Sprint by clicking the left stick | origin |
| `jog` | off | Jog in place (arm swing) to move | origin |
| `climb` | off | Climb `XRToolsClimbable` objects (needs pickup) | origin + zone |
| `flight` | off | Fly; left B/Y starts/stops flying (the left-hand crouch is switched off while flight is on) | origin |
| `glide` | off | Glide by spreading the arms while falling | origin |
| `grapple` | off | Grapple hook on the right trigger (targets on physics layer 5) | R |
| `wall_walk` | off | Walk on surfaces on physics layer 4 | origin |
| `world_grab` | off | Pull yourself through `world_grab_area`s | origin + zone |
| `wind` | off | `wind_area`s push the player | origin + zone |
| `footsteps` | off | Footstep audio (needs surface audio in the zone) | origin + zone |

### Comfort

| Toggle | Default | What it does | Rig |
|---|---|---|---|
| `vignette` | on | Tunnelling vignette while moving / turning | camera |
| `vignette_auto_adjust` | on | Vignette strength follows movement speed | camera |
| `head_behavior` | Fade | Head in a wall: Push away / Fade / Disabled | body |
| `height_calibration` | on | Calibrate player height from the headset | body |
| `player_body` | on | Physical player body; off for seated / arcade games | origin |
| `loading_prompt` | off | "Hold to continue" on every scene load (off: first load only) | staging |

### Hands & interaction

| Toggle | Default | What it does | Rig |
|---|---|---|---|
| `hand_models` | on | Low-poly hand meshes | L + R |
| `collision_hands` | on | Hands collide with the world | L + R |
| `pickup` | on | Grab objects with the grip | L + R |
| `ranged_pickup` | on | Grab objects from a distance | L + R |
| `pointer` | on | Laser pointer for UI / pointable objects | L + R |
| `laser_visible` | on | Show the laser (off = invisible pointer) | L + R |
| `gaze_pointer` | off | Head (gaze) pointer | camera |
| `poke` | on | Press UI / buttons with the index finger tip | L + R |
| `pockets` | on | Hip pockets and back pocket | body + camera |
| `wrist_ui` | on | Wrist menu on the left hand | L |
| `hand_pose_areas` | off | Hand-pose detection for `hand_pose_area`s | L + R + zone |
| `haptics` | on | Controller rumble through `Haptics.pulse()` | — |
| `virtual_keyboard` | off | Virtual keyboard objects in zones | zone |

### System

| Toggle | Default | What it does | Rig |
|---|---|---|---|
| `hand_tracking` | on | Show hands for controller-free hand tracking (project setting `xr/openxr/extensions/hand_tracking` must also be on) | L + R |
| `passthrough` | off | Mixed-reality passthrough (Quest) | origin |
| `desktop_fallback` | on | Keyboard / mouse controls when no headset is found | origin |
| `debug_hud` | off | FPS / frame time / draw calls / memory panel (debug builds only; Godot 4 has no battery API) | camera |
| `target_refresh_rate` | 0 | Display refresh rate in Hz; 0 = runtime default (Quest 3: 72/90/120) | staging |
| `physics_rate_multiplier` | 1 | Physics ticks per display frame | staging |

### Behaviour

| Toggle | Default | What it does |
|---|---|---|
| `remove_disabled_nodes` | off | Free the nodes of disabled features at startup instead of disabling them |

## 4. Adding a new toggle

1. Add an `@export var my_feature : bool = …` to `config/vr_feature_config.gd`
   in the right group, and the value to `config/vr_features_default.tres`.
2. Add the name to `REQUIRED_FEATURES` in `tools/smoke_test.gd` and a row to
   `docs/FEATURES.md`.
3. Add the node path(s) to `FEATURE_NODES` in
   `components/player/player_rig.gd` (or a special-case handler).
4. `bash tools/check.sh` — the smoke test fails if a path does not exist.
