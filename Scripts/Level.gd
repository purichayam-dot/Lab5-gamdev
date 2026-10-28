extends Node3D
# สคริปต์หลักของแต่ละด่าน: นับอัญมณี, เริ่มเพลง, ส่งชื่อด่านให้ HUD

@export var level_title := "ด่าน"
@export var level_subtitle := ""
@export var music: AudioStream

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().process_frame
	var gems := get_tree().get_nodes_in_group("Gem").size()
	GameManager.start_level(gems, level_title, level_subtitle)
	if music:
		if music is AudioStreamOggVorbis:
			(music as AudioStreamOggVorbis).loop = true
		AudioManager.play_music(music)
