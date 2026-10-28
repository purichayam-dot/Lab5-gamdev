extends Area3D
# ประตูโทริอิทางออก: ถูกล็อกจนกว่าจะเก็บอัญมณีครบ แล้วเดินเข้าไปเพื่อไปด่านต่อไป

@onready var portal: MeshInstance3D = $Portal
@onready var label: Label3D = $Label3D
@onready var light: OmniLight3D = $Light
@onready var sparkles: CPUParticles3D = $Sparkles

const LOCK_A := Color(0.45, 0.2, 0.25)
const LOCK_B := Color(0.25, 0.12, 0.2)
const OPEN_A := Color(0.35, 0.95, 1.0)
const OPEN_B := Color(1.0, 0.45, 0.85)

var unlocked := false
var entered := false

func _ready():
	body_entered.connect(_on_body_entered)
	GameManager.gems_changed.connect(_on_gems_changed)
	GameManager.all_gems_collected.connect(unlock)
	var m: ShaderMaterial = portal.material_override.duplicate()
	portal.material_override = m
	_set_portal(0.0, LOCK_A, LOCK_B)
	sparkles.emitting = false
	light.light_energy = 0.4
	light.light_color = Color(1.0, 0.4, 0.4)
	_on_gems_changed(GameManager.score, GameManager.total_gems)

func _set_portal(p: float, a: Color, b: Color):
	var m: ShaderMaterial = portal.material_override
	m.set_shader_parameter("power", p)
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)

func _on_gems_changed(c: int, total: int):
	if unlocked:
		return
	label.text = "เก็บอัญมณีให้ครบ  %d / %d" % [c, total]

func unlock():
	if unlocked:
		return
	unlocked = true
	AudioManager.unlock_sfx.play()
	label.text = "ประตูเปิดแล้ว!  เข้าไปเลย"
	label.modulate = Color(0.6, 1.0, 0.85)
	sparkles.emitting = true
	_set_portal(0.0, OPEN_A, OPEN_B)
	var t := create_tween().set_parallel()
	t.tween_method(func(v): (portal.material_override as ShaderMaterial).set_shader_parameter("power", v), 0.0, 1.0, 1.2)
	t.tween_property(light, "light_energy", 2.5, 1.2)
	t.tween_property(light, "light_color", Color(0.6, 0.9, 1.0), 1.2)

func _on_body_entered(body):
	if entered or not body.is_in_group("Player"):
		return
	if not GameManager.has_all_gems():
		GameManager.show_message.emit("ยังเก็บอัญมณีไม่ครบ!  (%d / %d)" % [GameManager.score, GameManager.total_gems], Color(1.0, 0.55, 0.5))
		return
	entered = true
	AudioManager.clear_sfx.play()
	body.victory()
	GameManager.show_message.emit("ผ่านด่าน!", Color(1.0, 0.9, 0.4))
	await get_tree().create_timer(2.4).timeout
	GameManager.complete_level()
