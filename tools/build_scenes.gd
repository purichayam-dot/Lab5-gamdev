extends SceneTree
# ===================================================================================
#  Scene builder — สร้างไฟล์ .tscn ทั้งหมดของเกม (รันแบบ headless)
#    godot --headless --path . -s tools/build_scenes.gd
#  ฉากที่ได้เปิดแก้ต่อใน Godot Editor ได้ตามปกติ
# ===================================================================================

const PROPS := "res://Assets/Models/Props/"
const FONT_BOLD := "res://Assets/Fonts/Kanit-Bold.ttf"

var _root: Node

# ---------------------------------------------------------------- helpers
func own(n: Node, root: Node):
	if n != root:
		n.owner = root
	if n.scene_file_path != "" and n != root:
		return # อย่าเป็นเจ้าของลูกของ instanced scene
	for c in n.get_children():
		own(c, root)

func add(parent: Node, n: Node, name := "", pos := Vector3.ZERO) -> Node:
	if name != "":
		n.name = name
	parent.add_child(n, true)
	if n is Node3D:
		(n as Node3D).position = pos
	return n

func inst(path: String, parent: Node, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, scl := 1.0, name := "") -> Node3D:
	var ps: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	var n: Node3D = ps.instantiate()
	if name != "":
		n.name = name
	parent.add_child(n, true)
	n.position = pos
	n.rotation_degrees = rot_deg
	n.scale = Vector3.ONE * scl
	return n

func save_scene(root: Node, path: String):
	own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed " + path)
	err = ResourceSaver.save(ps, path)
	print("saved ", path, " err=", err)
	root.free()

func node3d(parent: Node, name: String, pos := Vector3.ZERO) -> Node3D:
	return add(parent, Node3D.new(), name, pos)

func font() -> Font:
	return load(FONT_BOLD)

func make_sign(parent: Node, text: String, pos: Vector3, size := 64, color := Color(1, 0.95, 0.85)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font()
	l.font_size = size
	l.outline_size = 18
	l.modulate = color
	l.outline_modulate = Color(0.25, 0.06, 0.18, 1)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.pixel_size = 0.006
	l.no_depth_test = false
	add(parent, l, "Sign", pos)
	return l

# ---------------------------------------------------------------- object scenes
func build_ninja_model():
	var root := Node3D.new()
	root.name = "NinjaModel"
	root.set_script(load("res://Scripts/NinjaModel.gd"))
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	var ninja := inst("res://Assets/Models/Characters/Ninja.glb", root, Vector3.ZERO, Vector3.ZERO, 0.5, "Ninja")
	ap.root_node = NodePath("../Ninja")
	ap.add_animation_library("", load("res://Assets/Models/Characters/ninja_animations.res"))
	ap.autoplay = "Idle"
	save_scene(root, "res://Scenes/Objects/NinjaModel.tscn")

func build_player():
	var p := CharacterBody3D.new()
	p.name = "Player"
	p.set_script(load("res://Scripts/player.gd"))
	p.add_to_group("Player", true)
	p.floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.45
	cs.shape = cap
	add(p, cs, "CollisionShape3D", Vector3(0, 0.725, 0))
	inst("res://Scenes/Objects/NinjaModel.tscn", p, Vector3.ZERO, Vector3.ZERO, 1.0, "Model")
	var gimbal := Node3D.new()
	gimbal.set_script(load("res://Scripts/CameraMovement.gd"))
	add(p, gimbal, "Gimbal", Vector3(0, 0, 0))
	gimbal.unique_name_in_owner = true
	var arm := SpringArm3D.new()
	arm.spring_length = 6.0
	arm.margin = 0.3
	var sph := SphereShape3D.new()
	sph.radius = 0.25
	arm.shape = sph
	add(gimbal, arm, "SpringArm3D", Vector3(0, 1.4, 0))
	arm.rotation_degrees = Vector3(-18, 0, 0)
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 70
	add(arm, cam, "Camera3D")
	var timer := Timer.new()
	timer.wait_time = 2.0
	add(gimbal, timer, "CameraControlTimer")
	timer.timeout.connect(Callable(gimbal, "_on_camera_control_timer_timeout"), CONNECT_PERSIST)
	# ParticleTrail (จาก Starter Kit)
	var pt := CPUParticles3D.new()
	var pm := StandardMaterial3D.new()
	pm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	pm.specular_mode = BaseMaterial3D.SPECULAR_TOON
	pm.albedo_color = Color(1.0, 0.9, 0.93)
	pt.material_override = pm
	pt.amount = 30
	pt.mesh = load("res://Assets/Resources/cloud.res")
	pt.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	pt.emission_sphere_radius = 0.2
	pt.particle_flag_align_y = true
	pt.direction = Vector3.ZERO
	pt.gravity = Vector3(0, 0.1, 0)
	pt.scale_amount_min = 0.5
	pt.scale_amount_max = 0.7
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.236318, 1))
	curve.add_point(Vector2(1, 0))
	pt.scale_amount_curve = curve
	add(p, pt, "ParticleTrail")
	var fs := AudioStreamPlayer3D.new()
	fs.stream = load("res://Assets/Audio/SFX/walking.ogg")
	fs.pitch_scale = 0.75
	fs.autoplay = true
	add(p, fs, "Footsteps")
	save_scene(p, "res://Scenes/player.tscn")

func build_gem(path: String, glb: String, glow: Color, scl: float):
	var a := Area3D.new()
	a.name = "Gem"
	a.set_script(load("res://Scripts/Coin.gd"))
	inst(PROPS + glb, a, Vector3.ZERO, Vector3.ZERO, scl, "GemModel")
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.6
	cs.shape = sp
	add(a, cs, "CollisionShape3D")
	var l := OmniLight3D.new()
	l.light_color = glow
	l.light_energy = 1.2
	l.omni_range = 2.6
	add(a, l, "Glow")
	var spk := CPUParticles3D.new()
	var q := QuadMesh.new()
	var qm := StandardMaterial3D.new()
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.vertex_color_use_as_albedo = true
	qm.albedo_texture = load("res://Assets/Textures/particle.png")
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.billboard_keep_scale = true
	q.material = qm
	spk.mesh = q
	spk.amount = 10
	spk.lifetime = 1.2
	spk.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	spk.emission_sphere_radius = 0.5
	spk.spread = 180.0
	spk.gravity = Vector3(0, 0.4, 0)
	spk.initial_velocity_max = 0.5
	spk.scale_amount_min = 0.12
	spk.scale_amount_max = 0.18
	var grad := Gradient.new()
	grad.colors = PackedColorArray([glow.lightened(0.4), Color(1, 1, 1, 0)])
	spk.color_ramp = grad
	add(a, spk, "Sparkles")
	var rng := Area3D.new()
	var rcs := CollisionShape3D.new()
	var rsp := SphereShape3D.new()
	rsp.radius = 1.7
	rcs.shape = rsp
	add(rng, rcs, "CollisionShape3D")
	add(a, rng, "Range")
	save_scene(a, path)

func build_checkpoint():
	var a := Area3D.new()
	a.name = "Checkpoint"
	a.set_script(load("res://Scripts/Checkpoint.gd"))
	var s := 0.62
	inst(PROPS + "stone_lamp.glb", a, Vector3(0, 2.19 * s, 0), Vector3.ZERO, s, "StoneLamp")
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.4, 3, 2.4)
	cs.shape = bs
	add(a, cs, "CollisionShape3D", Vector3(0, 1.5, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.7, 0.35)
	l.light_energy = 2.2
	l.omni_range = 6.0
	add(a, l, "Light", Vector3(0, 1.7, 0))
	var f := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.3
	sm.radial_segments = 6
	sm.rings = 3
	f.mesh = sm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1.0, 0.7, 0.3)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.6, 0.2)
	fm.emission_energy_multiplier = 4.0
	f.material_override = fm
	add(a, f, "Flame", Vector3(0, 1.62, 0))
	save_scene(a, "res://Scenes/Objects/Checkpoint.tscn")

func build_exit_gate():
	var a := Area3D.new()
	a.name = "ExitGate"
	a.set_script(load("res://Scripts/ExitGate.gd"))
	inst(PROPS + "torii.glb", a, Vector3.ZERO, Vector3.ZERO, 0.75, "Torii")
	var portal := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.9, 3.0)
	portal.mesh = q
	var sm := ShaderMaterial.new()
	sm.shader = load("res://Assets/Shaders/portal.gdshader")
	portal.material_override = sm
	add(a, portal, "Portal", Vector3(0, 1.55, 0))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.6, 3.0, 1.0)
	cs.shape = bs
	add(a, cs, "CollisionShape3D", Vector3(0, 1.5, 0))
	var lbl := Label3D.new()
	lbl.text = "เก็บอัญมณีให้ครบ  0 / 0"
	lbl.font = font()
	lbl.font_size = 56
	lbl.outline_size = 16
	lbl.pixel_size = 0.006
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.outline_modulate = Color(0.2, 0.05, 0.15)
	add(a, lbl, "Label3D", Vector3(0, 4.7, 0))
	var l := OmniLight3D.new()
	l.omni_range = 8.0
	add(a, l, "Light", Vector3(0, 1.8, 0.8))
	var spk := CPUParticles3D.new()
	var qq := QuadMesh.new()
	qq.size = Vector2(0.15, 0.15)
	var qm := StandardMaterial3D.new()
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.vertex_color_use_as_albedo = true
	qm.albedo_texture = load("res://Assets/Textures/glow.png")
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qq.material = qm
	spk.mesh = qq
	spk.amount = 40
	spk.lifetime = 2.0
	spk.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spk.emission_box_extents = Vector3(1.4, 1.5, 0.2)
	spk.direction = Vector3(0, 1, 0)
	spk.spread = 20.0
	spk.gravity = Vector3(0, 0.6, 0)
	spk.initial_velocity_min = 0.3
	spk.initial_velocity_max = 0.8
	spk.scale_amount_min = 0.8
	spk.scale_amount_max = 1.6
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.6, 1, 1, 1), Color(1, 0.5, 0.9, 0)])
	spk.color_ramp = grad
	add(a, spk, "Sparkles", Vector3(0, 1.5, 0))
	save_scene(a, "res://Scenes/Objects/ExitGate.tscn")

func build_simple(script: String, type: String, name: String, path: String):
	var n: Node = ClassDB.instantiate(type)
	n.name = name
	n.set_script(load(script))
	save_scene(n, path)

func build_hud():
	var c := CanvasLayer.new()
	c.name = "HUD"
	c.set_script(load("res://Scripts/GameUI.gd"))
	save_scene(c, "res://Scenes/UI/HUD.tscn")

# ---------------------------------------------------------------- level helpers
func platform(parent: Node, pos: Vector3, size: Vector3, round := true, cols := [], extra := {}) -> Node3D:
	var p: Node3D = inst("res://Scenes/Objects/Platform.tscn", parent, pos)
	p.set("shape", 0 if round else 1)
	p.set("size", size)
	if cols.size() >= 3:
		p.set("top_color", cols[0])
		p.set("side_color", cols[1])
		p.set("under_color", cols[2])
	p.set("variation_seed", int(abs(pos.x * 13 + pos.z * 7)) % 97)
	for k in extra:
		p.set(k, extra[k])
	return p

func gem(parent: Node, pos: Vector3, scene := "res://Scenes/Objects/Gem.tscn"):
	inst(scene, parent, pos)

func prop(parent: Node, file: String, pos: Vector3, scl := 1.0, rot_y := 0.0, y_off := 0.0) -> Node3D:
	return inst(PROPS + file + ".glb", parent, pos + Vector3(0, y_off * scl, 0), Vector3(0, rot_y, 0), scl)

func hazard_box(parent: Node, pos: Vector3, size: Vector3, name := "SpikeBed") -> Area3D:
	var a := Area3D.new()
	a.set_script(load("res://Scripts/Hazard.gd"))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	add(a, cs, "CollisionShape3D", Vector3(0, size.y * 0.5, 0))
	add(parent, a, name, pos)
	return a

func spike_bed(parent: Node, pos: Vector3, rot_y := 0.0):
	var a := hazard_box(parent, pos, Vector3(1.5, 0.8, 1.5))
	a.rotation_degrees.y = rot_y
	inst(PROPS + "spike_platform.glb", a, Vector3.ZERO, Vector3.ZERO, 1.0, "Model")

func environment(parent: Node, sky_top: Color, sky_hor: Color, ground: Color, ambient: Color, amb_energy: float, fog_col: Color, fog_density: float, sun_col: Color, sun_energy: float, sun_rot: Vector3, exposure := 1.0) -> WorldEnvironment:
	var envn := node3d(parent, "Environment")
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = sky_top
	psm.sky_horizon_color = sky_hor
	psm.ground_horizon_color = sky_hor
	psm.ground_bottom_color = ground
	psm.sun_angle_max = 20.0
	sky.sky_material = psm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = amb_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = exposure
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_density = fog_density
	env.fog_sky_affect = 0.25
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.04
	we.environment = env
	add(envn, we, "WorldEnvironment")
	var sun := DirectionalLight3D.new()
	sun.light_color = sun_col
	sun.light_energy = sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add(envn, sun, "Sun")
	sun.rotation_degrees = sun_rot
	return we

func water(parent: Node, y: float, color: Color, emission := Color.BLACK, name := "Water"):
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(700, 700)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.08
	m.metallic = 0.35
	m.metallic_specular = 0.8
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.3
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add(parent, mi, name, Vector3(0, y, -40))

func dead_zone(parent: Node, y: float):
	var a := Area3D.new()
	a.set_script(load("res://Scripts/DeadZone.gd"))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(400, 10, 400)
	cs.shape = bs
	add(a, cs, "CollisionShape3D")
	add(parent, a, "DeadZone", Vector3(0, y - 5, -40))
	a.body_entered.connect(Callable(a, "_on_body_entered"), CONNECT_PERSIST)

func spawn_point(parent: Node, pos: Vector3):
	var m := Marker3D.new()
	add(parent, m, "SpawnPosition", pos)
	m.unique_name_in_owner = true
	m.add_to_group("SpawnPoint", true)

func flat_mesh_instance(parent: Node, mesh: Mesh, color: Color, pos: Vector3, sd := 0, wobble := 0.0, name := "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.flat(mesh, color, 0.08, sd, wobble)
	add(parent, mi, name, pos)
	return mi

func mountains(parent: Node, center: Vector3, radius: float, count: int, col_a: Color, col_b: Color, snow: Color, h_range := Vector2(25, 60), sd := 1):
	var g := node3d(parent, "Mountains")
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for i in count:
		var ang := TAU * i / count + rng.randf_range(-0.15, 0.15)
		var r := radius * rng.randf_range(0.85, 1.15)
		var h := rng.randf_range(h_range.x, h_range.y)
		var w := h * rng.randf_range(0.7, 1.1)
		var pos := center + Vector3(sin(ang) * r, h * 0.5 - 2.0, cos(ang) * r)
		var col := col_a.lerp(col_b, rng.randf())
		var mi := flat_mesh_instance(g, LowPoly.cylinder(0.0, w, h, rng.randi_range(5, 7)), col, pos, i, w * 0.15, "Mountain")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.rotation.y = rng.randf() * TAU
		if snow.a > 0.0:
			var cap := flat_mesh_instance(g, LowPoly.cylinder(0.0, w * 0.32, h * 0.32 + 0.05, 6), snow, pos + Vector3(0, h * 0.34 + 0.02, 0), i + 50, 0.0, "Snow")
			cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cap.rotation.y = mi.rotation.y

func particles_field(parent: Node, name: String, pos: Vector3, extents: Vector3, tex: String, amount: int, lifetime: float, gravity: Vector3, size_range: Vector2, c1: Color, c2: Color, unshaded := false, velocity := Vector2(0.2, 0.8)) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = load(tex)
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = 1.5
	m.distance_fade_max_distance = 5.0
	q.material = m
	p.mesh = q
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(1, 0, 0.3)
	p.spread = 60.0
	p.gravity = gravity
	p.initial_velocity_min = velocity.x
	p.initial_velocity_max = velocity.y
	p.angular_velocity_min = -120.0
	p.angular_velocity_max = 120.0
	p.angle_max = 360.0
	p.scale_amount_min = size_range.x
	p.scale_amount_max = size_range.y
	var g := Gradient.new()
	g.colors = PackedColorArray([c1, c2])
	p.color_initial_ramp = g
	p.visibility_aabb = AABB(-extents - Vector3(20, 40, 20), extents * 2 + Vector3(40, 80, 40))
	add(parent, p, name, pos)
	return p

func lantern_post(parent: Node, pos: Vector3, rot_y := 0.0, light := true):
	var g := node3d(parent, "LanternPost", pos)
	g.rotation_degrees.y = rot_y
	flat_mesh_instance(g, LowPoly.cylinder(0.08, 0.11, 2.6, 6), Color(0.2, 0.12, 0.1), Vector3(0, 1.3, 0), 5)
	flat_mesh_instance(g, LowPoly.box(Vector3(0.9, 0.08, 0.1)), Color(0.2, 0.12, 0.1), Vector3(0.35, 2.55, 0), 6)
	prop(g, "red_lantern", Vector3(0.7, 2.0, 0), 1.1)
	if light:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.3)
		l.light_energy = 1.8
		l.omni_range = 6.0
		add(g, l, "Light", Vector3(0.7, 2.0, 0.3))
		var glow := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.2
		sm.height = 0.4
		sm.radial_segments = 6
		sm.rings = 3
		glow.mesh = sm
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(1, 0.6, 0.3)
		gm.emission_enabled = true
		gm.emission = Color(1, 0.45, 0.2)
		gm.emission_energy_multiplier = 3.0
		glow.material_override = gm
		add(g, glow, "Glow", Vector3(0.7, 2.0, 0))

func glowing_crystal(parent: Node, pos: Vector3, scl: float, col: Color, rot_y := 0.0):
	var c := prop(parent, "crystal", pos, scl, rot_y)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.4
	l.omni_range = 4.5
	add(c, l, "Light", Vector3(0, 4.0, 0))

func pagoda(parent: Node, pos: Vector3, floors: int, base_w: float, wall: Color, roof: Color):
	var g := node3d(parent, "Pagoda", pos)
	var y := 0.0
	var w := base_w
	for i in floors:
		var h := w * 0.45
		var b := flat_mesh_instance(g, LowPoly.box(Vector3(w * 0.7, h, w * 0.7)), wall, Vector3(0, y + h * 0.5, 0), i * 3)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var r := flat_mesh_instance(g, LowPoly.cylinder(w * 0.2, w * 0.82, h * 0.45, 4), roof, Vector3(0, y + h + h * 0.2, 0), i * 3 + 1)
		r.rotation.y = PI / 4
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		y += h + h * 0.4
		w *= 0.78
	var sp := flat_mesh_instance(g, LowPoly.cylinder(0.0, w * 0.15, w * 1.2, 6), roof.lightened(0.3), Vector3(0, y + w * 0.6, 0), 99)
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func common_level_nodes(root: Node3D, spawn: Vector3):
	spawn_point(root, spawn)
	inst("res://Scenes/player.tscn", root, spawn, Vector3.ZERO, 1.0, "Player")
	var hud: Node = (load("res://Scenes/UI/HUD.tscn") as PackedScene).instantiate()
	add(root, hud, "HUD")

# ================================================================== LEVEL 1
func build_level1():
	var root := Node3D.new()
	root.name = "Level1_SakuraValley"
	root.set_script(load("res://Scripts/Level.gd"))
	root.set("level_title", "ด่าน 1 · หุบเขาซากุระ")
	root.set("level_subtitle", "เก็บอัญมณีวิญญาณให้ครบ 9 เม็ด แล้วเข้าประตูโทริอิ")
	root.set("music", load("res://Assets/Audio/Music/sakura.ogg"))
	environment(root, Color(0.42, 0.58, 0.92), Color(1.0, 0.8, 0.82), Color(0.3, 0.5, 0.62), Color(0.95, 0.85, 0.95), 0.4, Color(1.0, 0.82, 0.88), 0.0035, Color(1.0, 0.92, 0.84), 1.05, Vector3(-48, -35, 0), 0.9)
	common_level_nodes(root, Vector3(0, 0.3, 2.5))

	var GRASS := [Color(0.9, 0.46, 0.64), Color(0.62, 0.45, 0.33), Color(0.5, 0.45, 0.48)]   # หญ้าซากุระสีชมพู
	var GREEN := [Color(0.5, 0.74, 0.33), Color(0.6, 0.45, 0.32), Color(0.48, 0.44, 0.46)]
	var WOOD := [Color(0.62, 0.4, 0.24), Color(0.55, 0.35, 0.22), Color(0.4, 0.28, 0.2)]
	var STONE := [Color(0.78, 0.76, 0.72), Color(0.6, 0.58, 0.56), Color(0.45, 0.43, 0.45)]

	var plats := node3d(root, "Platforms")
	platform(plats, Vector3(0, 0, 0), Vector3(10, 1.4, 10), true, GRASS, {"sides": 10})
	platform(plats, Vector3(0, 0.4, -8), Vector3(3, 1.0, 3), true, STONE, {"sides": 7, "underside_depth": 1.0})
	platform(plats, Vector3(2.5, 0.9, -11.5), Vector3(3, 1.0, 3), true, STONE, {"sides": 7, "underside_depth": 1.0})
	platform(plats, Vector3(2.5, 0.9, -18), Vector3(2.4, 0.4, 9.2), false, WOOD, {"underside_depth": 0.0})
	platform(plats, Vector3(2.5, 0.9, -27), Vector3(9, 1.4, 9), true, GREEN, {"sides": 9})
	platform(plats, Vector3(-2.5, 1.3, -33), Vector3(3, 0.5, 3), false, WOOD, {"underside_depth": 0.6, "move_offset": Vector3(-4, 0, 0), "move_duration": 2.4})
	platform(plats, Vector3(-9, 1.8, -37), Vector3(7, 1.4, 7), true, GRASS, {"sides": 8})
	platform(plats, Vector3(-9, 2.8, -42.5), Vector3(2, 0.8, 2), false, STONE, {"underside_depth": 0.8})
	platform(plats, Vector3(-5, 3.8, -44.5), Vector3(2, 0.8, 2), false, STONE, {"underside_depth": 0.8})
	platform(plats, Vector3(-1, 4.8, -46.5), Vector3(2, 0.8, 2), false, STONE, {"underside_depth": 0.8})
	platform(plats, Vector3(3.5, 4.8, -53), Vector3(12, 1.6, 12), true, GREEN, {"sides": 11, "underside_depth": 3.0})
	platform(plats, Vector3(3.5, 4.6, -61), Vector3(3, 0.5, 3), false, WOOD, {"underside_depth": 0.6, "move_offset": Vector3(0, 2.6, 0), "move_duration": 2.2, "move_pause": 0.8})
	platform(plats, Vector3(3.5, 7.2, -68), Vector3(11, 1.6, 11), true, GRASS, {"sides": 10, "underside_depth": 3.5})

	var gems := node3d(root, "Gems")
	for p in [Vector3(0, 1.0, -3.5), Vector3(2.5, 1.9, -11.5), Vector3(2.5, 1.9, -21.5), Vector3(2.5, 1.9, -27), Vector3(-9, 2.8, -37), Vector3(-5, 6.6, -44.5), Vector3(3.5, 5.8, -57.8), Vector3(0.5, 8.2, -66.5), Vector3(6.5, 8.2, -66.5)]:
		gem(gems, p)

	var traps := node3d(root, "Traps")
	var sp := inst("res://Scenes/Objects/Spinner.tscn", traps, Vector3(2.5, 0.9, -18))
	sp.set("speed_deg", 70.0)
	inst("res://Scenes/Objects/SpikeTrap.tscn", traps, Vector3(0.6, 0.9, -26)).set("phase", 0.0)
	inst("res://Scenes/Objects/SpikeTrap.tscn", traps, Vector3(4.4, 0.9, -28.2)).set("phase", 0.5)
	var sp2 := inst("res://Scenes/Objects/Spinner.tscn", traps, Vector3(3.5, 4.8, -53))
	sp2.set("speed_deg", 60.0)
	sp2.set("arm_length", 3.8)
	spike_bed(traps, Vector3(-0.5, 4.8, -53.5))
	spike_bed(traps, Vector3(7.8, 4.8, -51), 30)
	spike_bed(traps, Vector3(7.0, 4.8, -56.8), 15)
	inst("res://Scenes/Objects/SpikeTrap.tscn", traps, Vector3(3.5, 7.2, -69.2)).set("phase", 0.25)

	var cps := node3d(root, "Checkpoints")
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(5.6, 0.9, -24.0))
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(-6.8, 1.8, -35.0))
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(0.2, 4.8, -49.5))

	inst("res://Scenes/Objects/ExitGate.tscn", root, Vector3(3.5, 7.2, -71.8), Vector3.ZERO, 1.0, "ExitGate")

	# ---------- ตกแต่ง
	var deco := node3d(root, "Decor")
	var tree_s := 0.036
	for t in [[Vector3(-3.2, 0, 1.0), 20], [Vector3(3.6, 0, -1.5), 150], [Vector3(6.2, 0.9, -29.5), 80], [Vector3(-11.2, 1.8, -38.8), 200], [Vector3(8.2, 4.8, -56.0), 40], [Vector3(-1.2, 4.8, -57.0), 260], [Vector3(-0.6, 7.2, -71.2), 120], [Vector3(7.8, 7.2, -70.8), 300]]:
		prop(deco, "sakura_tree", t[0], tree_s, t[1])
	for b in [[Vector3(-4.0, 0, -2.6), 0], [Vector3(4.2, 0, 2.2), 70], [Vector3(-1.0, 0.9, -30.4), 30], [Vector3(-11.8, 1.8, -35.5), 110], [Vector3(-6.8, 1.8, -39.6), 10], [Vector3(8.6, 4.8, -50.5), 40]]:
		prop(deco, "bamboo_b" if randi() % 2 == 0 else "bamboo_a", b[0], 1.0, b[1])
	for r in [[Vector3(3.8, 0, 3.2), 1.2], [Vector3(-2.2, 0, -3.8), 1.0], [Vector3(-0.6, 0.9, -24.2), 1.4], [Vector3(-11.6, 1.8, -34.2), 1.1], [Vector3(0.5, 7.2, -64.4), 1.3], [Vector3(6.8, 7.2, -64.2), 1.0], [Vector3(-2.0, 4.8, -50.5), 1.2]]:
		prop(deco, "rock_b", r[0], r[1], randf() * 360)
	for bsh in [Vector3(-4.2, 0, 3.6), Vector3(2.0, 0, 4.2), Vector3(6.8, 0.9, -25.8), Vector3(-6.4, 1.8, -34.0), Vector3(-12.2, 1.8, -37.6), Vector3(9.0, 4.8, -53.6), Vector3(-1.8, 7.2, -67.0), Vector3(8.6, 7.2, -67.4)]:
		prop(deco, "bush", bsh, 1.1, randf() * 360)
	prop(deco, "stone_lamp", Vector3(1.4, 7.2, -70.6), 0.55, 0, 2.19)
	prop(deco, "stone_lamp", Vector3(5.6, 7.2, -70.6), 0.55, 0, 2.19)
	prop(deco, "rock_large", Vector3(-22, -1.6, -20), 1.4, 30)
	prop(deco, "rock_large", Vector3(20, -1.6, -40), 1.8, 120)
	prop(deco, "rock_large", Vector3(-25, -1.6, -62), 1.2, 200)
	# เกาะลอยฟ้าไกล ๆ เป็นฉากหลัง
	var far := node3d(root, "FarIslands")
	platform(far, Vector3(-30, 10, -50), Vector3(9, 2, 9), true, GRASS, {"underside_depth": 6.0})
	platform(far, Vector3(28, 14, -80), Vector3(12, 2, 12), true, GREEN, {"underside_depth": 8.0})
	platform(far, Vector3(-18, 18, -95), Vector3(7, 2, 7), true, GRASS, {"underside_depth": 5.0})
	prop(far, "sakura_tree", Vector3(-30, 10, -50), 0.05, 40)
	prop(far, "sakura_tree", Vector3(28, 14, -80), 0.06, 10)
	prop(far, "sakura_tree", Vector3(-18, 18, -95), 0.045, 90)
	pagoda(far, Vector3(28, 14, -82), 4, 6.0, Color(0.92, 0.88, 0.8), Color(0.75, 0.2, 0.18))
	mountains(root, Vector3(0, -1.5, -35), 150, 16, Color(0.48, 0.58, 0.75), Color(0.62, 0.55, 0.72), Color(1, 0.97, 0.98, 1), Vector2(30, 70), 3)

	# ---------- ป้ายสอนเล่น
	var signs := node3d(root, "Signs")
	make_sign(signs, "หุบเขาซากุระ", Vector3(0, 3.6, -1.5), 120, Color(1.0, 0.82, 0.9))
	make_sign(signs, "เก็บอัญมณีให้ครบ แล้วไปที่ประตูโทริอิ", Vector3(0, 2.8, -1.5), 56)
	make_sign(signs, "กระโดดข้ามแท่งหนามหมุน!", Vector3(2.5, 3.0, -13.6), 48, Color(1, 0.85, 0.6))
	make_sign(signs, "ระวังหนามผุด!", Vector3(2.5, 3.4, -23.4), 48, Color(1, 0.75, 0.65))
	make_sign(signs, "กด Space ซ้ำกลางอากาศ = ตีลังกา", Vector3(-9, 4.6, -40.5), 46, Color(0.8, 0.95, 1.0))

	water(root, -1.5, Color(0.36, 0.72, 0.82, 0.82))
	dead_zone(root, -3.0)
	particles_field(root, "SakuraPetals", Vector3(0, 14, -35), Vector3(40, 2, 55), "res://Assets/Textures/petal.png", 450, 14.0, Vector3(0.25, -0.8, 0.1), Vector2(0.18, 0.32), Color(1, 0.8, 0.88), Color(1, 0.62, 0.78))
	save_scene(root, "res://Scenes/Levels/Level1_SakuraValley.tscn")

# ================================================================== LEVEL 2
func build_level2():
	var root := Node3D.new()
	root.name = "Level2_MoonTemple"
	root.set_script(load("res://Scripts/Level.gd"))
	root.set("level_title", "ด่าน 2 · วิหารจันทรา")
	root.set("level_subtitle", "ฝ่ากับดักยามราตรี เก็บอัญมณี 10 เม็ด แล้วหนีออกทางโทริอิ")
	root.set("music", load("res://Assets/Audio/Music/moon.ogg"))
	environment(root, Color(0.04, 0.03, 0.14), Color(0.3, 0.14, 0.4), Color(0.02, 0.01, 0.06), Color(0.42, 0.4, 0.72), 0.42, Color(0.16, 0.09, 0.28), 0.0045, Color(0.62, 0.7, 1.0), 0.75, Vector3(-38, 140, 0), 1.0)
	common_level_nodes(root, Vector3(0, 0.3, 2.8))

	var STONE := [Color(0.42, 0.4, 0.56), Color(0.3, 0.27, 0.38), Color(0.22, 0.2, 0.3)]
	var MOSS := [Color(0.36, 0.5, 0.52), Color(0.3, 0.27, 0.38), Color(0.22, 0.2, 0.3)]
	var CRACK := [Color(0.62, 0.55, 0.5), Color(0.45, 0.38, 0.35), Color(0.3, 0.25, 0.25)]
	var LACQ := [Color(0.62, 0.2, 0.2), Color(0.3, 0.12, 0.12), Color(0.2, 0.1, 0.12)]

	var plats := node3d(root, "Platforms")
	platform(plats, Vector3(0, 0, 0), Vector3(9, 1.4, 9), false, STONE, {"underside_depth": 2.5})
	platform(plats, Vector3(0, 0.3, -7.3), Vector3(2.6, 0.7, 2.6), true, CRACK, {"sides": 6, "crumble": true, "underside_depth": 0.9})
	platform(plats, Vector3(-2.5, 0.8, -10.8), Vector3(2.6, 0.7, 2.6), true, CRACK, {"sides": 6, "crumble": true, "underside_depth": 0.9})
	platform(plats, Vector3(0, 1.3, -14.3), Vector3(2.6, 0.7, 2.6), true, CRACK, {"sides": 6, "crumble": true, "underside_depth": 0.9})
	platform(plats, Vector3(0, 1.3, -21), Vector3(9.6, 1.4, 8), false, MOSS, {"underside_depth": 3.0})
	platform(plats, Vector3(0, 5.3, -30), Vector3(5, 1.0, 5), false, STONE, {"underside_depth": 2.0})
	platform(plats, Vector3(0, 5.3, -34.5), Vector3(3, 0.5, 3), false, LACQ, {"underside_depth": 0.5, "move_offset": Vector3(0, 0, -6), "move_duration": 2.6, "move_pause": 0.6})
	platform(plats, Vector3(0, 5.8, -46), Vector3(7, 1.4, 8), false, STONE, {"underside_depth": 3.0})
	platform(plats, Vector3(9, 5.8, -55), Vector3(11, 1.4, 11), true, MOSS, {"sides": 10, "underside_depth": 3.5})
	platform(plats, Vector3(14.5, 6.4, -60.5), Vector3(2.6, 0.7, 2.6), true, CRACK, {"sides": 6, "crumble": true, "underside_depth": 0.9})
	platform(plats, Vector3(16.5, 7.0, -64.0), Vector3(2.6, 0.7, 2.6), true, CRACK, {"sides": 6, "crumble": true, "underside_depth": 0.9})
	platform(plats, Vector3(17.5, 7.6, -67.8), Vector3(2.6, 0.7, 2.6), true, CRACK, {"sides": 6, "crumble": true, "underside_depth": 0.9})
	platform(plats, Vector3(17.5, 8.0, -75), Vector3(12, 1.6, 12), true, STONE, {"sides": 12, "underside_depth": 4.0})

	var gems := node3d(root, "Gems")
	var G2 := "res://Scenes/Objects/GemGreen.tscn"
	for p in [Vector3(0, 1.0, -3), Vector3(-2.5, 1.8, -10.8), Vector3(0, 2.3, -21), Vector3(0, 7.0, -26.4), Vector3(0, 6.8, -49.3), Vector3(0, 6.5, -38.0), Vector3(12.8, 6.8, -57.4), Vector3(16.5, 8.0, -64), Vector3(14, 9.0, -76.5), Vector3(21, 9.0, -76.5)]:
		gem(gems, p, G2)

	var traps := node3d(root, "Traps")
	inst("res://Scenes/Objects/Pendulum.tscn", traps, Vector3(0, 1.3, -19)).set("phase", 0.0)
	inst("res://Scenes/Objects/Pendulum.tscn", traps, Vector3(0, 1.3, -22.4)).set("phase", 0.5)
	inst("res://Scenes/Objects/JumpPad.tscn", traps, Vector3(0, 1.3, -24.4))
	var ph := [0.0, 0.5, 0.0, 0.5, 0.0, 0.5]
	var i := 0
	for z in [-44.2, -47.6]:
		for x in [-2.2, 0.0, 2.2]:
			inst("res://Scenes/Objects/SpikeTrap.tscn", traps, Vector3(x, 5.8, z)).set("phase", ph[(i + (1 if z < -45 else 0)) % 6])
			i += 1
	var sp := inst("res://Scenes/Objects/Spinner.tscn", traps, Vector3(9, 5.8, -55))
	sp.set("arms", 3)
	sp.set("arm_length", 4.0)
	sp.set("speed_deg", 65.0)
	var pg := inst("res://Scenes/Objects/Pendulum.tscn", traps, Vector3(17.5, 8.0, -72.6))
	pg.set("speed", 2.1)
	pg.set("frame_color", Color(0.85, 0.2, 0.2))

	var cps := node3d(root, "Checkpoints")
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(3.8, 1.3, -17.6))
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(-2.6, 5.8, -42.8))
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(2.6, 5.8, -49.4))
	inst("res://Scenes/Objects/Checkpoint.tscn", cps, Vector3(14.5, 8.0, -71.0))

	inst("res://Scenes/Objects/ExitGate.tscn", root, Vector3(17.5, 8.0, -78.8), Vector3.ZERO, 1.0, "ExitGate")

	# ---------- ตกแต่ง
	var deco := node3d(root, "Decor")
	for lp in [[Vector3(-3.8, 0, 3.6), 0], [Vector3(3.8, 0, 3.6), 180], [Vector3(-3.8, 0, -3.6), 0], [Vector3(3.8, 0, -3.6), 180], [Vector3(-4.2, 1.3, -24.4), 0], [Vector3(4.2, 1.3, -24.4), 180], [Vector3(-3.0, 5.8, -49.6), 0], [Vector3(3.0, 5.8, -49.6), 180], [Vector3(13.0, 8.0, -79.0), 0], [Vector3(22.0, 8.0, -79.0), 180]]:
		lantern_post(deco, lp[0], lp[1])
	for c in [[Vector3(-3.4, 0, -1), 0.13, Color(0.4, 0.7, 1.0)], [Vector3(2.0, 5.3, -31.6), 0.12, Color(0.75, 0.45, 1.0)], [Vector3(-2.0, 5.3, -28.6), 0.1, Color(0.4, 0.7, 1.0)], [Vector3(13.4, 5.8, -52.4), 0.15, Color(0.75, 0.45, 1.0)], [Vector3(5.0, 5.8, -58.6), 0.12, Color(0.4, 0.9, 1.0)], [Vector3(22.4, 8.0, -73.0), 0.16, Color(0.75, 0.45, 1.0)], [Vector3(12.8, 8.0, -74.0), 0.13, Color(0.4, 0.7, 1.0)]]:
		glowing_crystal(deco, c[0], c[1], c[2], randf() * 360)
	for b in [Vector3(4.0, 1.3, -21.0), Vector3(-4.2, 1.3, -19.5), Vector3(3.0, 5.8, -42.6), Vector3(13.6, 5.8, -57.0), Vector3(20.4, 8.0, -71.0)]:
		prop(deco, "bamboo_b", b, 1.0, randf() * 360)
	for r in [[Vector3(4.0, 0, 0.5), 1.4], [Vector3(-4.0, 1.3, -17.6), 1.2], [Vector3(2.0, 5.3, -28.0), 1.0], [Vector3(4.6, 5.8, -54.0), 1.3], [Vector3(23.0, 8.0, -76.5), 1.4]]:
		prop(deco, "rock_b", r[0], r[1], randf() * 360)
	prop(deco, "spikes", Vector3(-30, -3, -35), 3.0, 20)
	prop(deco, "spikes", Vector3(32, -3, -60), 3.6, 80)
	prop(deco, "spikes", Vector3(-24, -3, -80), 2.6, 140)
	var far := node3d(root, "Background")
	pagoda(far, Vector3(-40, -2, -70), 5, 10.0, Color(0.22, 0.18, 0.3), Color(0.5, 0.12, 0.2))
	pagoda(far, Vector3(48, -2, -95), 6, 12.0, Color(0.22, 0.18, 0.3), Color(0.5, 0.12, 0.2))
	pagoda(far, Vector3(10, -2, -140), 4, 9.0, Color(0.2, 0.16, 0.28), Color(0.42, 0.1, 0.18))
	platform(far, Vector3(-26, 14, -40), Vector3(8, 2, 8), true, STONE, {"underside_depth": 6.0})
	platform(far, Vector3(30, 18, -50), Vector3(6, 2, 6), true, STONE, {"underside_depth": 5.0})
	glowing_crystal(far, Vector3(-26, 14, -40), 0.25, Color(0.6, 0.5, 1.0))
	mountains(root, Vector3(10, -3, -40), 160, 14, Color(0.12, 0.1, 0.22), Color(0.2, 0.12, 0.3), Color(0, 0, 0, 0), Vector2(35, 80), 7)
	# ดวงจันทร์
	var moon := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 22
	ms.height = 44
	ms.radial_segments = 24
	ms.rings = 12
	moon.mesh = ms
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(1, 0.96, 0.85)
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.emission_enabled = true
	mm.emission = Color(1, 0.92, 0.75)
	mm.emission_energy_multiplier = 2.5
	mm.disable_fog = true
	moon.material_override = mm
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add(far, moon, "Moon", Vector3(-70, 80, -220))

	var signs := node3d(root, "Signs")
	make_sign(signs, "วิหารจันทรา", Vector3(0, 3.6, -1.8), 120, Color(0.8, 0.85, 1.0))
	make_sign(signs, "แท่นหินร้าวจะถล่ม — รีบข้าม!", Vector3(0, 2.8, -1.8), 52, Color(1, 0.8, 0.7))
	make_sign(signs, "ระวังลูกตุ้มหนาม", Vector3(-3.8, 4.4, -17.4), 48, Color(1, 0.75, 0.75))
	make_sign(signs, "เหยียบดอกบัวเพื่อกระโดดสูง ↑", Vector3(0, 3.6, -25.6), 46, Color(1, 0.8, 0.95))

	water(root, -3.0, Color(0.22, 0.1, 0.36, 0.8), Color(0.25, 0.08, 0.38), "SpiritMist")
	dead_zone(root, -4.5)
	particles_field(root, "SpiritMotes", Vector3(8, 6, -40), Vector3(30, 8, 45), "res://Assets/Textures/glow.png", 110, 10.0, Vector3(0, 0.15, 0), Vector2(0.05, 0.1), Color(0.45, 0.85, 1.0, 0.8), Color(0.85, 0.5, 1.0, 0.8), true, Vector2(0.05, 0.3))
	var stars := particles_field(root, "Stars", Vector3(0, 90, -60), Vector3(260, 40, 200), "res://Assets/Textures/glow.png", 350, 30.0, Vector3.ZERO, Vector2(1.2, 2.6), Color(1, 1, 1), Color(0.8, 0.85, 1), true, Vector2(0, 0))
	stars.angular_velocity_min = 0
	stars.angular_velocity_max = 0
	save_scene(root, "res://Scenes/Levels/Level2_MoonTemple.tscn")

# ================================================================== MENUS
func menu_scene(name: String, script: String, path: String, night := false):
	var root := Node3D.new()
	root.name = name
	root.set_script(load(script))
	root.set("music", load("res://Assets/Audio/Music/sakura.ogg"))
	if night:
		environment(root, Color(0.05, 0.04, 0.16), Color(0.5, 0.25, 0.45), Color(0.03, 0.02, 0.08), Color(0.6, 0.5, 0.8), 0.8, Color(0.4, 0.25, 0.5), 0.01, Color(1.0, 0.75, 0.6), 0.9, Vector3(-25, -60, 0))
	else:
		environment(root, Color(0.42, 0.58, 0.92), Color(1.0, 0.78, 0.8), Color(0.3, 0.5, 0.62), Color(0.95, 0.85, 0.95), 0.4, Color(1.0, 0.82, 0.88), 0.008, Color(1.0, 0.9, 0.8), 1.0, Vector3(-40, -30, 0), 0.9)
	var cam := Camera3D.new()
	cam.fov = 55
	add(root, cam, "Camera3D", Vector3(0, 2.6, 6.5))
	platform(root, Vector3(0, 0, 0), Vector3(9, 1.4, 9), true, [Color(0.95, 0.6, 0.74), Color(0.62, 0.45, 0.33), Color(0.5, 0.45, 0.48)], {"sides": 10, "underside_depth": 3.0})
	inst("res://Scenes/Objects/NinjaModel.tscn", root, Vector3(0, 0, 0), Vector3(0, 20, 0), 1.0, "Ninja")
	prop(root, "sakura_tree", Vector3(-2.6, 0, -2.0), 0.04, 30)
	prop(root, "sakura_tree", Vector3(3.0, 0, -1.2), 0.03, 160)
	var tg := inst("res://Scenes/Objects/ExitGate.tscn", root, Vector3(0, 0, -3.2), Vector3.ZERO, 0.9, "Torii")
	tg.set_script(null)
	tg.get_node("Label3D").visible = false
	prop(root, "bamboo_b", Vector3(-3.6, 0, 1.0), 1.0)
	prop(root, "bush", Vector3(2.8, 0, 2.2), 1.1)
	prop(root, "rock_b", Vector3(1.8, 0, 3.0), 1.2)
	prop(root, "stone_lamp", Vector3(-1.8, 0, 2.6), 0.5, 0, 2.19)
	if night:
		lantern_post(root, Vector3(3.6, 0, 1.0), 180)
		lantern_post(root, Vector3(-3.4, 0, -0.5), 0)
	water(root, -1.5, Color(0.36, 0.72, 0.82, 0.82) if not night else Color(0.35, 0.18, 0.55, 0.75))
	mountains(root, Vector3(0, -1.5, 0), 90, 14, Color(0.48, 0.58, 0.75), Color(0.62, 0.55, 0.72), Color(1, 0.97, 0.98, 1), Vector2(25, 50), 5)
	particles_field(root, "SakuraPetals", Vector3(0, 9, 0), Vector3(14, 2, 14), "res://Assets/Textures/petal.png", 160, 10.0, Vector3(0.3, -0.8, 0.1), Vector2(0.15, 0.25), Color(1, 0.8, 0.88), Color(1, 0.62, 0.78))
	save_scene(root, path)

# ================================================================== MAIN
func _init():
	process_frame.connect(_build, CONNECT_ONE_SHOT)

func _build():
	build_ninja_model()
	build_player()
	build_gem("res://Scenes/Objects/Gem.tscn", "gem_blue.glb", Color(0.4, 0.75, 1.0), 1.25)
	build_gem("res://Scenes/Objects/GemGreen.tscn", "gem_green.glb", Color(0.5, 1.0, 0.6), 1.5)
	build_checkpoint()
	build_exit_gate()
	build_simple("res://Scripts/Platform.gd", "AnimatableBody3D", "Platform", "res://Scenes/Objects/Platform.tscn")
	build_simple("res://Scripts/SpikeTrap.gd", "Node3D", "SpikeTrap", "res://Scenes/Objects/SpikeTrap.tscn")
	build_simple("res://Scripts/Spinner.gd", "Node3D", "Spinner", "res://Scenes/Objects/Spinner.tscn")
	build_simple("res://Scripts/Pendulum.gd", "Node3D", "Pendulum", "res://Scenes/Objects/Pendulum.tscn")
	build_simple("res://Scripts/JumpPad.gd", "Area3D", "JumpPad", "res://Scenes/Objects/JumpPad.tscn")
	build_hud()
	seed(42)
	build_level1()
	seed(7)
	build_level2()
	seed(3)
	menu_scene("MainMenu", "res://Scripts/MainMenu.gd", "res://Scenes/UI/MainMenu.tscn")
	menu_scene("Victory", "res://Scripts/Victory.gd", "res://Scenes/UI/Victory.tscn", true)
	quit()
