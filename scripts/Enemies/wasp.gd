extends CharacterBody2D
class_name WaspEnemy

# ---------------- EXPORTS ----------------
@export var max_health := 15
@export var hover_speed := 90.0

@export var shoot_range := 220.0
@export var too_close_range := 120.0

@export var shoot_cooldown := 1.2
@export var projectile_scene: PackedScene
@export var projectile_speed := 450.0
@export var damage_amount := 8

# ---------------- VARIABLES ----------------
var current_health := 0
var is_dead := false
var shoot_timer := 0.0
var shootpoint_offset_x := 0.0

var player: CharacterBody2D
var player_hitbox: Area2D

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
	if player:
		player_hitbox = player.get_node("Hitbox") as Area2D
		
	shootpoint_offset_x = shoot_point.position.x
	
	add_to_group("Enemy")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

# ---------------- PHYSICS PROCESS ----------------
func _physics_process(delta: float) -> void:
	if not player:
		player = Global.playerbody
		if player:
			player_hitbox = player.get_node("Hitbox") as Area2D
		return

	if shoot_timer > 0:
		shoot_timer -= delta

	_process_movement()
	move_and_slide()
	_handle_animation()

# ---------------- MOVEMENT & SHOOT LOGIC ----------------
func _process_movement() -> void:
	if not player_hitbox:
		return

	var target_pos := player_hitbox.global_position
	var distance := global_position.distance_to(target_pos)
	var dir := (target_pos - global_position).normalized()

	# Too far → chase
	if distance > shoot_range:
		velocity = dir * hover_speed

	# Too close → back away
	elif distance < too_close_range:
		velocity = -dir * hover_speed

	# In shooting zone → stop & shoot
	else:
		velocity = Vector2.ZERO
		if shoot_timer <= 0:
			shoot(dir)

# ---------------- SHOOTING ----------------
func shoot(direction: Vector2) -> void:
	shoot_timer = shoot_cooldown

	if not projectile_scene:
		return

	var bullet = projectile_scene.instantiate()
	get_parent().add_child(bullet)

	bullet.global_position = shoot_point.global_position

	if bullet.has_method("setup"):
		bullet.setup(direction, projectile_speed, damage_amount)
	else:
		bullet.velocity = direction * projectile_speed

# ---------------- ANIMATION ----------------
func _handle_animation() -> void:
	sprite.play("fly")

	if player and player.global_position.x < global_position.x:
		sprite.flip_h = true
		shoot_point.position.x = -shootpoint_offset_x
	else:
		sprite.flip_h = false
		shoot_point.position.x = shootpoint_offset_x

# ---------------- HITBOX DAMAGE ----------------
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("PlayerAttack") and body.has_method("get_damage"):
		take_damage(body.get_damage())

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
