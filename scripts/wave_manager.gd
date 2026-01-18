extends Node2D

@export var spider_scene: PackedScene
@export var moth_scene: PackedScene
@export var wasp_scene: PackedScene
@export var wasp_spawn_points: Array[Node2D]
@export var spider_spawn_points: Array[Node2D]
@export var moth_spawn_points: Array[Node2D]
@export var spawn_delay: float = 1.0
@onready var spawn_timer := Timer.new()

@export var fruit_pickups: Array[PackedScene] = []
@export var fruit_spawn_points: Array[Node2D] = []

@export var min_spawn_per_wave: int = 1
@export var max_spawn_per_wave: int = 2
@export var max_fruits_alive: int = 3

signal wave_completed(wave_number: int)

var _alive_fruits: int = 0
var _last_wave: int = 0
var _wave_manager: Node = null
var wave_scale := 0
var current_wave := 0
var enemies_alive := 0
var wave_in_progress := false

var spawn_queue: Array = []

var waves = [
	 { "spider": 3 },
	{ "spider": 5 },
	{ "spider": 7 },

	# Phase 2 — Air melee only
	{ "moth": 3 },
	{ "moth": 5 },
	{ "moth": 7 },

	# Phase 3 — Land + Air melee
	{ "spider": 4, "moth": 3 },
	{ "spider": 6, "moth": 4 },
	{ "spider": 8, "moth": 5 },

	# Phase 4 — Wasp intro
	{ "wasp": 2 },
	{ "wasp": 4 },
	{ "wasp": 6 },

	# Phase 5 — Air combo
	{ "wasp": 3, "moth": 3 },
	{ "wasp": 5, "moth": 5 },
	{ "wasp": 7, "moth": 7 },

	# Phase 6 — Full mix
	{ "spider": 6, "moth": 4, "wasp": 3 },
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
	
	wave_scale = current_wave - waves.size() + 1

	waves.append({
	"spider": 5 + wave_scale,
	"moth": 4 + int(wave_scale * 0.8),
	"wasp": 3 + int(wave_scale * 0.6)
})

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
	
	for i in range(wave_data.get("wasp", 0)):
		spawn_queue.append(wasp_scene)

	for i in range(wave_data.get("spider", 0)):
		spawn_queue.append(spider_scene)

	for i in range(wave_data.get("moth", 0)):
		spawn_queue.append(moth_scene)

	spawn_timer.start()
	
func _on_wave_completed():
	print("Wave", current_wave, "completed!")

	# Add 1 skill point for finishing the wave
	SkillManager.add_skill_points(1)

	# Apply Post-Wave Heal if unlocked
	if SkillManager.post_wave_heal_active and Global.playerbody:
		Global.playerbody.current_health += 1  # heal 1 heart
		if Global.playerbody.current_health > Global.playerbody.max_health:
			Global.playerbody.current_health = Global.playerbody.max_health
		print("Post-Wave Heal applied! Current Health:", Global.playerbody.current_health)


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
	elif scene == wasp_scene:
		spawn_point = wasp_spawn_points.pick_random()
	
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
		
	if enemies_alive == 0 and spawn_queue.size() == 0:
		wave_in_progress = false
		emit_signal("wave_completed", current_wave)
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
