extends Area2D

@export var enable_burst := true

@export var speed: float = 900.0
@export var damage: int = 5

const BURSTS := 3
const SHOTS_PER_BURST := 3
const SHOT_INTERVAL := 0.05
const BURST_INTERVAL := 0.12

var direction: Vector2 = Vector2.RIGHT

var _is_original := true
var _burst_started := false

var _burst_idx := 0
var _shot_idx := 0


func _ready() -> void:
	# Ensure this projectile actually collides with enemies.
	# Enemies in this project are typically on physics layer 2.
	# BreadBullet is configured with (layer=15, mask=15), so we mirror that.
	monitoring = true
	monitorable = true
	if collision_layer == 1:
		collision_layer = 15
	if collision_mask == 1:
		collision_mask = 15

	# Make sure signals are connected even if the scene connection was lost.
	var be := Callable(self, "_on_body_entered")
	if not is_connected("body_entered", be):
		connect("body_entered", be)
	var ae := Callable(self, "_on_area_entered")
	if not is_connected("area_entered", ae):
		connect("area_entered", ae)

	# Fallback: if for some reason setup() is not called, still start.
	if enable_burst and _is_original and not _burst_started:
		_start_burst_schedule()


func setup(dir: Vector2) -> void:
	direction = dir.normalized()
	if enable_burst and _is_original and not _burst_started:
		_start_burst_schedule()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	_try_damage(body)


func _on_area_entered(area: Area2D) -> void:
	_try_damage(area)


func _start_burst_schedule() -> void:
	_burst_started = true
	_burst_idx = 0
	_shot_idx = 0
	_schedule_next(SHOT_INTERVAL)


func _schedule_next(delay: float) -> void:
	var t := get_tree().create_timer(delay)
	t.timeout.connect(_on_burst_tick)


func _on_burst_tick() -> void:
	_shot_idx += 1

	if _shot_idx >= SHOTS_PER_BURST:
		_burst_idx += 1
		_shot_idx = 0

	if _burst_idx >= BURSTS:
		return

	if not (_burst_idx == 0 and _shot_idx == 0):
		_spawn_clone_from_player()

	var next_delay := SHOT_INTERVAL
	if _shot_idx == SHOTS_PER_BURST - 1:
		next_delay = BURST_INTERVAL

	_schedule_next(next_delay)


func _spawn_clone_from_player() -> void:
	var packed: PackedScene = load(get_scene_file_path())
	if packed == null:
		return

	var clone = packed.instantiate()

	clone._is_original = false
	clone._burst_started = true
	clone.enable_burst = false

	get_tree().current_scene.add_child(clone)
	clone.global_position = _get_player_muzzle_pos()
	clone.rotation = rotation

	if clone.has_method("setup"):
		clone.setup(direction)
	elif "direction" in clone:
		clone.direction = direction


func _get_player_muzzle_pos() -> Vector2:
	if Global.playerbody:
		var p = Global.playerbody
		if "muzzle" in p and p.muzzle:
			return p.muzzle.global_position
		if p.has_node("Muzzle"):
			return p.get_node("Muzzle").global_position
		return p.global_position
	return global_position


func _try_damage(hit: Node) -> void:
	var target: Node = hit

	# If we hit an enemy child, try its parent too.
	if not target.is_in_group("Enemy") and target.get_parent():
		if target.get_parent().is_in_group("Enemy"):
			target = target.get_parent()

	if target.is_in_group("Enemy"):
		if target.has_method("take_damage"):
			target.call("take_damage", damage)
			queue_free()
			return
		if target.has_method("hit"):
			target.call("hit", damage)
			queue_free()
			return
		if "current_health" in target:
			target.current_health -= damage
			queue_free()
			return
