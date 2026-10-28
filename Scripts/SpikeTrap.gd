@tool
extends Node3D
# กับดักหนามผุด: หนามโผล่ขึ้น-หดลงเป็นจังหวะ (มีสั่นเตือนก่อนโผล่)

@export var period := 3.0
@export var up_time := 1.2
@export_range(0.0, 1.0) var phase := 0.0
@export var spike_color := Color(0.78, 0.8, 0.86)

const BASE_SCENE := preload("res://Assets/Models/Props/spike_trap.glb")
const DOWN_Y := -0.75
const UP_Y := 0.0

var _spikes: Node3D
var _base: Node3D
var _hazard: Area3D
var _t := 0.0
var _was_up := false

func _ready():
	_base = BASE_SCENE.instantiate()
	_base.position = Vector3(0, -0.62, 0)
	add_child(_base, false, Node.INTERNAL_MODE_FRONT)
	_spikes = Node3D.new()
	add_child(_spikes, false, Node.INTERNAL_MODE_FRONT)
	var cone := LowPoly.cylinder(0.0, 0.13, 0.75, 4)
	for x in 3:
		for z in 3:
			var mi := LowPoly.add_mesh(_spikes, cone, spike_color, Vector3((x - 1) * 0.55, 0.37, (z - 1) * 0.55), x * 3 + z, 0.0, 0.12)
			mi.rotation.y = PI / 4
	_spikes.position.y = DOWN_Y
	_hazard = preload("res://Scripts/Hazard.gd").new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.7, 0.7, 1.7)
	cs.shape = bs
	cs.position = Vector3(0, 0.35, 0)
	_hazard.add_child(cs)
	add_child(_hazard, false, Node.INTERNAL_MODE_FRONT)
	_hazard.active = false
	if Engine.is_editor_hint():
		_spikes.position.y = UP_Y

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	_t += delta
	var p := fmod(_t + phase * period, period)
	var down_time := period - up_time
	var warn := 0.45
	var y := DOWN_Y
	if p < down_time - warn:
		y = DOWN_Y
		_base.position.x = 0
	elif p < down_time:
		y = DOWN_Y + 0.12
		_base.position.x = sin(_t * 70.0) * 0.03
	else:
		var k := p - down_time
		y = lerp(DOWN_Y, UP_Y, clamp(k / 0.08, 0.0, 1.0))
		if k > up_time - 0.25:
			y = lerp(UP_Y, DOWN_Y, (k - (up_time - 0.25)) / 0.25)
		_base.position.x = 0
	_spikes.position.y = y
	var up := y > -0.35
	_hazard.active = up
	if up and not _was_up:
		var pl := get_tree().get_first_node_in_group("Player")
		if pl and pl.global_position.distance_to(global_position) < 10.0:
			AudioManager.spike_sfx.play()
	_was_up = up
