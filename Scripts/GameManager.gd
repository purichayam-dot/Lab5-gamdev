extends Node
# ----------------------------------------------------------------------------------- #
#  GameManager (Autoload) — ต่อยอดจาก 3D Platformer Starter Kit (SD Studios)
#  เก็บสถานะเกม: อัญมณีที่เก็บได้, พลังชีวิต, ด่านปัจจุบัน, เวลา และการเปลี่ยนฉาก
# ----------------------------------------------------------------------------------- #

signal gems_changed(collected: int, total: int)
signal lives_changed(lives: int)
signal show_message(text: String, color: Color)
signal level_started(title: String, subtitle: String)
signal all_gems_collected
signal game_over

const LEVELS := [
	"res://Scenes/Levels/Level1_SakuraValley.tscn",
	"res://Scenes/Levels/Level2_MoonTemple.tscn",
]
const MAIN_MENU := "res://Scenes/UI/MainMenu.tscn"
const VICTORY := "res://Scenes/UI/Victory.tscn"
const MAX_LIVES := 3

# ---------- VARIABLES ---------- #

var score := 0          # อัญมณีที่เก็บได้ในด่านนี้ (ชื่อเดิมจาก Starter Kit)
var total_gems := 0     # อัญมณีทั้งหมดในด่าน
var lives := MAX_LIVES
var level_index := 0
var total_score := 0    # อัญมณีรวมทุกด่าน
var deaths := 0
var level_time := 0.0
var run_time := 0.0
var level_running := false
var _changing := false

# ---------- FUNCTIONS ---------- #

func _process(delta):
	show_mouse_cursor()
	if level_running:
		level_time += delta
	if Input.is_action_just_pressed("restart") and level_running:
		restart_level()

# กด ESC เพื่อสลับเมาส์ (ของเดิมจาก Starter Kit)
func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif level_running:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func start_level(gem_count: int, title: String, subtitle: String):
	score = 0
	total_gems = gem_count
	lives = MAX_LIVES
	level_time = 0.0
	level_running = true
	_changing = false
	gems_changed.emit(score, total_gems)
	lives_changed.emit(lives)
	level_started.emit(title, subtitle)

func add_score():
	score += 1
	gems_changed.emit(score, total_gems)
	if score >= total_gems:
		all_gems_collected.emit()
		show_message.emit("เก็บอัญมณีครบแล้ว!  ประตูโทริอิเปิดแล้ว", Color(0.55, 1.0, 0.75))

func has_all_gems() -> bool:
	return score >= total_gems

# คืนค่า true ถ้าหมดชีวิต
func lose_life() -> bool:
	lives = max(lives - 1, 0)
	deaths += 1
	lives_changed.emit(lives)
	if lives <= 0:
		level_running = false
		game_over.emit()
		return true
	return false

func start_game():
	level_index = 0
	total_score = 0
	deaths = 0
	run_time = 0.0
	change_scene(LEVELS[0])

func complete_level():
	if _changing:
		return
	level_running = false
	total_score += score
	run_time += level_time
	level_index += 1
	if level_index >= LEVELS.size():
		change_scene(VICTORY)
	else:
		change_scene(LEVELS[level_index])

func restart_level():
	change_scene(LEVELS[clamp(level_index, 0, LEVELS.size() - 1)])

func go_to_menu():
	level_running = false
	change_scene(MAIN_MENU)

func change_scene(path: String):
	if _changing:
		return
	_changing = true
	level_running = false
	await Transition.fade_out()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_changing = false
	Transition.fade_in()

func format_time(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]
