extends Node2D

@export var fruit_pickups : Array[PackedScene] = [
	preload("res://scenes/Pickups/pomegranate_pickup.tscn"),
	preload("res://scenes/Pickups/orange_pickup.tscn"),
	preload("res://scenes/Pickups/banana_pickup.tscn"),
	preload("res://scenes/Pickups/coconut_pickup.tscn"),
]
@export var spawn_points: Array[Node2D] = []

@export var min_spawn_per_wave: int = 1
@export var max_spawn_per_wave: int = 2
@export var max_fruits_alive: int = 3

var _alive_fruits: int = 0
var _wave_manager: Node = null
var _last_wave: int = 0


func _ready() -> void:
	_wave_manager = get_tree().get_first_node_in_group("WaveManager")
	spawn_points.clear()

	var holder := $FruitSpawnPoints
	for c in holder.get_children():
		if c is Node2D:
			spawn_points.append(c)

	print("FruitSpawner points found:", spawn_points.size())


func spawn_for_wave(_wave_index: int) -> void:
	if fruit_pickups.is_empty() or spawn_points.is_empty():
		return

	if _alive_fruits >= max_fruits_alive:
		return

	# SAFE CHECK: Look for the upgrade bonus
	var bonus: int = 0
	if Global.playerbody and "extra_spawn_chance" in Global.playerbody:
		bonus = Global.playerbody.extra_spawn_chance

	# Apply the bonus to the spawn count
	var count: int = randi_range(min_spawn_per_wave, max_spawn_per_wave) + bonus
	var capacity: int = max_fruits_alive - _alive_fruits
	count = min(count, capacity)

	for i in range(count):
		_spawn_one()
	
	print("spawn_for_wave:", _wave_index,
	" fruit_pickups=", fruit_pickups.size(),
	" spawn_points=", spawn_points.size(),
	" alive=", _alive_fruits)

func _spawn_one() -> void:
	var scene: PackedScene = fruit_pickups.pick_random() as PackedScene
	if scene == null:
		return

	var point: Node2D = spawn_points.pick_random() as Node2D
	if point == null:
		return

	# instantiate() returns Node, so we cast it to Node2D
	var inst: Node2D = scene.instantiate() as Node2D
	if inst == null:
		return

	get_tree().current_scene.add_child(inst)
	inst.global_position = point.global_position

	_alive_fruits += 1

	inst.tree_exited.connect(func() -> void:
		_alive_fruits = max(0, _alive_fruits - 1)
	)
	
func _process(_delta: float) -> void:
	if _wave_manager == null:
		return

	var w := int(_wave_manager.get("current_wave"))
	if w != _last_wave:
		_last_wave = w
		spawn_for_wave(w)
