extends CharacterBody2D
# --- UPGRADE SYSTEM VARIABLES ---
var dash_unlocked: bool = false
var fire_rate_level: int = 0         # Each level reduces cooldown by 15%
var projectile_speed_level: int = 0  # Each level increases bullet speed by 20%
var movement_speed_level: int = 0    # Each level increases walk speed by 10%
var extra_spawn_chance: int = 0      # Used by FruitSpawner

# Dash variables
@export var dash_speed := 1000.0
@export var dash_duration := 0.2
var is_dashing := false
var can_dash := true
# --------------------------------
@export var normal_projectile_scene: PackedScene
@export var special_projectiles := {
	"Pomegranate": preload("res://scenes/Bullets/PomegranateBullet_Throw.tscn"),
	"Orange": preload("res://scenes/Bullets/OrangeBullet_Throw.tscn"),
	"Banana": preload("res://scenes/Bullets/BananaBullet_Throw.tscn"),
	"Coconut": preload("res://scenes/Bullets/CoconutBullet_Throw.tscn"),
	
}
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
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 1. Handle Dash Input
	if dash_unlocked and Input.is_action_just_pressed("dash") and can_dash:
		perform_dash()

	# 2. Movement Speed Upgrade
	var move_speed_mod = 1.0 + (movement_speed_level * 0.1)
	
	if not is_dashing: # Normal movement
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction := Input.get_axis("Left", "Right")
		if direction:
			velocity.x = direction * (SPEED * move_speed_mod)
			facing_dir = Vector2.LEFT if direction < 0 else Vector2.RIGHT
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else: # Dash movement
		velocity.x = facing_dir.x * dash_speed
		velocity.y = 0 # Hover during dash

	move_and_slide()
		
	if Input.is_action_just_pressed("shoot"):
		shoot()

func perform_dash():
	is_dashing = true
	can_dash = false
	# Add invulnerability here if you want: set_collision_layer_value(1, false)
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	# set_collision_layer_value(1, true)
	await get_tree().create_timer(1.0).timeout # Dash Cooldown
	can_dash = true

func shoot() -> void:
	if not can_shoot: return
	
	# 1. Fire Rate Upgrade (Reduces cooldown)
	var fire_rate_mod = 1.0 - (fire_rate_level * 0.15)
	var current_cooldown = shoot_cooldown * fire_rate_mod
	
	if shot_stack.size() > 0:
		match shot_stack[-1]:
			"Orange": current_cooldown = 0.06 * fire_rate_mod
			"Pomegranate": current_cooldown = 0.1 * fire_rate_mod
			"Coconut": current_cooldown = 0.4 * fire_rate_mod
			"Banana": current_cooldown = 1.2 * fire_rate_mod

	can_shoot = false
	
	if shot_stack.size() > 0:
		_fire_special(shot_stack[-1])
	else:
		_fire_normal()

	await get_tree().create_timer(current_cooldown).timeout
	can_shoot = true

func _spawn_projectile(proj: Node, dir: Vector2, skip_setup: bool = false) -> void:
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position

	# 2. Projectile Velocity Upgrade
	var proj_speed_mod = 1.0 + (projectile_speed_level * 0.2)
	if "speed" in proj:
		proj.speed *= proj_speed_mod

	if not skip_setup:
		if proj.has_method("setup"):
			proj.setup(dir)
		elif "direction" in proj:
			proj.direction = dir

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
	
	# Logic for Coconut Arc
	if item_id == "Coconut" and proj.has_method("setup"):
		# We pass a modified vector to create an upward toss
		var toss_dir = (facing_dir + Vector2.UP * 0.5).normalized()
		proj.setup(toss_dir)
		_spawn_projectile(proj, toss_dir, true) 
	else:
		_spawn_projectile(proj, facing_dir)
		
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
