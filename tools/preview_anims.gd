extends SceneTree
func _init():
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _run():
	var r := Node3D.new()
	root.add_child(r)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.7,0.75,0.85); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.5; env.environment = e; r.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 20, 0); r.add_child(sun)
	var names := ["Idle", "Run", "Jump", "Fall", "Flip", "Hurt", "VictorySign", "Land"]
	var aps := []
	for i in names.size():
		var n: Node3D = load("res://Scenes/Objects/NinjaModel.tscn").instantiate()
		n.position = Vector3((i % 4) * 1.6 - 2.4, 0 if i < 4 else -2.2, 0)
		r.add_child(n)
		var l := Label3D.new(); l.text = names[i]; l.position = n.position + Vector3(0, -0.25, 0.5); l.font_size = 40; r.add_child(l)
		aps.append(n.get_node("AnimationPlayer"))
	await process_frame
	for i in names.size():
		aps[i].play(names[i])
	var cam := Camera3D.new(); r.add_child(cam); cam.look_at_from_position(Vector3(0, 0.2, 6.5), Vector3(0, -0.4, 0)); cam.current = true
	var t := float(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 0.3
	await create_timer(t).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/home/claude/shots/anims.png")
	quit()
