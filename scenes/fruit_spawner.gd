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
	_spawn(FruitPickup.FruitType.POMEGRANATE, icon_pomegranate, 0)
	_spawn(FruitPickup.FruitType.ORANGE,      icon_orange,      1)
	_spawn(FruitPickup.FruitType.BANANA,      icon_banana,      2)
	_spawn(FruitPickup.FruitType.COCONUT,     icon_coconut,     3)

func _spawn(ftype: int, tex: Texture2D, index: int) -> void:
	if fruit_pickup_scene == null:
		push_error("FruitSpawner: fruit_pickup_scene is not set.")
		return

	var inst := fruit_pickup_scene.instantiate() as FruitPickup
	add_child(inst)

	inst.global_position = global_position + Vector2(spacing * index, 0)

	inst.fruit_type = ftype
	inst.icon = tex
