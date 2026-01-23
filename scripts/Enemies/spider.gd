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
@export var min_jump_delay := 0.6
@export var max_jump_delay := 1.8
@export var base_max_health := 10
@export var base_scale := 1.0
var current_health := base_max_health
var difficulty_applied := false

var dash_cooldown_left := 0.0
var is_retreating := false
var is_dashing := false
var dash_time_left := 0.0
var player: CharacterBody2D
var dir := Vector2.ZERO
var has_hit_player := false
var _jump_timer: Timer
var can_jump := true
var is_jumping := false
var current_target_in_range = null
var attack_target: Node2D

@onready var sprite := $AnimatedSprite2D

signal enemy_died
var is_dead := false

# =========================
# LINKED LIST: STATUS EFFECTS
# =========================
class EffectNode:
	var effect_type: String
	var duration: float
	var next: EffectNode = null

	func _init(t: String, d: float) -> void:
		effect_type = t
		duration = d

var effect_head: EffectNode = null

func add_or_refresh_effect(effect_type: String, duration: float) -> void:
	# If already present, refresh to max(current, new)
	var cur := effect_head
	while cur != null:
		if cur.effect_type == effect_type:
			cur.duration = max(cur.duration, duration)
			return
		cur = cur.next

	# Otherwise insert at head (O(1))
	var node := EffectNode.new(effect_type, duration)
	node.next = effect_head
	effect_head = node

func has_effect(effect_type: String) -> bool:
	var cur := effect_head
	while cur != null:
		if cur.effect_type == effect_type:
			return true
		cur = cur.next
	return false

func consume_effect(effect_type: String) -> bool:
	# Remove first matching node. Returns true if removed.
	var cur := effect_head
	var prev: EffectNode = null

	while cur != null:
		if cur.effect_type == effect_type:
			if prev == null:
				effect_head = cur.next
			else:
				prev.next = cur.next
			return true
		prev = cur
		cur = cur.next

	return false

func update_effects(delta: float) -> void:
	var cur := effect_head
	var prev: EffectNode = null

	while cur != null:
		cur.duration -= delta

		if cur.duration <= 0.0:
			# Remove expired node
			if prev == null:
				effect_head = cur.next
				cur = effect_head
			else:
				prev.next = cur.next
				cur = prev.next
		else:
			prev = cur
			cur = cur.next

func die():
	if is_dead:
		return

	is_dead = true
	emit_signal("enemy_died")
	queue_free()

func take_damage(amount: int) -> void:
	var dmg := amount

	# If vulnerable is active, double damage ONCE, then consume it
	if has_effect("vulnerable"):
		dmg *= 2
		consume_effect("vulnerable")

	current_health -= dmg

	# Flash red on hit
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	if current_health <= 0:
		die()

func _ready():
	current_health = max_health
	player = Global.playerbody
	add_to_group("Enemy")

	randomize()

	_jump_timer = Timer.new()
	_jump_timer.one_shot = true
	_jump_timer.timeout.connect(_on_jump_cooldown_finished)
	add_child(_jump_timer)

	_start_random_jump_cooldown()

func _start_random_jump_cooldown():
	can_jump = false
	_jump_timer.start(randf_range(min_jump_delay, max_jump_delay))

func _on_jump_cooldown_finished():
	can_jump = true

func _physics_process(delta):
	update_effects(delta)

	if player == null:
		player = Global.playerbody
		return
		
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta

	# 1. APPLY GRAVITY
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. STATE MACHINE (Only run one logic block per frame)
	if is_dashing:
		_dash_process(delta)
	elif is_retreating:
		# Retreat logic was missing movement code in your snippet, 
		# but velocity is set in end_dash, so we just slide.
		pass 
	else:
		# If not dashing or retreating, we are Chasing/Patrolling
		_chase_process(delta)
	
	# 3. MOVEMENT (Actually move the spider)
	move_and_slide()
	
	if is_jumping and is_on_floor():
		is_jumping = false
	
	_handle_animation()

	

# ---------------- CHASE ----------------
func _chase_process(_delta):
	var hitbox := player.get_node("Hitbox") as Area2D
	var target_pos := hitbox.global_position

	dir = (target_pos - global_position).normalized()
	velocity.x = dir.x * walk_speed
	
	if global_position.distance_to(target_pos) <= dash_distance and not is_dashing and dash_cooldown_left <= 0:  
			start_dash()

	_try_jump(target_pos)

	# Dash check
	if global_position.distance_to(target_pos) <= dash_distance and not is_dashing:
		start_dash()

func _try_jump(target_pos: Vector2):
	if not can_jump:
		return
	if not is_on_floor():
		return
	if is_dashing or is_retreating:
		return
	if target_pos.y >= global_position.y - 20:
		return

	# Random chance
	if randf() > 0.6:
		_start_random_jump_cooldown()
		return

	# JUMP
	velocity.y = jump_force
	is_jumping = true
	can_jump = false
	sprite.play("jump")

	_start_random_jump_cooldown()


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

	dash_cooldown_left = dash_cooldown 


# ---------------- DAMAGE ----------------
func _on_hitbox_body_entered(body):
	if body == player and not has_hit_player:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			has_hit_player = true
			
func apply_difficulty(wave: int, hp_multiplier: float) -> void:
	if difficulty_applied:
		return
	difficulty_applied = true

	# --- HP scaling ---
	max_health = int(base_max_health * hp_multiplier)
	current_health = max_health

	# --- Size scaling ---
	var size_bonus: float = min(wave * 0.03, 0.5)
	scale = Vector2.ONE * (base_scale + size_bonus)

	print(
		name,
		"| Wave:", wave,
		"| HP:", max_health,
		"| Scale:", scale
	)


# ---------------- ANIMATION ----------------
func _handle_animation():
	# Jump animation has highest priority
	if is_jumping:
		if sprite.animation != "jump":
			sprite.play("jadump")
		return

	# Dash animation
	if is_dashing:
		# Check if "dash" exists, otherwise fallback to "walk" or "run"
		if sprite.sprite_frames.has_animation("dash"):
			sprite.play("dash")
		else:
			sprite.play("walk")

	# Walk / Idle
	if abs(velocity.x) > 5:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

	# Flip sprite
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
