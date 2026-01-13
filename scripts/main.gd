extends CharacterBody2D
@export var normal_projectile_scene: PackedScene
@export var special_projectiles := {
	"pomegranate": preload("res://Pickups/pomegranate_pickup.tscn"),
	"orange": preload("res://Pickups/orange_pickup.tscn"),
	"banana": preload("res://Pickups/banana_pickup.tscn"),
	"coconut": preload("res://Pickups/coconut_pickup.tscn"),
}

@onready var muzzle: Marker2D = $Muzzle

@export var powerup_default_duration := 5.0
var _powerup_timer: Timer

# Two-slot fruit inventory:
# each slot is {"id": String, "time": float}
var fruit_slots: Array[Dictionary] = []
var active_slot: int = -1

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
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if direction < 0:
		facing_dir = Vector2.LEFT
	elif direction > 0:
		facing_dir = Vector2.RIGHT
		
	if Input.is_action_just_pressed("shoot"):
		shoot()
		
	if Input.is_action_just_pressed("switch_fruit"):
		switch_fruit()




func shoot() -> void:
	if not can_shoot:
		return

	can_shoot = false

	print("Shoot pressed")

	if active_slot != -1 and active_slot < fruit_slots.size():
		print("Using fruit:", fruit_slots[active_slot]["id"])
	else:
		print("Using normal ammo")

	if active_slot != -1 and active_slot < fruit_slots.size():
		var item_id: String = fruit_slots[active_slot]["id"]
		_fire_special(item_id)
	else:
		_fire_normal()

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func push_and_autoshoot(item_id: String) -> void:
	shot_stack.push_back(item_id)
	shoot()


func _fire_normal() -> void:
	if normal_projectile_scene == null:
		return

	var proj = normal_projectile_scene.instantiate()
	_spawn_projectile(proj, facing_dir)


func _fire_special(item_id: String) -> void:
	item_id = _normalize_item_id(item_id)

	if not special_projectiles.has(item_id):
		print("Special not found for:", item_id, " -> firing normal")
		_fire_normal()
		return

	print("Firing special:", item_id)
	var proj_scene: PackedScene = special_projectiles[item_id]
	var proj = proj_scene.instantiate()
	_spawn_projectile(proj, facing_dir)


func _spawn_projectile(proj: Node, dir: Vector2) -> void:
	get_tree().current_scene.add_child(proj)

	if proj is Node2D:
		proj.global_position = muzzle.global_position

	if proj.has_method("setup"):
		proj.call("setup", dir)
	elif proj.has_variable("direction"):
		proj.direction = dir
		
func push_powerup(item_id: String, duration: float = -1.0, auto_fire: bool = true) -> void:
	
	if duration < 0.0:
		duration = powerup_default_duration

	# normalize ids to match dictionary keys (see Fix 2)
	item_id = _normalize_item_id(item_id)

	# If the fruit already exists in a slot, refresh its time and make it active
	for i in range(fruit_slots.size()):
		if fruit_slots[i]["id"] == item_id:
			_save_active_remaining()
			fruit_slots[i]["time"] = duration
			active_slot = i
			_start_active_timer()
			if auto_fire:
				shoot()
			_debug_inventory("After pickup (refresh): " + item_id)
			return

	# Otherwise add
	if fruit_slots.size() < 2:
		_save_active_remaining()
		fruit_slots.append({"id": item_id, "time": duration})
		active_slot = fruit_slots.size() - 1
		_start_active_timer()
		if auto_fire:
			shoot()
		_debug_inventory("After pickup (add): " + item_id)
		return

	# Full: replace the inactive slot if possible
	var replace_index := 0
	if active_slot == 0:
		replace_index = 1
	elif active_slot == 1:
		replace_index = 0

	_save_active_remaining()
	fruit_slots[replace_index] = {"id": item_id, "time": duration}
	active_slot = replace_index
	_start_active_timer()
	if auto_fire:
		shoot()

	_debug_inventory("After pickup (replace): " + item_id)


func _on_powerup_timeout() -> void:
	print("Powerup expired on slot:", active_slot)

	if active_slot == -1:
		return

	fruit_slots.remove_at(active_slot)

	if fruit_slots.is_empty():
		active_slot = -1
		_debug_inventory("After timeout (empty)")
		return

	if active_slot >= fruit_slots.size():
		active_slot = 0

	_start_active_timer()
	_debug_inventory("After timeout (still has fruit)")


func switch_fruit() -> void:
	if fruit_slots.size() < 2:
		print("Switch ignored: only one or zero fruits")
		return

	_save_active_remaining()
	active_slot = (active_slot + 1) % fruit_slots.size()
	_start_active_timer()

	print("Switched fruit")
	_debug_inventory("After switch")


func _save_active_remaining() -> void:
	if active_slot == -1:
		return
	if _powerup_timer == null:
		return

	if not _powerup_timer.is_stopped() and active_slot < fruit_slots.size():
		fruit_slots[active_slot]["time"] = _powerup_timer.time_left

	_powerup_timer.stop()


func _start_active_timer() -> void:
	if _powerup_timer == null:
		return
	if active_slot == -1:
		return
	if active_slot >= fruit_slots.size():
		return

	var t: float = float(fruit_slots[active_slot]["time"])
	if t <= 0.0:
		t = powerup_default_duration

	_powerup_timer.wait_time = t
	_powerup_timer.start()

func _normalize_item_id(id: String) -> String:
	return id.strip_edges().to_lower()

func _debug_inventory(context: String = "") -> void:
	print("\n=== FRUIT DEBUG:", context, "===")

	if fruit_slots.is_empty():
		print("Slots: EMPTY")
	else:
		for i in range(fruit_slots.size()):
			var marker = " (ACTIVE)" if i == active_slot else ""
			print("Slot ", i, ": ", fruit_slots[i]["id"], 
				  " | time left: ", fruit_slots[i]["time"], marker)

	print("Active slot index:", active_slot)

	if _powerup_timer and not _powerup_timer.is_stopped():
		print("Timer running. Time left:", _powerup_timer.time_left)
	else:
		print("Timer stopped")

	print("============================\n")
