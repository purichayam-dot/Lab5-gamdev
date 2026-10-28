@tool
extends Area3D
# แท่นดอกบัวดีดตัว: เหยียบแล้วเด้งขึ้นสูง

@export var bounce_force := 15.0
@export var petal_color := Color(1.0, 0.55, 0.75)
@export var leaf_color := Color(0.3, 0.62, 0.35)

var _flower: Node3D

func _ready():
	LowPoly.add_mesh(self, LowPoly.cylinder(1.05, 1.0, 0.12, 9), leaf_color, Vector3(0, 0.06, 0), 21)
	_flower = Node3D.new()
	add_child(_flower, false, Node.INTERNAL_MODE_FRONT)
	for i in 8:
		var p := LowPoly.add_mesh(_flower, LowPoly.cylinder(0.0, 0.32, 0.9, 4), petal_color, Vector3.ZERO, 30 + i)
		p.rotation = Vector3(deg_to_rad(55), TAU * i / 8.0, 0)
		p.position = Vector3(sin(TAU * i / 8.0) * 0.45, 0.4, cos(TAU * i / 8.0) * 0.45)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.4
	sm.radial_segments = 8
	sm.rings = 4
	core.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.3)
	mat.emission_energy_multiplier = 2.0
	core.material_override = mat
	core.position = Vector3(0, 0.3, 0)
	_flower.add_child(core)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.95
	sh.height = 0.6
	cs.shape = sh
	cs.position = Vector3(0, 0.3, 0)
	add_child(cs, false, Node.INTERNAL_MODE_FRONT)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _process(delta):
	if Engine.is_editor_hint():
		return
	_flower.rotate_y(delta * 0.6)

func _on_body_entered(body):
	if body.is_in_group("Player") and body.has_method("bounce"):
		body.bounce(bounce_force)
		AudioManager.bounce_sfx.play()
		var t := create_tween()
		t.tween_property(_flower, "scale", Vector3(1.3, 0.5, 1.3), 0.06)
		t.tween_property(_flower, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
