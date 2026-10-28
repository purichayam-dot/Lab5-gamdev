extends CanvasLayer
# HUD ในเกม: อัญมณี x/y, หัวใจ, ชื่อด่าน, เวลา, ข้อความแจ้งเตือน, ป้าย Game Over
# (ต่อยอดจาก GameUI.gd ของ Starter Kit ที่โชว์ "x จำนวนเหรียญ")

const FONT_BOLD := preload("res://Assets/Fonts/Kanit-Bold.ttf")
const FONT_REG := preload("res://Assets/Fonts/Kanit-Regular.ttf")
const GEM_ICON := preload("res://Assets/Textures/UI/gem_icon.png")
const HEART := preload("res://Assets/Textures/UI/heart.png")
const HEART_EMPTY := preload("res://Assets/Textures/UI/heart_empty.png")

var coinsLabel: Label
var hearts: Array[TextureRect] = []
var level_label: Label
var time_label: Label
var message: Label
var banner: VBoxContainer
var banner_title: Label
var banner_sub: Label
var game_over_panel: PanelContainer
var _msg_tween: Tween

func _ready():
	layer = 10
	_build()
	GameManager.gems_changed.connect(_on_gems)
	GameManager.lives_changed.connect(_on_lives)
	GameManager.show_message.connect(flash_message)
	GameManager.level_started.connect(_on_level_started)
	GameManager.game_over.connect(_on_game_over)

func _process(_delta):
	time_label.text = "เวลา  " + GameManager.format_time(GameManager.level_time)

func _label(text: String, size: int, bold := true, color := Color.WHITE, outline := 10) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.12, 0.9))
	l.add_theme_constant_override("outline_size", outline)
	return l

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.05, 0.12, 0.55)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 18
	sb.content_margin_right = 22
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.border_color = Color(1, 0.75, 0.85, 0.5)
	sb.set_border_width_all(2)
	return sb

func _build():
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ---- มุมซ้ายบน: อัญมณี + หัวใจ
	var left := VBoxContainer.new()
	left.position = Vector2(28, 22)
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)
	var gem_panel := PanelContainer.new()
	gem_panel.add_theme_stylebox_override("panel", _panel_style())
	left.add_child(gem_panel)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 12)
	gem_panel.add_child(gh)
	var icon := TextureRect.new()
	icon.texture = GEM_ICON
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gh.add_child(icon)
	coinsLabel = _label("0 / 0", 40, true, Color(0.75, 0.93, 1.0))
	gh.add_child(coinsLabel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	left.add_child(hb)
	for i in GameManager.MAX_LIVES:
		var h := TextureRect.new()
		h.texture = HEART
		h.custom_minimum_size = Vector2(46, 46)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(h)
		hearts.append(h)

	# ---- มุมขวาบน: ชื่อด่าน + เวลา
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.position = Vector2(-28, 22)
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(right)
	level_label = _label("", 30, true, Color(1.0, 0.86, 0.92))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(level_label)
	time_label = _label("", 24, false, Color(1, 1, 1, 0.9), 8)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(time_label)

	# ---- ข้อความกลางจอ
	message = _label("", 42, true, Color.WHITE, 14)
	message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message.position.y = 150
	message.modulate.a = 0.0
	root.add_child(message)

	# ---- ป้ายชื่อด่านตอนเริ่ม
	banner = VBoxContainer.new()
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.modulate.a = 0.0
	root.add_child(banner)
	banner_title = _label("", 84, true, Color(1.0, 0.82, 0.9), 22)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_title)
	banner_sub = _label("", 30, false, Color(1, 1, 1), 10)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_sub)

	# ---- คำแนะนำด้านล่าง
	var hint := _label("WASD เดิน   •   Space กระโดด (กดซ้ำกลางอากาศ = ตีลังกา)   •   เมาส์ / Q E หมุนกล้อง   •   R เริ่มด่านใหม่   •   Esc ปล่อยเมาส์", 18, false, Color(1, 1, 1, 0.85), 6)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.position.y = -16
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	# ---- Game Over
	game_over_panel = PanelContainer.new()
	var sb := _panel_style()
	sb.bg_color = Color(0.12, 0.02, 0.06, 0.85)
	sb.content_margin_left = 48
	sb.content_margin_right = 48
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	game_over_panel.add_theme_stylebox_override("panel", sb)
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_over_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	game_over_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	game_over_panel.visible = false
	root.add_child(game_over_panel)
	var gv := VBoxContainer.new()
	gv.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(gv)
	var t1 := _label("หมดพลังชีวิต!", 64, true, Color(1.0, 0.45, 0.5), 16)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(t1)
	var t2 := _label("กำลังเริ่มด่านใหม่...", 28, false)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(t2)

func _on_gems(c: int, total: int):
	coinsLabel.text = "%d / %d" % [c, total]
	var t := create_tween()
	t.tween_property(coinsLabel, "scale", Vector2(1.25, 1.25), 0.06)
	t.tween_property(coinsLabel, "scale", Vector2.ONE, 0.15)
	if c >= total and total > 0:
		coinsLabel.add_theme_color_override("font_color", Color(0.55, 1.0, 0.7))

func _on_lives(lives: int):
	for i in hearts.size():
		hearts[i].texture = HEART if i < lives else HEART_EMPTY
	if lives < GameManager.MAX_LIVES:
		var idx: int = clamp(lives, 0, hearts.size() - 1)
		var t := create_tween()
		hearts[idx].pivot_offset = Vector2(23, 23)
		t.tween_property(hearts[idx], "scale", Vector2(1.5, 1.5), 0.08)
		t.tween_property(hearts[idx], "scale", Vector2.ONE, 0.2)

func flash_message(text: String, color := Color.WHITE):
	message.text = text
	message.add_theme_color_override("font_color", color)
	if _msg_tween:
		_msg_tween.kill()
	message.modulate.a = 1.0
	_msg_tween = create_tween()
	_msg_tween.tween_interval(1.8)
	_msg_tween.tween_property(message, "modulate:a", 0.0, 0.6)

func _on_level_started(title: String, subtitle: String):
	level_label.text = title
	banner_title.text = title
	banner_sub.text = subtitle
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.5)
	t.tween_interval(2.2)
	t.tween_property(banner, "modulate:a", 0.0, 0.8)

func _on_game_over():
	game_over_panel.visible = true
	await get_tree().create_timer(2.5).timeout
	GameManager.restart_level()
