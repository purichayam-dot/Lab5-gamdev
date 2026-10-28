@tool
extends Node3D
# ลูกตุ้มหนามแกว่ง ห้อยจากซุ้มเสาแดงสไตล์ญี่ปุ่น
# ลูกตุ้มแกว่งตามแกน X ของโหนด → วางให้ทางเดินอยู่ตามแกน Z

@export var length := 3.4
@export var amplitude_deg := 60.0
@export var speed := 1.8
@export_range(0.0, 1.0) var phase := 0.0
@export var frame_color := Color(0.78, 0.16, 0.12)
@export var beam_color := Color(0.18, 0.12, 0.12)

const BALL := preload("res://Assets/Models/Props/spiky_ball.glb")
const HAZARD := preload("res://Scripts/Hazard.gd")

var _pivot: Node3D
var _t := 0.0

func _ready():
	var top := length + 1.0
	var half_w := length * sin(deg_to_rad(amplitude_deg)) + 1.2
	# เสา + คาน (มีชนกันได้)
	var body := StaticBody3D.new()
	add_child(body, false, Node.INTERNAL_MODE_FRONT)
	for sx in [-1, 1]:
		LowPoly.add_mesh(body, LowPoly.cylinder(0.22, 0.26, top + 0.4, 6), frame_color, Vector3(sx * half_w, (top + 0.4) * 0.5, 0), 11)
		LowPoly.add_mesh(body, LowPoly.cylinder(0.34, 0.34, 0.3, 6), beam_color, Vector3(sx * half_w, 0.15, 0), 12)
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.26
		sh.height = top + 0.4
		cs.shape = sh
		cs.position = Vector3(sx * half_w, (top + 0.4) * 0.5, 0)
		body.add_child(cs)
	LowPoly.add_mesh(body, LowPoly.box(Vector3(half_w * 2 + 1.0, 0.3, 0.45)), beam_color, Vector3(0, top + 0.45, 0), 13)
	LowPoly.add_mesh(body, LowPoly.box(Vector3(half_w * 2 + 0.4, 0.22, 0.38)), frame_color, Vector3(0, top + 0.1, 0), 14)
	# ตัวแกว่ง
	_pivot = Node3D.new()
	_pivot.position = Vector3(0, top, 0)
	add_child(_pivot, false, Node.INTERNAL_MODE_FRONT)
	LowPoly.add_mesh(_pivot, LowPoly.cylinder(0.05, 0.05, length, 4), Color(0.25, 0.25, 0.28), Vector3(0, -length * 0.5, 0), 15)
	var ball: Node3D = BALL.instantiate()
	ball.scale = Vector3.ONE * 1.1
	ball.position = Vector3(0, -length, 0)
	_pivot.add_child(ball)
	var hz: Area3D = HAZARD.new()
	var cs2 := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.62
	cs2.shape = sp
	hz.add_child(cs2)
	hz.position = Vector3(0, -length, 0)
	_pivot.add_child(hz)
	_apply()

func _apply():
	_pivot.rotation.z = deg_to_rad(amplitude_deg) * sin(_t * speed + phase * TAU)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	_t += delta
	_apply()
