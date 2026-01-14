extends Node2D

@export var spider_scene: PackedScene
@export var moth_scene: PackedScene
@export var spider_spawn_points: Array[Node2D]
@export var moth_spawn_points: Array[Node2D]
@export var spawn_delay: float = 1.0
@onready var spawn_timer := Timer.new()

@export var fruit_pickups: Array[PackedScene] = []
@export var fruit_spawn_points: Array[Node2D] = []

@export var min_spawn_per_wave: int = 1
@export var max_spawn_per_wave: int = 2
@export var max_fruits_alive: int = 3

var _alive_fruits: int = 0
var _last_wave: int = 0
var _wave_manager: Node = null

var current_wave := 0
var enemies_alive := 0
var wave_in_progress := false

var spawn_queue: Array = []

var waves = [
	{ "spider": 3, "moth": 2 },
	{ "spider": 5, "moth": 4 },
	{ "spider": 8, "moth": 6 },
	{ "spider": 12, "moth": 10 }
]

func _ready():
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_delay
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	start_next_wave()

	_wave_manager = get_tree().get_first_node_in_group("WaveManager")
	if _wave_manager == null:
		push_warning("FruitSpawner: WaveManager not found. Add WaveManager node to group 'WaveManager'.")
		
func start_next_wave():
	if wave_in_progress:
		return

	if current_wave >= waves.size():
		print("ALL WAVES COMPLETE")
		return

	current_wave += 1
	wave_in_progress = true
	enemies_alive = 0
	spawn_queue.clear()

	print("Starting wave", current_wave)

	var wave_data = waves[current_wave - 1]

	for i in range(wave_data.get("spider", 0)):
		spawn_queue.append(spider_scene)

	for i in range(wave_data.get("moth", 0)):
		spawn_queue.append(moth_scene)

	spawn_timer.start()

func _on_spawn_timer_timeout():
	if spawn_queue.is_empty():
		spawn_timer.stop()
		return

	var scene: PackedScene = spawn_queue.pop_front()
	var enemy: Node2D = scene.instantiate()

	var spawn_point: Node2D = null

	if scene == spider_scene:
		spawn_point = spider_spawn_points.pick_random()
	elif scene == moth_scene:
		spawn_point = moth_spawn_points.pick_random()

	if spawn_point == null:
		push_warning("No spawn point assigned for this enemy type!")
		return

	enemy.global_position = spawn_point.global_position
	enemy.enemy_died.connect(_on_enemy_died)

	add_child(enemy)
	enemies_alive += 1

func _on_enemy_died():
	if enemies_alive <= 0:
		return

	enemies_alive -= 1
	print("Enemy died. Remaining:", enemies_alive)

	if enemies_alive == 0 and spawn_queue.size() == 0:  # <- fixed here
		wave_in_progress = false
		start_next_wave()
		
func _process(_delta: float) -> void:
	if _wave_manager == null:
		return

	# Watch the WaveManager's current_wave
	var w := int(_wave_manager.get("current_wave"))
	if w != _last_wave:
		_last_wave = w
		spawn_for_wave(w)


func spawn_for_wave(_wave_index: int) -> void:
	if fruit_pickups.is_empty() or fruit_spawn_points.is_empty():
		return

	if _alive_fruits >= max_fruits_alive:
		return

	var count: int = randi_range(min_spawn_per_wave, max_spawn_per_wave)
	var capacity: int = max_fruits_alive - _alive_fruits
	count = min(count, capacity)

	for i in range(count):
		_spawn_one()


func _spawn_one() -> void:
	var scene: PackedScene = fruit_pickups.pick_random() as PackedScene
	if scene == null:
		return

	var point: Node2D = fruit_spawn_points.pick_random() as Node2D
	if point == null:
		return

	var inst: Node2D = scene.instantiate() as Node2D
	if inst == null:
		return

	get_tree().current_scene.add_child(inst)
	inst.global_position = point.global_position

	_alive_fruits += 1
	inst.tree_exited.connect(func() -> void:
		_alive_fruits = max(0, _alive_fruits - 1)
	)
