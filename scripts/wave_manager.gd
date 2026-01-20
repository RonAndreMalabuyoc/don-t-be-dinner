extends Node2D

@export var spider_scene: PackedScene
@export var moth_scene: PackedScene
@export var wasp_scene: PackedScene

@export var wasp_spawn_points: Array[Node2D]
@export var spider_spawn_points: Array[Node2D]
@export var moth_spawn_points: Array[Node2D]

@export var spawn_delay: float = 1.0
@onready var spawn_timer := Timer.new()

@export var base_enemy_hp_multiplier := 1.0
@export var hp_per_wave := 0.15
@export var hp_per_minute := 0.10

var run_time := 0.0

signal wave_completed(wave_number: int)

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

func _ready() -> void:
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_delay
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	start_next_wave()

func _process(delta: float) -> void:
	run_time += delta

func start_next_wave() -> void:
	if wave_in_progress:
		return

	# Infinite scaling waves after the designed list
	if current_wave >= waves.size():
		var wave_scale := current_wave - waves.size() + 1
		print("Scaling factor for wave:", wave_scale)

		waves.append({
			"spider": 5 + wave_scale,
			"moth": 4 + int(wave_scale * 0.8),
			"wasp": 3 + int(wave_scale * 0.6)
		})

	current_wave += 1
	wave_in_progress = true
	enemies_alive = 0
	spawn_queue.clear()

	print("Starting wave", current_wave)

	var wave_data = waves[current_wave - 1]

	# Queue order (your original order)
	for i in range(wave_data.get("wasp", 0)):
		spawn_queue.append(wasp_scene)
	for i in range(wave_data.get("spider", 0)):
		spawn_queue.append(spider_scene)
	for i in range(wave_data.get("moth", 0)):
		spawn_queue.append(moth_scene)

	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if spawn_queue.is_empty():
		spawn_timer.stop()
		return

	var scene: PackedScene = spawn_queue.pop_front()
	var enemy: Node2D = scene.instantiate()

	# Difficulty scaling
	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(
			current_wave,
			get_enemy_hp_multiplier()
		)

	var spawn_point: Node2D = null
	if scene == spider_scene:
		spawn_point = spider_spawn_points.pick_random()
	elif scene == moth_scene:
		spawn_point = moth_spawn_points.pick_random()
	elif scene == wasp_scene:
		spawn_point = wasp_spawn_points.pick_random()

	if spawn_point == null:
		push_warning("No spawn point assigned!")
		return

	enemy.global_position = spawn_point.global_position
	enemy.enemy_died.connect(_on_enemy_died)

	add_child(enemy)
	enemies_alive += 1

func _on_enemy_died() -> void:
	if enemies_alive <= 0:
		return

	enemies_alive -= 1
	print("Enemy died. Remaining:", enemies_alive)

	# Wave ends only when nothing is alive AND nothing left to spawn
	if enemies_alive == 0 and spawn_queue.size() == 0:
		wave_in_progress = false

		# Wave rewards (skill points, post-wave heal skill)
		_on_wave_completed()

		# Optional: your Player.gd has heal_after_wave(amount)
		if Global.playerbody:
			Global.playerbody.heal_after_wave(10)

		# This is what FruitSpawner listens to
		emit_signal("wave_completed", current_wave)

		# Start the next wave after listeners run (fruit drop timing, etc.)
		call_deferred("start_next_wave")

func get_enemy_hp_multiplier() -> float:
	var wave_bonus := current_wave * hp_per_wave
	var time_bonus := (run_time / 60.0) * hp_per_minute
	return base_enemy_hp_multiplier + wave_bonus + time_bonus

func _on_wave_completed() -> void:
	print("Wave", current_wave, "completed!")

	# Add 1 skill point for finishing the wave
	SkillManager.add_skill_points(1)

	# Apply Post-Wave Heal if unlocked (1 heart)
	if SkillManager.post_wave_heal_active and Global.playerbody:
		Global.playerbody.current_health += 1
		if Global.playerbody.current_health > Global.playerbody.max_health:
			Global.playerbody.current_health = Global.playerbody.max_health
		print("Post-Wave Heal applied! Current Health:", Global.playerbody.current_health)
