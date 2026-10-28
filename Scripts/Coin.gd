extends Area3D
# อัญมณีวิญญาณ (เดิมคือเหรียญใน Starter Kit) — ลอยขึ้นลง หมุน และดูดเข้าหาผู้เล่นเมื่อเข้าใกล้

# ---------- VARIABLES ---------- #

# You can change these values from inspector!
@export_category("Properties")
@export var follow_speed := 7.0
@export var amplitude := 0.2
@export var frequency := 3

var time_passed = 0.0
var is_in_range = false
var collected = false

# Vector
var initial_position := Vector3.ZERO

@onready var player := get_tree().get_first_node_in_group("Player")

# ---------- FUNCTIONS ---------- #

func _ready():
	add_to_group("Gem")
	initial_position = position
	time_passed = randf() * TAU
	body_entered.connect(_on_body_entered)
	$Range.body_entered.connect(_on_range_body_entered)

func _process(delta):
	if collected:
		return
	rotate_y(deg_to_rad(120) * delta)
	if is_in_range and player:
		follow_player(delta)
	else:
		coin_hover(delta) # Call the coin_hover function

# Coin Hover Animation
func coin_hover(delta):
	time_passed += delta
	var new_y = initial_position.y + amplitude * sin(frequency * time_passed)
	position.y = new_y

func follow_player(delta):
	var target = player.global_position + Vector3(0, 0.8, 0)
	global_position += global_position.direction_to(target) * follow_speed * delta

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	# Delete The Coin and Add Score
	if collected or not body.is_in_group("Player"):
		return
	collected = true
	GameManager.add_score()
	AudioManager.coin_sfx.play()
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.08)
	t.tween_property(self, "scale", Vector3.ONE * 0.01, 0.18)
	t.tween_callback(queue_free)

func _on_range_body_entered(body):
	if body.is_in_group("Player"):
		is_in_range = true
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.7, 0.7, 0.7), 0.3).set_ease(Tween.EASE_IN_OUT)
