extends CharacterBody2D
class_name Enemy

# ---------------- EXPORTS ----------------
@export var hover_speed := 80.0
@export var dash_speed := 600.0
@export var dash_distance := 160.0
@export var dash_duration := 0.25
@export var dash_cooldown := 1.0
@export var damage_amount := 10
@export var retreat_time := 0.35
@export var base_max_health := 30
@export var base_scale := 1.0
@export var hp_factor := 0.6
var max_health := base_max_health
var current_health := base_max_health
var difficulty_applied := false

# ---------------- VARIABLES ----------------
var is_dead := false
var is_dashing := false
var is_retreating := false
var dash_time_left := 0.0
var dir := Vector2.ZERO
var has_hit_player := false
var dash_cooldown_timer := 0.0
const ANIM_FLY := "fly"
const ANIM_ATTACK := "attack"
var player: CharacterBody2D
var player_hitbox: Area2D
var anim_locked := false

# ---------------- NODES ----------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var timer: Timer = $Timer   # Optional, can be used for timed events

# ---------------- SIGNALS ----------------
signal enemy_died

# ---------------- READY ----------------
func _ready():
	sprite.frame_changed.connect(_on_frame_changed)
	current_health = max_health
	player = Global.playerbody
	if player:
		player_hitbox = player.get_node("Hitbox") as Area2D

	add_to_group("Enemy")

	# Connect hitbox to detect player attacks
	hitbox.body_entered.connect(_on_hitbox_body_entered)

# ---------------- PHYSICS PROCESS ----------------
func _physics_process(delta: float) -> void:
	if not player:
		player = Global.playerbody
		if player:
			player_hitbox = player.get_node("Hitbox") as Area2D
		return

	# Reduce dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Movement logic
	if is_dashing:
		_dash_process(delta)
	elif not is_retreating:
		_chase_process(delta)

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
	anim_locked = true 
	dash_time_left = dash_duration
	has_hit_player = false
	dash_cooldown_timer = dash_cooldown

	dir = (player_hitbox.global_position - global_position).normalized()
	velocity = dir * dash_speed

	sprite.stop()
	sprite.play(ANIM_ATTACK)

func _dash_process(delta: float) -> void:
	dash_time_left -= delta
	velocity = dir * dash_speed

	if dash_time_left <= 0:
		end_dash()

func end_dash() -> void:
	is_dashing = false
	anim_locked = false
	is_retreating = true

	if player:
		var retreat_dir = (global_position - player.global_position).normalized()
		velocity = retreat_dir * hover_speed * 1.5

	await get_tree().create_timer(retreat_time).timeout
	is_retreating = false
	velocity = Vector2.ZERO

func apply_difficulty(wave: int, hp_multiplier: float) -> void:
	if difficulty_applied:
		return
	difficulty_applied = true

	var effective_multiplier: float = hp_multiplier * hp_factor

	max_health = int(base_max_health * effective_multiplier)
	current_health = max_health

	var effective_wave: int = max(wave - 2, 0)
	var size_bonus: float = min(effective_wave * 0.02, 0.35)
	scale = Vector2.ONE * (base_scale + size_bonus)

	print(
		"MOTH | Wave:", wave,
		"| HP:", max_health,
		"| Mult:", effective_multiplier
	)

# ---------------- ANIMATION ----------------
func _handle_animation() -> void:
	if is_dead:
		return

	# HARD animation lock
	if anim_locked:
		return

	if is_dashing:
		sprite.play(ANIM_ATTACK)
	else:
		sprite.play(ANIM_FLY)

	# Flip sprite
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false


func _on_frame_changed():
	if sprite.animation == ANIM_ATTACK and sprite.frame == 3:
		if player and not has_hit_player:
			if global_position.distance_to(player.global_position) <= 20:
				player.take_damage(damage_amount)
				has_hit_player = true

# ---------------- HITBOX DAMAGE ----------------
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("PlayerAttack") and body.has_method("get_damage"):
		take_damage(body.get_damage())

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
