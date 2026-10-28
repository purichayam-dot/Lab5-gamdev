extends Node

# ---------- VARIABLES ---------- #

# References (jump/coin = ของเดิมจาก Starter Kit, ที่เหลือเพิ่มใหม่)
@onready var jump_sfx = $JumpSfx
@onready var coin_sfx = $CoinSfx
@onready var hurt_sfx = $HurtSfx
@onready var checkpoint_sfx = $CheckpointSfx
@onready var bounce_sfx = $BounceSfx
@onready var unlock_sfx = $UnlockSfx
@onready var clear_sfx = $ClearSfx
@onready var spike_sfx = $SpikeSfx
@onready var crumble_sfx = $CrumbleSfx
@onready var music = $Music

func play_music(stream: AudioStream):
	if music.stream == stream and music.playing:
		return
	music.stream = stream
	music.play()

func stop_music():
	music.stop()
