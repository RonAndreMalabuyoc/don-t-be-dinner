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

# --- FRUIT SLOTS ---
# current_fruit = the one you will consume with right click
# reserve_fruit = stored until you consume or swap
var current_fruit: String = ""
var reserve_fruit: String = ""

var can_shoot := true
@export var shoot_cooldown := 0.15

var facing_dir := Vector2.RIGHT

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

func _ready() -> void:
	print("PLAYER SCRIPT RUNNING:", get_path(), " script=", get_script())
	Global.playerbody = self

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

	# Left click: normal bread shots (your existing "shoot" action)
	if Input.is_action_just_pressed("shoot"):
		shoot_normal()

	# Right click: consume current fruit (if any)
	if Input.is_action_just_pressed("fruit_shoot"):
		shoot_fruit()

	# Q: swap current and reserve
	if Input.is_action_just_pressed("swap_fruit"):
		swap_fruit_slots()

func perform_dash() -> void:
	is_dashing = true
	can_dash = false
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	await get_tree().create_timer(1.0).timeout # Dash Cooldown
	can_dash = true

# ---------------- SHOOTING ----------------
func _get_cooldown_for(item_id: String) -> float:
	# Fire Rate Upgrade (reduces cooldown)
	var fire_rate_mod := 1.0 - (fire_rate_level * 0.15)

	if item_id == "":
		return shoot_cooldown * fire_rate_mod

	match item_id:
		"Orange": return 0.06 * fire_rate_mod
		"Pomegranate": return 0.1 * fire_rate_mod
		"Coconut": return 0.4 * fire_rate_mod
		"Banana": return 1.2 * fire_rate_mod
		_: return shoot_cooldown * fire_rate_mod

func shoot_normal() -> void:
	if not can_shoot:
		return

	can_shoot = false
	_fire_normal()

	await get_tree().create_timer(_get_cooldown_for(""))
	can_shoot = true

func shoot_fruit() -> void:
	if not can_shoot:
		return
	if current_fruit == "":
		return

	var item := current_fruit
	can_shoot = false
	_fire_special(item)

	# Consume current fruit
	current_fruit = ""

	# Auto-load reserve into current
	if reserve_fruit != "":
		current_fruit = reserve_fruit
		reserve_fruit = ""

	await get_tree().create_timer(_get_cooldown_for(item))
	can_shoot = truefunc shoot_fruit() -> void:
	if not can_shoot:
		print("Tried to shoot but still on cooldown")
		return

	if current_fruit == "":
		print("Right click pressed but no fruit in current slot")
		return

	var item := current_fruit
	print("Shooting fruit:", item)

	can_shoot = false
	_fire_special(item)

	current_fruit = ""
	print("Consumed fruit:", item)

	if reserve_fruit != "":
		current_fruit = reserve_fruit
		reserve_fruit = ""
		print("Reserve moved to current:", current_fruit)

	_debug_slots("After Shoot")

	await get_tree().create_timer(_get_cooldown_for(item))
	can_shoot = true
	print("Shoot cooldown finished")


func _spawn_projectile(proj: Node, dir: Vector2, skip_setup: bool = false) -> void:
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position

	# Projectile Velocity Upgrade
	var proj_speed_mod = 1.0 + (projectile_speed_level * 0.2)
	if "speed" in proj:
		proj.speed *= proj_speed_mod

	if not skip_setup:
		if proj.has_method("setup"):
			proj.setup(dir)
		elif "direction" in proj:
			proj.direction = dir

func _fire_normal() -> void:
	if normal_projectile_scene == null:
		return
	var proj = normal_projectile_scene.instantiate()
	_spawn_projectile(proj, facing_dir)

func _fire_special(item_id: String) -> void:
	if not special_projectiles.has(item_id):
		return

	var proj_scene: PackedScene = special_projectiles[item_id]
	var proj = proj_scene.instantiate()

	# Coconut arc
	if item_id == "Coconut" and proj.has_method("setup"):
		var toss_dir = (facing_dir + Vector2.UP * 0.5).normalized()
		proj.setup(toss_dir)
		_spawn_projectile(proj, toss_dir, true)
	else:
		_spawn_projectile(proj, facing_dir)

# ---------------- FRUIT PICKUP API ----------------
# Called by pick_up.gd
# Rules:
# - if current slot empty -> fill current
# - else if reserve empty -> fill reserve
# - else replace reserve (simple, predictable)
func push_powerup(item_id: String, duration: float = -1.0, auto_fire: bool = true) -> void:
	if item_id == "":
		return

	print("Picked up:", item_id)

	if current_fruit == "":
		current_fruit = item_id
		_debug_slots("Pickup -> Filled Current")
	elif reserve_fruit == "":
		reserve_fruit = item_id
		_debug_slots("Pickup -> Filled Reserve")
	else:
		reserve_fruit = item_id
		_debug_slots("Pickup -> Replaced Reserve")

	if auto_fire:
		print("Auto firing:", current_fruit)
		shoot_fruit()


func swap_fruit_slots() -> void:
	print("Swap key pressed")

	if current_fruit == "" and reserve_fruit != "":
		current_fruit = reserve_fruit
		reserve_fruit = ""
		_debug_slots("Swap -> Reserve moved to Current")
		return

	if reserve_fruit == "" and current_fruit != "":
		reserve_fruit = current_fruit
		current_fruit = ""
		_debug_slots("Swap -> Current moved to Reserve")
		return

	var tmp := current_fruit
	current_fruit = reserve_fruit
	reserve_fruit = tmp

	_debug_slots("Swap -> Swapped Normally")

func _debug_slots(context: String) -> void:
	print("[" + context + "] Current:", current_fruit, " | Reserve:", reserve_fruit)
