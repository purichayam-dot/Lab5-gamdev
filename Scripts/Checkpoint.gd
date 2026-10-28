extends Area3D
# โคมหินจุดเช็กพอยต์: เดินผ่านแล้วโคมสว่าง และจะเกิดใหม่ที่นี่

@onready var light: OmniLight3D = $Light
@onready var flame: MeshInstance3D = $Flame
var activated := false

func _ready():
	body_entered.connect(_on_body_entered)
	light.visible = false
	flame.visible = false

func _on_body_entered(body):
	if activated or not body.is_in_group("Player"):
		return
	activated = true
	var spawn := get_tree().get_first_node_in_group("SpawnPoint")
	if spawn:
		spawn.global_position = global_position + Vector3(0, 0.5, 0)
	light.visible = true
	flame.visible = true
	flame.scale = Vector3.ZERO
	var t := create_tween()
	t.tween_property(flame, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.checkpoint_sfx.play()
	GameManager.show_message.emit("จุดเช็กพอยต์!", Color(1.0, 0.85, 0.45))
