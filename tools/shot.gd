extends SceneTree
# ใช้ทดสอบ: godot -s tools/shot.gd -- <scene> <outdir> name,px,py,pz,yaw,pitch [name,...]
func _init():
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run():
	var a := OS.get_cmdline_user_args()
	var scene: String = a[0]
	var outdir: String = a[1]
	change_scene_to_file(scene)
	for i in 3: await process_frame
	await create_timer(3.6).timeout
	var gm = root.get_node("/root/GameManager")
	for i in range(2, a.size()):
		var p := a[i].split(",")
		var pl := get_first_node_in_group("Player")
		if pl and p.size() >= 4:
			pl.global_position = Vector3(float(p[1]), float(p[2]), float(p[3]))
			pl.velocity = Vector3.ZERO
			var g = pl.get_node("%Gimbal")
			g.rotation_degrees.y = float(p[4]) if p.size() > 4 else 0.0
			g.rotation_degrees.x = float(p[5]) if p.size() > 5 else -8.0
			g.auto_rotate = false
			g.timer.start(100)
			pl.snap_camera()
		await create_timer(0.6).timeout
		if pl: print(p[0], ": player at ", pl.global_position, " floor=", pl.is_on_floor(), " lives=", gm.lives, " gems=", gm.score, "/", gm.total_gems)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(outdir + "/" + p[0] + ".png")
	quit()
