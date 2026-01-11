extends Node
class_name WeaponManager

@export var shoot_point_path: NodePath
@export var normal_projectile_scene: PackedScene

# Map: "orange" -> OrangeProjectileScene, etc.
@export var special_projectiles: Dictionary = {"pomegranate":"res://scenes/pomegranate_shot.tscn"}

# Base cooldown (breadcrumbs)
@export var base_cooldown := 0.30

var _can_shoot := true
var _cooldown_timer: Timer

# Fruit stack
@export var powerup_default_duration := 5.0
var _powerup_timer: Timer
var shot_stack: Array[String] = []

func _ready() -> void:
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(func(): _can_shoot = true)

	_powerup_timer = Timer.new()
	_powerup_timer.one_shot = true
	add_child(_powerup_timer)
	_powerup_timer.timeout.connect(_on_powerup_timeout)

func current_weapon_id() -> String:
	return "" if shot_stack.is_empty() else shot_stack.back()

func push_powerup(item_id: String, duration: float = -1.0, auto_fire: bool = true) -> void:
	if duration < 0.0:
		duration = powerup_default_duration

	shot_stack.push_back(item_id)

	_powerup_timer.stop()
	_powerup_timer.wait_time = duration
	_powerup_timer.start()

	if auto_fire:
		try_shoot()

func _on_powerup_timeout() -> void:
	if shot_stack.is_empty():
		return
	shot_stack.pop_back()

	# If another fruit is still stacked below, it remains active until replaced
	# (You can upgrade this later to “pause and resume remaining time” per fruit.)

func try_shoot() -> void:
	if not _can_shoot:
		return

	var shoot_point := get_node_or_null(shoot_point_path) as Node2D
	if shoot_point == null:
		push_error("WeaponManager: shoot_point_path not set or invalid.")
		return

	var weapon_id := current_weapon_id()

	# Pick projectile scene + cooldown by fruit
	var scene_to_spawn: PackedScene = normal_projectile_scene
	var cooldown := base_cooldown

	if weapon_id != "" and special_projectiles.has(weapon_id):
		scene_to_spawn = special_projectiles[weapon_id]

		# Optional per fruit cooldown feel
		match weapon_id:
			"orange":
				cooldown = 0.05
			"pomegranate":
				cooldown = 0.12
			"coconut":
				cooldown = 0.45
			"banana":
				cooldown = 0.80
			_:
				cooldown = base_cooldown

	# Spawn
	var inst := scene_to_spawn.instantiate()
	if inst is Node2D:
		(inst as Node2D).global_position = shoot_point.global_position

	# Aim at mouse by convention: if projectile has setup(dir, target_pos)
	var mouse_pos := get_viewport().get_mouse_position()
	var global_mouse := (shoot_point.get_viewport() as Viewport).get_camera_2d().get_global_mouse_position()

	var dir := (global_mouse - shoot_point.global_position).normalized()

	# Common setup hooks (choose what you implement per projectile)
	if inst.has_method("setup"):
		inst.call("setup", dir, global_mouse)
		

	# Add to scene
	get_tree().current_scene.add_child(inst)

	# Cooldown gate
	_can_shoot = false
	_cooldown_timer.start(cooldown)
	
	print("weapon:", current_weapon_id(), "has:", special_projectiles.has(current_weapon_id()))
	print("Projectile setup called")
