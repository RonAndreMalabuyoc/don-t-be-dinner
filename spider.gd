extends CharacterBody2D
class_name LandEnemy

@export var walk_speed := 80.0
@export var dash_speed := 600.0
@export var dash_distance := 160.0
@export var dash_duration := 0.25
@export var dash_cooldown := 1.0
@export var damage_amount := 10
@export var retreat_time := 0.35
@export var gravity := 1200.0
@export var jump_force := -350.0
@export var jump_cooldown := 1.0
@export var max_health := 20

var current_health := 20
var dash_cooldown_left := 0.0
var is_retreating := false
var is_dashing := false
var dash_time_left := 0.0
var player: CharacterBody2D
var dir := Vector2.ZERO
var has_hit_player := false
var _jump_timer: Timer

@onready var sprite := $AnimatedSprite2D

signal enemy_died
var is_dead := false

func die():
	if is_dead:
		return

	is_dead = true
	emit_signal("enemy_died")
	queue_free()

func take_damage(amount: int) -> void:
	current_health -= amount

	# Flash red on hit (same idea as your bat)
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	if current_health <= 0:
		die()

func _ready():
	current_health = max_health
	player = Global.playerbody
	add_to_group("Enemy")
	_jump_timer = Timer.new()
	_jump_timer.one_shot = true
	add_child(_jump_timer)


func _physics_process(delta):
	if player == null:
		player = Global.playerbody
		return

	# APPLY GRAVITY
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dashing:
		_dash_process(delta)
	elif is_retreating:
		pass
	else:
		_chase_process(delta)

	move_and_slide()
	_handle_animation()



# ---------------- CHASE ----------------
func _chase_process(_delta):
	var hitbox := player.get_node("Hitbox") as Area2D
	var target_pos := hitbox.global_position

	dir = (target_pos - global_position).normalized()
	velocity.x = dir.x * walk_speed

	# Jump ONLY if:
	# - on floor
	# - not already jumping
	# - player is above
	if is_on_floor() \
	and _jump_timer.is_stopped() \
	and target_pos.y < global_position.y - 20 \
	and not is_dashing \
	and not is_retreating:
		velocity.y = jump_force
		_jump_timer.start(jump_cooldown)

	# Dash check
	if global_position.distance_to(target_pos) <= dash_distance and not is_dashing:
		start_dash()


# ---------------- DASH ----------------
func start_dash():
	is_dashing = true
	dash_time_left = dash_duration
	has_hit_player = false

	var hitbox := player.get_node("Hitbox") as Area2D
	dir = (hitbox.global_position - global_position).normalized()
	velocity.x = dir.x * dash_speed

func _dash_process(delta):
	dash_time_left -= delta
	velocity.x = dir.x * dash_speed

	# Damage player
	if not has_hit_player and global_position.distance_to(player.global_position) <= dash_distance:
		if player.has_method("take_damage"):
			player.take_damage(damage_amount)
			has_hit_player = true

	if dash_time_left <= 0:
		end_dash()

func end_dash():
	is_dashing = false
	is_retreating = true

	if player:
		var retreat_dir = (global_position - player.global_position).normalized()
		velocity.x = retreat_dir.x * walk_speed * 1.5

		await get_tree().create_timer(retreat_time * 1.5).timeout

	is_retreating = false
	velocity = Vector2.ZERO

	# Immediately attack again if player is in range
	if player and global_position.distance_to(player.global_position) <= dash_distance:
		start_dash()

# ---------------- DAMAGE ----------------
func _on_hitbox_body_entered(body):
	if body == player and not has_hit_player:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			has_hit_player = true

# ---------------- ANIMATION ----------------
func _handle_animation():
	sprite.play("walk")
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
