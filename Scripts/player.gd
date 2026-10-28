# ----------------------------------------------------------------------------------- #
# -------------- FEEL FREE TO USE IN ANY PROJECT, COMMERCIAL OR NON-COMMERCIAL ------ #
# ---------------------- 3D PLATFORMER CONTROLLER BY SD STUDIOS --------------------- #
# ---------------------------- ATTRIBUTION NOT REQUIRED ----------------------------- #
# ----------------------------------------------------------------------------------- #
# ดัดแปลง: เปลี่ยนตัวละครเป็น Ninja (Quaternius / poly.pizza) และเพิ่มระบบ
# บาดเจ็บ-เกิดใหม่, กระโดดตีลังกา, แท่นดีด, ท่าชนะ, coyote time

extends CharacterBody3D

# ---------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 6
@export var jump_force : float = 7
@export var follow_lerp_factor : float = 4
@export var jump_limit : int = 2

@export_group("Game Juice")
@export var jumpStretchSize := Vector3(0.8, 1.2, 0.8)
@export var invincible_time := 1.4
@export var knockback_force := 7.0

# Booleans
var is_grounded = false
var can_double_jump = false
var is_flipping = false
var is_hurt = false
var input_enabled = true
var was_grounded = true
var coyote_timer := 0.0
var invincible_timer := 0.0
var knockback := Vector3.ZERO

# Onready Variables
@onready var model = $Model
@onready var animation : AnimationPlayer = $Model/AnimationPlayer
@onready var spring_arm = %Gimbal

@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2

# ---------- FUNCTIONS ---------- #

func _ready():
	add_to_group("Player")
	spring_arm.spring.add_excluded_object(get_rid())
	animation.play("Idle")
	snap_camera()

func _process(delta):
	# Smoothly follow player's position
	spring_arm.position = lerp(spring_arm.position, position, delta * follow_lerp_factor)

	# Player Rotation
	if is_moving() and input_enabled:
		var look_direction = Vector2(velocity.z, velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * 12)
		if spring_arm.auto_rotate:
			spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, look_direction.angle()-deg_to_rad(180), delta*0.4)
			spring_arm.rotation.x = lerp_angle(spring_arm.rotation.x, deg_to_rad(0), delta*0.4)

	# กระพริบตอนอมตะหลังโดนกับดัก
	if invincible_timer > 0.0:
		invincible_timer -= delta
		model.visible = int(invincible_timer * 14.0) % 2 == 0 or invincible_timer <= 0.0
	else:
		model.visible = true

	player_animations()

func _physics_process(delta):
	get_input(delta)

	# Check if player is grounded or not
	is_grounded = is_on_floor()

	# Handle Jumping (Jump + Double/Flip Jump แบบเดิมของ Starter Kit)
	if is_grounded:
		can_double_jump = true
		coyote_timer = 0.12
		if not was_grounded:
			land()
	else:
		coyote_timer -= delta
	was_grounded = is_grounded

	if input_enabled and Input.is_action_just_pressed("jump"):
		if is_grounded or coyote_timer > 0.0:
			perform_jump()
		elif can_double_jump:
			perform_flip_jump()

	velocity.y -= gravity * delta

func perform_jump():
	coyote_timer = 0.0
	AudioManager.jump_sfx.pitch_scale = 1.12
	AudioManager.jump_sfx.play()
	jumpTween()
	animation.play("Jump", 0.05)
	velocity.y = jump_force

func perform_flip_jump():
	can_double_jump = false
	is_flipping = true
	AudioManager.jump_sfx.pitch_scale = 0.8
	AudioManager.jump_sfx.play()
	animation.play("Flip", 0.05, 1.0)
	velocity.y = jump_force * 0.95
	await animation.animation_finished
	is_flipping = false

func land():
	var tween = create_tween()
	tween.tween_property(model, "scale", Vector3(1.15, 0.85, 1.15), 0.07)
	tween.tween_property(model, "scale", Vector3.ONE, 0.12)

# ใช้กับแท่นดอกบัวดีดตัว
func bounce(force: float):
	velocity.y = force
	can_double_jump = true
	is_flipping = false
	coyote_timer = 0.0
	jumpTween()
	animation.play("Jump", 0.05)

func is_moving():
	return abs(velocity.z) > 0.05 || abs(velocity.x) > 0.05

func jumpTween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", jumpStretchSize, 0.1)
	tween.tween_property(self, "scale", Vector3(1,1,1), 0.1)

# Get Player Input
func get_input(_delta):
	var move_direction := Vector3.ZERO
	if input_enabled:
		move_direction.x = Input.get_axis("move_left", "move_right")
		move_direction.z = Input.get_axis("move_forward", "move_back")

	# Move The player Towards Spring Arm/Camera Rotation
	move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity = Vector3(move_direction.x * move_speed, velocity.y, move_direction.z * move_speed)
	velocity += knockback
	knockback = knockback.lerp(Vector3.ZERO, 0.12)

	move_and_slide()

# Handle Player Animations (ชื่อแอนิเมชันเหมือนของเดิม: Idle / Run / Jump / Flip + Fall)
func player_animations():
	particle_trail.emitting = false
	footsteps.stream_paused = true

	if is_hurt or not input_enabled:
		return
	if is_flipping:
		return

	if is_on_floor():
		if is_moving(): # Checks if player is moving
			if animation.current_animation != "Run":
				animation.play("Run", 0.15)
			particle_trail.emitting = true
			footsteps.stream_paused = false
		else:
			if animation.current_animation != "Idle":
				animation.play("Idle", 0.2)
	else:
		if velocity.y < -1.0 and animation.current_animation != "Fall" and animation.current_animation != "Jump":
			animation.play("Fall", 0.25)
		elif velocity.y < -1.0 and animation.current_animation == "Jump" and not animation.is_playing():
			animation.play("Fall", 0.25)

# ---------- DAMAGE / RESPAWN ---------- #

func hurt(from_position: Vector3 = global_position):
	if invincible_timer > 0.0 or is_hurt or not input_enabled:
		return
	var dir := (global_position - from_position)
	dir.y = 0
	if dir.length() < 0.01:
		dir = -model.global_basis.z
	knockback = dir.normalized() * knockback_force
	velocity.y = 5.0
	is_hurt = true
	AudioManager.hurt_sfx.play()
	animation.play("Hurt", 0.05)
	Engine.time_scale = 0.4
	await get_tree().create_timer(0.12, true, false, true).timeout
	Engine.time_scale = 1.0
	var dead := GameManager.lose_life()
	if dead:
		input_enabled = false
		animation.play("Death", 0.1)
		return
	await get_tree().create_timer(0.45).timeout
	respawn()

# ตกน้ำ / ตกเหว
func fall_out():
	if not input_enabled:
		return
	AudioManager.hurt_sfx.play()
	var dead := GameManager.lose_life()
	if dead:
		input_enabled = false
		velocity = Vector3.ZERO
		return
	respawn()

func respawn():
	var spawn := get_tree().get_first_node_in_group("SpawnPoint")
	if spawn:
		global_position = spawn.global_position
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	is_hurt = false
	is_flipping = false
	invincible_timer = invincible_time
	animation.play("Idle", 0.1)
	snap_camera()

func snap_camera():
	if spring_arm:
		spring_arm.position = position

func victory():
	input_enabled = false
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	# หันหน้าเข้าหากล้องแล้วโบกมือ
	var to_cam = spring_arm.camera.global_position - global_position
	model.rotation.y = atan2(to_cam.x, to_cam.z)
	animation.play("VictorySign", 0.2)
