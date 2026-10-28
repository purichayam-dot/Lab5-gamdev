# ----------------------------------------------------------------------------------- #
# -------------- FEEL FREE TO USE IN ANY PROJECT, COMMERCIAL OR NON-COMMERCIAL ------ #
# ---------------------- 3D PLATFORMER CONTROLLER BY SD STUDIOS --------------------- #
# ---------------------------- ATTRIBUTION NOT REQUIRED ----------------------------- #
# ----------------------------------------------------------------------------------- #

extends Node3D

# ---------- VARIABLES ---------- #

# Control Mouse Sensitivity through inspector or from here
@export var mouse_sensitivity := 0.2

# Assign Camera Node here it might be named different in your Project
@onready var camera = $SpringArm3D/Camera3D
@onready var spring = $SpringArm3D
@onready var auto_rotate = false
@onready var timer = $CameraControlTimer

# ---------- FUNCTIONS ---------- #

func _ready():
	top_level = true
	# Confining Mouse Cursor in the game view so it doesnt get in the way of gameplay
	timer.start()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handling Camera Movement
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -60, 10)

		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)
		auto_rotate = false
		timer.start()

# หมุนกล้องด้วยปุ่มลูกศร ซ้าย/ขวา (สำหรับคนเล่นทัชแพด)
func _process(delta):
	var turn := Input.get_axis("camera_right", "camera_left")
	if turn != 0.0:
		rotation_degrees.y = wrapf(rotation_degrees.y + turn * 120.0 * delta, 0, 360)
		auto_rotate = false
		timer.start()


func _on_camera_control_timer_timeout():
	auto_rotate = true
