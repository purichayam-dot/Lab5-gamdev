extends "res://Scripts/MenuBase.gd"
# ฉากจบเกม: นินจาโบกมือ + สรุปผล

func _ninja_anim() -> String:
	return "VictorySign"

func _ready():
	super._ready()
	AudioManager.clear_sfx.play()
	var ui := CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style(0.7))
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.position.x = -80
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(label("ชนะแล้ว!", 86, true, Color(1.0, 0.85, 0.4), 22))
	v.add_child(label("นินจาพิชิตทั้ง 2 ด่านสำเร็จ", 32, false))
	v.add_child(label("อัญมณีที่เก็บได้:  %d" % GameManager.total_score, 30, true, Color(0.7, 0.93, 1.0)))
	v.add_child(label("เวลารวม:  %s" % GameManager.format_time(GameManager.run_time), 30, true))
	v.add_child(label("จำนวนครั้งที่พลาด:  %d" % GameManager.deaths, 30, true, Color(1.0, 0.7, 0.75)))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 16)
	v.add_child(sp)
	var again := button("เล่นอีกครั้ง", func(): GameManager.start_game())
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(again)
	var menu := button("เมนูหลัก", func(): GameManager.go_to_menu())
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(menu)
	again.grab_focus.call_deferred()
