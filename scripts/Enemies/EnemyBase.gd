extends CharacterBody2D
class_name EnemyBase

@export var max_health := 10
var current_health := 10

func apply_difficulty(wave: int, hp_multiplier: float) -> void:
	max_health = int(max_health * hp_multiplier)
	current_health = max_health
