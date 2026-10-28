@tool
extends Node3D
# โมเดลนินจา (Quaternius / poly.pizza) + AnimationPlayer ที่ตั้งชื่อท่าเหมือน Starter Kit
# ไฟล์ glb จาก poly.pizza ไม่ได้ผูก MeshInstance3D เข้ากับ Skeleton3D (skeleton path ว่าง)
# ทำให้ตัวละครค้างท่า T-pose → สคริปต์นี้ผูกให้ใหม่ตอนเริ่มฉาก

func _ready():
	for mi in find_children("*", "MeshInstance3D", true, false):
		if mi.skin and mi.get_node_or_null(mi.skeleton) == null:
			var sk := mi.get_parent() as Skeleton3D
			if sk == null:
				var found := find_children("*", "Skeleton3D", true, false)
				if found.size() > 0:
					sk = found[0]
			if sk:
				mi.skeleton = mi.get_path_to(sk)
