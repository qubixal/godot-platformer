extends Area2D

var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	add_to_group("coin")
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# coin floating effect
	_t += delta
	$Sprite2D.scale.x = 0.35 + 0.65 * absf(cos(_t * 4.0))
	position.y = _base_y + sin(_t * 2.5) * 4.0

func _on_body_entered(body: Node2D) -> void:
	# collide with player
	if body.is_in_group("player"):
		get_tree().call_group("game", "collect_coin", self)
