extends Node2D

@export var fruit_pickups: Array[PackedScene] = [
	preload("res://scenes/Pickups/pomegranate_pickup.tscn"),
	preload("res://scenes/Pickups/orange_pickup.tscn"),
	preload("res://scenes/Pickups/banana_pickup.tscn"),
	preload("res://scenes/Pickups/coconut_pickup.tscn"),
]

@export var min_spawn_per_wave: int = 1
@export var max_spawn_per_wave: int = 2
@export var max_fruits_alive: int = 3

# Drop behavior (spawn above player then fall)
@export var drop_height: float = 500.0
@export var drop_time: float = 1.75
@export var drop_target_offset: Vector2 = Vector2(0, -20)

var _alive_fruits: int = 0
var _wave_manager: Node = null


func _ready() -> void:
	# Only listen for wave_completed. No spawn points. No spawning in _process.
	_wave_manager = get_tree().get_first_node_in_group("WaveManager")
	if _wave_manager and _wave_manager.has_signal("wave_completed"):
		_wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
	else:
		push_warning("FruitSpawner: WaveManager not found (group 'WaveManager') or missing wave_completed signal.")


func _on_wave_completed(wave_number: int) -> void:
	_spawn_for_wave(wave_number)



func _spawn_for_wave(wave_number: int) -> void:
	if fruit_pickups.is_empty():
		return
	if Global.playerbody == null:
		return
	if _alive_fruits >= max_fruits_alive:
		return

	# First 5 waves: 1 fruit. Wave 6+: 2 fruits.
	var base_count := 1 if wave_number <= 5 else 2

	# Keep your upgrade bonus if you want it
	var bonus: int = 0
	if "extra_spawn_chance" in Global.playerbody:
		bonus = Global.playerbody.extra_spawn_chance

	var count := base_count + bonus
	count = min(count, max_fruits_alive - _alive_fruits)

	for i in range(count):
		_spawn_one_on_player()


func _spawn_one_on_player() -> void:
	var scene: PackedScene = fruit_pickups.pick_random() as PackedScene
	if scene == null:
		return
	if Global.playerbody == null:
		return

	var inst: Node2D = scene.instantiate() as Node2D
	if inst == null:
		return

	get_tree().current_scene.add_child(inst)

	var target_pos: Vector2 = Global.playerbody.global_position + drop_target_offset
	var start_pos: Vector2 = target_pos + Vector2(0, -absf(drop_height))
	inst.global_position = start_pos

	var tw := create_tween()
	tw.tween_property(inst, "global_position", target_pos, drop_time)
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN)

	_alive_fruits += 1
	inst.tree_exited.connect(func() -> void:
		_alive_fruits = max(0, _alive_fruits - 1)
	)
