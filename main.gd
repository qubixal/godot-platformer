extends Node

const COIN_SCENE: PackedScene = preload("res://coin.tscn")
const BEETLE_SCENE: PackedScene = preload("res://beetle.tscn")
const GOAL_SCENE: PackedScene = preload("res://goal.tscn")

const SPAWN := Vector2(16, 320)
const GOAL_POS := Vector2(2128, 352)
const KILL_Y := 1200.0

# Tile size is 32. Coins hand-placed: pit arcs, platform tops, ceiling row.
const COINS: Array[Vector2] = [
	Vector2(144, 344), Vector2(176, 344),
	Vector2(456, 300), Vector2(480, 278), Vector2(504, 300),
	Vector2(968, 300), Vector2(992, 274), Vector2(1016, 274), Vector2(1040, 300),
	Vector2(288, 216), Vector2(624, 248), Vector2(800, 152),
	Vector2(1184, 216), Vector2(1456, 248), Vector2(1696, 152),
	Vector2(720, 96), Vector2(784, 96), Vector2(848, 96), Vector2(912, 96),
	Vector2(976, 96), Vector2(1040, 96), Vector2(1104, 96), Vector2(1168, 96),
	Vector2(1232, 96),
]
const BEETLES: Array[Vector2] = [
	Vector2(336, 368), Vector2(816, 368), Vector2(1360, 368),
]
# Patrol leashes (world x): keep clear of pit rims and the world's edge.
const BEETLE_BOUNDS: Array[Vector2] = [
	Vector2(-150, 420), Vector2(580, 920), Vector2(1150, 1600),
]

const CENTER := Vector2(576, 324)
const ANCHOR := Vector2(1150, 300)

var score := 0
var total_coins := 0
var deaths := 0
var elapsed := 0.0
var won := false
var trauma := 0.0
var _shake_t := 0.0

@onready var player: CharacterBody2D = $Player
@onready var cam: Camera2D = $Player/Camera2D
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var deaths_label: Label = $HUD/DeathsLabel
@onready var win_panel: PanelContainer = $HUD/WinPanel
@onready var win_stats: Label = $HUD/WinPanel/Margin/VBox/StatsLabel


func _ready() -> void:
	add_to_group("game")
	for pos in COINS:
		var coin := COIN_SCENE.instantiate()
		coin.position = pos
		add_child(coin)
	for i in BEETLES.size():
		var beetle := BEETLE_SCENE.instantiate()
		beetle.position = BEETLES[i]
		beetle.min_x = BEETLE_BOUNDS[i].x
		beetle.max_x = BEETLE_BOUNDS[i].y
		add_child(beetle)
	var goal := GOAL_SCENE.instantiate()
	goal.position = GOAL_POS
	add_child(goal)
	total_coins = COINS.size()
	win_panel.visible = false
	_update_hud()


func _process(delta: float) -> void:
	if not won:
		elapsed += delta
		timer_label.text = _fmt_time(elapsed)
	# sky lock to screen
	$BG/Sky.position = CENTER
	$BG/Mid.position = CENTER + (ANCHOR - cam.global_position) * 0.25
	$BG/Near.position = CENTER + (ANCHOR - cam.global_position) * 0.55
	if trauma > 0.0:
		_shake_t += delta * 40.0
		trauma = maxf(0.0, trauma - delta * 1.6)
		var s := trauma * trauma * 22.0
		cam.offset = Vector2(sin(_shake_t * 1.3), cos(_shake_t * 1.7)) * s
	else:
		cam.offset = Vector2.ZERO
	# fall into void or flew away from gravity
	if not won and (player.global_position.y > KILL_Y or player.global_position.y < -2000.0):
		hurt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()


func collect_coin(coin: Node2D) -> void:
	if won:
		return
	score += 1
	sfx("coin")
	coin.queue_free()
	_update_hud()


func stomp(beetle: Node2D, body: Node2D) -> void:
	if won:
		return
	score += 2
	beetle.queue_free()
	body.bounce()
	shake(0.35)
	_update_hud()


func hurt() -> void:
	if won:
		return
	deaths += 1
	sfx("hurt")
	shake(0.6)
	player.global_position = SPAWN
	player.velocity = Vector2.ZERO
	player.gravity_sign = 1.0
	player.sprite.rotation = 0.0
	player.invuln_t = 1.2
	_update_hud()


func win() -> void:
	if won:
		return
	won = true
	sfx("win")
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	win_stats.text = "TIME %s   SCORE %d   DEATHS %d   (R to retry)" % [
		_fmt_time(elapsed), score, deaths]
	win_panel.visible = true


func sfx(sound: String) -> void:
	match sound:
		"jump":
			$Audio/Jump.play()
		"coin":
			$Audio/Coin.play()
		"flip":
			$Audio/Flip.play()
		"hurt":
			$Audio/Hurt.play()
		"win":
			$Audio/Win.play()


func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func _update_hud() -> void:
	score_label.text = "COINS %d/%d" % [score, total_coins]
	deaths_label.text = "DEATHS %d" % deaths


func _fmt_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	return "%d:%02d" % [m, s]
