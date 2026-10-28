extends Node3D
# พื้นฐานของฉากเมนู: กล้องหมุนรอบ + ฟังก์ชันสร้างปุ่ม/ป้ายด้วยฟอนต์ภาษาไทย

const FONT_BOLD := preload("res://Assets/Fonts/Kanit-Bold.ttf")
const FONT_REG := preload("res://Assets/Fonts/Kanit-Regular.ttf")

@export var orbit_speed := 0.12
@export var orbit_radius := 8.5
@export var orbit_height := 2.4
@export var look_at_point := Vector3(0, 1.6, 0)
@export var music: AudioStream

var _t := 0.0
@onready var cam: Camera3D = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if music:
		if music is AudioStreamOggVorbis:
			(music as AudioStreamOggVorbis).loop = true
		AudioManager.play_music(music)
	var tl := get_node_or_null("Torii/Label3D")
	if tl:
		tl.visible = false
	var ap: AnimationPlayer = find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(_ninja_anim()):
		ap.play(_ninja_anim())

func _ninja_anim() -> String:
	return "Idle"

func _process(delta):
	_t += delta * orbit_speed
	cam.position = look_at_point + Vector3(sin(_t) * orbit_radius, orbit_height, cos(_t) * orbit_radius)
	cam.look_at(look_at_point)

func label(text: String, size: int, bold := true, color := Color.WHITE, outline := 12) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.18, 0.05, 0.15, 0.95))
	l.add_theme_constant_override("outline_size", outline)
	return l

func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", 30)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.85, 0.25, 0.4, 0.92)
	n.set_corner_radius_all(32)
	n.border_color = Color(1, 0.85, 0.9)
	n.set_border_width_all(3)
	var h := n.duplicate()
	h.bg_color = Color(1.0, 0.45, 0.6, 1.0)
	var p := n.duplicate()
	p.bg_color = Color(0.6, 0.15, 0.3, 1.0)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(func(): AudioManager.coin_sfx.play(); cb.call())
	b.mouse_entered.connect(func(): b.grab_focus())
	return b

func panel_style(alpha := 0.6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.05, 0.14, alpha)
	sb.set_corner_radius_all(24)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	sb.border_color = Color(1, 0.75, 0.85, 0.6)
	sb.set_border_width_all(2)
	return sb
