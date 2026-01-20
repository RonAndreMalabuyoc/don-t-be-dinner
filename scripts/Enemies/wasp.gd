extends CharacterBody2D
class_name WaspEnemy

# ---------------- EXPORTS ----------------
@export var max_health := 15
@export var hover_speed := 90.0
@export var strafe_speed := 70.0
@export var strafe_switch_time := 1.5

var strafe_dir := 1
var strafe_timer := 0.0

@export var shoot_range := 220.0
@export var too_close_range := 120.0

@export var shoot_cooldown := 1.2
@export var projectile_scene: PackedScene
@export var projectile_speed := 450.0
@export var damage_amount := 8
@onready var attack_timer: Timer = $AttackTimer # Create a Timer node in your enemy scene

# ---------------- VARIABLES ----------------
var current_health := 0
var is_dead := false
var shoot_timer := 0.0
var shootpoint_offset_x := 0.0
var attack_target: Node2D
var current_target_in_range = null
var player: CharacterBody2D
var player_hitbox: Area2D
# ---------------- ANIMATION ----------------
const SHOOT_FRAME := 2   # change if needed
var is_shooting := false
var shot_fired := false
var shoot_dir_cache := Vector2.ZERO

# ---------------- NODES ----------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var shoot_point: Node2D = $ShootPoint

# ---------------- SIGNALS ----------------
signal enemy_died

# ---------------- READY ----------------
func _ready():
	current_health = max_health
	player = Global.playerbody
	strafe_timer = strafe_switch_time
	if player:
		player_hitbox = player.get_node("Hitbox") as Area2D
		
	shootpoint_offset_x = shoot_point.position.x
	
	add_to_group("Enemy")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	sprite.frame_changed.connect(_on_sprite_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)

# ---------------- PHYSICS PROCESS ----------------
func _process_movement() -> void:
	if not player_hitbox:
		return

	var target_pos := player_hitbox.global_position
	var to_player := target_pos - global_position
	var distance := to_player.length()
	var dir := to_player.normalized()

	# Too far → chase
	if distance > shoot_range:
		velocity = dir * hover_speed
		return

	# Too close → back away
	if distance < too_close_range:
		velocity = -dir * hover_speed
		return

	# ---------------- STRAFING ZONE ----------------
	var strafe_vec := Vector2(-dir.y, dir.x) * strafe_dir
	velocity = strafe_vec * strafe_speed

	# Switch strafe direction
	strafe_timer -= get_physics_process_delta_time()
	if strafe_timer <= 0:
		strafe_dir *= -1
		strafe_timer = strafe_switch_time

	# Shooting while strafing
	if shoot_timer <= 0:
		shoot(dir)


	# ---------------- STRAFING ZONE ----------------
func _physics_process(delta: float) -> void:
	if not player:
		player = Global.playerbody
		if player:
			player_hitbox = player.get_node("Hitbox") as Area2D
		return

	if shoot_timer > 0:
		shoot_timer -= delta
		
	var plant = get_tree().get_first_node_in_group("POI")
	var move_target = plant if is_instance_valid(plant) else player
	
	if is_instance_valid(move_target):
		var dist = global_position.distance_to(move_target.global_position)
		
		# 2. Distance Check: Stop 55 pixels away so you don't jitter against the plant
		if dist > 55.0:
			var direction = (move_target.global_position - global_position).normalized()
			velocity.x = direction.x * 150.0
		else:
			# Stop moving and let the AttackTimer do the work
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()
		
	

	# Move toward attack_target.position...

	_process_movement()
	move_and_slide()
	_handle_animation()

# ---------------- SHOOTING ----------------
func shoot(direction: Vector2) -> void:
	if is_shooting:
		return

	is_shooting = true
	shot_fired = false
	shoot_timer = shoot_cooldown

	sprite.play("shoot")

	# Store direction for frame callback
	shoot_dir_cache = direction
	
func _on_sprite_frame_changed() -> void:
	if sprite.animation != "shoot":
		return

	if sprite.frame == SHOOT_FRAME and not shot_fired:
		shot_fired = true
		_fire_projectile()

func _fire_projectile():
	if not projectile_scene:
		return

	var bullet = projectile_scene.instantiate()
	get_parent().add_child(bullet)

	bullet.global_position = shoot_point.global_position

	if bullet.has_method("setup"):
		bullet.setup(shoot_dir_cache, projectile_speed, damage_amount)
	else:
		bullet.velocity = shoot_dir_cache * projectile_speed


# ---------------- ANIMATION ----------------
func _handle_animation() -> void:
	if is_shooting:
		return

	sprite.play("fly")

	if player and player.global_position.x < global_position.x:
		sprite.flip_h = true
		shoot_point.position.x = -shootpoint_offset_x
	else:
		sprite.flip_h = false
		shoot_point.position.x = shootpoint_offset_x

func _on_animation_finished():
	if sprite.animation == "shoot":
		is_shooting = false
		sprite.play("fly")

# ---------------- HITBOX DAMAGE ----------------
func _on_hitbox_body_entered(body):
	# 1. Check if it's the player
	if body.has_method("take_damage"):
		body.take_damage(damage_amount)
		print("Attacked: ", body.name)
		current_target_in_range = body
		attack_timer.start() # Set this timer to Wait Time: 1.0 and Autostart: Off

func _on_hitbox_body_exited(body):
	if body == current_target_in_range:
		current_target_in_range = null
		attack_timer.stop()

func _on_attack_timer_timeout():
	if is_instance_valid(current_target_in_range):
		current_target_in_range.take_damage(damage_amount)
	else:
		attack_timer.stop()

# ---------------- DAMAGE ----------------
func take_damage(amount: int) -> void:
	current_health -= amount
	sprite.modulate = Color.RED

	if player:
		velocity = (global_position - player.global_position).normalized() * 180

	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	if current_health <= 0:
		die()

# ---------------- DEATH ----------------
func die() -> void:
	if is_dead:
		return
	is_dead = true
	emit_signal("enemy_died")
	queue_free()
