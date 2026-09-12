extends CharacterBody2D

const SPEED := 60.0

var dir := -1.0
var home := Vector2.ZERO
var min_x := -100000.0
var max_x := 100000.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var edge: RayCast2D = $Edge
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("beetle")
	home = global_position
	hitbox.body_entered.connect(_on_hitbox_body)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	velocity.x = dir * SPEED
	move_and_slide()
	# can't use is_on_wall=Tile because corner contacts at pit rims classify as walls
	# which flips beetle back off the edge
	edge.position.x = 20.0 * dir
	
	if is_on_floor() and not edge.is_colliding():
		dir *= -1.0
		
	if global_position.x < min_x:
		dir = 1.0
	elif global_position.x > max_x:
		dir = -1.0
	sprite.flip_h = dir > 0.0
	if global_position.y > 2000.0:
		global_position = home
		velocity = Vector2.ZERO


func _on_hitbox_body(body: Node2D) -> void:
	#collision
	if not body.is_in_group("player"):
		return
	if body.invuln_t > 0.0:
		return
	var falling: bool = body.velocity.y * body.gravity_sign > 120.0
	var above: bool = (global_position.y - body.global_position.y) * body.gravity_sign > 0.0
	if falling and above:
		get_tree().call_group("game", "stomp", self, body)
	else:
		get_tree().call_group("game", "hurt")
