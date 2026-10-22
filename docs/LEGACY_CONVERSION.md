# Pixel Art Top Down — Godot 4 port

A native Godot 4.7 port of the Unity project in
`../GAME_COMP_RPG-2026-10-09_22-39-09` (the Cainos *Pixel Art Top Down – Basic*
demo plus the Unisza chest / point-and-click additions).

Open `project.godot` in Godot 4.7 and press **F5**. The main scene is
`scenes/main.tscn`.

## Controls

| Input | Action |
| --- | --- |
| **WASD** / **arrow keys** | Walk (takes over from a click immediately) |
| **Left click** | Walk to the clicked spot |
| **E** | Open the chest when standing next to it |

## What was converted

| Unity | Godot |
| --- | --- |
| `SC Demo.unity` (639 YAML objects) | `scenes/main.tscn` (548 nodes) |
| 264 prefab instances + their overrides | Instanced in place, transforms/sorting/refs applied |
| 9 Tilemaps | 9 `TileMapLayer`s, 875 cells total, cell-for-cell identical |
| Tile assets (`*.asset`) | `TileSet` + `TileSetAtlasSource` in `assets/tilesets/` |
| 337 sprite slices from 9 atlases | `AtlasTexture` resources in `assets/sprites/` |
| `SpriteRenderer` + `MT Shadow` material | `Sprite2D` + `modulate` tint (no shader needed) |
| 4 sorting layers × sorting order | absolute `z_index` = `layer * 100 + order` |
| `BoxCollider2D` / `CircleCollider2D` / `EdgeCollider2D` | `CollisionShape2D` / `CollisionPolygon2D` |
| `TilemapCollider2D` | TileSet physics polygons from the sprite physics shapes |
| `CameraFollow.cs` | `scripts/camera_follow.gd` |
| `ChestInteract.cs` | `scripts/chest_interact.gd` |
| `PointAndClickController.cs` | `scripts/point_and_click_controller.gd` |
| `WelcomePopup.cs` | `scripts/welcome_popup.gd` |
| `PropsAltar.cs` | `scripts/props_altar.gd` |
| `SpriteColorAnimation.cs` | `scripts/sprite_color_animation.gd` |
| `StairsLayerTrigger.cs` | `scripts/stairs_layer_trigger.gd` |
| `TopDownCharacterController.cs` + the Animator | `scripts/player_visual.gd` (replaces both) |
| `ControlMode.cs` / `ControlModePrefs` | `scripts/control_mode.gd` |
| Legacy `UI.Text` popup | `CanvasLayer` → `ColorRect` + `Label` (theme overrides) |

## Things worth knowing

**Y axis.** Unity is Y-up, Godot is Y-down, so world Y is negated on conversion
(and rotation signs flip with it). TileMapLayer is the one non-negation: Unity
cell `(x, y)` becomes Godot cell `(x, -y - 1)` because Godot's grid is Y-down
from the top-left.

**Pixels per unit.** Godot has no PPU concept, so every `Sprite2D` carries
`scale = 1/32` and the camera uses `zoom = 72` (720 px / 10 world units, matching
Unity's orthographic size of 5). Tilemap layers get the same `1/32` scale.

**The player's "animation" was not frame animation.** The Unity Animator only
drove the sliced `SpriteRenderer.m_Size.y` between `1.40 → 1.45 → 1.40` (idle)
and `1.35 → 1.45 → 1.35` (moving). `player_visual.gd` reproduces those exact
keyframes as a squash-and-stretch, and swaps the four directional stills
(`F`/`B`/`S`, with East reusing `S` flipped).

**Shadows need no shader.** `MT Shadow` multiplies by `_Color` and outputs
premultiplied alpha with `Blend One OneMinusSrcAlpha`. That is arithmetically
identical to Godot's default mix blending with the same colour in `modulate`, so
the tint moves onto the node.

**Stair triggers.** The original swapped a Unity physics layer *and* a sorting
layer. The project's `Physics2D` layer matrix has all four layers colliding with
one another, so the physics half was a no-op; only the sorting (draw order)
change was visible. The port therefore changes `z_index` only.

**Unresolved by design.** `TopDownCharacterController.cs` is intentionally not
ported: `PointAndClickController` disables it at runtime in Unity, and the
Godot player is a `CharacterBody2D` driven solely by the point-and-click
controller. The four nine-sliced player sprites are stretched rather than
nine-patched because Unity's slice borders on that sprite add up to more than
the target height, so Unity itself effectively scaled the whole frame.

## Re-running the conversion

The converter reads the original Unity YAML directly; it needs no Unity install.

```sh
godot --headless --path . --script tools/convert.gd -- --assets-only
godot --headless --path . --import
godot --headless --path . --script tools/convert.gd
```

Pass 1 copies textures and writes `AtlasTexture` resources. `--import` turns
those PNGs into imported textures. Pass 2 builds the `TileSet`s (which need the
imported textures), encodes the tilemap cell data through a real `TileMapLayer`,
and writes `scenes/main.tscn`. Output notes land in `CONVERSION.md`.

## Verifying

```sh
# structure: does the scene load, are the expected nodes there
godot --headless --path . --script tools/smoke_test.gd

# behaviour: click-to-move, keyboard, chest + popup, stairs triggers
godot --path . --script tools/play_test.gd -- --shots <dir>
```

Both exit non-zero if a check fails.

## Layout

```
assets/textures/   9 source atlases copied from Unity
assets/sprites/    337 AtlasTexture slices (one per Unity sprite)
assets/tilesets/   9 TileSets with per-tile colliders
scenes/main.tscn   the converted scene
scripts/           GDScript ports of every gameplay script
tools/             converter and test harnesses
```
