extends Area2D
class_name FruitProjectile

@export var speed := 700.0
@export var damage := 5
@export var lifetime := 2.0
@export var pierce := 0  # 0 = no pierce, 1 = hits 2 targets, etc.

var direction: Vector2 = Vector2.RIGHT
var _hits_done := 0

func setup(dir: Vector2, _target_pos: Vector2 = Vector2.ZERO) -> void:
	direction = dir.normalized()

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _deal_damage(target: Node) -> void:
	# Adjust this to match your enemy damage API
	if target.has_method("take_damage"):
		target.call("take_damage", damage)
	elif "health" in target:
		target.health -= damage

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		_deal_damage(body)
		_register_hit()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		_deal_damage(area)
		_register_hit()

func _register_hit() -> void:
	_hits_done += 1
	if _hits_done > pierce:
		queue_free()
