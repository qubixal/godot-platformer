extends CharacterBody2D

const SPEED := 300.0
const STOP_DECEL := 900.0
const JUMP_VELOCITY := -900.0
const COYOTE := 0.10
const BUFFER := 0.12
const FLIP_COOLDOWN := 0.35

var gravity_sign := 1.0 # +1 is down gravity, -1 is up gravity
var coyote_t := 0.0
var buffer_t := 0.0
var flip_cd := 0.0
var control_enabled := true
var invuln_t := 0.0
var _blink := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var land_dust: CPUParticles2D = $LandDust
@onready var flip_burst: CPUParticles2D = $FlipBurst


func _ready() -> void:
	add_to_group("player")


func ground_side_down() -> bool:
	return gravity_sign > 0.0


func on_ground() -> bool:
	if ground_side_down():
		return is_on_floor()
	return is_on_ceiling()


func flip_gravity() -> void:
	gravity_sign *= -1.0
	flip_cd = FLIP_COOLDOWN
	# keep half momentum reversed by gravity
	velocity.y = -velocity.y * 0.5
	sprite.rotation = 0.0 if ground_side_down() else PI
	flip_burst.direction = Vector2(0, gravity_sign)
	flip_burst.restart()
	get_tree().call_group("game", "sfx", "flip")
	get_tree().call_group("game", "shake", 0.25)


func bounce() -> void:
	velocity.y = JUMP_VELOCITY * gravity_sign * 0.75
	coyote_t = COYOTE
	get_tree().call_group("game", "sfx", "jump")


func _physics_process(delta: float) -> void:
	flip_cd = maxf(0.0, flip_cd - delta)
	invuln_t = maxf(0.0, invuln_t - delta)
	var was_ground := on_ground()
	var fall_speed := velocity.y

	if is_on_floor() or is_on_ceiling():
		if on_ground():
			coyote_t = COYOTE
	else:
		velocity += get_gravity() * gravity_sign * delta
		coyote_t = maxf(0.0, coyote_t - delta)

	if not control_enabled:
		velocity.x = move_toward(velocity.x, 0.0, STOP_DECEL)
		move_and_slide()
		return

	buffer_t = maxf(0.0, buffer_t - delta)
	if Input.is_action_just_pressed("jump"):
		buffer_t = BUFFER
	if flip_cd <= 0.0 and Input.is_action_just_pressed("flip"):
		flip_gravity()

	if buffer_t > 0.0 and coyote_t > 0.0:
		velocity.y = JUMP_VELOCITY * gravity_sign
		buffer_t = 0.0
		coyote_t = 0.0
		get_tree().call_group("game", "sfx", "jump")
	elif Input.is_action_just_released("jump") and velocity.y * gravity_sign < -350.0:
		# Jump-cut: release early for a short hop.
		velocity.y = -350.0 * gravity_sign

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, STOP_DECEL)

	move_and_slide()

	if not was_ground and on_ground() and absf(fall_speed) > 700.0:
		land_dust.direction = Vector2(0, -gravity_sign)
		land_dust.restart()
		get_tree().call_group("game", "shake", 0.2)
		
# because of this there is bug that gets you stuck onto the bottom side of sprites but i'm too lazy to fix so it's intended feature now


func _process(delta: float) -> void:
	if invuln_t > 0.0:
		_blink += delta * 20.0
		sprite.modulate.a = 0.35 + 0.65 * absf(sin(_blink))
	else:
		sprite.modulate.a = 1.0
