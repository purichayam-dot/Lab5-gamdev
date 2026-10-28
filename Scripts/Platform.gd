@tool
class_name LowPolyPlatform
extends AnimatableBody3D
# แท่น/เกาะลอยฟ้าแบบ Low-Poly (สร้างรูปทรงเองด้วยโค้ด → ไฟล์เล็ก, แก้ขนาด/สีได้ใน Inspector)
# ผิวด้านบนอยู่ที่ y = 0 ของโหนดเสมอ ทำให้วางด่านง่าย
# รองรับ: แท่นเคลื่อนที่ (move_offset) และแท่นถล่ม (crumble)

enum PlatformShape { ROUND, BOX }

@export var shape: PlatformShape = PlatformShape.ROUND:
	set(v): shape = v; _queue_rebuild()
@export var size := Vector3(4, 1.2, 4):
	set(v): size = v; _queue_rebuild()
@export_range(3, 24) var sides := 8:
	set(v): sides = v; _queue_rebuild()
@export var underside_depth := 1.8:
	set(v): underside_depth = v; _queue_rebuild()
@export var top_color := Color(0.55, 0.78, 0.36):
	set(v): top_color = v; _queue_rebuild()
@export var side_color := Color(0.55, 0.42, 0.3):
	set(v): side_color = v; _queue_rebuild()
@export var under_color := Color(0.42, 0.38, 0.36):
	set(v): under_color = v; _queue_rebuild()
@export var variation_seed := 0:
	set(v): variation_seed = v; _queue_rebuild()

@export_group("Movement")
@export var move_offset := Vector3.ZERO
@export var move_duration := 3.0
@export_range(0.0, 1.0) var move_phase := 0.0
@export var move_pause := 0.4

@export_group("Crumble")
@export var crumble := false
@export var crumble_delay := 0.7
@export var respawn_delay := 3.0

var _gen: Node3D
var _col: CollisionShape3D
var _origin := Vector3.ZERO
var _t := 0.0
var _crumbling := false
var _dirty := false

func _ready():
	_origin = position
	_rebuild()
	if Engine.is_editor_hint():
		return
	sync_to_physics = move_offset != Vector3.ZERO
	if crumble:
		_make_crumble_sensor()

func _queue_rebuild():
	if not is_inside_tree() or _dirty:
		return
	_dirty = true
	_rebuild.call_deferred()

func _rebuild():
	_dirty = false
	if _gen:
		_gen.queue_free()
	if _col:
		_col.queue_free()
	_gen = Node3D.new()
	_gen.name = "Visual"
	add_child(_gen, false, Node.INTERNAL_MODE_FRONT)
	var h := size.y
	var top_h: float = min(0.3, h * 0.4)
	if shape == PlatformShape.ROUND:
		var r := size.x * 0.5
		LowPoly.add_mesh(_gen, LowPoly.cylinder(r, r * 0.97, top_h, sides), top_color, Vector3(0, -top_h * 0.5, 0), variation_seed, 0.0, 0.05)
		LowPoly.add_mesh(_gen, LowPoly.cylinder(r * 0.95, r * 0.82, h - top_h, sides), side_color, Vector3(0, -top_h - (h - top_h) * 0.5, 0), variation_seed + 1, 0.0, 0.08)
		if underside_depth > 0.05:
			LowPoly.add_mesh(_gen, LowPoly.cylinder(r * 0.82, r * 0.18, underside_depth, sides), under_color, Vector3(0, -h - underside_depth * 0.5, 0), variation_seed + 2, r * 0.25, 0.1)
		var cs := CylinderShape3D.new()
		cs.radius = r
		cs.height = h
		_col = CollisionShape3D.new()
		_col.shape = cs
		_col.position = Vector3(0, -h * 0.5, 0)
		# ทำให้ size.z ย่อ/ขยายเป็นวงรีได้
		_gen.scale = Vector3(1, 1, size.z / max(size.x, 0.01))
		if abs(size.z - size.x) > 0.01:
			var bs := BoxShape3D.new()
			bs.size = Vector3(size.x * 0.82, h, size.z * 0.82)
			_col.shape = bs
	else:
		LowPoly.add_mesh(_gen, LowPoly.box(Vector3(size.x, top_h, size.z)), top_color, Vector3(0, -top_h * 0.5, 0), variation_seed, 0.0, 0.05)
		LowPoly.add_mesh(_gen, LowPoly.box(Vector3(size.x * 0.96, h - top_h, size.z * 0.96)), side_color, Vector3(0, -top_h - (h - top_h) * 0.5, 0), variation_seed + 1, 0.0, 0.08)
		if underside_depth > 0.05:
			var under := LowPoly.add_mesh(_gen, LowPoly.cylinder(0.68, 0.14, underside_depth, 4), under_color, Vector3(0, -h - underside_depth * 0.5, 0), variation_seed + 2, 0.18, 0.1)
			under.rotation.y = PI / 4
			under.scale = Vector3(size.x, 1, size.z)
		var bs := BoxShape3D.new()
		bs.size = Vector3(size.x, h, size.z)
		_col = CollisionShape3D.new()
		_col.shape = bs
		_col.position = Vector3(0, -h * 0.5, 0)
	add_child(_col, false, Node.INTERNAL_MODE_FRONT)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	if move_offset == Vector3.ZERO:
		return
	_t += delta
	var cycle := move_duration * 2.0 + move_pause * 2.0
	var p := fmod(_t + move_phase * cycle, cycle)
	var s := 0.0
	if p < move_pause:
		s = 0.0
	elif p < move_pause + move_duration:
		s = (p - move_pause) / move_duration
	elif p < move_pause * 2.0 + move_duration:
		s = 1.0
	else:
		s = 1.0 - (p - move_pause * 2.0 - move_duration) / move_duration
	s = s * s * (3.0 - 2.0 * s)
	position = _origin + move_offset * s

# ---------- แท่นถล่ม ---------- #

func _make_crumble_sensor():
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(size.x * 0.9, 0.5, size.z * 0.9)
	cs.shape = bs
	cs.position = Vector3(0, 0.3, 0)
	area.add_child(cs)
	add_child(area, false, Node.INTERNAL_MODE_FRONT)
	area.body_entered.connect(_on_crumble_body_entered)

func _on_crumble_body_entered(body):
	if _crumbling or not body.is_in_group("Player"):
		return
	_crumbling = true
	AudioManager.crumble_sfx.play()
	# สั่นเตือน
	var shake := create_tween()
	var steps := int(crumble_delay / 0.05)
	for i in steps:
		shake.tween_property(_gen, "position", Vector3(randf_range(-0.08, 0.08), randf_range(-0.03, 0.03), randf_range(-0.08, 0.08)), 0.05)
	await shake.finished
	_col.set_deferred("disabled", true)
	var fall := create_tween().set_parallel()
	fall.tween_property(_gen, "position", Vector3(0, -6, 0), 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(_gen, "scale", _gen.scale * 0.3, 0.7)
	await fall.finished
	_gen.visible = false
	await get_tree().create_timer(respawn_delay).timeout
	var keep_scale := Vector3(1, 1, size.z / max(size.x, 0.01)) if shape == PlatformShape.ROUND else Vector3.ONE
	_gen.position = Vector3.ZERO
	_gen.scale = keep_scale * 0.1
	_gen.visible = true
	var back := create_tween()
	back.tween_property(_gen, "scale", keep_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await back.finished
	_col.set_deferred("disabled", false)
	_crumbling = false
