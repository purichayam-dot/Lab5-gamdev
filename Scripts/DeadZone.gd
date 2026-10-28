extends Area3D

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	# ผู้เล่นตกน้ำ/ตกเหว → เสียชีวิต 1 ครั้งและเกิดใหม่ที่จุดเช็กพอยต์ล่าสุด
	if body.is_in_group("Player") and body.has_method("fall_out"):
		body.fall_out()
