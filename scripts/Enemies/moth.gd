extends CharacterBody2D
class_name Enemy

# ---------------- EXPORTS ----------------
@export var max_health := 20
@export var hover_speed := 80.0
@export var dash_speed := 600.0
@export var dash_distance := 160.0
@export var dash_duration := 0.25
@export var dash_cooldown := 1.0
@export var damage_amount := 10
@export var retreat_time := 0.35

# ---------------- VARIABLES ----------------
var current_health := 20
var is_dead := false
var is_dashing := false
var is_retreating := false
var dash_time_left := 0.0
var dir := Vector2.ZERO
var has_hit_player := false
var dash_cooldown_timer := 0.0
var attack_target: Node2D

var player: CharacterBody2D
var player_hitbox: Area2D

# ---------------- NODES ----------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var timer: Timer = $Timer   # Optional, can be used for timed events

# ---------------- SIGNALS ----------------
signal enemy_died

# ---------------- READY ----------------
func _ready():
	current_health = max_health
	player = Global.playerbody
	if player:
		player_hitbox = player.get_node("Hitbox") as Area2D

	add_to_group("Enemy")

	# Connect hitbox to detect player attacks
	hitbox.body_entered.connect(_on_hitbox_body_entered)

# ---------------- PHYSICS PROCESS ----------------
func _physics_process(_delta: float) -> void:
	if not player:
		player = Global.playerbody
		if player:
			player_hitbox = player.get_node("Hitbox") as Area2D
		return

	var plant = get_tree().get_first_node_in_group("POI")
	var move_target = plant if is_instance_valid(plant) else Global.playerbody
	
	if is_instance_valid(move_target):
		var dist = global_position.distance_to(move_target.global_position)
		
		# INCREASE THIS NUMBER until they stop jittering. 
		# If your plant is wide, you might need 70.0 or 80.0
		if dist > 65.0: 
			var direction = (move_target.global_position - global_position).normalized()
			velocity.x = direction.x * 150.0
		else:
			velocity.x = 0 # They stop here and let the AttackTimer do the work
	else:
		velocity.x = 0

	move_and_slide()
	_handle_animation()

	# Check collision with player during dash
	if is_dashing and player and not has_hit_player:
		if global_position.distance_to(player.global_position) <= 16:
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
				has_hit_player = true

# ---------------- CHASE LOGIC ----------------
func _chase_process(_delta: float) -> void:
	if not player_hitbox:
		return
	var target_pos := player_hitbox.global_position
	dir = (target_pos - global_position).normalized()
	velocity = dir * hover_speed

	# Only dash if close enough and cooldown finished
	if global_position.distance_to(target_pos) <= dash_distance and dash_cooldown_timer <= 0:
		start_dash()

# ---------------- DASH LOGIC ----------------
func start_dash() -> void:
	if not player_hitbox or dash_cooldown_timer > 0:
		return

	is_dashing = true
	dash_time_left = dash_duration
	has_hit_player = false
	dash_cooldown_timer = dash_cooldown
	dir = (player_hitbox.global_position - global_position).normalized()
	velocity = dir * dash_speed

func _dash_process(delta: float) -> void:
	dash_time_left -= delta
	velocity = dir * dash_speed

	if dash_time_left <= 0:
		end_dash()

func end_dash() -> void:
	is_dashing = false
	is_retreating = true

	if player:
		var retreat_dir = (global_position - player.global_position).normalized()
		velocity = retreat_dir * hover_speed * 1.5

		# Wait for retreat_time seconds
		await get_tree().create_timer(retreat_time).timeout

	is_retreating = false
	velocity = Vector2.ZERO

# ---------------- ANIMATION ----------------
func _handle_animation() -> void:
	sprite.play("fly")
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

# ---------------- HITBOX DAMAGE ----------------
func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_amount)
		print("Attacked: ", body.name)
		
# ---------------- DAMAGE ----------------
func take_damage(amount: int) -> void:
	current_health -= amount
	sprite.modulate = Color.RED

	# Knockback from player
	if player:
		velocity = (global_position - player.global_position).normalized() * 200

	# Flash red briefly
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
