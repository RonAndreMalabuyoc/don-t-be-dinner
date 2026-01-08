extends Node2D

@export var spider_scene: PackedScene
@export var moth_scene: PackedScene
@export var spawn_points: Array[Node2D]

var current_wave := 0
var enemies_alive := 0
var wave_in_progress := false

var waves = [
	{ "spider": 3, "moth": 2 },
	{ "spider": 5, "moth": 4 },
	{ "spider": 8, "moth": 6 },
	{ "spider": 12, "moth": 10 }
]

func _ready():
	start_next_wave()

func start_next_wave():
	if wave_in_progress:
		return

	if current_wave >= waves.size():
		print("ALL WAVES COMPLETE")
		return

	wave_in_progress = true
	current_wave += 1
	enemies_alive = 0

	print("Starting wave ", current_wave)

	var wave_data = waves[current_wave - 1]

	spawn_enemies(spider_scene, wave_data.get("spider", 0))
	spawn_enemies(moth_scene, wave_data.get("moth", 0))

func spawn_enemies(scene: PackedScene, amount: int):
	for i in range(amount):
		var spawn_point = spawn_points.pick_random()
		var enemy = scene.instantiate()
		enemy.global_position = spawn_point.global_position

		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

		add_child(enemy)
		enemies_alive += 1

	for i in range(amount):
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

	if enemies_alive == 0:
		wave_in_progress = false
		start_next_wave()
