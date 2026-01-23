extends CharacterBody2D
class_name WaspEnemy

# ---------------- EXPORTS ----------------
@export var max_health := 15
@export var hover_speed := 90.0
@export var strafe_speed := 70.0
@export var strafe_switch_time := 1.5
@export var base_max_health := 10
@export var base_scale := 1.0

var current_health := base_max_health
var difficulty_applied := false

var strafe_dir := 1
var strafe_timer := 0.0

@export var shoot_range := 220.0
@export var too_close_range := 120.0

@export var shoot_cooldown := 1.2
@export var projectile_scene: PackedScene
@export var projectile_speed := 450.0
@export var damage_amount := 10
@onready var attack_timer: Timer = $AttackTimer # Create a Timer node in your enemy scene

# ---------------- VARIABLES ----------------
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
	update_effects(delta)

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
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("PlayerAttack") and body.has_method("get_damage"):
		take_damage(body.get_damage())
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

# ---------------- DAMAGE ----------------
func take_damage(amount: int) -> void:
	var dmg := amount

	if has_effect("vulnerable"):
		dmg *= 2
		consume_effect("vulnerable")

	current_health -= dmg
	sprite.modulate = Color.RED

	if player:
		velocity = (global_position - player.global_position).normalized() * 180

	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	if current_health <= 0:
		die()

# ---------------- DEATH ----------------
func die() -> void:
	Global.enemies_defeated += 1
	if is_dead:
		return
	is_dead = true
	emit_signal("enemy_died")
	queue_free()
