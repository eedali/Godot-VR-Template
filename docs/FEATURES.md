# Features

Every mechanic below ships with the template and is switched on or off in
**one place**: the `VRFeatureConfig` resource named by the project setting
`vr_template/feature_config` (default `res://config/vr_features_default.tres`).
How to use it: [HOWTO_TOGGLE.md](HOWTO_TOGGLE.md).

Columns:
- **Default** — value in `vr_features_default.tres`.
- **Verified** — `headless`: covered by the automated checks (`tools/check.sh
  --run` loads every zone with the default config, with every feature on and
  with a minimal config, and toggles features at runtime) · `needs headset`:
  the code path runs headless but the feel/visuals must be checked on a Quest
  or PC VR headset (see the list at the bottom).

Try them all in the **Showcase** zone (start menu → New Game → Showcase, or the
wrist menu's *Showcase* button). Each station shows the live on/off state of
its toggles.

## Locomotion

| Feature | Toggle | Default | What it does | Verified |
|---|---|---|---|---|
| Smooth movement | `direct_movement` | on | Thumbstick movement (both sticks forward/back) | headless |
| Strafe | `strafe` | on | Sideways movement on the left stick | headless |
| Turning | `turn` | on | Right stick turns | headless |
| Turn mode | `turn_mode` | Default | `DEFAULT` follows the user setting (Options → snap turning), `SNAP`, `SMOOTH` | headless |
| Teleport | `teleport` | on | Left trigger: arc teleport; the left stick turns the landing direction while aiming; pauses while the left pointer is on UI or the hand holds something | needs headset |
| Jump | `jump` | on | A / X | headless |
| Physical jump | `physical_jump` | off | Jump by jumping (or swinging the arms) | needs headset |
| Crouch | `crouch` | on | Hold B / Y | headless |
| Sprint | `sprint` | on | Click the left stick | headless |
| Jog in place | `jog` | off | Swing the arms to walk / run | needs headset |
| Climb | `climb` | off | Grab `climbable_wall` / any `XRToolsClimbable` (needs `pickup`) | needs headset |
| Flight | `flight` | off | Left B / Y toggles flying (left crouch is off while flight is on) | needs headset |
| Glide | `glide` | off | Spread the arms while falling | needs headset |
| Grapple | `grapple` | off | Right trigger at a target on physics layer 5 (`grapple_target`); pauses while the right pointer is on UI or the hand holds something | needs headset |
| Wall walk | `wall_walk` | off | Walk on surfaces on physics layer 4 (`wall_walk_surface`) | needs headset |
| World grab | `world_grab` | off | Grab inside a `world_grab_area` to pull yourself (needs `pickup`) | needs headset |
| Wind | `wind` | off | `wind_area`s push the player | needs headset |
| Footsteps | `footsteps` | off | Step sounds from `XRToolsSurfaceAudio` in the zone | needs headset |

Zone-side pieces in `components/locomotion/`: `teleport_area` (teleporter pad
with a `Destination` marker), `climbable_wall`, `grapple_target`,
`wall_walk_surface`, `world_grab_area`, `wind_area`.

## Comfort

| Feature | Toggle | Default | What it does | Verified |
|---|---|---|---|---|
| Vignette | `vignette` | on | Tunnel vision while moving / turning | needs headset |
| Vignette auto-adjust | `vignette_auto_adjust` | on | Strength follows speed; off = permanent tunnel (`PlayerRig.static_vignette_radius`) | needs headset |
| Head in wall | `head_behavior` | Fade | Push away / Fade / Disabled | needs headset |
| Height calibration | `height_calibration` | on | Calibrate the player height from the headset at start | needs headset |
| Player body | `player_body` | on | Physical body. Off = seated game: movement features, teleport, hip pockets and zone-switch areas need the body and stop working | headless |
| Loading prompt | `loading_prompt` | off | "Hold to continue" on every scene load (off: only the first) | headless |

The user's own comfort options (snap turning, dead zones, haptics scale,
player height) are in the start menu → **Options** (XR Tools user settings UI).

## Hands & interaction

| Feature | Toggle | Default | What it does | Verified |
|---|---|---|---|---|
| Hand models | `hand_models` | on | Low-poly animated hands | headless |
| Collision hands | `collision_hands` | on | Hands stop at walls and tables; off = hands follow the controllers exactly | needs headset |
| Pickup | `pickup` | on | Grip picks up objects (switching it off drops what you hold) | headless |
| Ranged pickup | `ranged_pickup` | on | Pick up from a distance | needs headset |
| Pointer | `pointer` | on | Laser pointer for UI and pointable objects (both hands) | headless |
| Laser visible | `laser_visible` | on | Show the laser (off = invisible pointer) | headless |
| Gaze pointer | `gaze_pointer` | off | Head pointer; look at a target for 1.5 s to click | needs headset |
| Poke | `poke` | on | Press buttons / UI with the index finger tip | needs headset |
| Pockets | `pockets` | on | Two hip pockets and a back pocket (backpack) | needs headset |
| Wrist menu | `wrist_ui` | on | Save / Quit / Showcase on the left wrist | headless |
| Hand-pose areas | `hand_pose_areas` | off | Hands change pose inside a `hand_pose_area` | needs headset |
| Haptics | `haptics` | on | Rumble on pick-up, drop and pointer press; `Haptics.pulse()` for your code | needs headset |
| Virtual keyboard | `virtual_keyboard` | off | Shows `components/interactables/virtual_keyboard.tscn` instances | headless |

Interactable prefabs in `components/interactables/`: `push_button`, `lever`
(hinge), `slider`, `joystick`, `snap_zone`, `hand_pose_area`,
`virtual_keyboard`. Two-hand grab and grab points work on any
`XRToolsPickable` (see `game/items/crate` and `rock`).

## System

| Feature | Toggle | Default | What it does | Verified |
|---|---|---|---|---|
| Hand tracking | `hand_tracking` | on | Controller-free hands (pinch = trigger, grasp = grip); off hides hands driven by optical tracking | needs headset |
| Passthrough | `passthrough` | off | Mixed reality on Quest (project setting `xr/openxr/extensions/meta/passthrough` is on so the runtime offers alpha blend); can be switched at runtime (showcase kiosk button) | needs headset |
| Desktop fallback | `desktop_fallback` | on | WASD / arrows, mouse look, Space, C / Ctrl, Shift, left click when no headset is found | headless |
| Debug HUD | `debug_hud` | off | FPS / frame time / draw calls / memory panel (debug builds only) | needs headset |
| Refresh rate | `target_refresh_rate` | 0 | Display Hz (0 = runtime default; Quest 3: 72 / 90 / 120) | needs headset |
| Physics rate | `physics_rate_multiplier` | 1 | Physics ticks per display frame | headless |
| Remove disabled nodes | `remove_disabled_nodes` | off | Free the nodes of disabled features at startup (no runtime re-enable) | headless |

Always on (no toggle): persistence (save / load, items carried between
zones), zone switching with spawn points, the start menu, the loading screen.

## Not included

Multiplayer, Steamworks, Meta Platform SDK (achievements, entitlement checks),
analytics, eye tracking (Quest 3 has none), full-body tracking / IK.

## Needs a headset test

The automated checks run without a headset. Before relying on a feature in a
game, try it on the device:

1. Hand tracking: put the controllers down, raise the hands; pinch on UI, grasp a crate.
2. Passthrough: showcase kiosk button; the sky disappears, geometry stays.
3. Teleport arc visuals in `gl_compatibility`; trigger on UI must not teleport.
4. Vignette strength while smooth-turning and walking.
5. Collision hands (now on layer 18) against walls and while reaching for pockets.
6. Climb / world grab with collision hands enabled.
7. Flight with the left B / Y button.
8. Refresh rate 72 / 90 / 120 Hz.
9. Haptics on pick-up, drop and UI clicks.
10. Debug HUD readability in a debug build.
