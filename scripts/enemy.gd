extends CharacterBody2D
class_name Enemy

@export var max_health := 20
var current_health := 20

@export var hover_speed := 80.0
@export var dash_speed := 600.0        # faster dash
@export var dash_distance := 160.0
@export var dash_duration := 0.25
@export var dash_cooldown := 1.0       # short cooldown to allow continuous cycle
@export var damage_amount := 10
@export var retreat_time := 0.35

var dash_cooldown_left := 0.0
var is_retreating := false
var is_dashing := false
var dash_time_left := 0.0
var player: CharacterBody2D
var dir := Vector2.ZERO
var has_hit_player := false  # tracks if player was hit this dash

@onready var sprite := $AnimatedSprite2D

func take_damage(amount: int):
	current_health -= amount
	sprite.modulate = Color.RED  # Flash red on hit
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	if current_health <= 0:
		die()

func die():
	queue_free()

func _ready():
	current_health = max_health
	player = Global.playerbody
	add_to_group("Enemy")
	
func _physics_process(delta):
	if player == null:
		player = Global.playerbody
		return

	if is_dashing:
		_dash_process(delta)
	elif is_retreating:
		move_and_slide()
	else:
		_chase_process(delta)

	move_and_slide()
	_handle_animation()

# ---------------- CHASE ----------------
func _chase_process(_delta):
	var hitbox := player.get_node("Hitbox") as Area2D
	var target_pos := hitbox.global_position

	dir = (target_pos - global_position).normalized()
	velocity = dir * hover_speed

	# Automatically start dash if in range, ignoring cooldown
	if global_position.distance_to(target_pos) <= dash_distance:
		start_dash()

# ---------------- DASH ----------------
func start_dash():
	is_dashing = true
	dash_time_left = dash_duration
	has_hit_player = false

	var hitbox := player.get_node("Hitbox") as Area2D
	dir = (hitbox.global_position - global_position).normalized()
	velocity = dir * dash_speed

func _dash_process(delta):
	dash_time_left -= delta
	velocity = dir * dash_speed

	if dash_time_left <= 0:
		end_dash()

func end_dash():
	is_dashing = false
	is_retreating = true

	if player:
		# Retreat in opposite direction
		var retreat_dir = (global_position - player.global_position).normalized()
		velocity = retreat_dir * (hover_speed * 1.5)

		# Wait during retreat
		await get_tree().create_timer(retreat_time * 1.5).timeout

	is_retreating = false
	velocity = Vector2.ZERO
	# After retreat, immediately attack again if player is in range
	var hitbox := player.get_node("Hitbox") as Area2D
	if global_position.distance_to(hitbox.global_position) <= dash_distance:
		start_dash()

# ---------------- DAMAGE ----------------
func _on_hitbox_body_entered(body):
	if body == player and not has_hit_player:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			has_hit_player = true

# ---------------- ANIMATION ----------------
func _handle_animation():
	sprite.play("fly")
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
