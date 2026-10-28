extends "res://Scripts/MenuBase.gd"
# หน้าเมนูหลัก: ชื่อเกม, เริ่มเกม, วิธีเล่น, ออก

var how_panel: PanelContainer
var main_box: VBoxContainer

func _ready():
	super._ready()
	var ui := CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	main_box = VBoxContainer.new()
	main_box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	main_box.position = Vector2(90, -250)
	main_box.add_theme_constant_override("separation", 14)
	root.add_child(main_box)
	var t1 := label("NINJA BLOSSOM", 92, true, Color(1.0, 0.8, 0.9), 26)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main_box.add_child(t1)
	var t2 := label("ตำนานนินจาซากุระ", 44, true, Color(1, 1, 1), 14)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main_box.add_child(t2)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	main_box.add_child(sp)
	var start := button("เริ่มเกม", func(): GameManager.start_game())
	main_box.add_child(start)
	main_box.add_child(button("วิธีเล่น", func(): _toggle_how(true)))
	if OS.get_name() != "Web":
		main_box.add_child(button("ออกจากเกม", func(): get_tree().quit()))
	start.grab_focus.call_deferred()

	how_panel = PanelContainer.new()
	how_panel.add_theme_stylebox_override("panel", panel_style(0.88))
	how_panel.set_anchors_preset(Control.PRESET_CENTER)
	how_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	how_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	how_panel.visible = false
	root.add_child(how_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	how_panel.add_child(v)
	v.add_child(label("วิธีเล่น", 52, true, Color(1.0, 0.8, 0.9)))
	var lines := [
		"เป้าหมาย: เก็บ \"อัญมณีวิญญาณ\" ให้ครบทุกเม็ด แล้วเข้าประตูโทริอิเพื่อไปด่านต่อไป",
		"หลบกับดัก: หนามผุด, แท่งหนามหมุน, ลูกตุ้มหนาม และแท่นหินถล่ม",
		"ตกน้ำ/ตกเหว หรือโดนกับดัก = เสียหัวใจ 1 ดวง (มี 3 ดวงต่อด่าน)",
		"โคมหินคือจุดเช็กพอยต์ — เดินผ่านแล้วจะเกิดใหม่ที่นั่น",
		"ดอกบัวสีชมพูคือแท่นดีดตัว ช่วยกระโดดขึ้นที่สูง",
		"",
		"WASD = เดิน     Space = กระโดด (กดซ้ำกลางอากาศ = ตีลังกา)",
		"เมาส์ หรือ Q / E = หมุนกล้อง     R = เริ่มด่านใหม่     Esc = ปล่อยเมาส์",
	]
	for s in lines:
		var l := label(s, 24, false, Color.WHITE, 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(l)
	var back := button("กลับ", func(): _toggle_how(false))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)

	var credit := label("จัดทำโดย ภูริชญา โมรานะ  •  ต่อยอดจาก 3D Platformer Starter Kit (SD Studios)  •  ตัวละคร Ninja โดย Quaternius (poly.pizza)", 16, false, Color(1, 1, 1, 0.8), 6)
	credit.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	credit.grow_horizontal = Control.GROW_DIRECTION_BOTH
	credit.grow_vertical = Control.GROW_DIRECTION_BEGIN
	credit.position.y = -14
	root.add_child(credit)

func _toggle_how(show: bool):
	how_panel.visible = show
	main_box.visible = not show
