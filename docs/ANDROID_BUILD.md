# Android Build Notes

## Export configuration

`project.godot` contains:

```ini
[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=0

[rendering]

textures/canvas_textures/default_texture_filter=0
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

`0` is landscape. The HUD anchors to the viewport. The joystick and combat
buttons are bottom-left/bottom-right; backpack and Build are intentionally at
top-left below the currency and XP bars. There is no minimap, no floating NPC
name labels and no timed toast banner.

## Remaining machine setup

1. Open in **Godot 4.7.2**.
2. Install matching Export Templates.
3. Install Android Studio or Android SDK command-line tools:
   - SDK Platform 34+,
   - Build Tools,
   - debug keystore.
4. Set Android SDK and debug keystore in Editor Settings.
5. Add an Android preset, enable Landscape, choose `arm64-v8a` (optionally
   `armeabi-v7a`), export.

Release builds need a release keystore. No keystore is committed.

## Device checklist

- Launch on 16:9 and 20:9.
- Joystick + Strike simultaneously.
- Pack/Build at top-left are reachable and do not overlap combat touch zones.
- Close buttons work in every modal.
- Tutorial Next/Skip touches work.
- Build mode drags buildings with one finger while movement is locked.
- `Game._notification` saves on pause/focus loss.
- Ten-segment player and five-segment pet bars remain legible.
- Player and pet XP bars remain legible beneath the currency row.
- Pet Battle Portal opens the tournament; Fight, the three skill buttons,
  Forfeit and Back work by touch. Verify the 2-second choice timer and both
  simultaneous health-bar updates.
- Forest tree impacts, aggro charges and battle SFX play through the device's
  media volume without external audio assets.
- Pet Food Buy/Feed buttons work in Nia's shop.
- Settlement raiders from sea and forest, resident flee paths, invulnerable tree
  impact VFX/SFX, forest-monster line-of-sight charges, resident cottages and
  defender attacks run at target frame rate.
- Play through: choose hero -> tutorial -> shop -> house -> pet food -> pet duel
  -> monster portal -> auto-loot -> emergency -> return -> defender battle ->
  recovery -> settlement editing -> save/continue.

Permanent daytime means there is no night-lighting performance test.
