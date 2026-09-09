# HOLLOW WARD - Blender asset contract

GLB (binary glTF), textures embedded (<=1024px, PBR metallic-roughness), Y-up,
1 unit = 1 meter, pivot at floor-center, front faces -Z (Godot forward).
No lights/cameras. Loader path: res://assets/models/<name>.glb (exact names).

| file | spec |
|---|---|
| hollowed_shambler.glb | emaciated patient, tattered gown, original design. Rigged, ~1.75 m tall, <=20k tris. Animations: idle, walk, attack, stagger, death |
| pistol.glb | heavy service pistol, pivot at grip, barrel along -Z, <=3k tris |
| door_ward.glb | institutional door + frame, opening 1.0 x 2.1 m, leaf pivot at hinge edge |
| save_desk.glb | clerk desk with open brass-bound ledger, ~1.4 x 0.9 m |
| ward_key.glb | oversized ornate brass key, ~0.15 m |
| salve_plant.glb | pale fern in cracked pot, ~0.4 m |
| ammo_box.glb | battered ammo box, ~0.15 m |
| keypad_lock.glb | wall keypad, ~0.2 x 0.3 m |
| gurney.glb / wheelchair.glb / cabinet.glb / ceiling_lamp.glb / note_paper.glb | ward props |

Art direction: grimy institutional, desaturated bone + oxidized teal, one amber
accent. Every file optional-but-atomic: a styled placeholder fills any gap.
