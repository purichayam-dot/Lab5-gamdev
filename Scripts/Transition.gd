extends CanvasLayer
# Autoload: ม่านเฟดดำตอนเปลี่ยนฉาก

var _rect: ColorRect

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.05, 0.03, 0.08, 0.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

func fade_out(time := 0.45):
	var t := create_tween()
	t.tween_property(_rect, "color:a", 1.0, time)
	await t.finished

func fade_in(time := 0.6):
	var t := create_tween()
	t.tween_property(_rect, "color:a", 0.0, time)
	await t.finished
