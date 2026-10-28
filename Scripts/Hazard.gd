extends Area3D
# พื้นที่อันตราย: ถ้าผู้เล่นแตะจะบาดเจ็บ (ใช้กับหนาม, ลูกตุ้ม, แท่งหมุน)

@export var active := true

func _physics_process(_delta):
	if not active:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("Player") and b.has_method("hurt"):
			b.hurt(global_position)
