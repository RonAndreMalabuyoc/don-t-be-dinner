extends Node2D

@export var spider_scene: PackedScene
@export var moth_scene: PackedScene
@export var spawn_points: Array[Node2D]
@export var spawn_delay: float = 1.0
@onready var spawn_timer := Timer.new()

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
	if spawn_queue.size() == 0:  # <- fixed here
		spawn_timer.stop()
		return

	var scene = spawn_queue.pop_front()
	var spawn_point = spawn_points.pick_random()
	var enemy = scene.instantiate()
	enemy.global_position = spawn_point.global_position
	enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

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
