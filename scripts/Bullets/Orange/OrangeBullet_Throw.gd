extends Area2D

# Orange Beam: short-lived, persistent beam that ticks very fast.
# - Deals very low damage per tick
# - Applies a debuff that makes the enemy take double damage from ANY hit

@export var beam_length: float = 430.0
@export var beam_width: float = 18.0
@export var duration: float = 0.75

@export var tick_interval: float = 0.05  # lower = faster ticks (try 0.03)
@export var tick_damage: int = 1
@export var debuff_duration: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var _targets: Array[Node] = []
var _tick_accum := 0.0
var _life := 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _line: Line2D = $Line2D


func _ready() -> void:
	monitoring = true
	monitorable = true
	if collision_layer == 1:
		collision_layer = 15
	if collision_mask == 1:
		collision_mask = 15

	var be := Callable(self, "_on_body_entered")
	if not is_connected("body_entered", be):
		connect("body_entered", be)
	var bx := Callable(self, "_on_body_exited")
	if not is_connected("body_exited", bx):
		connect("body_exited", bx)

	_update_beam_geometry()
	_update_beam_visual()


func setup(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
	_update_beam_geometry()
	_update_beam_visual()


func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= duration:
		queue_free()
		return

	# Stick to the player's muzzle while active.
	global_position = _get_player_muzzle_pos()

	# Keep aiming at the mouse (beam feel).
	var aim_dir := (get_global_mouse_position() - global_position).normalized()
	if aim_dir.length() > 0.001:
		direction = aim_dir
		rotation = direction.angle()

	_update_beam_geometry()
	_update_beam_visual()

	_tick_accum += delta
	while _tick_accum >= tick_interval:
		_tick_accum -= tick_interval
		_apply_tick()


func _apply_tick() -> void:
	# Clean invalid entries
	for i in range(_targets.size() - 1, -1, -1):
		var t := _targets[i]
		if not is_instance_valid(t):
			_targets.remove_at(i)

	for t in _targets:
		var enemy := _coerce_enemy_node(t)
		if enemy == null:
			continue

		# Apply debuff
		if enemy.has_method("apply_orange_debuff"):
			enemy.call("apply_orange_debuff", debuff_duration)
		elif "orange_debuff_time" in enemy:
			enemy.orange_debuff_time = max(enemy.orange_debuff_time, debuff_duration)

		# Tick damage (very low)
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", tick_damage)


func _on_body_entered(body: Node) -> void:
	var enemy := _coerce_enemy_node(body)
	if enemy != null and not _targets.has(body):
		_targets.append(body)


func _on_body_exited(body: Node) -> void:
	if _targets.has(body):
		_targets.erase(body)


func _coerce_enemy_node(n: Node) -> Node:
	if n == null:
		return null
	if n.is_in_group("Enemy"):
		return n
	if n.get_parent() and n.get_parent().is_in_group("Enemy"):
		return n.get_parent()
	return null


func _update_beam_geometry() -> void:
	# Center the hitbox on the beam: forward from origin.
	if _shape and _shape.shape is RectangleShape2D:
		var r := _shape.shape as RectangleShape2D
		r.size = Vector2(beam_length, beam_width)
		_shape.position = Vector2(beam_length * 0.5, 0)
	elif _shape:
		var r2 := RectangleShape2D.new()
		r2.size = Vector2(beam_length, beam_width)
		_shape.shape = r2
		_shape.position = Vector2(beam_length * 0.5, 0)


func _update_beam_visual() -> void:
	if not _line:
		return
	_line.clear_points()
	_line.add_point(Vector2.ZERO)
	_line.add_point(Vector2(beam_length, 0))
	_line.width = beam_width


func _get_player_muzzle_pos() -> Vector2:
	if Global.playerbody:
		var p = Global.playerbody
		if "muzzle" in p and p.muzzle:
			return p.muzzle.global_position
		if p.has_node("Muzzle"):
			return p.get_node("Muzzle").global_position
		if p.has_node("ShootPoint"):
			return p.get_node("ShootPoint").global_position
		return p.global_position
	return global_position
