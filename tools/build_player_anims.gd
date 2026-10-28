extends SceneTree
# Builds res://Assets/Models/Characters/ninja_animations.res
# Re-maps the Quaternius Ninja clips to the SAME animation names the
# Starter Kit's Gobot used (Idle, Run, Jump, Flip, Fall ...), so player.gd
# can keep calling animation.play("Run") etc.

const SRC := "res://Assets/Models/Characters/Ninja.glb"
const OUT := "res://Assets/Models/Characters/ninja_animations.res"
const P := "CharacterArmature|"

var neutral := {}   # bone track path -> Quaternion (ท่ายืนปกติ แขนแนบลำตัว)

# ไฟล์ glb จาก poly.pizza บางคลิป (เช่น Idle, Wave) ไม่มีคีย์ของกระดูกแขน/ลำตัว
# ทำให้ตัวละครกาง T-pose → เติมท่าปกติ (ค่าเฉลี่ยจากคลิป Walk) ให้กระดูกที่ขาดหายไป
func build_neutral(ap: AnimationPlayer, sk: Skeleton3D):
	var w := ap.get_animation(P + "Walk")
	for t in w.get_track_count():
		if w.track_get_type(t) != Animation.TYPE_ROTATION_3D or w.track_get_key_count(t) < 2:
			continue
		var acc := Vector4.ZERO
		var first: Quaternion = w.track_get_key_value(t, 0)
		for k in w.track_get_key_count(t):
			var q: Quaternion = w.track_get_key_value(t, k)
			if q.dot(first) < 0.0:
				q = -q
			acc += Vector4(q.x, q.y, q.z, q.w)
		acc = acc.normalized()
		neutral[String(w.track_get_path(t))] = Quaternion(acc.x, acc.y, acc.z, acc.w)

func fill_missing(a: Animation, sk: Skeleton3D) -> int:
	var fixed := 0
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
			continue
		var path := String(a.track_get_path(t))
		if not neutral.has(path) or a.track_get_key_count(t) > 1:
			continue
		var bone := sk.find_bone(path.get_slice(":", 1))
		var rest_q := sk.get_bone_rest(bone).basis.get_rotation_quaternion()
		var v: Quaternion = a.track_get_key_value(t, 0)
		if abs(v.dot(rest_q)) > 0.9999:
			a.track_set_key_value(t, 0, neutral[path])
			fixed += 1
	return fixed

var _sk: Skeleton3D

func dup(ap: AnimationPlayer, src: String, loop: bool, speed := 1.0) -> Animation:
	var a: Animation = ap.get_animation(P + src).duplicate(true)
	var nf := fill_missing(a, _sk)
	if nf > 0:
		print("  fixed ", nf, " T-pose bone tracks in ", src)
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if speed != 1.0:
		# time-scale every key so the clip plays faster/slower by default
		for t in a.get_track_count():
			var n := a.track_get_key_count(t)
			var keys := []
			for k in n:
				keys.append([a.track_get_key_time(t, k) / speed, a.track_get_key_value(t, k), a.track_get_key_transition(t, k)])
			for k in range(n - 1, -1, -1):
				a.track_remove_key(t, k)
			for kk in keys:
				a.track_insert_key(t, kk[0], kk[1], kk[2])
		a.length = a.length / speed
	return a

func add_root_rest(a: Animation, rest: Transform3D) -> void:
	# Keep RootNode at its rest pose in every clip so an interrupted Flip
	# never leaves the character upside-down.
	var tp := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(tp, "RootNode")
	a.position_track_insert_key(tp, 0.0, rest.origin)
	var tr := a.add_track(Animation.TYPE_ROTATION_3D)
	a.track_set_path(tr, "RootNode")
	a.rotation_track_insert_key(tr, 0.0, rest.basis.get_rotation_quaternion())

func _init():
	process_frame.connect(_go, CONNECT_ONE_SHOT)

func _go():
	var scene: Node = load(SRC).instantiate()
	var ap: AnimationPlayer = scene.get_node("AnimationPlayer")
	var root_node: Node3D = scene.get_node("RootNode")
	_sk = scene.get_node("RootNode/CharacterArmature/Skeleton3D")
	build_neutral(ap, _sk)
	var rest := root_node.transform
	print("RootNode rest: ", rest)
	var lib := AnimationLibrary.new()
	var map := {
		"Idle": dup(ap, "Idle", true),
		"Run": dup(ap, "Run", true),
		"Walk": dup(ap, "Walk", true),
		"Jump": dup(ap, "Jump", false),
		"Fall": dup(ap, "Jump_Idle", true),
		"Land": dup(ap, "Jump_Land", false),
		"Hurt": dup(ap, "HitReact", false),
		"Death": dup(ap, "Death", false),
		"VictorySign": dup(ap, "Wave", true),
		"Punch": dup(ap, "Punch", false),
	}
	for k in map:
		add_root_rest(map[k], rest)
	# ---- Flip: tucked air pose + a full 360° front-flip around the body's centre
	var flip := dup(ap, "Jump_Idle", false)
	flip.length = 0.5
	var centre := Vector3(0, 1.45, 0) # mid-height of the model in its own units
	var tp := flip.add_track(Animation.TYPE_POSITION_3D)
	flip.track_set_path(tp, "RootNode")
	var tr := flip.add_track(Animation.TYPE_ROTATION_3D)
	flip.track_set_path(tr, "RootNode")
	var steps := 12
	for i in steps + 1:
		var f := float(i) / steps
		var eased := f * f * (3.0 - 2.0 * f)
		var ang := -TAU * eased
		var q := Quaternion(Vector3.RIGHT, ang)
		var b := Basis(q) * rest.basis
		var pos := centre - Basis(q) * centre + rest.origin
		flip.position_track_insert_key(tp, f * flip.length, pos)
		flip.rotation_track_insert_key(tr, f * flip.length, b.get_rotation_quaternion())
	map["Flip"] = flip
	for k in map:
		lib.add_animation(k, map[k])
	var err := ResourceSaver.save(lib, OUT)
	print("saved ", OUT, " err=", err, " anims=", lib.get_animation_list())
	scene.free()
	quit()
