extends FruitProjectile

@export var pomegranate_speed := 900.0
@export var pomegranate_damage := 8

func _ready() -> void:
	speed = pomegranate_speed
	damage = pomegranate_damage
	lifetime = 1.8
	pierce = 0
	super._ready()
