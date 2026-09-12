extends SceneTree
## One-shot level builder: rebuilds the TileSet from assets/tiles.png as
## four 32px tiles (0 top / 1 fill / 2 edge-L / 3 edge-R) with full-square
## physics, then paints the GRAVITY-FROG level and re-saves main.tscn.
## Run: godot --headless --path . --script res://tools/paint_level.gd

const PITS := {14: true, 15: true, 30: true, 31: true, 32: true}
const GX0 := -6
const GX1 := 70
const GY := 12


func _init() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var scene: Node = packed.instantiate()
	var layer: TileMapLayer = scene.get_node("TileMapLayer")

	var tex: Texture2D = load("res://assets/tiles.png")
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()
	var square := PackedVector2Array(
		[Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	for i in range(4):
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	for i in range(4):
		var td: TileData = src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, square)
	layer.tile_set = ts
	layer.clear()

	# Ground top row with pits + edge tiles at cuts.
	for x in range(GX0, GX1 + 1):
		if PITS.has(x):
			continue
		var left_gap := PITS.has(x - 1) or x == GX0
		var right_gap := PITS.has(x + 1) or x == GX1
		var idx := 0
		if left_gap and right_gap:
			idx = 0
		elif left_gap:
			idx = 2
		elif right_gap:
			idx = 3
		layer.set_cell(Vector2i(x, GY), 0, Vector2i(idx, 0), 0)
	# Dirt fill under ground (skip pits).
	for x in range(GX0, GX1 + 1):
		if PITS.has(x):
			continue
		layer.set_cell(Vector2i(x, GY + 1), 0, Vector2i(1, 0), 0)
		layer.set_cell(Vector2i(x, GY + 2), 0, Vector2i(1, 0), 0)
	# Ceiling runway (walk it upside-down) + thickness.
	for x in range(20, 41):
		layer.set_cell(Vector2i(x, 1), 0, Vector2i(1, 0), 0)
		layer.set_cell(Vector2i(x, 0), 0, Vector2i(1, 0), 0)
	# Floating platforms.
	_platform(layer, 8, 10, 8)
	_platform(layer, 18, 21, 9)
	_platform(layer, 24, 26, 6)
	_platform(layer, 36, 38, 8)
	_platform(layer, 44, 47, 9)
	_platform(layer, 52, 54, 6)

	var out := PackedScene.new()
	out.pack(scene)
	ResourceSaver.save(out, "res://main.tscn")
	print("LEVEL PAINTED")
	quit()


func _platform(layer: TileMapLayer, x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		var idx := 0
		if x == x0:
			idx = 2
		elif x == x1:
			idx = 3
		layer.set_cell(Vector2i(x, y), 0, Vector2i(idx, 0), 0)
