# Feature matrix

Goal: every row below is available in the template and can be switched on/off
from `config/vr_features_default.tres` (a `VRFeatureConfig` resource, see
`ARCHITECTURE.md`). "Toggle" is the exported property name on `VRFeatureConfig`.

Status legend — **wired**: already in `zone_base.tscn` today ·
**addon**: exists in XR Tools, just needs wiring · **custom**: must be written in
`components/` · **doc**: no runtime switch, documented only.

Rig placement legend — **L/R**: child of the left/right `XRController3D`
(inside the collision hand where one exists) · **origin**: child of `XROrigin3D` ·
**camera**: child of `XRCamera3D` · **body**: child of `XRToolsPlayerBody` ·
**zone**: placed in a zone scene, not on the rig.

## 1. Locomotion

| Feature | Toggle | XR Tools node | Status | Rig | Notes |
|---|---|---|---|---|---|
| Smooth (direct) movement | `direct_movement` | `functions/movement_direct.tscn` | wired | L (strafe) + R | Keep `order` defaults. |
| Strafe on left stick | `strafe` | property `strafe` on left `MovementDirect` | wired | L | |
| Turn (snap/smooth) | `turn` + `turn_mode` | `functions/movement_turn.tscn` | wired | R | `turn_mode` → `XRToolsMovementTurn.TurnMode` (DEFAULT follows user settings). |
| Teleport (arc) | `teleport` | `functions/function_teleport.tscn` | addon | L (and/or R) | README promised it; missing today. Default on. |
| Teleport areas (zone) | — | `objects/teleport_area.tscn` | addon | zone | Showcase zone demo. |
| Jump | `jump` | `functions/movement_jump.tscn` | wired | L+R | |
| Physical jump (crouch & spring) | `physical_jump` | `functions/movement_physical_jump.tscn` | addon | origin | Default off. |
| Crouch | `crouch` | `functions/movement_crouch.tscn` | wired | L+R | |
| Sprint | `sprint` | `functions/movement_sprint.tscn` | wired | origin | |
| Jog in place (arm swing) | `jog` | `functions/movement_jog.tscn` | addon | origin | Default off. |
| Climb | `climb` | `functions/movement_climb.tscn` + `objects/climbable.tscn` | addon | origin + zone | Needs `FunctionPickup` on both hands. Default off. |
| Flight | `flight` | `functions/movement_flight.tscn` | addon | L or R | Default off. |
| Glide | `glide` | `functions/movement_glide.tscn` | addon | origin | Default off. |
| Grapple | `grapple` | `functions/movement_grapple.tscn` | addon | R | Uses physics layer 5 "Grappling Target". Default off. |
| Wall walk | `wall_walk` | `functions/movement_wall_walk.tscn` | addon | origin | Layer 4. Default off. |
| World grab | `world_grab` | `functions/movement_world_grab.tscn` + `objects/world_grab_area.tscn` | addon | origin + zone | Default off. |
| Wind zones | — | `functions/movement_wind.tscn` + `objects/wind_area.tscn` | addon | origin + zone | Showcase only; toggle `wind`. Default off. |
| Footstep audio | `footsteps` | `functions/movement_footstep.tscn` + `audio/surface_audio.tscn` | addon | origin + zone | Default off (needs sounds). |
| Gravity zones (desktop) | — | `desktop-support/movement_gravity_zones.tscn` | addon | origin | Only with desktop fallback; doc. |

## 2. Comfort

| Feature | Toggle | XR Tools node | Status | Rig | Notes |
|---|---|---|---|---|---|
| Vignette (tunnelling) | `vignette` + `vignette_auto_adjust` | `effects/vignette.tscn` | addon | camera | Default on, auto-adjust on. |
| Head-in-wall fade | `head_behavior` | `XRToolsPlayerBody.head_behavior_mode` (Fade) | wired (default) | body | Expose as toggle (Fade vs Push-away vs Disabled). |
| Player height calibration | `height_calibration` | `XRToolsPlayerBody.player_calibrate_height` | wired | body | |
| Snap turn user setting | — | `XRToolsUserSettings.snap_turning` | addon | — | Shown in Options pane (Phase 5). |
| Loading-screen fade & "hold to continue" | — | `staging/loading_screen.tscn` | wired | staging | `prompt_for_continue` toggle `loading_prompt`. |
| Seated mode (no body) | `player_body` | `player/player_body.tscn` `enabled` | wired | origin | Off = seated/arcade experiences. |

## 3. Hands & interaction

| Feature | Toggle | XR Tools node | Status | Rig | Notes |
|---|---|---|---|---|---|
| Hand models (low-poly) | `hand_models` | `hands/scenes/lowpoly/*_hand_low.tscn` | wired | L+R | Full-detail hands available in addon; `hand_style` enum optional. |
| Collision hands (physical) | `collision_hands` | `hands/collision_hand.gd` | wired | L+R | When off, hands are kinematic (direct child of controller). |
| Pickup (near) | `pickup` | `functions/function_pickup.tscn` | wired | L+R | |
| Ranged pickup | `ranged_pickup` | property `ranged_distance`/`ranged_angle` | wired | L+R | Off = `ranged_distance = 0`. |
| Two-hand grab | — | `XRToolsPickable.second_hand_grab` | wired (crate/rock) | items | doc only. |
| Grab points / hand poses | — | `objects/grab_points/*` + `hands/poses/*` | wired (items) | items | doc only; showcase shows one. |
| Pointer (laser + UI) | `pointer` | `functions/function_pointer.tscn` | wired | L+R | `laser_visible` sub-toggle via `show_laser`. |
| Gaze pointer | `gaze_pointer` | `functions/function_gaze_pointer.tscn` | addon | camera | Default off. |
| Poke (finger press) | `poke` | `player/poke/poke.tscn` | wired | L+R (index tip) | |
| Pockets / snap zones on body | `pockets` | `components/persistent/persistent_pocket.tscn` | wired | body (+ back) | |
| Wrist UI | `wrist_ui` | `objects/viewport_2d_in_3d.tscn` + `game/zones/zone_wrist_ui.tscn` | wired | L | |
| Hand-pose detector / areas | `hand_pose_areas` | `functions/function_pose_detector.tscn` + `objects/hand_pose_area.tscn` | addon | L+R + zone | Default off. |
| Haptics / rumble | `haptics` | `rumble/*` + `XRToolsRumbleManager` autoload | addon | — | Add `components/feedback/haptics.gd` helper (`Haptics.pulse(hand, strength, ms)`). Default on. |
| Interactables | — | `interactables/*` (area button, handle, hinge, slider, joystick) | addon | zone | Showcase stations; prefab scenes in `components/interactables/`. |
| Snap zones / return-to-snap | — | `objects/snap_zone.tscn`, `objects/return_to_snap_zone.gd`, `snap_path.tscn` | addon | zone | Showcase. |
| Climbable objects | — | `objects/climbable.tscn` | addon | zone | Pairs with `climb`. |
| Virtual keyboard | `virtual_keyboard` | `objects/virtual_keyboard.tscn` | addon | zone/showcase | Default off. |
| Highlight ring | — | `objects/highlight/highlight_ring.tscn` | wired (pockets) | items | doc. |
| Pickable / area / surface audio | — | `audio/*` | addon | items/zone | Showcase. |
| Hold-to-activate button | — | `misc/hold_button.tscn` | wired (loading screen) | — | doc. |

## 4. System / platform

| Feature | Toggle | Where | Status | Notes |
|---|---|---|---|---|
| OpenXR hand tracking (controller-free) | `hand_tracking` | `project.godot` `xr/openxr/extensions/hand_tracking` + `hand_interaction_profile`; XR Tools hands `show_when_tracked` | custom/setting | Project setting is read at startup; the toggle sets `show_when_tracked` and documents the project key. |
| Passthrough (Quest MR) | `passthrough` | `components/system/passthrough_controller.gd` | custom | Sets `XRInterface.environment_blend_mode = XR_ENV_BLEND_MODE_ALPHA_BLEND`, `get_viewport().transparent_bg = true`, hides sky; also `StartXR.enable_passthrough`. Runtime toggleable. |
| Desktop fallback (WASD/mouse) | `desktop_fallback` | `addons/godot-xr-tools/desktop-support/*` | addon | Add `components/system/desktop_fallback.tscn` instanced by the rig when `XRServer.primary_interface` is null. |
| Target refresh rate | `target_refresh_rate` (int, 0 = default) | `StartXR.target_refresh_rate` | wired | 72/90/120 on Quest 3. |
| Physics rate multiplier | `physics_rate_multiplier` | `StartXR.physics_rate_multiplier` | wired | |
| Persistence / save-load | — | `components/persistent/*` | wired | doc; `save_file_password` exposed on `GameState`. |
| Scene switching + spawn points | — | staging + `zone_switch_area` | wired | doc. |
| User settings UI | — | `user_settings/user_settings_ui.tscn` | addon | Options pane (Phase 5). |
| Debug HUD (fps, frame time, battery) | `debug_hud` | `components/system/debug_hud.tscn` | custom | Viewport-in-3D label on the left wrist or camera; default off; never on in release (`OS.is_debug_build()`). |
| Quality presets per platform | — | `project.godot` `.mobile` overrides | custom | Phase 6. |
| Export presets (Quest APK/AAB, Windows, Linux, WebXR) | — | `export_presets.cfg` | wired | Clean stale filters (AUDIT C1). |
| CI build | — | `.github/workflows` | wired | Harden (AUDIT D1–D4). |

## 5. Not in scope (document as "add when needed")

- Multiplayer / networking, Steamworks SDK, Meta Platform SDK (achievements,
  entitlement), analytics, localisation beyond Godot's built-in `tr()`.
- Eye tracking (Quest 3 has none; Quest Pro only).
- Body tracking / full-body IK.
