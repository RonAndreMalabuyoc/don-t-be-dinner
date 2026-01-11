extends Node2D

@export var fruit_pickup_scene: PackedScene

@export var icon_pomegranate: Texture2D
@export var icon_orange: Texture2D
@export var icon_banana: Texture2D
@export var icon_coconut: Texture2D

@export var spacing: float = 60.0
@export var spawn_on_ready: bool = true

func _ready() -> void:
	if spawn_on_ready:
		spawn_all_4()

func spawn_all_4() -> void:
	if fruit_pickup_scene == null:
		push_error("FruitSpawner: fruit_pickup_scene is not set.")
		return

	_spawn_one(FruitPickup.FruitType.POMEGRANATE, icon_pomegranate, 0)
	_spawn_one(FruitPickup.FruitType.ORANGE,      icon_orange,      1)
	_spawn_one(FruitPickup.FruitType.BANANA,      icon_banana,      2)
	_spawn_one(FruitPickup.FruitType.COCONUT,     icon_coconut,     3)

func _spawn_one(ftype: int, icon: Texture2D, index: int) -> void:
	var inst := fruit_pickup_scene.instantiate() as Area2D
	add_child(inst)

	# Position in a row
	inst.global_position = global_position + Vector2(spacing * float(index), 0.0)

	# Set exported vars on FruitPickup
	inst.set("fruit_type", ftype)
	inst.set("icon", icon)
