# Industrial Pack Asset Library

This directory is intentionally separate from the existing `assets/game`, `scenes/props`, and `resources/tilesets` trees.

## Source

- `art/industrial.png` is extracted from `particle_example.zip`.
- The pack is treated as a 16x16 atlas.

## Complete Extraction

`extracted/` contains a complete generated extraction of every alpha-visible pixel in the atlas:

- `extracted/by_cell/<category>/`  
  Every non-empty 16x16 atlas cell exported as an individual PNG. This is the safest set for tile-by-tile level building.

- `extracted/connected_objects/<category>/`  
  Every 8-neighbor connected visible pixel region exported as an individual transparent PNG. This is the closest automatic split for standalone visible objects.

- `extracted/manifests/industrial_extraction_manifest.json`  
  Machine-readable index with source rectangles, categories, counts, and coverage flags.

- `extracted/contact_sheets/`  
  Category preview sheets for quick browsing.

Coverage in the manifest must remain complete for both extraction sets before treating the extraction as up to date.

## Drag-Ready Scenes

- `scenes/extracted/by_cell/<category>/`  
  Drag-ready `Sprite2D` scenes for all 407 exported 16x16 cell PNGs.

- `scenes/extracted/connected_objects/<category>/`  
  Drag-ready `Sprite2D` scenes for all 483 automatically isolated connected-object PNGs.

- `scenes/extracted/drag_scene_manifest.csv`  
  Machine-readable mapping from each extracted PNG to its generated scene.

- `scenes/industrial_block.tscn`  
  StaticBody2D block that tiles one atlas cell across `block_size`.
- `scenes/blocks/plated_block.tscn`, `grated_block.tscn`, `dark_panel_block.tscn`, `concrete_block.tscn`  
  Ready-made block variants for quick level layout.

- `scenes/industrial_button.tscn`  
  Area2D button. Set `button_kind` to Safe, Danger, Unknown, Goal, or Forbidden. It emits `pressed(button)` and can also be activated by player interaction.
- `scenes/buttons/safe_button.tscn`, `danger_button.tscn`, `unknown_button.tscn`, `goal_button.tscn`, `forbidden_button.tscn`  
  Ready-made button variants for dragging directly into a level.

- `scenes/industrial_spike_strip.tscn`  
  Area2D hazard strip. Calls `die()` on bodies that support it.

- `scenes/industrial_door.tscn`  
  A door using the existing `Door` script, with industrial atlas visuals.

- `scenes/industrial_robot.tscn`, `industrial_screen.tscn`, `industrial_warning_panel.tscn`  
  Simple display props using atlas regions.
- `scenes/props/robot_square.tscn`, `screen_panel.tscn`, `warning_panel.tscn`, `terminal.tscn`  
  Ready-made prop variants.

## Showcase

`res://scenes/levels/level_02.tscn` is currently a showcase level for this pack. The level root uses `scripts/industrial_showcase_level.gd`, so stepping on each button changes a visible room state.

## Texture Resources

`resources/atlas_textures/` contains small `AtlasTexture` resources for direct use in Sprite2D, UI, particles, or quick prototypes.

## TileSet

`resources/industrial_tileset_basic.tres` is a small starter TileSet with selected atlas cells. For level building, the block scene is currently safer because it has simple exported sizing and collision.
