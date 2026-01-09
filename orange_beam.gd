extends Area2D

@export var lifetime := 0.35
@export var tick_rate := 0.05
@export var damage_per_tick := 1

var _targets: Array[Node] = []
var _tick_timer: Timer

func setup(dir: Vector2, _target_pos: Vector2) -> void:
	rotation = dir.normalized().angle()

func _ready() -> void:
	# Track overlapping enemies
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.wait_time = tick_rate
	add_child(_tick_timer)
	_tick_timer.timeout.connect(_tick)
	_tick_timer.start()

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") and not _targets.has(body):
		_targets.append(body)

func _on_body_exited(body: Node) -> void:
	_targets.erase(body)

func _tick() -> void:
	for t in _targets:
		if not is_instance_valid(t):
			continue

		# Damage hook (adjust later to your real enemy API)
		if t.has_method("take_damage"):
			t.call("take_damage", damage_per_tick)
		elif "health" in t:
			t.health -= damage_per_tick
