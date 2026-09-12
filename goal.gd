extends Area2D
## Signal beacon goal: touch the flag to restore the signal and win.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	$Sprite2D.position.y = sin(Time.get_ticks_msec() / 350.0) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("game", "win")
