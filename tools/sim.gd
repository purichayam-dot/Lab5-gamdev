extends SceneTree
# ทดสอบเกมเพลย์อัตโนมัติ (headless): กระโดดข้ามช่วงสำคัญ, กับดัก, แท่นดีด, ประตู, เปลี่ยนด่าน

var gm
var pl
var results := []

func _init():
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(name: String, ok: bool, info := ""):
	results.append(("PASS " if ok else "FAIL ") + name + "  " + info)

func load_level(path: String):
	change_scene_to_file(path)
	for i in 5: await process_frame
	await create_timer(0.3).timeout
	pl = get_first_node_in_group("Player")
	pl.invincible_time = 0.0

func release_all():
	for a in ["move_forward", "move_back", "move_left", "move_right", "jump"]:
		Input.action_release(a)

# วางผู้เล่นแล้ววิ่งไปทาง yaw (องศา, 0 = -Z) พร้อมกดกระโดดตามเวลา
func run_jump(start: Vector3, yaw: float, run_time: float, jumps: Array, settle := 0.8) -> Vector3:
	release_all()
	pl.global_position = start
	pl.velocity = Vector3.ZERO
	var g = pl.get_node("%Gimbal")
	g.rotation_degrees = Vector3(0, yaw, 0)
	g.auto_rotate = false
	g.timer.start(1000)
	pl.snap_camera()
	await create_timer(0.25).timeout
	Input.action_press("move_forward")
	var t := 0.0
	var ji := 0
	while t < run_time:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if ji < jumps.size() and t >= jumps[ji]:
			Input.action_press("jump")
			await physics_frame
			Input.action_release("jump")
			ji += 1
	release_all()
	await create_timer(settle).timeout
	return pl.global_position

func _run():
	gm = root.get_node("/root/GameManager")
	# ---------------- LEVEL 1
	await load_level("res://Scenes/Levels/Level1_SakuraValley.tscn")
	check("L1 gem count", gm.total_gems == 9, str(gm.total_gems))
	var p: Vector3
	# start island -> stepping stone 1 (z -8)
	p = await run_jump(Vector3(0, 0.1, -3.6), 0, 0.55, [0.12])
	check("L1 start->stone1", p.y > 0.3 and abs(p.z + 8) < 1.5, str(p))
	# stone1 -> stone2 (2.5, 0.9, -11.5): yaw towards
	var dir := Vector3(2.5, 0, -11.5) - Vector3(0, 0, -8)
	var yaw := rad_to_deg(atan2(-dir.x, -dir.z))
	p = await run_jump(Vector3(0, 0.5, -8), yaw, 0.6, [0.05])
	check("L1 stone1->stone2", p.y > 0.85 and Vector2(p.x - 2.5, p.z + 11.5).length() < 1.5, str(p) + " yaw=" + str(yaw))
	# step blocks: B1 (-9,2.8,-42.5) -> B2 (-5,3.8,-44.5)
	dir = Vector3(-5, 0, -44.5) - Vector3(-9, 0, -42.5)
	yaw = rad_to_deg(atan2(-dir.x, -dir.z))
	p = await run_jump(Vector3(-9, 2.9, -42.5), yaw, 0.6, [0.12])
	check("L1 B1->B2 (+1m)", p.y > 3.7 and Vector2(p.x + 5, p.z + 44.5).length() < 1.2, str(p))
	dir = Vector3(-1, 0, -46.5) - Vector3(-5, 0, -44.5)
	yaw = rad_to_deg(atan2(-dir.x, -dir.z))
	p = await run_jump(Vector3(-5, 3.9, -44.5), yaw, 0.6, [0.12])
	check("L1 B2->B3 (+1m)", p.y > 4.7 and Vector2(p.x + 1, p.z + 46.5).length() < 1.2, str(p))
	# B3 -> big island
	dir = Vector3(3.5, 0, -53) - Vector3(-1, 0, -46.5)
	yaw = rad_to_deg(atan2(-dir.x, -dir.z))
	p = await run_jump(Vector3(-1, 4.9, -46.5), yaw, 0.5, [0.1])
	check("L1 B3->island", p.y > 4.7, str(p))
	# spike trap hurts
	var lives_before: int = gm.lives
	pl.global_position = Vector3(0.6, 1.0, -26)
	for i in 40:
		await create_timer(0.1).timeout
		if gm.lives < lives_before: break
	check("L1 spike trap hurts", gm.lives < lives_before, "lives %d -> %d" % [lives_before, gm.lives])
	# fall in water -> respawn
	gm.lives = 3
	lives_before = gm.lives
	pl.global_position = Vector3(10, 0, -10)
	await create_timer(1.5).timeout
	check("L1 water respawn", gm.lives == lives_before - 1 and pl.global_position.y > -1.0, str(pl.global_position))
	# gate locked
	gm.lives = 3
	pl.global_position = Vector3(3.5, 7.4, -70.5)
	await create_timer(0.5).timeout
	check("L1 gate stays locked", get_root().get_child(get_root().get_child_count() - 1).name == "Level1_SakuraValley", current_scene.name)
	# collect all gems
	pl.invincible_timer = 1000.0
	for gem_node in get_nodes_in_group("Gem"):
		if is_instance_valid(gem_node):
			pl.global_position = gem_node.global_position - Vector3(0, 0.6, 0)
			pl.velocity = Vector3.ZERO
			await create_timer(0.25).timeout
	check("L1 all gems collected", gm.score == gm.total_gems, "%d/%d" % [gm.score, gm.total_gems])
	pl.global_position = Vector3(3.5, 7.4, -68.5)
	await create_timer(0.3).timeout
	pl.global_position = Vector3(3.5, 7.4, -71.6)
	await create_timer(4.5).timeout
	check("L1 -> L2 transition", current_scene.name == "Level2_MoonTemple", current_scene.name)

	# ---------------- LEVEL 2
	await load_level("res://Scenes/Levels/Level2_MoonTemple.tscn")
	gm.level_index = 1
	check("L2 gem count", gm.total_gems == 10, str(gm.total_gems))
	p = await run_jump(Vector3(0, 0.1, -3.8), 0, 0.5, [0.1])
	check("L2 yard->crumble1", p.y > 0.2 and abs(p.z + 7.3) < 1.3, str(p))
	await create_timer(1.6).timeout
	check("L2 crumble drops player", pl.global_position.y < -1.0 or gm.lives < 3, str(pl.global_position) + " lives=" + str(gm.lives))
	gm.lives = 3
	# crumble path (14.5,6.4,-60.5)->(16.5,7.0,-64)
	dir = Vector3(16.5, 0, -64) - Vector3(14.5, 0, -60.5)
	yaw = rad_to_deg(atan2(-dir.x, -dir.z))
	p = await run_jump(Vector3(14.5, 6.6, -60.5), yaw, 0.6, [0.08], 0.3)
	check("L2 crumble step +0.6", p.y > 6.8 and Vector2(p.x - 16.5, p.z + 64).length() < 1.3, str(p))
	# jump pad -> high platform
	gm.lives = 3
	p = await run_jump(Vector3(0, 1.5, -23.4), 0, 1.6, [], 0.6)
	check("L2 jump pad -> high platform", p.y > 5.0 and abs(p.z + 30) < 3.0, str(p))
	# P8 -> spinner island
	dir = Vector3(9, 0, -55) - Vector3(3, 0, -49.5)
	yaw = rad_to_deg(atan2(-dir.x, -dir.z))
	gm.lives = 3
	p = await run_jump(Vector3(3.0, 6.0, -49.5), yaw, 0.55, [0.1], 0.2)
	check("L2 P8->spinner island", p.y > 5.6, str(p))
	# pendulum hurts
	gm.lives = 3
	pl.global_position = Vector3(0, 1.4, -19)
	for i in 40:
		await create_timer(0.1).timeout
		if gm.lives < 3: break
	pl.global_position = Vector3(0, 1.4, -26)
	check("L2 pendulum hurts", gm.lives < 3, "lives=" + str(gm.lives))
	gm.lives = 3
	pl.invincible_timer = 1000.0
	for gem_node in get_nodes_in_group("Gem"):
		if is_instance_valid(gem_node):
			pl.global_position = gem_node.global_position - Vector3(0, 0.6, 0)
			pl.velocity = Vector3.ZERO
			await create_timer(0.25).timeout
	check("L2 all gems collected", gm.score == gm.total_gems, "%d/%d" % [gm.score, gm.total_gems])
	pl.global_position = Vector3(17.5, 8.2, -78.6)
	await create_timer(4.5).timeout
	check("L2 -> Victory", current_scene.name == "Victory", current_scene.name)
	print("\n===== RESULTS =====")
	for r in results:
		print(r)
	quit()
