extends Node2D
# UI ไม่ถือ state ของโครงสร้าง/ของ: อยู่ใน BuildGrid กับ Inventory ทั้งหมด

const REASONS : Dictionary = {
	BuildResult.OK: "วางแล้ว",
	BuildResult.OUT_OF_BOUNDS: "ออกนอกพื้นที่",
	BuildResult.OVERLAP: "มีของวางทับอยู่",
	BuildResult.CANNOT_ROTATE: "ชิ้นนี้หมุนไม่ได้",
	BuildResult.NOT_ENOUGH: "ไม่มีชิ้นนี้ในกระเป๋า",
	BuildResult.NO_STRUCTURE: "ไม่มีอะไรให้รื้อ",
	BuildResult.CHEST_NOT_EMPTY: "หีบยังมีของ เอาออกก่อน",
	BuildResult.INVENTORY_FULL: "กระเป๋าเต็ม รื้อไม่ได้",
}
const CAT_COLORS : Array = [Color(0.55, 0.45, 0.3), Color(0.5, 0.5, 0.55), Color(0.3, 0.5, 0.8), Color(0.8, 0.6, 0.2)]
const CAT_NAMES : Array = ["พื้น", "ผนัง", "สถานี", "หีบ"]   # ลำดับต้องตรง BuildingCategory

var db : ItemDatabase = ItemDatabase.new()
var inv : Inventory = Inventory.new()
var grid : BuildGrid = BuildGrid.new()
var build_mode : bool = false
var cat : int = 0
var sel_id : StringName = &""
var rot : int = 0
var _cell : Vector2i = Vector2i.ZERO
var _ghost : Dictionary = {}
var status : Label
var cat_bar : HBoxContainer
var piece_grid : GridContainer
var hint : Label
var msg : Label

func _ready() -> void:
	db.load_from_directory("res://data/")
	for e in [[&"floor_00", 20], [&"wall_00", 20], [&"workbench_00", 2], [&"chest_00", 2], [&"stone_00", 50]]:
		inv.add_to_existing_stacks(db, e[0], e[1])
	inv.inventory_changed.connect(_refresh_pieces)
	_build_ui()
	_set_mode(false)

func _build_ui() -> void:
	var layer : CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var panel : VBoxContainer = VBoxContainer.new()
	panel.position = Vector2(680, 10)
	panel.custom_minimum_size = Vector2(380, 0)
	layer.add_child(panel)
	status = Label.new()
	panel.add_child(status)
	cat_bar = HBoxContainer.new()
	panel.add_child(cat_bar)
	for i in CAT_NAMES.size():
		var b : Button = Button.new()
		b.text = CAT_NAMES[i]
		b.pressed.connect(_set_cat.bind(i))
		cat_bar.add_child(b)
	piece_grid = GridContainer.new()
	piece_grid.columns = 2
	panel.add_child(piece_grid)
	hint = Label.new()
	panel.add_child(hint)
	msg = Label.new()
	panel.add_child(msg)

func _set_mode(v : bool) -> void:
	build_mode = v
	cat_bar.visible = v
	piece_grid.visible = v
	hint.visible = v
	status.text = "BUILD MODE | ซ้าย=วาง ขวา=รื้อ R=หมุน B=ออก" if v else "กด B เข้าโหมดสร้าง"
	_refresh_pieces()
	queue_redraw()

func _set_cat(i : int) -> void:
	cat = i
	sel_id = &""
	rot = 0
	_refresh_pieces()

func _select(id : StringName) -> void:
	sel_id = id
	rot = 0
	_refresh_pieces()

# แสดงเฉพาะชิ้นที่มีใน Inventory จริง ตามหมวดที่เลือก
func _refresh_pieces() -> void:
	for c in piece_grid.get_children():
		piece_grid.remove_child(c)
		c.queue_free()
	var seen : Dictionary = {}
	for s in inv.slots:
		if s == null or s.item_data == null or s.quantity <= 0 or not (s.item_data is BuildingPieceData):
			continue
		var p : BuildingPieceData = s.item_data
		if p.category != cat or seen.has(p.id):
			continue
		seen[p.id] = true
		var b : Button = Button.new()
		b.text = "%s%s x%d" % ["> " if p.id == sel_id else "", p.display_name, inv.count_of(p.id)]
		b.pressed.connect(_select.bind(p.id))
		piece_grid.add_child(b)

func _show(reason : StringName) -> void:
	msg.text = REASONS.get(reason, String(reason))

func _rotate() -> void:
	var p : BuildingPieceData = db.get_item(sel_id) as BuildingPieceData
	if p == null:
		return
	if p.can_be_rotated:
		rot = (rot + 1) % 4
	else:
		_show(BuildResult.CANNOT_ROTATE)

func _place() -> void:
	if sel_id == &"":
		msg.text = "เลือกชิ้นส่วนก่อน"
		return
	var r : Dictionary = grid.place(db, inv, sel_id, _cell, rot)
	_show(r["reason"])
	if r["done"] > 0 and inv.count_of(sel_id) < 1:
		sel_id = &""
		_refresh_pieces()

func _remove() -> void:
	_show(grid.remove_at(db, inv, _cell)["reason"])

func _unhandled_input(e : InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_B:
			_set_mode(not build_mode)
		elif build_mode and e.keycode == KEY_R:
			_rotate()
	elif build_mode and e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			_place()
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			_remove()

func _process(_d : float) -> void:
	if not build_mode:
		return
	_cell = BuildConst.world_to_cell(get_global_mouse_position())
	_ghost = grid.check(db, sel_id, _cell, rot) if sel_id != &"" else {}
	if _ghost.is_empty():
		hint.text = "เลือกชิ้นส่วนจากแถบด้านบน"
	else:
		hint.text = "วางได้" if _ghost["ok"] else "วางไม่ได้: " + REASONS.get(_ghost["reason"], String(_ghost["reason"]))
	queue_redraw()

func _rect(cell : Vector2i, fp : Vector2i) -> Rect2:
	return Rect2(BuildConst.cell_to_world(cell), Vector2(fp * BuildConst.CELL_SIZE))

func _draw() -> void:
	var sz : Vector2 = Vector2(grid.size * BuildConst.CELL_SIZE)
	var a : float = 0.25 if build_mode else 0.08
	for x in range(grid.size.x + 1):
		draw_line(Vector2(x * BuildConst.CELL_SIZE, 0), Vector2(x * BuildConst.CELL_SIZE, sz.y), Color(1, 1, 1, a))
	for y in range(grid.size.y + 1):
		draw_line(Vector2(0, y * BuildConst.CELL_SIZE), Vector2(sz.x, y * BuildConst.CELL_SIZE), Color(1, 1, 1, a))
	var items : Array = grid.all_structs()
	for pass_layer in [BuildGrid.LAYER_FLOOR, BuildGrid.LAYER_OBJECT]:
		for s in items:
			var p : BuildingPieceData = db.get_item(StringName(s["piece"])) as BuildingPieceData
			if p == null or BuildGrid.layer_of(p) != pass_layer:
				continue
			var r : Rect2 = _rect(s["cell"], BuildGrid.footprint(p, s["rot"]))
			draw_rect(r, CAT_COLORS[p.category])
			draw_rect(r, Color.BLACK, false, 1.0)
			draw_string(ThemeDB.fallback_font, r.position + Vector2(4, 14), p.display_name.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	if build_mode and not _ghost.is_empty():
		var p : BuildingPieceData = db.get_item(sel_id) as BuildingPieceData
		var r : Rect2 = _rect(_cell, BuildGrid.footprint(p, rot))
		if _ghost["ok"]:
			draw_rect(r, Color(0.2, 1, 0.3, 0.4))
			draw_rect(r, Color(0.2, 1, 0.3), false, 2.0)
		else:
			draw_rect(r, Color(1, 0.2, 0.2, 0.4))
			draw_rect(r, Color(1, 0.2, 0.2), false, 2.0)
			draw_line(r.position, r.end, Color(1, 0.2, 0.2), 2.0)   # กากบาท: ไม่พึ่งสีอย่างเดียว
			draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Color(1, 0.2, 0.2), 2.0)
