extends Area2D

@export var enable_burst := true

# Match these to your original projectile values
@export var speed: float = 900.0
@export var damage: int = 5

const BURSTS := 3
const SHOTS_PER_BURST := 3
const SHOT_INTERVAL := 0.05
const BURST_INTERVAL := 0.12

var direction: Vector2 = Vector2.RIGHT

var _is_original := true
var _burst_started := false

# burst state
var _burst_idx := 0
var _shot_idx := 0


func _ready() -> void:
	# Fallback: if for some reason setup() is not called, still start.
	# This won't duplicate bursts because of _burst_started.
	if enable_burst and _is_original and not _burst_started:
		_start_burst_schedule()


func setup(dir: Vector2) -> void:
	direction = dir.normalized()

	# Start burst exactly when the player fires THIS projectile
	if enable_burst and _is_original and not _burst_started:
		_start_burst_schedule()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	_try_damage(body)

func _on_area_entered(area: Area2D) -> void:
	_try_damage(area)


func _start_burst_schedule() -> void:
	_burst_started = true
	_burst_idx = 0
	_shot_idx = 0

	# We already have 1 projectile (this one) as shot 0 of burst 0.
	# Next tick should spawn shot 1 of burst 0.
	_schedule_next(SHOT_INTERVAL)


func _schedule_next(delay: float) -> void:
	var t := get_tree().create_timer(delay)
	t.timeout.connect(_on_burst_tick)


func _on_burst_tick() -> void:
	# Advance to the next shot position we need to spawn.
	_shot_idx += 1

	# Move to next burst if we finished this one
	if _shot_idx >= SHOTS_PER_BURST:
		_burst_idx += 1
		_shot_idx = 0

	# Done?
	if _burst_idx >= BURSTS:
		return

	# Skip spawning shot 0 of burst 0 because that's the original projectile
	if not (_burst_idx == 0 and _shot_idx == 0):
		_spawn_clone_from_player()

	# Decide next delay
	var next_delay := SHOT_INTERVAL
	if _shot_idx == SHOTS_PER_BURST - 1:
		# next tick would move to the next burst
		next_delay = BURST_INTERVAL

	_schedule_next(next_delay)


func _spawn_clone_from_player() -> void:
	var packed: PackedScene = load(get_scene_file_path())
	if packed == null:
		return

	var clone = packed.instantiate()

	# Prevent clones from bursting
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

		# Best: your player script has `@onready var muzzle = $Muzzle`
		if "muzzle" in p and p.muzzle:
			return p.muzzle.global_position

		# Fallback: child node named "Muzzle"
		if p.has_node("Muzzle"):
			return p.get_node("Muzzle").global_position

		return p.global_position

	return global_position

func _try_damage(hit: Node) -> void:
	# If you tag enemies with a group, this is the cleanest.
	# Add your Enemy root nodes to group "Enemy" in the editor.
	var target: Node = hit

	# If we collided with an enemy's child (like Hitbox Area2D),
	# try the parent too.
	if not target.is_in_group("Enemy") and target.get_parent():
		if target.get_parent().is_in_group("Enemy"):
			target = target.get_parent()

	# Apply damage using whichever method your enemies actually have.
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
