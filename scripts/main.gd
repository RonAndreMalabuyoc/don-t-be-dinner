extends CharacterBody2D
@export var normal_projectile_scene: PackedScene
@export var special_projectiles: Dictionary

@onready var muzzle: Marker2D = $Muzzle

@export var powerup_default_duration := 5.0
var _powerup_timer: Timer

var shot_stack: Array[String] = []
var can_shoot := true
@export var shoot_cooldown := 0.15

var facing_dir := Vector2.RIGHT


const SPEED = 300.0
const JUMP_VELOCITY = -600.0

func _ready():
	Global.playerbody = self

	_powerup_timer = Timer.new()
	_powerup_timer.one_shot = true
	add_child(_powerup_timer)
	_powerup_timer.timeout.connect(_on_powerup_timeout)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if direction < 0:
		facing_dir = Vector2.LEFT
	elif direction > 0:
		facing_dir = Vector2.RIGHT
		
	if Input.is_action_just_pressed("shoot"):
		shoot()

func shoot() -> void:
	if not can_shoot:
		return
	print("SHOOT CALLED")

	can_shoot = false

	if shot_stack.size() > 0:
		var item_id: String = shot_stack[-1]
		_fire_special(item_id)
	else:
		_fire_normal()


	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func push_and_autoshoot(item_id: String) -> void:
	shot_stack.push_back(item_id)
	shoot()


func _fire_normal() -> void:
	if normal_projectile_scene == null:
		return

	var proj = normal_projectile_scene.instantiate()
	_spawn_projectile(proj, facing_dir)


func _fire_special(item_id: String) -> void:
	if not special_projectiles.has(item_id):
		_fire_normal()
		return

	var proj_scene: PackedScene = special_projectiles[item_id]
	var proj = proj_scene.instantiate()
	_spawn_projectile(proj, facing_dir)


func _spawn_projectile(proj: Node, dir: Vector2) -> void:
	get_tree().current_scene.add_child(proj)

	if proj is Node2D:
		proj.global_position = muzzle.global_position

	if proj.has_method("setup"):
		proj.call("setup", dir)
	elif proj.has_variable("direction"):
		proj.direction = dir
		
func push_powerup(item_id: String, duration: float = -1.0, auto_fire: bool = true) -> void:
	if duration < 0.0:
		duration = powerup_default_duration

	# Pause current top powerup by storing remaining time (stack-friendly behavior)
	if shot_stack.size() > 0 and not _powerup_timer.is_stopped():
		# Store remaining time alongside the id
		# Convert shot_stack items to dictionaries if you want true pausing.
		# For the simple version, we just let the new powerup override the old timer.
		_powerup_timer.stop()

	shot_stack.push_back(item_id)
	_powerup_timer.wait_time = duration
	_powerup_timer.start()

	if auto_fire:
		shoot()


func _on_powerup_timeout() -> void:
	if shot_stack.is_empty():
		return

	shot_stack.pop_back()

	# If you want stacked timers (pause/resume) later, we’ll enhance this part.
	# For now: when top expires, you revert to previous (which stays until replaced).
