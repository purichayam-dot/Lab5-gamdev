@tool
extends Node3D
# แท่งหนามหมุน: ต้องกระโดดข้ามจังหวะที่แขนหมุนผ่าน

@export var speed_deg := 80.0
@export_range(1, 4) var arms := 2
@export var arm_length := 3.6
@export var arm_height := 0.45
@export var arm_thickness := 0.7
@export var hub_color := Color(0.45, 0.22, 0.16)

const ARM_SCENE := preload("res://Assets/Models/Props/cylinder_hazard.glb")
const HAZARD := preload("res://Scripts/Hazard.gd")

var _rotor: Node3D

func _ready():
	LowPoly.add_mesh(self, LowPoly.cylinder(0.32, 0.42, arm_height + 0.5, 6), hub_color, Vector3(0, (arm_height + 0.5) * 0.5, 0), 3)
	_rotor = Node3D.new()
	add_child(_rotor, false, Node.INTERNAL_MODE_FRONT)
	var cap := LowPoly.add_mesh(_rotor, LowPoly.cylinder(0.25, 0.45, 0.3, 6), Color(0.85, 0.65, 0.2), Vector3(0, arm_height + 0.6, 0), 4)
	cap.name = "Cap"
	for i in arms:
		var arm := Node3D.new()
		arm.rotation.y = TAU * i / arms
		_rotor.add_child(arm)
		var m: Node3D = ARM_SCENE.instantiate()
		# โมเดลตั้งตรงยาว 3.88, กว้าง 2.28 → วางนอนตามแกน X
		m.rotation.z = PI / 2
		m.scale = Vector3(arm_thickness / 2.28, arm_length / 3.88, arm_thickness / 2.28)
		m.position = Vector3(0.3 + arm_length * 0.5 + arm_length * 0.5, arm_height, 0)
		arm.add_child(m)
		var hz: Area3D = HAZARD.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(arm_length, arm_thickness * 0.9, arm_thickness * 0.9)
		cs.shape = bs
		hz.add_child(cs)
		hz.position = Vector3(0.3 + arm_length * 0.5, arm_height, 0)
		arm.add_child(hz)
	if Engine.is_editor_hint():
		_rotor.rotation.y = 0.3

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	_rotor.rotate_y(deg_to_rad(speed_deg) * delta)
