extends Area2D

@export var damage := 20
@export var lifetime := 2.5
@export var pierce := 3

@export var initial_speed := 900.0
@export var gravity := 1600.0
@export var upward_boost := 420.0

var _vel := Vector2.ZERO
var _hits := 0

func setup(dir: Vector2, _target_pos: Vector2) -> void:
	var d := dir.normalized()
	_vel = d * initial_speed
	_vel.y -= upward_boost

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	_vel.y += gravity * delta
	global_position += _vel * delta
	rotation = _vel.angle()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Enemy"):
		return

	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	elif "health" in body:
		body.health -= damage

	_hits += 1
	if _hits > pierce:
		queue_free()
